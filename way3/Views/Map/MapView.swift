import SwiftUI
@_spi(Experimental) import MapboxMaps
import CoreLocation

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

// MARK: - Enhanced MapView with Pokemon GO Style
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
    @State private var showingMerchantSheet = false
    @State private var selectedMerchant: Merchant?
    @State private var showNearbyPlayers = false
    @State private var showTradeActivity = false
    @State private var showingLocationPicker = false

    // MARK: - 3D Puck State
    @State private var playerModelScale: [Double] = [2.0, 2.0, 2.0]
    @State private var playerModelOpacity: Double = 0.9
    @State private var isPlayerMoving = false

    // MARK: - Game State
    @State private var userLocation: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    @State private var isTracking = true
    @State private var nearbyMerchants: [Merchant] = []
    @State private var lastLocationUpdate = Date()

    // 플레이어 위치를 동기화하기 위한 computed property
    private var synchronizedLocation: CLLocationCoordinate2D? {
        if let playerLocation = gameManager.currentPlayer?.currentLocation {
            return playerLocation
        }
        return userLocation
    }

    // 오프라인 데이터 생성기
    private let offlineDataGenerator = OfflineDataGenerator()

    // 모든 상인을 표시 (거래는 상인 마커에서 거리 체크)
    private var allMerchants: [Merchant] {
        return offlineDataGenerator.generateOfflineData().merchants
    }
    
    var body: some View {
        ZStack {
            // 🗺️ Enhanced 3D Mapbox with Pokemon GO Style
            Map(viewport: $viewport) {
                // 🎯 Enhanced 3D Player Puck with Dynamic Animation
                Puck3D(model: create3DPlayerModel(), bearing: .heading)

                // 🏪 Animated Merchant Markers (Pokemon GO Style)
                ForEvery(allMerchants) { merchant in
                    MapViewAnnotation(coordinate: merchant.coordinate) {
                        EnhancedMerchantPinView(
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
        .sheet(isPresented: $showingMerchantSheet) {
            if let selectedMerchant = selectedMerchant {
                MerchantDetailSheet(merchant: selectedMerchant)
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
    }
    
    // MARK: - 🎮 Simplified Map Overlay
    private var pokemonGOStyleOverlay: some View {
        VStack {
            // 상단 영역은 비어있음 (플레이어 정보와 설정 아이콘 제거)
            Spacer()

            // 🎯 Bottom Action Panel with proper margin
            bottomActionPanel
        }
    }

    // MARK: - 👤 Enhanced Player Info Panel
    private var playerInfoPanel: some View {
        HStack(spacing: 12) {
            // 🎨 Player Avatar with Level Ring
            ZStack {
                Circle()
                    .stroke(Color.yellow, lineWidth: 3)
                    .frame(width: 48, height: 48)

                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                if let player = gameManager.currentPlayer {
                    Text(player.name)
                        .font(.custom("ChosunCentennial", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 2)

                    HStack(spacing: 8) {
                        // 💰 Money Display
                        HStack(spacing: 4) {
                            Image(systemName: "wonsign.circle.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                            Text("\(player.money)")
                                .font(.custom("ChosunCentennial", size: 12))
                                .foregroundColor(.white)
                        }

                        // 📊 Level Display
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("Lv.\(player.level)")
                                .font(.custom("ChosunCentennial", size: 12))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    Text("플레이어")
                        .font(.custom("ChosunCentennial", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(radius: 8)
    }

    // MARK: - 🎯 Bottom Action Panel (Pokemon GO Style)
    private var bottomActionPanel: some View {
        HStack(spacing: 24) {
            // 👥 Nearby Players
            actionButton(
                icon: "person.2.fill",
                title: "플레이어",
                badgeCount: socketManager.nearbyPlayers.count,
                color: .blue
            ) {
                showNearbyPlayers = true
            }

            // 🏪 Merchant Finder
            actionButton(
                icon: "storefront.fill",
                title: "상인",
                badgeCount: allMerchants.filter { $0.isActive }.count,
                color: .green
            ) {
                findNearestMerchant()
            }

            // 💱 Trade Activity
            actionButton(
                icon: "arrow.left.arrow.right",
                title: "거래",
                badgeCount: socketManager.recentTradeActivity.count,
                color: .orange
            ) {
                showTradeActivity = true
            }

            // 📍 Current Location
            actionButton(
                icon: "location.fill",
                title: "위치",
                color: .purple
            ) {
                centerOnPlayerLocation()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.bottom, 50)
        .shadow(radius: 12)
    }

    // MARK: - 🎮 Action Button Component
    private func actionButton(
        icon: String,
        title: String,
        badgeCount: Int? = nil,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 44, height: 44)
                        .shadow(radius: 4)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    // 📊 Badge Count
                    if let count = badgeCount, count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .fill(Color.red.gradient)
                            )
                            .offset(x: 16, y: -16)
                    }
                }

                Text(title)
                    .font(.custom("ChosunCentennial", size: 11))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(radius: 1)
            }
            .frame(width: 60, height: 70)
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
        // 플레이어 상태에 따른 3D 모델 선택
        let modelName = getPlayerModelName()

        // 🔍 로컬 3D 모델 파일 확인 및 개선된 오류 처리
        if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "glb") {
            print("✅ 로컬 glb 모델 발견: \(modelName).glb")
            return Model(
                uri: modelURL,
                orientation: [0, 0, 180],
                scale: [1.8, 1.8, 1.8]  // 로컬 모델도 크기 증가
            )
        } else if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "gltf") {
            print("✅ 로컬 gltf 모델 발견: \(modelName).gltf")
            return Model(
                uri: modelURL,
                orientation: [0, 0, 180],
                scale: [1.8, 1.8, 1.8]
            )
        } else {
            print("⚠️ 로컬 모델 없음. 기본 온라인 모델 사용: \(modelName)")
            // 기본 3D 플레이어 표현 사용
            return createDefaultPlayerModel()
        }
    }

    private func getPlayerModelName() -> String {
        guard let player = gameManager.currentPlayer else { return "player_default" }

        // 플레이어 레벨과 상태에 따른 모델 선택
        switch player.level {
        case 1...5:
            return isPlayerMoving ? "player_novice_walking" : "player_novice_idle"
        case 6...10:
            return isPlayerMoving ? "player_trader_walking" : "player_trader_idle"
        case 11...20:
            return isPlayerMoving ? "player_expert_walking" : "player_expert_idle"
        default:
            return isPlayerMoving ? "player_master_walking" : "player_master_idle"
        }
    }

    private func createDefaultPlayerModel() -> Model {
        // 💫 Enhanced 3D Player Model with Better Visibility
        // 신뢰성 높은 glTF 2.0 샘플 모델 사용 (안정적인 호스팅)
        let modelURLs = [
            "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/main/2.0/Duck/glTF-Binary/Duck.glb",
            "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/main/2.0/Avocado/glTF-Binary/Avocado.glb",
            "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/main/2.0/DamagedHelmet/glTF-Binary/DamagedHelmet.glb"
        ]

        // 플레이어 레벨에 따라 다른 모델 선택
        let modelIndex = min((gameManager.currentPlayer?.level ?? 1) / 5, modelURLs.count - 1)
        let selectedURL = modelURLs[modelIndex]

        guard let url = URL(string: selectedURL) else {
            // Fallback to most reliable model
            return Model(
                uri: URL(string: modelURLs[0])!,
                orientation: [0, 0, 0],
                scale: [1.5, 1.5, 1.5]
            )
        }

        return Model(
            uri: url,
            orientation: [0, 0, 0],
            scale: [1.5, 1.5, 1.5]  // 1.5배 크기로 가시성 향상
        )
    }

    // MARK: - 🎯 3D Puck Animation Methods
    private func startPlayerMovingAnimation() {
        guard !isPlayerMoving else { return }

        withAnimation(.easeInOut(duration: 0.5)) {
            isPlayerMoving = true
            playerModelScale = [2.2, 2.2, 2.2] // 움직일 때 약간 커짐
            playerModelOpacity = 1.0
        }

        // 걸음 애니메이션 효과
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            if isPlayerMoving {
                withAnimation(.easeInOut(duration: 0.4)) {
                    playerModelScale = playerModelScale == [2.2, 2.2, 2.2] ? [2.0, 2.0, 2.0] : [2.2, 2.2, 2.2]
                }
            } else {
                timer.invalidate()
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

    private func playTradeAnimation() {
        // 거래 시 특별한 애니메이션
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            playerModelScale = [2.5, 2.5, 2.5]
            playerModelOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                playerModelScale = [2.0, 2.0, 2.0]
                playerModelOpacity = 0.9
            }
        }
    }

    // MARK: - 🎮 Game Methods
    private func handleMerchantTap(_ merchant: Merchant) {
        // 500m 이내에서만 거래 가능
        if let syncLocation = synchronizedLocation {
            let merchantLocation = CLLocation(
                latitude: merchant.coordinate.latitude,
                longitude: merchant.coordinate.longitude
            )
            let userLocationCL = CLLocation(
                latitude: syncLocation.latitude,
                longitude: syncLocation.longitude
            )
            let distance = userLocationCL.distance(from: merchantLocation)

            if distance <= 1000 {
                selectedMerchant = merchant
                showingMerchantSheet = true

                // 🎯 Focus camera on merchant with smooth animation
                withAnimation(.easeInOut(duration: 1.2)) {
                    viewport = .camera(
                        center: merchant.coordinate,
                        zoom: 17,
                        bearing: 45,
                        pitch: 65
                    )
                }

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

    private func findNearestMerchant() {
        guard let playerLocation = synchronizedLocation else { return }

        let nearestMerchant = allMerchants.min { merchant1, merchant2 in
            let distance1 = CLLocation(
                latitude: merchant1.coordinate.latitude,
                longitude: merchant1.coordinate.longitude
            ).distance(from: CLLocation(
                latitude: playerLocation.latitude,
                longitude: playerLocation.longitude
            ))

            let distance2 = CLLocation(
                latitude: merchant2.coordinate.latitude,
                longitude: merchant2.coordinate.longitude
            ).distance(from: CLLocation(
                latitude: playerLocation.latitude,
                longitude: playerLocation.longitude
            ))

            return distance1 < distance2
        }

        if let merchant = nearestMerchant {
            withAnimation(.easeInOut(duration: 1.5)) {
                viewport = .camera(
                    center: merchant.coordinate,
                    zoom: 17,
                    bearing: 45,
                    pitch: 65
                )
            }
        }
    }

    private func centerOnPlayerLocation() {
        if let location = synchronizedLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
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

    private func stopTracking() {
        isTracking = false
        viewport = .idle
    }
}

// MARK: - 🎯 Enhanced Merchant Pin View (Pokemon GO Style)
struct EnhancedMerchantPinView: View {
    let merchant: Merchant
    let userLocation: CLLocationCoordinate2D?

    @State private var animationScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.7

    private var isNearby: Bool {
        guard let userLoc = userLocation else { return false }
        let distance = CLLocation(
            latitude: merchant.coordinate.latitude,
            longitude: merchant.coordinate.longitude
        ).distance(from: CLLocation(
            latitude: userLoc.latitude,
            longitude: userLoc.longitude
        ))
        return distance <= 500
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

            // 🏪 Main Merchant Pin
            Circle()
                .fill(merchant.type.color.gradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: merchant.type.iconName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
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
            animationScale = merchant.isActive ? 1.3 : 1.1
            pulseOpacity = merchant.isActive ? 0.8 : 0.4
        }
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
