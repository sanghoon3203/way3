import SwiftUI
@_spi(Experimental) import MapboxMaps
import CoreLocation
import UIKit

/**
 * 🎯 3D Player Puck 사용 가이드:
 *
 * 1. 3D 모델 파일 추가:
 *    - Bundle에 .glb 또는 .gltf 파일 추가
 *    - 파일명: player_novice_idle.glb, player_trader_walking.glb 등
 *
 * 2. 권장 3D 모델 사양:
 *    - 파일 크기: < 2MB
 *    - 폴리곤 수: < 5,000 triangles
 *    - 텍스처 해상도: 512x512 이하
 *    - 포맷: glTF 2.0 (.glb) 권장
 *
*
 * 4. 테스트용 모델:
 *    - Khronos glTF Sample Models 사용 중
 *    - 실제 게임용 캐릭터로 교체 권장
 */

// MARK: - Enhanced MapView with 3D Player Visualization
struct MapView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var socketManager = SocketManager.shared

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
    private let merchantSearchRadius: Double = 2000
    private let defaultMerchantCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    // ⚡ 성능 최적화: 화면에 보이는 상인만 표시
    private var allMerchants: [Merchant] {
        // 화면에 보이는 상인만 필터링 (성능 향상)
        guard let userLoc = synchronizedLocation else { return serverMerchants }

        return serverMerchants.filter { merchant in
            let distance = calculateDistance(from: userLoc, to: merchant.coordinate)
            return distance <= 2000 // 2km 이내 상인만 표시
        }
    }
    
    var body: some View {
        ZStack {
            // 🗺️ Enhanced 3D Mapbox with Pokemon GO Style
            Map(viewport: $viewport) {
                // 🎯 Enhanced 3D Player Puck with Dynamic Animation
                Puck3D(model: create3DPlayerModel(), bearing: .heading)

                // 🏪 Animated Merchant Markers (Pokemon GO Style)
                ForEvery(allMerchants.prefix(20)) { merchant in
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

                // 👥 Nearby Players Display
                ForEvery(socketManager.nearbyPlayers) { nearbyPlayer in
                    MapViewAnnotation(coordinate: nearbyPlayer.location) {
                        NearbyPlayerPinView(player: nearbyPlayer)
                            .onTapGesture {
                                // Show player info or trade offer
                                GameLogger.shared.logDebug("근처 플레이어 선택: \(nearbyPlayer.name)", category: .gameplay)
                            }
                    }
                    .allowOverlap(true)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()

            // 🎮 Pokemon GO Style UI Overlay
            pokemonGOStyleOverlay

            // 📊 Real-time Activity Feed
            if !socketManager.recentTradeActivity.isEmpty {
                tradeActivityFeed
            }
        }
        .fullScreenCover(isPresented: $showingMerchantDetail) {
            if let selectedMerchant = selectedMerchant {
                MerchantDetailView(merchant: selectedMerchant, isPresented: $showingMerchantDetail)
                    .environmentObject(gameManager)
            }
        }
        .sheet(isPresented: $showNearbyPlayers) {
            NearbyPlayersView()
                .environmentObject(socketManager)
        }
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
                shouldReloadMerchants = distance >= 200
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
                Merchant(
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
                    imageFileName: generateImageFileName(from: merchantData.name)
                )
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
                    Merchant(
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
                        imageFileName: generateImageFileName(from: merchantData.name)
                    )
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
            // 💰 Money Display (왼쪽 하단)
            VStack {
                Spacer()
                HStack {
                    moneyDisplayComponent
                    Spacer()
                }
                .padding(.leading, 30)
                .padding(.bottom, 20)
            }

            // 📍 Location Button (오른쪽 하단)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    locationButton
                }
                .padding(.trailing, 30)
                .padding(.bottom, 40)
            }
        }
    }


    // MARK: - 💰 Money Display Component
    private var moneyDisplayComponent: some View {
        HStack(spacing: 8) {
            Image(systemName: "wonsign.circle.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16, weight: .semibold))

            if let player = gameManager.currentPlayer {
                Text("₩\(player.money.formatted())")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text("₩0")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    // MARK: - 📍 Location Button
    private var locationButton: some View {
        Button(action: {
            centerOnPlayerLocation()
        }) {
            Image(systemName: "location.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.purple.gradient)
                        .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 📊 Trade Activity Feed
    private var tradeActivityFeed: some View {
        VStack {
            HStack {
                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(socketManager.recentTradeActivity.prefix(3), id: \.id) { activity in
                        TradeActivityNotification(activity: activity)
                    }
                }
                .padding(.trailing)
                .padding(.top, 120)
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
        // 1차: 로컬 GLB 모델 검색 (Resources/3D_Models/)
        if let modelURL = findLocalModel(named: modelName, extension: "glb") {
            print("✅ 로컬 GLB 모델 로드: \(modelName).glb")
            return createModelWithOptimization(url: modelURL)
        }

        // 2차: 로컬 GLTF 모델 검색
        if let modelURL = findLocalModel(named: modelName, extension: "gltf") {
            print("✅ 로컬 GLTF 모델 로드: \(modelName).gltf")
            return createModelWithOptimization(url: modelURL)
        }

        // 모델 없음: 기본 큐브나 빈 모델 사용
        print("❌ 로컬 모델 없음: \(modelName) - 기본 모델 사용")
        return createEmptyPlayerModel()
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
            "아니박": "Anipark",
            "카타리나최": "Catarinachoi",
            "진백호": "Jinbaekho",
            "주불수": "Jubulsu",
            "기주리": "Kijuri",
            "김세휘": "Kimsehwui",
            "마리": "Mari"
        ]

        return nameMapping[koreanName] ?? koreanName
    }

    // 📦 기본 빈 모델 (로컬 모델 없을 때 사용)
    private func createEmptyPlayerModel() -> Model {
        // 기본 학습용 모델 또는 빈 모델 반환
        // 사용자가 모델을 추가할 때까지 대기
        fatalError("📦 3D 모델을 Resources/3D_Models/ 폴더에 추가해주세요!\n필요한 모델: \(getPlayerModelName())")
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
        // 1000m 이내에서만 거래 가능
        if let syncLocation = synchronizedLocation {
            let distance = calculateDistance(from: syncLocation, to: merchant.coordinate)

            if distance <= 1000 {
                selectedMerchant = merchant
                showingMerchantDetail = true

                // 🎯 Focus camera on merchant with smooth animation
                focusCamera(on: merchant.coordinate)

                // 🎯 플레이어 거래 애니메이션 실행
                playTradeAnimation()

                GameLogger.shared.logDebug("상인 선택됨: \(merchant.name) (거리: \(Int(distance))m)", category: .gameplay)
            } else {
                GameLogger.shared.logDebug("거래 불가: \(merchant.name) (거리: \(Int(distance))m > 500m)", category: .gameplay)

                // 🚫 Show distance warning with haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
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
                socketManager.updatePlayerLocation(coordinate: location, playerId: playerId)
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
        guard let userLoc = userLocation else { return false }
        let distance = calculateDistance(from: userLoc, to: merchant.coordinate)
        return distance <= 500
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

// MARK: - 👥 Nearby Player Pin View
struct NearbyPlayerPinView: View {
    let player: SocketManager.NearbyPlayer

    var body: some View {
        ZStack {
            // 🌀 Player Aura
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 50, height: 50)

            // 👤 Player Pin
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 32, height: 32)
                .overlay(
                    Text("\(player.level)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
                .shadow(radius: 4)
        }
    }
}

// MARK: - 📢 Trade Activity Notification
struct TradeActivityNotification: View {
    let activity: SocketManager.TradeActivity

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right")
                .foregroundColor(.green)
                .font(.system(size: 14, weight: .semibold))

            Text("\(activity.playerName)님이 거래를 완료했습니다")
                .font(.custom("ChosunCentennial", size: 12))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(radius: 4)
    }
}

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
