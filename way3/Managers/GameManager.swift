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

    // MARK: - Profile Management
    @Published var profileViewState: ProfileViewState = .loading
    @Published var lastProfileUpdate: Date = Date()

    // MARK: - Inventory Management
    @Published var inventoryViewState: InventoryViewState = .loading
    @Published var lastInventoryUpdate: Date = Date()

    // MARK: - Personal Items Management
    @Published var personalItems: [PersonalItem] = []
    @Published var personalItemsViewState: PersonalItemsViewState = .loading
    @Published var activeEffects: [ActiveEffect] = []
    @Published var permanentEffects: [PermanentEffect] = []
    @Published var lastPersonalItemsUpdate: Date = Date()

    // MARK: - Game Statistics (Simplified)
    @Published var gameStats: GameStatistics = GameStatistics()

    // MARK: - Managers Dependencies
    private var networkManager: NetworkManager
    private var locationManager: LocationManager
    private var tradeManager: TradeManager
    private var authManager: AuthManager

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

        setupObservers()
        setupAutoSave()

        // 앱 시작 시 캐시된 플레이어 데이터 로드 시도
        if let cachedPlayer = loadCachedPlayer() {
            currentPlayer = cachedPlayer
            profileViewState = .loaded
            GameLogger.shared.logInfo("캐시된 플레이어 데이터로 초기화", category: .gameplay)
        }
    }

    // MARK: - Game Lifecycle

    /**
     * 게임 시작
     */
    func startGame() {
        guard let player = currentPlayer else {
            GameLogger.shared.logError("플레이어 정보 없음", category: .gameplay)
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

        GameLogger.shared.logInfo("게임 시작됨", category: .gameplay)
    }

    /**
     * 게임 일시정지
     */
    func pauseGame() {
        gameState = .paused
        stopGameLoop()
        locationManager.stopLocationUpdates()

        GameLogger.shared.logInfo("게임 일시정지됨", category: .gameplay)
    }

    /**
     * 게임 재개
     */
    func resumeGame() {
        guard isGameActive else { return }

        gameState = .active
        locationManager.startLocationUpdates()
        startGameLoop()

        GameLogger.shared.logInfo("게임 재개됨", category: .gameplay)
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

        GameLogger.shared.logInfo("게임 종료됨", category: .gameplay)
    }

    // MARK: - Player Management

    /**
     * 플레이어 설정
     */
    func setPlayer(_ player: Player) {
        self.currentPlayer = player
        updateGameStatistics()

        GameLogger.shared.logInfo("플레이어 설정됨 - \(player.core.name)", category: .gameplay)
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
            GameLogger.shared.logError("플레이어 데이터 새로고침 실패 - \(error)", category: .gameplay)
            addNotification(
                title: "데이터 동기화 실패",
                message: "플레이어 정보를 업데이트할 수 없습니다",
                type: .error
            )
        }
    }

    /**
     * 프로필 화면용 데이터 로딩
     */
    func loadProfileData() async {
        await MainActor.run {
            profileViewState = .loading
            GameLogger.shared.logInfo("프로필 데이터 로딩 시작", category: .gameplay)
        }

        do {
            // 서버에서 최신 플레이어 데이터 가져오기
            let response = try await networkManager.getPlayerData()

            if response.success, let playerDetail = response.data {
                await MainActor.run {
                    updatePlayerFromDetail(playerDetail)
                    profileViewState = .loaded
                    lastProfileUpdate = Date()
                    GameLogger.shared.logInfo("프로필 데이터 로딩 완료", category: .gameplay)
                }
            } else {
                await handleProfileLoadingError("서버에서 올바른 데이터를 받지 못했습니다")
            }
        } catch {
            await handleProfileLoadingError(error.localizedDescription)
        }
    }

    /**
     * 프로필 데이터 새로고침 (이미 로드된 상태에서)
     */
    func refreshProfileData() async {
        guard profileViewState == .loaded else {
            await loadProfileData()
            return
        }

        await MainActor.run { profileViewState = .refreshing }

        do {
            let response = try await networkManager.getPlayerData()

            if response.success, let playerDetail = response.data {
                await MainActor.run {
                    updatePlayerFromDetail(playerDetail)
                    profileViewState = .loaded
                    lastProfileUpdate = Date()

                    // 성공 알림
                    addNotification(
                        title: "프로필 업데이트",
                        message: "최신 정보로 업데이트되었습니다",
                        type: .success
                    )
                }
            }
        } catch {
            await MainActor.run {
                profileViewState = .loaded // 기존 데이터 유지
                addNotification(
                    title: "업데이트 실패",
                    message: "프로필 정보를 업데이트할 수 없습니다",
                    type: .error
                )
            }
        }
    }

    /**
     * 프로필 로딩 에러 처리
     */
    private func handleProfileLoadingError(_ message: String) async {
        await MainActor.run {
            // 캐시된 플레이어 데이터가 있는지 확인
            if let cachedPlayer = loadCachedPlayer() {
                currentPlayer = cachedPlayer
                profileViewState = .loaded
                addNotification(
                    title: "오프라인 모드",
                    message: "캐시된 데이터를 사용합니다",
                    type: .warning
                )
                GameLogger.shared.logInfo("캐시된 프로필 데이터 사용", category: .gameplay)
            } else {
                profileViewState = .error(message)
                GameLogger.shared.logError("프로필 데이터 로딩 실패: \(message)", category: .gameplay)
            }
        }
    }

    /**
     * 캐시된 플레이어 데이터 로드
     */
    private func loadCachedPlayer() -> Player? {
        // 캐시 유효성 확인 (24시간 이내)
        if let timestamp = UserDefaults.standard.object(forKey: "cached_player_timestamp") as? Date {
            let cacheAge = Date().timeIntervalSince(timestamp)
            let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24시간

            if cacheAge > maxCacheAge {
                GameLogger.shared.logInfo("캐시 데이터가 만료되어 삭제", category: .gameplay)
                clearPlayerCache()
                return nil
            }
        }

        // UserDefaults에서 마지막 저장된 플레이어 데이터 로드
        guard let data = UserDefaults.standard.data(forKey: "cached_player_data"),
              let player = try? JSONDecoder().decode(Player.self, from: data) else {
            return nil
        }

        GameLogger.shared.logInfo("유효한 캐시 데이터 발견", category: .gameplay)
        return player
    }

    /**
     * 플레이어 데이터 캐시 저장
     */
    private func cachePlayerData() {
        guard let player = currentPlayer,
              let data = try? JSONEncoder().encode(player) else { return }

        UserDefaults.standard.set(data, forKey: "cached_player_data")
        UserDefaults.standard.set(Date(), forKey: "cached_player_timestamp")

        GameLogger.shared.logInfo("플레이어 데이터 캐시 저장", category: .gameplay)
    }

    /**
     * 플레이어 캐시 데이터 삭제
     */
    private func clearPlayerCache() {
        UserDefaults.standard.removeObject(forKey: "cached_player_data")
        UserDefaults.standard.removeObject(forKey: "cached_player_timestamp")
    }

    /**
     * 네트워크 연결 상태 확인
     */
    private var isNetworkAvailable: Bool {
        return networkManager.isConnected
    }

    /**
     * 스마트 프로필 로딩 (네트워크 상태에 따라 캐시 우선 또는 서버 우선)
     */
    func smartLoadProfile() async {
        if isNetworkAvailable {
            // 네트워크 사용 가능 시 서버 데이터 우선
            await loadProfileData()
        } else {
            // 오프라인 시 캐시 데이터 사용
            await handleProfileLoadingError("네트워크에 연결되지 않았습니다")
        }
    }

    // MARK: - Inventory Management

    /**
     * 인벤토리 데이터 로딩 (서버 우선, 캐시 fallback)
     */
    func loadInventoryData() async {
        await MainActor.run {
            inventoryViewState = .loading
            GameLogger.shared.logInfo("인벤토리 데이터 로딩 시작", category: .gameplay)
        }

        do {
            let playerDetail = try await networkManager.fetchPlayerProfile()
            await MainActor.run {
                if let playerData = playerDetail.data {
                    updatePlayerInventoryFromDetail(playerData)
                }
                inventoryViewState = .loaded
                lastInventoryUpdate = Date()
                GameLogger.shared.logInfo("인벤토리 데이터 로딩 성공", category: .gameplay)
            }
        } catch {
            GameLogger.shared.logError("인벤토리 로딩 실패 - \(error)", category: .gameplay)
            await handleInventoryLoadingError("인벤토리를 불러올 수 없습니다")
        }
    }

    /**
     * 인벤토리 데이터 새로고침
     */
    func refreshInventoryData() async {
        guard inventoryViewState == .loaded else {
            await loadInventoryData()
            return
        }

        await MainActor.run {
            inventoryViewState = .refreshing
        }

        do {
            let playerDetail = try await networkManager.fetchPlayerProfile()
            await MainActor.run {
                if let playerData = playerDetail.data {
                    updatePlayerInventoryFromDetail(playerData)
                }
                inventoryViewState = .loaded
                lastInventoryUpdate = Date()
                GameLogger.shared.logInfo("인벤토리 새로고침 성공", category: .gameplay)
            }
        } catch {
            GameLogger.shared.logError("인벤토리 새로고침 실패 - \(error)", category: .gameplay)
            await MainActor.run {
                inventoryViewState = .loaded // 기존 데이터 유지
            }
        }
    }

    /**
     * 스마트 인벤토리 로딩 (온라인/오프라인 대응)
     */
    func smartLoadInventory() async {
        if isNetworkAvailable {
            // 네트워크 사용 가능 시 서버 데이터 우선
            await loadInventoryData()
        } else {
            // 오프라인 시 캐시 데이터 사용
            await handleInventoryLoadingError("네트워크에 연결되지 않았습니다")
        }
    }

    /**
     * 서버 데이터로 플레이어 인벤토리 업데이트
     */
    private func updatePlayerInventoryFromDetail(_ playerDetail: PlayerDetail) {
        guard let player = currentPlayer else { return }

        // 서버 inventory를 TradeItem으로 변환하여 player.inventory.inventory에 저장
        let serverInventoryItems = playerDetail.inventory.map { inventoryItem in
            TradeItem(
                itemId: inventoryItem.id,
                name: inventoryItem.name,
                category: inventoryItem.category,
                grade: ItemGrade(rawValue: inventoryItem.grade == "common" ? 0 : inventoryItem.grade == "intermediate" ? 1 : inventoryItem.grade == "advanced" ? 2 : inventoryItem.grade == "rare" ? 3 : 4) ?? .common,
                requiredLicense: LicenseLevel(rawValue: inventoryItem.requiredLicense) ?? .beginner,
                basePrice: inventoryItem.basePrice
            )
        }

        player.inventory.inventory = serverInventoryItems

        // 인벤토리 캐시 저장
        saveInventoryToCache(serverInventoryItems)
    }

    /**
     * 인벤토리 로딩 에러 처리
     */
    private func handleInventoryLoadingError(_ message: String) async {
        await MainActor.run {
            // 캐시된 인벤토리 데이터 확인
            if let cachedInventory = loadCachedInventory() {
                // 캐시된 인벤토리가 유효한지 확인
                let cacheAge = Date().timeIntervalSince(lastInventoryUpdate)
                let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24시간

                if cacheAge <= maxCacheAge || !isNetworkAvailable {
                    if let player = currentPlayer {
                        player.inventory.inventory = cachedInventory
                        inventoryViewState = .loaded
                        GameLogger.shared.logInfo("캐시된 인벤토리 데이터 사용 (age: \(Int(cacheAge/60))분)", category: .gameplay)

                        addNotification(
                            title: "오프라인 모드",
                            message: "저장된 인벤토리 데이터를 표시합니다",
                            type: .warning
                        )
                        return
                    }
                }
            }

            // 캐시가 없거나 만료된 경우
            inventoryViewState = .error(message)
            GameLogger.shared.logError("인벤토리 에러: \(message)", category: .gameplay)
        }
    }

    // MARK: - Inventory Cache Management

    /**
     * 인벤토리 데이터를 캐시에 저장
     */
    private func saveInventoryToCache(_ inventory: [TradeItem]) {
        do {
            let data = try JSONEncoder().encode(inventory)
            UserDefaults.standard.set(data, forKey: "cached_inventory")
            UserDefaults.standard.set(Date(), forKey: "inventory_cache_timestamp")
            GameLogger.shared.logInfo("인벤토리 캐시 저장 완료", category: .gameplay)
        } catch {
            GameLogger.shared.logError("인벤토리 캐시 저장 실패: \(error)", category: .gameplay)
        }
    }

    /**
     * 캐시에서 인벤토리 데이터 로드
     */
    private func loadCachedInventory() -> [TradeItem]? {
        guard let data = UserDefaults.standard.data(forKey: "cached_inventory") else {
            return nil
        }

        do {
            let inventory = try JSONDecoder().decode([TradeItem].self, from: data)
            if let timestamp = UserDefaults.standard.object(forKey: "inventory_cache_timestamp") as? Date {
                lastInventoryUpdate = timestamp
            }
            return inventory
        } catch {
            GameLogger.shared.logError("인벤토리 캐시 로드 실패: \(error)", category: .gameplay)
            return nil
        }
    }

    /**
     * 인벤토리 캐시 정리
     */
    private func clearInventoryCache() {
        UserDefaults.standard.removeObject(forKey: "cached_inventory")
        UserDefaults.standard.removeObject(forKey: "inventory_cache_timestamp")
        GameLogger.shared.logInfo("인벤토리 캐시 정리 완료", category: .gameplay)
    }

    /**
     * 인벤토리 캐시 유효성 검사
     */
    private func isInventoryCacheValid() -> Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: "inventory_cache_timestamp") as? Date else {
            return false
        }

        let cacheAge = Date().timeIntervalSince(timestamp)
        let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24시간

        return cacheAge <= maxCacheAge
    }

    // MARK: - Personal Items Management

    /**
     * 개인 아이템 데이터 로딩
     */
    func loadPersonalItemsData() async {
        await MainActor.run {
            personalItemsViewState = .loading
            GameLogger.shared.logInfo("개인 아이템 데이터 로딩 시작", category: .gameplay)
        }

        do {
            let response = try await networkManager.getPersonalItems()
            if response.success, let itemsData = response.data {
                await MainActor.run {
                    personalItems = itemsData.personalItems.map { PersonalItem.from(serverData: $0) }
                    personalItemsViewState = .loaded
                    lastPersonalItemsUpdate = Date()
                    cachePersonalItemsData()
                    GameLogger.shared.logInfo("개인 아이템 데이터 로딩 완료 (\(personalItems.count)개)", category: .gameplay)
                }
            } else {
                await handlePersonalItemsLoadingError("서버에서 올바른 데이터를 받지 못했습니다")
            }
        } catch {
            await handlePersonalItemsLoadingError(error.localizedDescription)
        }
    }

    /**
     * 개인 아이템 데이터 새로고침
     */
    func refreshPersonalItemsData() async {
        guard personalItemsViewState == .loaded else {
            await loadPersonalItemsData()
            return
        }

        await MainActor.run { personalItemsViewState = .refreshing }

        do {
            let response = try await networkManager.getPersonalItems()
            if response.success, let itemsData = response.data {
                await MainActor.run {
                    personalItems = itemsData.personalItems.map { PersonalItem.from(serverData: $0) }
                    personalItemsViewState = .loaded
                    lastPersonalItemsUpdate = Date()
                    cachePersonalItemsData()
                    GameLogger.shared.logInfo("개인 아이템 새로고침 완료", category: .gameplay)
                }
            }
        } catch {
            await MainActor.run {
                personalItemsViewState = .loaded
                GameLogger.shared.logError("개인 아이템 새로고침 실패: \(error)", category: .gameplay)
            }
        }
    }

    /**
     * 개인 아이템 사용
     */
    func usePersonalItem(_ item: PersonalItem, targetId: String? = nil) async -> Bool {
        guard item.isUsable else {
            await MainActor.run {
                addNotification(
                    title: "사용 불가",
                    message: "이 아이템은 현재 사용할 수 없습니다",
                    type: .warning
                )
            }
            return false
        }

        await MainActor.run {
            personalItemsViewState = .using(item)
        }

        do {
            let response = try await networkManager.usePersonalItem(itemId: item.id, targetId: targetId)
            if response.success {
                await MainActor.run {
                    // 아이템 목록과 활성 효과 업데이트
                    refreshPersonalItemsAndEffects()
                    personalItemsViewState = .loaded

                    addNotification(
                        title: "아이템 사용",
                        message: "\(item.name)을(를) 사용했습니다",
                        type: .success
                    )
                }
                return true
            } else {
                await MainActor.run {
                    personalItemsViewState = .loaded
                    addNotification(
                        title: "사용 실패",
                        message: response.error ?? "아이템을 사용할 수 없습니다",
                        type: .error
                    )
                }
                return false
            }
        } catch {
            await MainActor.run {
                personalItemsViewState = .loaded
                addNotification(
                    title: "사용 실패",
                    message: "네트워크 오류가 발생했습니다",
                    type: .error
                )
            }
            return false
        }
    }

    /**
     * 개인 아이템 장착/해제
     */
    func toggleEquipPersonalItem(_ item: PersonalItem) async -> Bool {
        guard item.isEquippable else {
            await MainActor.run {
                addNotification(
                    title: "장착 불가",
                    message: "이 아이템은 장착할 수 없습니다",
                    type: .warning
                )
            }
            return false
        }

        await MainActor.run {
            personalItemsViewState = .equipping(item)
        }

        do {
            let response: PersonalItemActionResponse
            if item.isEquipped {
                response = try await networkManager.unequipPersonalItem(itemId: item.id)
            } else {
                response = try await networkManager.equipPersonalItem(itemId: item.id)
            }

            if response.success {
                await MainActor.run {
                    refreshPersonalItemsAndEffects()
                    personalItemsViewState = .loaded

                    let action = item.isEquipped ? "해제" : "장착"
                    addNotification(
                        title: "아이템 \(action)",
                        message: "\(item.name)을(를) \(action)했습니다",
                        type: .success
                    )
                }
                return true
            } else {
                await MainActor.run {
                    personalItemsViewState = .loaded
                    addNotification(
                        title: "장착 실패",
                        message: response.error ?? "아이템을 장착할 수 없습니다",
                        type: .error
                    )
                }
                return false
            }
        } catch {
            await MainActor.run {
                personalItemsViewState = .loaded
                addNotification(
                    title: "장착 실패",
                    message: "네트워크 오류가 발생했습니다",
                    type: .error
                )
            }
            return false
        }
    }

    /**
     * 활성 효과 로딩
     */
    func loadActiveEffects() async {
        do {
            let response = try await networkManager.getActiveEffects()
            if response.success, let effectsData = response.data {
                await MainActor.run {
                    activeEffects = effectsData.temporaryEffects.map { ActiveEffect.from(serverData: $0) }
                    permanentEffects = effectsData.permanentEffects.map { PermanentEffect.from(serverData: $0) }
                    GameLogger.shared.logInfo("활성 효과 로딩 완료 (임시: \(activeEffects.count), 영구: \(permanentEffects.count))", category: .gameplay)
                }
            }
        } catch {
            GameLogger.shared.logError("활성 효과 로딩 실패: \(error)", category: .gameplay)
        }
    }

    /**
     * 개인 아이템과 효과 새로고침 (통합)
     */
    private func refreshPersonalItemsAndEffects() {
        Task {
            await refreshPersonalItemsData()
            await loadActiveEffects()
        }
    }

    /**
     * 개인 아이템 로딩 에러 처리
     */
    private func handlePersonalItemsLoadingError(_ message: String) async {
        await MainActor.run {
            if let cachedItems = loadCachedPersonalItems() {
                personalItems = cachedItems
                personalItemsViewState = .loaded
                addNotification(
                    title: "오프라인 모드",
                    message: "저장된 개인 아이템 데이터를 표시합니다",
                    type: .warning
                )
                GameLogger.shared.logInfo("캐시된 개인 아이템 데이터 사용", category: .gameplay)
            } else {
                personalItemsViewState = .error(message)
                GameLogger.shared.logError("개인 아이템 로딩 실패: \(message)", category: .gameplay)
            }
        }
    }

    /**
     * 개인 아이템 데이터 캐시 저장
     */
    private func cachePersonalItemsData() {
        guard let data = try? JSONEncoder().encode(personalItems) else { return }
        UserDefaults.standard.set(data, forKey: "cached_personal_items")
        UserDefaults.standard.set(Date(), forKey: "cached_personal_items_timestamp")
        GameLogger.shared.logInfo("개인 아이템 데이터 캐시 저장", category: .gameplay)
    }

    /**
     * 캐시된 개인 아이템 데이터 로드
     */
    private func loadCachedPersonalItems() -> [PersonalItem]? {
        if let timestamp = UserDefaults.standard.object(forKey: "cached_personal_items_timestamp") as? Date {
            let cacheAge = Date().timeIntervalSince(timestamp)
            let maxCacheAge: TimeInterval = 24 * 60 * 60

            if cacheAge > maxCacheAge {
                clearPersonalItemsCache()
                return nil
            }
        }

        guard let data = UserDefaults.standard.data(forKey: "cached_personal_items"),
              let cachedItems = try? JSONDecoder().decode([PersonalItem].self, from: data) else {
            return nil
        }

        return cachedItems
    }

    /**
     * 개인 아이템 캐시 클리어
     */
    private func clearPersonalItemsCache() {
        UserDefaults.standard.removeObject(forKey: "cached_personal_items")
        UserDefaults.standard.removeObject(forKey: "cached_personal_items_timestamp")
        GameLogger.shared.logInfo("개인 아이템 캐시 클리어", category: .gameplay)
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
                GameLogger.shared.logError("위치 업데이트 실패 - \(error)", category: .gameplay)
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
                GameLogger.shared.logError("근처 상인 검색 실패 - \(error)", category: .gameplay)
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
            GameLogger.shared.logError("시장 가격 업데이트 실패 - \(error)", category: .gameplay)
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

        GameLogger.shared.logInfo("게임 데이터 저장됨", category: .gameplay)
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
        // 기존 플레이어가 없으면 새로 생성 (올바른 Player 생성자 사용)
        if currentPlayer == nil {
            currentPlayer = Player(
                id: detail.id,
                userId: detail.id, // userId로 서버 ID 사용
                name: detail.name,
                email: nil
            )
        }

        guard let player = currentPlayer else { return }

        // PlayerDetail의 모든 정보로 Player 업데이트
        player.core.id = detail.id
        player.core.name = detail.name
        player.core.money = detail.money
        // trustPoints는 core가 아닌 relationships에서 관리
        // player.core.trustPoints = detail.trustPoints // 이 라인 제거
        player.core.currentLicense = LicenseLevel(rawValue: detail.currentLicense) ?? .beginner
        player.inventory.maxInventorySize = detail.maxInventorySize

        // 위치 정보 업데이트
        if let location = detail.currentLocation {
            if location.lat != 0 && location.lng != 0 {
                player.currentLocation = CLLocationCoordinate2D(
                    latitude: location.lat,
                    longitude: location.lng
                )
            }
        }

        // 인벤토리 업데이트 (기존 인벤토리 클리어 후 서버 데이터로 대체)
        player.inventory.inventory.removeAll()
        for inventoryItem in detail.inventory {
            let tradeItem = TradeItem(
                itemId: inventoryItem.id,
                name: inventoryItem.name,
                category: inventoryItem.category,
                grade: ItemGrade(rawValue: inventoryItem.grade == "common" ? 0 : inventoryItem.grade == "intermediate" ? 1 : inventoryItem.grade == "advanced" ? 2 : inventoryItem.grade == "rare" ? 3 : 4) ?? .common,
                requiredLicense: LicenseLevel(rawValue: inventoryItem.requiredLicense) ?? .beginner,
                basePrice: inventoryItem.basePrice
            )
            player.inventory.inventory.append(tradeItem)
        }

        player.inventory.storageItems.removeAll()
        for storageItem in detail.storageItems {
            let tradeItem = TradeItem(
                itemId: storageItem.id,
                name: storageItem.name,
                category: storageItem.category,
                grade: ItemGrade(rawValue: storageItem.grade == "common" ? 0 : storageItem.grade == "intermediate" ? 1 : storageItem.grade == "advanced" ? 2 : storageItem.grade == "rare" ? 3 : 4) ?? .common,
                requiredLicense: LicenseLevel(rawValue: storageItem.requiredLicense) ?? .beginner,
                basePrice: storageItem.basePrice
            )
            player.inventory.storageItems.append(tradeItem)
        }

        // 캐시에 저장
        cachePlayerData()

        GameLogger.shared.logInfo("플레이어 데이터 업데이트 완료 - \(player.core.name)", category: .gameplay)
    }

    private func convertMerchantData(_ data: MerchantData) -> Merchant {
        var merchant = Merchant(
            id: data.id,
            name: data.name,
            type: MerchantType(rawValue: data.type) ?? .retail,
            personality: .calm, // 기본값
            district: SeoulDistrict(rawValue: data.district) ?? .jongno,
            coordinate: CLLocationCoordinate2D(
                latitude: data.location.lat,
                longitude: data.location.lng
            ),
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

// MARK: - Profile View State Enum
enum ProfileViewState: Equatable {
    case loading
    case loaded
    case error(String)
    case refreshing

    var isLoading: Bool {
        switch self {
        case .loading, .refreshing:
            return true
        default:
            return false
        }
    }
}

// MARK: - Inventory View State Enum
enum InventoryViewState: Equatable {
    case loading
    case loaded
    case error(String)
    case refreshing

    var isLoading: Bool {
        switch self {
        case .loading, .refreshing:
            return true
        default:
            return false
        }
    }
}

// MARK: - Personal Items View State Enum
enum PersonalItemsViewState: Equatable {
    case loading
    case loaded
    case error(String)
    case refreshing
    case using(PersonalItem)  // 아이템 사용 중
    case equipping(PersonalItem)  // 아이템 장착/해제 중

    var isLoading: Bool {
        switch self {
        case .loading, .refreshing, .using, .equipping:
            return true
        default:
            return false
        }
    }
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
