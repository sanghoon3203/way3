import SwiftUI
@_spi(Experimental) import MapboxMaps
import CoreLocation
import UIKit

// MARK: - Enhanced MapView with 3D Player Visualization
struct MapView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var locationManager: LocationManager

    // MARK: - 3D Map Configuration
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        zoom: 16,
        bearing: 45,      // 45도 회전으로 입체감
        pitch: 65         // 더 기울여서 3D 효과 강화
    )

    // MARK: - UI State
    @State private var showingMerchantDetail = false
    @State private var selectedMerchant: Merchant?
    @State private var showNearbyPlayers = false

    // MARK: - 3D Puck State
    @State private var playerModelScale: [Double] = [2.0, 2.0, 2.0]
    @State private var playerModelOpacity: Double = 0.9
    @State private var isPlayerMoving = false

    // MARK: - Game State
    @State private var userLocation: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    // 플레이어 위치를 동기화하기 위한 computed property
    private var synchronizedLocation: CLLocationCoordinate2D? {
        if let currentGameLocation = gameManager.currentLocation {
            return currentGameLocation
        }
        if let playerLocation = gameManager.currentPlayer?.currentLocation {
            return playerLocation
        }
        return userLocation
    }

    // 서버 데이터 매니저
    private let merchantDataManager = MerchantDataManager.shared
    @State private var serverMerchants: [Merchant] = []
    @State private var isLoadingMerchants = false
    @State private var lastMerchantRequestLocation: CLLocationCoordinate2D?
    private let merchantSearchRadius: Double = 5000 // 5km로 확장 (서울 전역 커버)
    private let defaultMerchantCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    // ⚡ 모든 상인 표시 (거리 필터링 없음)
    private var allMerchants: [Merchant] {
        GameLogger.shared.logDebug("🏪 전체 상인 표시: \(serverMerchants.count)명", category: .gameplay)
        return serverMerchants
    }
    
    var body: some View {
        ZStack {
            // \
            Map(viewport: $viewport) {
                // 🎯 Enhanced 3D Player Puck with Dynamic Animation
                Puck3D(model: create3DPlayerModel(), bearing: .heading)

                // 🏪 Animated Merchant Markers
                ForEvery(allMerchants) { merchant in
                    MapViewAnnotation(coordinate: merchant.coordinate) {
                        OptimizedMerchantPinView(
                            merchant: merchant,
                            userLocation: synchronizedLocation
                        )
                        .onTapGesture {
                            handleMerchantTap(merchant)
                        }
                    }
                    .allowOverlap(true)
                }

            }
            .mapStyle(.standard(lightPreset: .night))
            .ignoresSafeArea()

            // 💰-📍 Restore UI Overlay
            pokemonGOStyleOverlay
        }
        .fullScreenCover(isPresented: $showingMerchantDetail) {
            if let selectedMerchant = selectedMerchant {
                MerchantDetailView(merchant: selectedMerchant, isPresented: $showingMerchantDetail)
                    .environmentObject(gameManager)
            }
        }
        // Nearby players feature removed (no multiplayer)
        .onAppear {
            setupGameEnvironment()
        }
        .onReceive(locationManager.$currentLocation.compactMap { $0 }) { latestLocation in
            userLocation = latestLocation
            withViewportAnimation(.default(maxDuration: 1.0)) {
                viewport = .camera(
                    center: latestLocation,
                    zoom: 16,
                    bearing: 45,
                    pitch: 65
                )
            }

            let shouldReloadMerchants: Bool
            if let previousLocation = lastMerchantRequestLocation {
                let distance = calculateDistance(from: previousLocation, to: latestLocation)
                shouldReloadMerchants = distance >= 10000
            } else {
                shouldReloadMerchants = true
            }

            if shouldReloadMerchants {
                Task {
                    await loadMerchantsFromServer()
                }
            }
        }
        .task {
            // 서버에서 상인 데이터 로드
            await loadMerchantsFromServer()
        }
    }
    
    // MARK: - 🌐 Server Data Loading
    @MainActor
    private func loadMerchantsFromServer() async {
        guard !isLoadingMerchants else { return }

        isLoadingMerchants = true

        do {
            // 서버에서 상인 목록 가져오기
            let networkManager = NetworkManager.shared
            let currentCoordinate = synchronizedLocation ?? defaultMerchantCoordinate
            let clampedRadius = min(max(merchantSearchRadius, 100), 5000)
            let response = try await networkManager.getNearbyMerchants(
                latitude: currentCoordinate.latitude,
                longitude: currentCoordinate.longitude,
                radius: clampedRadius
            )

            // 서버 응답을 Merchant 모델로 변환
            var merchants = response.merchants.map { merchantData in
                let tradeDistanceLimit = merchantData.tradeDistanceLimit.map(Double.init)
                let meetsRequirements = merchantData.meetsRequirements ?? true
                let withinTradeDistance = merchantData.withinTradeDistance ?? true

                var merchant = Merchant(
                    id: merchantData.id,
                    name: merchantData.name,
                    type: convertServerTypeToMerchantType(merchantData.type),
                    district: SeoulDistrict.fromCoordinate(lat: merchantData.location.lat, lng: merchantData.location.lng),
                    coordinate: CLLocationCoordinate2D(
                        latitude: merchantData.location.lat,
                        longitude: merchantData.location.lng
                    ),
                    requiredLicense: LicenseLevel(rawValue: merchantData.requiredLicense) ?? .beginner,
                    isActive: merchantData.canTrade,
                    imageFileName: merchantData.imageFileName ?? generateImageFileName(from: merchantData.name),
                    withinTradeDistance: withinTradeDistance,
                    tradeDistanceLimit: tradeDistanceLimit,
                    meetsRequirements: meetsRequirements
                )
                merchant.distance = Double(merchantData.distance)
                return merchant
            }

            var coordinateUsed = currentCoordinate

            // 근처 상인이 없으면 서울 중심 좌표로 폴백
            if merchants.isEmpty {
                let fallbackRadius = 5000.0
                let fallbackResponse = try await networkManager.getNearbyMerchants(
                    latitude: defaultMerchantCoordinate.latitude,
                    longitude: defaultMerchantCoordinate.longitude,
                    radius: fallbackRadius
                )

                let fallbackMerchants = fallbackResponse.merchants.map { merchantData in
                    let tradeDistanceLimit = merchantData.tradeDistanceLimit.map(Double.init)
                    let meetsRequirements = merchantData.meetsRequirements ?? true
                    let withinTradeDistance = merchantData.withinTradeDistance ?? true

                    var merchant = Merchant(
                        id: merchantData.id,
                        name: merchantData.name,
                        type: convertServerTypeToMerchantType(merchantData.type),
                        district: SeoulDistrict.fromCoordinate(lat: merchantData.location.lat, lng: merchantData.location.lng),
                        coordinate: CLLocationCoordinate2D(
                            latitude: merchantData.location.lat,
                            longitude: merchantData.location.lng
                        ),
                        requiredLicense: LicenseLevel(rawValue: merchantData.requiredLicense) ?? .beginner,
                        isActive: merchantData.canTrade,
                        imageFileName: merchantData.imageFileName ?? generateImageFileName(from: merchantData.name),
                        withinTradeDistance: withinTradeDistance,
                        tradeDistanceLimit: tradeDistanceLimit,
                        meetsRequirements: meetsRequirements
                    )
                    merchant.distance = Double(merchantData.distance)
                    return merchant
                }

                if !fallbackMerchants.isEmpty {
                    merchants = fallbackMerchants
                    coordinateUsed = defaultMerchantCoordinate
                    GameLogger.shared.logInfo("실제 위치 주변에 상인이 없어 서울 좌표로 폴백했습니다", category: .network)
                }
            }

            // UI 업데이트
            serverMerchants = merchants
            lastMerchantRequestLocation = coordinateUsed
            GameLogger.shared.logDebug("서버에서 \(merchants.count)명의 상인 데이터 로드 완료", category: .network)

            // 디버깅: 각 상인의 위치 출력
            for merchant in merchants {
                GameLogger.shared.logDebug("  🏪 \(merchant.name): (\(merchant.coordinate.latitude), \(merchant.coordinate.longitude))", category: .network)
            }

        } catch {
            GameLogger.shared.logError("상인 데이터 로드 실패: \(error)", category: .network)
            // 오류 시 빈 배열 유지 (fallback은 서버에서 처리됨)
        }

        isLoadingMerchants = false
    }

    // 서버 타입을 앱 MerchantType으로 변환
    private func convertServerTypeToMerchantType(_ serverType: String) -> MerchantType {
        switch serverType {
        case "weaponsmith": return .retail
        case "cafe": return .foodMerchant
        case "auction": return .antique
        case "retail": return .retail
        default: return .retail
        }
    }

    // MARK: - 🎮 Simplified Map Overlay
    private var pokemonGOStyleOverlay: some View {
        ZStack {
            // 💰 Money Display (왼쪽 하단 - 패딩 없이 Mapbox 로고 덮기)
            VStack {
                Spacer()
                HStack {
                    moneyDisplayComponent
                    Spacer()
                }
            }

            // 📍 Location Button (오른쪽 하단 - 바닥에 딱 붙이기)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    locationButton
                }
            }
        }
    }


    // MARK: - 💰 Money Display Component (Cyberpunk Theme)
    private var moneyDisplayComponent: some View {
        HStack(spacing: 8) {
            Image(systemName: "wonsign.circle.fill")
                .foregroundColor(.cyberpunkYellow)
                .font(.system(size: 18, weight: .bold, design: .monospaced))

            if let player = gameManager.currentPlayer {
                Text("₩\(player.money.formatted())")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            } else {
                Text("₩0")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.cyberpunkDarkBg)
                .overlay(
                    Rectangle()
                        .stroke(Color.cyberpunkYellow, lineWidth: 2)
                )
        )
        .overlay(
            Rectangle()
                .fill(Color.cyberpunkYellow)
                .frame(width: 4),
            alignment: .leading
        )
    }

    // MARK: - 📍 Location Button (Cyberpunk Theme)
    private var locationButton: some View {
        Button(action: {
            centerOnPlayerLocation()
        }) {
            Image(systemName: "location.fill")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.cyberpunkCyan)
                .frame(width: 50, height: 50)
                .background(
                    Rectangle()
                        .fill(Color.cyberpunkDarkBg)
                        .overlay(
                            Rectangle()
                                .stroke(Color.cyberpunkCyan, lineWidth: 2)
                        )
                )
                .overlay(
                    Rectangle()
                        .fill(Color.cyberpunkCyan)
                        .frame(width: 4),
                    alignment: .leading
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 📊 Trade Activity Feed
    private var tradeActivityFeed: some View {
        VStack {
            HStack {
                Spacer()

                // Trade activity notifications removed (multiplayer feature)
            }

            Spacer()
        }
    }

    // MARK: - 🎯 3D Player Model Configuration
    private func create3DPlayerModel() -> Model {
        let modelName = getPlayerModelName()

        // 🚀 개선된 모델 로딩 시스템: 캐싱 + 폴백
        return loadOptimizedPlayerModel(named: modelName)
    }

    // 🎯 로컬 전용 모델 로딩 시스템
    private func loadOptimizedPlayerModel(named modelName: String) -> Model {
        // 1차: 요청된 모델 검색 (glb, gltf 순서)
        if let modelURL = findLocalModel(named: modelName, extension: "glb") ?? findLocalModel(named: modelName, extension: "gltf") {
            print("✅ 모델 로드 성공: \(modelName)")
            return createModelWithOptimization(url: modelURL)
        }

        // 2차: 요청된 모델이 없을 경우, 기본 모델로 폴백
        print("❌ 모델 없음: '\(modelName)'. 기본 모델('player_novice_idle')로 폴백합니다.")
        let fallbackModelName = "player_novice_idle"
        
        guard let fallbackURL = findLocalModel(named: fallbackModelName, extension: "glb") ?? findLocalModel(named: fallbackModelName, extension: "gltf") else {
            // 최후의 수단: 기본 모델조차 없으면 크래시 발생.
            // 이는 앱 번들에 필수 리소스가 없다는 의미이므로, 개발 중에 바로잡아야 합니다.
            fatalError("기본 플레이어 모델('player_novice_idle.glb' 또는 '.gltf')을 찾을 수 없습니다. Resources/3D_Models/ 폴더를 확인해주세요.")
        }
        
        print("✅ 기본 모델 로드 성공: \(fallbackModelName)")
        return createModelWithOptimization(url: fallbackURL)
    }

    // 🔍 로컬 모델 파일 검색 최적화
    private func findLocalModel(named modelName: String, extension fileExtension: String) -> URL? {
        // Resources/3D_Models/ 폴더에서 검색
        return Bundle.main.url(forResource: "3D_Models/\(modelName)", withExtension: fileExtension) ??
               Bundle.main.url(forResource: modelName, withExtension: fileExtension)
    }

    // 🎯 최적화된 3D 모델 생성
    private func createModelWithOptimization(url: URL) -> Model {
        return Model(
            uri: url,
            orientation: [0, 0, 180]
        )
    }

    // 🎯 스마트 모델 네이밍 시스템
    private func getPlayerModelName() -> String {
        guard let player = gameManager.currentPlayer else { return "player_novice_idle" }

        let levelTier = getPlayerLevelTier(level: player.level)
        let animationState = isPlayerMoving ? "walking" : "idle"

        return "player_\(levelTier)_\(animationState)"
    }

    private func getPlayerLevelTier(level: Int) -> String {
        switch level {
        case 1...5: return "novice"    // 초보자: 간단한 복장
        case 6...10: return "trader"   // 상인: 가방, 계산기
        case 11...20: return "expert"  // 전문가: 정장, 브리프케이스
        default: return "master"       // 마스터: 화려한 복장
        }
    }

    // MARK: - 상인 이미지 파일명 생성
    private func generateImageFileName(from merchantName: String) -> String {
        // 서버에서 받은 상인 이름을 Resources 폴더 구조에 맞게 변환
        // 예: "서예나" -> "Seoyena"
        let imageFileName = convertKoreanNameToFileName(merchantName)
        return imageFileName
    }

    private func convertKoreanNameToFileName(_ koreanName: String) -> String {
        // 한국 이름 -> 영어 파일명 매핑
        let nameMapping: [String: String] = [
            "서예나": "Seoyena",
            "알리스강": "Alicegang",
            "애니박": "Anipark",
            "카타리나최": "Catarinachoi",
            "진백호": "Jinbaekho",
            "주불수": "Jubulsu",
            "기주리": "Kijuri",
            "김세휘": "Kimsehwui",
            "마리": "Mari"
        ]

        return nameMapping[koreanName] ?? koreanName
    }


    // MARK: - 🎯 최적화된 3D 애니메이션 시스템
    private func startPlayerMovingAnimation() {
        guard !isPlayerMoving else { return }

        withAnimation(.easeInOut(duration: 0.5)) {
            isPlayerMoving = true
            playerModelScale = [2.2, 2.2, 2.2]
            playerModelOpacity = 1.0
        }

        // ⚡ 성능 최적화: 타이머 대신 애니메이션 체인 사용
        startContinuousWalkingAnimation()
    }

    // 🚶‍♂️ 지속적인 걸음 애니메이션 (메모리 효율적)
    private func startContinuousWalkingAnimation() {
        guard isPlayerMoving else { return }

        withAnimation(.easeInOut(duration: 0.4)) {
            playerModelScale = [2.0, 2.0, 2.0]
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard self.isPlayerMoving else { return }

            withAnimation(.easeInOut(duration: 0.4)) {
                self.playerModelScale = [2.2, 2.2, 2.2]
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.startContinuousWalkingAnimation() // 재귀 호출
            }
        }
    }

    private func stopPlayerMovingAnimation() {
        guard isPlayerMoving else { return }

        withAnimation(.easeInOut(duration: 0.5)) {
            isPlayerMoving = false
            playerModelScale = [2.0, 2.0, 2.0]
            playerModelOpacity = 0.9
        }
    }

    // 💰 거래 애니메이션 (향상된 피드백)
    private func playTradeAnimation() {
        // 💫 거래 성공 피드백: 확대 + 회전 + 펄스
        let originalScale = playerModelScale
        let originalOpacity = playerModelOpacity

        // 1단계: 확대 애니메이션
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            playerModelScale = [2.8, 2.8, 2.8]
            playerModelOpacity = 1.0
        }

        // 2단계: 펄스 효과
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.2).repeatCount(2, autoreverses: true)) {
                self.playerModelOpacity = 0.7
            }
        }

        // 3단계: 원래 상태로 복귀
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.playerModelScale = originalScale
                self.playerModelOpacity = originalOpacity
            }
        }

        // 🎵 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }

    // MARK: - 🛠️ 유틸리티 함수들
    private func calculateDistance(from location1: CLLocationCoordinate2D, to location2: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: location1.latitude, longitude: location1.longitude)
        let loc2 = CLLocation(latitude: location2.latitude, longitude: location2.longitude)
        return loc1.distance(from: loc2)
    }

    private func focusCamera(on coordinate: CLLocationCoordinate2D, zoom: Double = 17) {
        withAnimation(.easeInOut(duration: 1.2)) {
            viewport = .camera(
                center: coordinate,
                zoom: zoom,
                bearing: 45,
                pitch: 65
            )
        }
    }

    // MARK: - 🎮 Game Methods
    private func handleMerchantTap(_ merchant: Merchant) {
        selectedMerchant = merchant
        showingMerchantDetail = true

        // 🎯 Focus camera on merchant with smooth animation
        focusCamera(on: merchant.coordinate)

        // 🎯 플레이어 거래 애니메이션 실행
        playTradeAnimation()

        if let syncLocation = synchronizedLocation {
            let distance = calculateDistance(from: syncLocation, to: merchant.coordinate)
            GameLogger.shared.logDebug("상인 선택됨: \(merchant.name) (거리: \(Int(distance))m)", category: .gameplay)
        } else {
            GameLogger.shared.logDebug("상인 선택됨: \(merchant.name)", category: .gameplay)
        }
    }


    private func centerOnPlayerLocation() {
        if let location = synchronizedLocation {
            withViewportAnimation(.default(maxDuration: 1.0)) {
                viewport = .camera(
                    center: location,
                    zoom: 16,
                    bearing: 45,
                    pitch: 65
                )
            }
        }
    }

    private func setupGameEnvironment() {
        // 📍 Start GPS location tracking
        locationManager.startLocationUpdates()
        GameLogger.shared.logInfo("🌍 GPS 위치 추적 시작", category: .system)

        // 🔄 Setup location tracking and movement detection
        var lastKnownLocation: CLLocationCoordinate2D?

        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            if let location = synchronizedLocation,
               let playerId = gameManager.currentPlayer?.id {

                // 📍 위치 변경 감지 및 이동 애니메이션
                if let lastLocation = lastKnownLocation {
                    let lastLocationCL = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                    let currentLocationCL = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    let distance = lastLocationCL.distance(from: currentLocationCL)

                    if distance > 5.0 { // 5미터 이상 이동했을 때
                        startPlayerMovingAnimation()

                        // 1.5초 후 이동 애니메이션 중지
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            stopPlayerMovingAnimation()
                        }
                    }
                }

                lastKnownLocation = location
                // Socket location update removed (multiplayer feature)
            }
        }

        // 🎯 3D Puck 초기화
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                playerModelScale = [2.0, 2.0, 2.0]
                playerModelOpacity = 0.9
            }
        }
    }

}

// MARK: - ⚡ 최적화된 상인 핀 뷰 (Pokemon GO Style + 성능 개선)
struct OptimizedMerchantPinView: View {
    let merchant: Merchant
    let userLocation: CLLocationCoordinate2D?

    @State private var animationScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.7
    @StateObject private var imageManager = MerchantImageManager.shared

    private var isNearby: Bool {
        return true
    }

    // ⚡ 로컬 거리 계산 유틸리티
    private func calculateDistance(from location1: CLLocationCoordinate2D, to location2: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: location1.latitude, longitude: location1.longitude)
        let loc2 = CLLocation(latitude: location2.latitude, longitude: location2.longitude)
        return loc1.distance(from: loc2)
    }

    var body: some View {
        ZStack {
            // 🌊 Outer Pulsing Ring (Pokemon GO Style)
            Circle()
                .fill(merchant.type.color.opacity(0.3))
                .frame(width: 70, height: 70)
                .scaleEffect(animationScale)
                .opacity(pulseOpacity)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: animationScale
                )

            // 💫 Middle Ring
            Circle()
                .fill(merchant.type.color.opacity(0.5))
                .frame(width: 50, height: 50)
                .scaleEffect(isNearby ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: isNearby)

            // 🏪 Main Merchant Pin with Real Image
            Circle()
                .fill(merchant.type.color.gradient)
                .frame(width: 36, height: 36)
                .overlay(
                    // 실제 상인 이미지 사용
                    Group {
                        if let image = imageManager.loadImage(for: merchant.name, imageFileName: merchant.imageFileName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            // 이미지가 없을 경우 fallback 아이콘
                            Image(systemName: merchant.type.iconName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                )
                .shadow(radius: 6)

            // ✨ Active Status Indicator
            if merchant.isActive && isNearby {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
                    .offset(x: 16, y: -16)
                    .shadow(radius: 2)
            }
        }
        .onAppear {
            // ⚡ 성능 최적화: 어니메이션 간소화
            animationScale = merchant.isActive ? 1.2 : 1.05
            pulseOpacity = merchant.isActive ? 0.7 : 0.3
        }
        .drawingGroup() // 렌더링 성능 향상
    }
}

// Multiplayer components removed (NearbyPlayerPinView, TradeActivityNotification)

// MARK: - 🎨 Merchant Type Extensions
extension MerchantType {
    var color: Color {
        switch self {
        case .retail: return .blue
        case .tech: return .purple
        case .fashion: return .pink
        case .foodMerchant: return .orange
        case .antique: return .brown
        default: return .gray
        }
    }

    var iconName: String {
        switch self {
        case .retail: return "bag.fill"
        case .tech: return "desktopcomputer"
        case .fashion: return "tshirt.fill"
        case .foodMerchant: return "fork.knife"
        case .antique: return "building.columns.fill"
        default: return "storefront.fill"
        }
    }
}
