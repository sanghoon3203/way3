// 📁 Managers/GameManager.swift - 중앙 게임 상태 관리자
import SwiftUI
import Combine
import CoreLocation

/**
 * GameManager
 *
 * 게임의 중앙 상태 관리 클래스
 * - 플레이어 상태 관리
 * - 게임 진행 상황 추적
 * - 게임 로직 중앙화
 * - 다양한 매니저들 간의 조정 역할
 */
@MainActor
class GameManager: ObservableObject {
    static let shared = GameManager()

    // MARK: - Published Properties
    @Published var currentPlayer: Player?
    @Published var isGameActive: Bool = false
    @Published var gameState: GameState = .inactive
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var nearbyMerchants: [Merchant] = []
    @Published var marketPrices: [MarketPrice] = []
    @Published var gameNotifications: [GameNotification] = []

    // MARK: - Game Statistics
    @Published var gameStats: GameStatistics = GameStatistics()

    // MARK: - Managers Dependencies
    private var networkManager: NetworkManager
    private var locationManager: LocationManager
    private var tradeManager: TradeManager
    private var authManager: AuthManager
    private var socketManager: SocketManager

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var gameTimer: Timer?
    private var autoSaveTimer: Timer?

    // MARK: - Initialization
    private init() {
        self.networkManager = NetworkManager.shared
        self.locationManager = LocationManager.shared
        self.tradeManager = TradeManager.shared
        self.authManager = AuthManager.shared
        self.socketManager = SocketManager.shared

        setupObservers()
        setupAutoSave()
    }

    // MARK: - Game Lifecycle

    /**
     * 게임 시작
     */
    func startGame() {
        guard let player = currentPlayer else {
            GameLogger.shared.logError("플레이어 정보 없음", category: .game)
            return
        }

        isGameActive = true
        gameState = .active

        // 위치 추적 시작
        locationManager.startLocationUpdates()

        // 주기적 게임 업데이트 시작
        startGameLoop()

        // 게임 시작 알림
        addNotification(
            title: "게임 시작!",
            message: "\(player.core.name)님, 모험을 시작하세요!",
            type: .info
        )

        GameLogger.shared.logInfo("게임 시작됨", category: .game)
    }

    /**
     * 게임 일시정지
     */
    func pauseGame() {
        gameState = .paused
        stopGameLoop()
        locationManager.stopLocationUpdates()

        GameLogger.shared.logInfo("게임 일시정지됨", category: .game)
    }

    /**
     * 게임 재개
     */
    func resumeGame() {
        guard isGameActive else { return }

        gameState = .active
        locationManager.startLocationUpdates()
        startGameLoop()

        GameLogger.shared.logInfo("게임 재개됨", category: .game)
    }

    /**
     * 게임 종료
     */
    func stopGame() {
        isGameActive = false
        gameState = .inactive

        stopGameLoop()
        locationManager.stopLocationUpdates()

        // 게임 데이터 저장
        saveGameData()

        GameLogger.shared.logInfo("게임 종료됨", category: .game)
    }

    // MARK: - Player Management

    /**
     * 플레이어 설정
     */
    func setPlayer(_ player: Player) {
        self.currentPlayer = player
        updateGameStatistics()

        GameLogger.shared.logInfo("플레이어 설정됨 - \(player.core.name)", category: .game)
    }

    /**
     * 플레이어 데이터 새로고침
     */
    func refreshPlayerData() async {
        do {
            let response = try await networkManager.getPlayerData()
            if response.success, let playerDetail = response.data {
                // PlayerDetail을 Player로 변환하는 로직 필요
                updatePlayerFromDetail(playerDetail)
            }
        } catch {
            GameLogger.shared.logError("플레이어 데이터 새로고침 실패 - \(error)", category: .game)
            addNotification(
                title: "데이터 동기화 실패",
                message: "플레이어 정보를 업데이트할 수 없습니다",
                type: .error
            )
        }
    }

    // MARK: - Location Management

    /**
     * 위치 업데이트
     */
    func updateLocation(_ coordinate: CLLocationCoordinate2D) {
        currentLocation = coordinate

        // 서버에 위치 전송
        Task {
            do {
                _ = try await networkManager.updatePlayerLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            } catch {
                GameLogger.shared.logError("위치 업데이트 실패 - \(error)", category: .game)
            }
        }

        // 근처 상인 검색
        searchNearbyMerchants()
    }

    /**
     * 근처 상인 검색
     */
    func searchNearbyMerchants() {
        guard let location = currentLocation else { return }

        Task {
            do {
                let response = try await networkManager.getMerchants(
                    latitude: location.latitude,
                    longitude: location.longitude
                )

                if response.success, let merchants = response.data {
                    await MainActor.run {
                        self.nearbyMerchants = merchants.map { merchantData in
                            // MerchantData를 Merchant로 변환
                            convertMerchantData(merchantData)
                        }
                    }
                }
            } catch {
                GameLogger.shared.logError("근처 상인 검색 실패 - \(error)", category: .game)
            }
        }
    }

    // MARK: - Market Data

    /**
     * 시장 가격 업데이트
     */
    func updateMarketPrices() async {
        do {
            let response = try await networkManager.getMarketPrices()
            if response.success, let prices = response.data {
                await MainActor.run {
                    self.marketPrices = prices
                }
            }
        } catch {
            GameLogger.shared.logError("시장 가격 업데이트 실패 - \(error)", category: .game)
        }
    }

    // MARK: - Game Notifications

    /**
     * 게임 알림 추가
     */
    func addNotification(title: String, message: String, type: GameNotificationType) {
        let notification = GameNotification(
            id: UUID().uuidString,
            title: title,
            message: message,
            type: type,
            timestamp: Date()
        )

        gameNotifications.append(notification)

        // 알림 개수 제한 (최근 20개만 유지)
        if gameNotifications.count > 20 {
            gameNotifications.removeFirst(gameNotifications.count - 20)
        }
    }

    /**
     * 알림 제거
     */
    func removeNotification(_ notification: GameNotification) {
        gameNotifications.removeAll { $0.id == notification.id }
    }

    /**
     * 모든 알림 제거
     */
    func clearAllNotifications() {
        gameNotifications.removeAll()
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // 인증 상태 관찰
        authManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if !isAuthenticated {
                    self?.stopGame()
                }
            }
            .store(in: &cancellables)

        // 위치 업데이트 관찰
        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.updateLocation(location)
            }
            .store(in: &cancellables)

        // 네트워크 상태 관찰
        networkManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if !isConnected && self?.isGameActive == true {
                    self?.addNotification(
                        title: "연결 끊김",
                        message: "네트워크 연결을 확인해주세요",
                        type: .warning
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.saveGameData()
        }
    }

    private func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.gameLoopTick()
            }
        }
    }

    private func stopGameLoop() {
        gameTimer?.invalidate()
        gameTimer = nil
    }

    private func gameLoopTick() async {
        guard gameState == .active else { return }

        // 주기적 게임 업데이트
        await updateMarketPrices()
        updateGameStatistics()

        // 게임 이벤트 체크
        checkGameEvents()
    }

    private func saveGameData() {
        // UserDefaults나 Core Data에 게임 상태 저장
        // 현재는 간단한 UserDefaults 사용
        if let player = currentPlayer {
            UserDefaults.standard.set(true, forKey: "hasGameData")
            UserDefaults.standard.set(player.core.name, forKey: "lastPlayerName")
        }

        GameLogger.shared.logInfo("게임 데이터 저장됨", category: .game)
    }

    private func updateGameStatistics() {
        guard let player = currentPlayer else { return }

        gameStats.totalMoney = player.core.money
        gameStats.totalItems = player.inventory.inventory.count
        gameStats.trustPoints = player.core.trustPoints
        gameStats.currentLevel = player.stats.level
    }

    private func checkGameEvents() {
        // 게임 이벤트 체크 로직
        // 예: 레벨업, 달성, 특별 이벤트 등
    }

    private func updatePlayerFromDetail(_ detail: PlayerDetail) {
        guard var player = currentPlayer else { return }

        // PlayerDetail의 정보로 Player 업데이트
        player.core.money = detail.money
        player.core.trustPoints = detail.trustPoints
        player.core.currentLicense = LicenseLevel(rawValue: detail.currentLicense) ?? .beginner
        player.inventory.maxInventorySize = detail.maxInventorySize

        currentPlayer = player
    }

    private func convertMerchantData(_ data: MerchantData) -> Merchant {
        var merchant = Merchant(
            id: data.id,
            name: data.name,
            type: MerchantType(rawValue: data.type) ?? .retail,
            district: SeoulDistrict(rawValue: data.district) ?? .jongno,
            coordinate: data.location.coordinate,
            requiredLicense: LicenseLevel(rawValue: data.requiredLicense) ?? .beginner,
            inventory: data.inventory
        )
        merchant.distance = data.distance ?? 0.0
        return merchant
    }
}

// MARK: - Game State Enum
enum GameState {
    case inactive
    case active
    case paused
    case loading
}

// MARK: - Game Statistics
struct GameStatistics {
    var totalMoney: Int = 0
    var totalItems: Int = 0
    var trustPoints: Int = 0
    var currentLevel: Int = 1
    var playTime: TimeInterval = 0
    var tradesCompleted: Int = 0
    var achievementsUnlocked: Int = 0
}

// MARK: - Game Notification
struct GameNotification: Identifiable {
    let id: String
    let title: String
    let message: String
    let type: GameNotificationType
    let timestamp: Date
}

enum GameNotificationType {
    case info
    case success
    case warning
    case error
    case achievement
}

// MARK: - Extensions
// LocationData extension은 CLLocationCoordinate2D+Codable.swift에 정의됨