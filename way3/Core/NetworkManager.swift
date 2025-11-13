// 📁 Core/NetworkManager.swift - Way Game Server 연동
import Foundation
import Combine

struct NetworkConfiguration {
    static let maxRetryCount = 3
    static let retryDelay: TimeInterval = 1.0
    static let requestTimeout: TimeInterval = 30.0
    static let resourceTimeout: TimeInterval = 60.0

    // 환경별 동적 Base URL 설정
    static let baseURL: String = {
        // 환경 변수에서 우선 확인
        if let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"] {
            return envURL
        }

        // Bundle의 Configuration 설정 확인
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
            return plistURL
        }

        // 빌드 설정에 따른 기본값
        #if DEBUG
            return "http://localhost:3000"  // 로컬 개발 환경
        #elseif STAGING
            return "https://way3-production.up.railway.app"  // 스테이징 환경
        #else
            return "https://way3-production.up.railway.app"  // 프로덕션 환경 (Railway)
        #endif
    }()

    // 현재 환경 표시 (디버깅용)
    static let currentEnvironment: String = {
        #if DEBUG
            return "Development (Local)"
        #elseif STAGING
            return "Staging (Railway)"
        #else
            return "Production (Railway)"
        #endif
    }()

    // 배포된 서버 헬스 체크
    static func checkServerHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("❌ 서버 헬스 체크 실패: \(error.localizedDescription)")
        }

        return false
    }

    // 네트워크 연결 상태 확인
    static func isNetworkAvailable() -> Bool {
        // 간단한 네트워크 체크 (실제로는 Reachability 라이브러리 사용 권장)
        return true
    }
}

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var isConnected = false
    @Published var lastError: NetworkError?
    @Published var currentPlayer: Player?
    
    // MARK: - Private Properties
    private var authToken: String? {
        didSet {
            let updateAuthState = {
                self.isAuthenticated = self.authToken != nil
            }
            
            if Thread.isMainThread {
                updateAuthState()
            } else {
                DispatchQueue.main.async(execute: updateAuthState)
            }
            
            if let token = authToken {
                UserDefaults.standard.set(token, forKey: "auth_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "auth_token")
            }
        }
    }
    
    private var refreshToken: String? {
        didSet {
            if let token = refreshToken {
                UserDefaults.standard.set(token, forKey: "refresh_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "refresh_token")
            }
        }
    }
    
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Cache and Request Management
    private let requestQueue = DispatchQueue(label: "networkmanager.requests", attributes: .concurrent)
    private var _activeRequests: [String: Task<Any, Error>] = [:]
    private var _requestCache: [String: (data: Data, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    // MARK: - Configuration
    private let baseURL = "\(NetworkConfiguration.baseURL)/api"
    
    // MARK: - Network Errors
    enum NetworkError: Error, LocalizedError {
        case invalidURL
        case invalidRequest
        case unauthorized
        case invalidResponse
        case clientError(Int, String? = nil)
        case serverError(String? = nil)
        case networkError(Error)
        case timeout
        case noInternetConnection
        case businessLogicError(String, String? = nil) // 게임 비즈니스 로직 에러

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "잘못된 URL입니다"
            case .invalidRequest:
                return "잘못된 요청입니다"
            case .unauthorized:
                return "인증이 필요합니다. 다시 로그인해주세요"
            case .invalidResponse:
                return "서버 응답을 해석할 수 없습니다"
            case .clientError(let code, let message):
                return message ?? "클라이언트 오류 (코드: \(code))"
            case .serverError(let message):
                return message ?? "서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요"
            case .networkError(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            case .timeout:
                return "요청 시간이 초과되었습니다"
            case .noInternetConnection:
                return "인터넷 연결을 확인해주세요"
            case .businessLogicError(let message, _):
                return message
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .unauthorized:
                return "로그인 페이지로 이동하겠습니다"
            case .serverError:
                return "잠시 후 다시 시도해주세요"
            case .noInternetConnection:
                return "네트워크 연결을 확인하고 다시 시도해주세요"
            case .businessLogicError(_, let suggestion):
                return suggestion
            default:
                return nil
            }
        }

        // 에러 타입별 사용자 친화적 메시지 매핑
        static func fromAPIError(_ apiError: APIError) -> NetworkError {
            switch apiError.code {
            case "INSUFFICIENT_FUNDS":
                return .businessLogicError("💰 자금이 부족합니다", "돈을 더 벌거나 더 저렴한 상품을 선택해보세요")
            case "INVENTORY_FULL":
                return .businessLogicError("🎒 인벤토리가 가득 찼습니다", "일부 아이템을 판매하거나 사용해보세요")
            case "ITEM_OUT_OF_STOCK":
                return .businessLogicError("📦 상품이 품절되었습니다", "다른 상인을 찾아보거나 시간을 두고 다시 시도해보세요")
            case "INSUFFICIENT_LICENSE":
                return .businessLogicError("📜 라이선스가 부족합니다", "상위 라이선스를 획득한 후 다시 시도해보세요")
            case "INVALID_MERCHANT":
                return .businessLogicError("🏪 유효하지 않은 상인입니다", "다른 상인을 선택해보세요")
            case "TRADE_COOLDOWN":
                return .businessLogicError("⏰ 거래 대기시간입니다", "잠시 후 다시 시도해보세요")
            case "VALIDATION_ERROR":
                return .clientError(400, apiError.message)
            case "AUTHENTICATION_ERROR":
                return .unauthorized
            case "AUTHORIZATION_ERROR":
                return .clientError(403, "접근 권한이 없습니다")
            case "NOT_FOUND":
                return .clientError(404, "요청한 리소스를 찾을 수 없습니다")
            case "RATE_LIMIT_EXCEEDED":
                return .clientError(429, "요청이 너무 많습니다. 잠시 후 다시 시도해보세요")
            case "INTERNAL_SERVER_ERROR":
                return .serverError("서버 내부 오류가 발생했습니다")
            case "DATABASE_ERROR":
                return .serverError("데이터베이스 오류가 발생했습니다")
            case "EXTERNAL_SERVICE_ERROR":
                return .serverError("외부 서비스 연동 오류가 발생했습니다")
            default:
                return .serverError(apiError.message)
            }
        }
    }
    
    // ✅ 재시도 설정
    private let maxRetryCount = NetworkConfiguration.maxRetryCount
    private let retryDelay: TimeInterval = NetworkConfiguration.retryDelay
    
    // MARK: - Configuration
    
    private init() {
        // ✅ URLSession 설정 최적화
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = NetworkConfiguration.requestTimeout
        config.timeoutIntervalForResource = NetworkConfiguration.resourceTimeout
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024)

        self.session = URLSession(configuration: config)

        // 환경 정보 로깅 (디버그 모드에서만)
        #if DEBUG
        GameLogger.shared.logInfo("NetworkManager initialized", category: .network)
        GameLogger.shared.logInfo("Environment: \(NetworkConfiguration.currentEnvironment)", category: .network)
        GameLogger.shared.logInfo("Base URL: \(NetworkConfiguration.baseURL)", category: .network)
        GameLogger.shared.logInfo("Request Timeout: \(NetworkConfiguration.requestTimeout)s", category: .network)
        #endif

        // 저장된 토큰 복원
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            self.authToken = token
        }

        // ✅ 주기적 캐시 정리
        setupCacheCleanup()

        // ✅ 서버 연결 상태 확인 (백그라운드)
        Task {
            await checkServerConnection()
        }
    }

    // MARK: - 서버 연결 확인
    /// 서버 연결 상태를 확인하고 UI 상태 업데이트
    @MainActor
    func checkServerConnection() async {
        let serverHealthy = await NetworkConfiguration.checkServerHealth()
        isConnected = serverHealthy

        if serverHealthy {
            GameLogger.shared.logInfo("✅ 서버 연결 확인됨: \(NetworkConfiguration.baseURL)", category: .network)
        } else {
            GameLogger.shared.logWarning("❌ 서버 연결 실패: \(NetworkConfiguration.baseURL)", category: .network)
            lastError = .noInternetConnection
        }
    }
    
    deinit {
        // ✅ 진행 중인 요청 취소 (스레드 안전)
        requestQueue.sync {
            _activeRequests.values.forEach { $0.cancel() }
        }
    }
}

// MARK: - Cache Management
extension NetworkManager {
    private func setupCacheCleanup() {
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.cleanupCache()
        }
    }
    
    private func cleanupCache() {
        let now = Date()
        requestQueue.async(flags: .barrier) {
            self._requestCache = self._requestCache.filter { _, value in
                now.timeIntervalSince(value.timestamp) < self.cacheTimeout
            }
        }
    }

    // MARK: - Auth Token Sync
    func applyAuthTokens(accessToken: String?, refreshToken: String?) {
        Task { @MainActor in
            self.authToken = accessToken
            self.refreshToken = refreshToken
        }
    }
    
    private func getCachedResponse(for key: String) -> Data? {
        return requestQueue.sync {
            if let cached = _requestCache[key],
               Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
                return cached.data
            }
            return nil
        }
    }
    
    private func setCachedResponse(_ data: Data, for key: String) {
        requestQueue.async(flags: .barrier) {
            self._requestCache[key] = (data: data, timestamp: Date())
        }
    }
}

// MARK: - Network Request Methods
extension NetworkManager {
    // ✅ 개선된 네트워크 요청 메서드
    func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        requiresAuth: Bool = false,
        responseType: T.Type,
        useCache: Bool = false,
        retryCount: Int = 0
    ) async throws -> T {
        
        // ✅ 중복 요청 방지 (스레드 안전)
        let requestKey = "\(method.rawValue)-\(endpoint)-\(body?.description ?? "")"
        
        let existingTask: Task<Any, Error>? = requestQueue.sync {
            return _activeRequests[requestKey]
        }
        
        if let activeTask = existingTask {
            return try await activeTask.value as! T
        }
        
        // ✅ 캐시 확인 (GET 요청만)
        if method == .GET && useCache,
           let cachedData = getCachedResponse(for: requestKey) {
            do {
                let response = try JSONDecoder().decode(T.self, from: cachedData)
                return response
            } catch {
                // 캐시된 데이터가 잘못된 경우 캐시 삭제
                requestQueue.async(flags: .barrier) {
                    self._requestCache.removeValue(forKey: requestKey)
                }
            }
        }
        
        let task = Task<Any, Error> {
            return try await performRequest(
                endpoint: endpoint,
                method: method,
                body: body,
                requiresAuth: requiresAuth,
                responseType: responseType,
                useCache: useCache,
                requestKey: requestKey,
                retryCount: retryCount
            )
        }
        
        requestQueue.async(flags: .barrier) {
            self._activeRequests[requestKey] = task
        }
        
        defer {
            requestQueue.async(flags: .barrier) {
                self._activeRequests.removeValue(forKey: requestKey)
            }
        }
        
        return try await task.value as! T
    }
    
    private func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: [String: Any]?,
        requiresAuth: Bool,
        responseType: T.Type,
        useCache: Bool,
        requestKey: String,
        retryCount: Int
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ 인증 헤더 추가
        if requiresAuth {
            guard let token = authToken else {
                await MainActor.run { self.lastError = .unauthorized }
                throw NetworkError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // ✅ 요청 본문 추가
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                throw NetworkError.invalidRequest
            }
        }
        
        do {
            await MainActor.run { self.isLoading = true }
            
            let (data, response) = try await session.data(for: request)
            
            await MainActor.run { self.isLoading = false }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // ✅ HTTP 상태 코드 처리
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            await MainActor.run {
                self.logout() // 자동 로그아웃
            }
            throw NetworkError.unauthorized
        case 400...499:
            if let bodyString = String(data: data, encoding: .utf8) {
                GameLogger.shared.logDebug("클라이언트 오류 응답: \(bodyString)", category: .network)
            }
            // 클라이언트 오류는 응답 본문에서 상세 정보 추출 시도
            if let errorData = try? JSONDecoder().decode(APIResponse<EmptyData>.self, from: data),
               let apiError = errorData.error {
                throw NetworkError.fromAPIError(apiError)
            } else {
                    throw NetworkError.clientError(httpResponse.statusCode)
                }
            case 500...599:
                // ✅ 서버 오류 시 재시도
                if retryCount < maxRetryCount {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(retryCount + 1) * 1_000_000_000))
                    return try await performRequest(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        requiresAuth: requiresAuth,
                        responseType: responseType,
                        useCache: useCache,
                        requestKey: requestKey,
                        retryCount: retryCount + 1
                    )
                }

                // 서버 오류도 응답 본문에서 상세 정보 추출 시도
                if let errorData = try? JSONDecoder().decode(APIResponse<EmptyData>.self, from: data),
                   let apiError = errorData.error {
                    throw NetworkError.fromAPIError(apiError)
                } else {
                    throw NetworkError.serverError()
                }
            default:
                throw NetworkError.invalidResponse
            }
            
            // ✅ JSON 파싱 - 표준화된 API 응답 처리
            do {
                // 먼저 표준 APIResponse로 파싱 시도
                if let apiResponse = try? JSONDecoder().decode(APIResponse<T>.self, from: data) {
                    // 표준화된 응답 처리
                    if apiResponse.success {
                        guard let responseData = apiResponse.data else {
                            throw NetworkError.invalidResponse
                        }

                        // ✅ 성공적인 GET 요청은 캐시에 저장
                        if method == .GET && useCache {
                            setCachedResponse(data, for: requestKey)
                        }

                        await MainActor.run { self.lastError = nil }
                        return responseData
                    } else {
                        // 서버에서 반환된 에러 처리
                        let errorMessage = apiResponse.error?.message ?? "알 수 없는 오류가 발생했습니다"
                        let userError = NetworkError.serverError(errorMessage)
                        await MainActor.run { self.lastError = userError }
                        throw userError
                    }
                } else {
                    // 기존 형식 호환성 유지
                    let response = try JSONDecoder().decode(T.self, from: data)

                    // ✅ 성공적인 GET 요청은 캐시에 저장
                    if method == .GET && useCache {
                        setCachedResponse(data, for: requestKey)
                    }

                    await MainActor.run { self.lastError = nil }
                    return response
                }

            } catch let decodingError {
                GameLogger.shared.logError("JSON 파싱 오류: \(decodingError.localizedDescription)", category: .network)
                GameLogger.shared.logDebug("응답 데이터: \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8")", category: .network)
                throw NetworkError.invalidResponse
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                if let networkError = error as? NetworkError {
                    self.lastError = networkError
                } else {
                    self.lastError = .networkError(error)
                }
            }
            throw error
        }
    }
}

// MARK: - Authentication API
extension NetworkManager {
    func register(email: String, password: String, playerName: String) async throws -> AuthResponse {
        let body = [
            "email": email,
            "password": password,
            "playerName": playerName
        ]
        
        let response: AuthResponse = try await makeRequest(
            endpoint: "/auth/register",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
        
        // ✅ 성공 시 토큰 저장 및 Socket 연결
        if response.success, let authData = response.data {
            let token = authData.token
            await MainActor.run {
                self.authToken = token
                SocketManager.shared.connect(with: token)
            }
        }
        
        return response
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = [
            "email": email,
            "password": password
        ]
        
        let response: AuthResponse = try await makeRequest(
            endpoint: "/auth/login",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
        
        // ✅ 성공 시 토큰 저장 및 Socket 연결
        if response.success, let authData = response.data {
            let token = authData.token
            await MainActor.run {
                self.authToken = token
                SocketManager.shared.connect(with: token)
            }
        }
        
        return response
    }
    
    func logout() {
        Task { @MainActor in
            self.authToken = nil
            self.isAuthenticated = false
        }
        
        // ✅ Socket 연결 해제
        SocketManager.shared.disconnect()
        
        // ✅ 캐시 정리 (스레드 안전)
        requestQueue.async(flags: .barrier) {
            self._requestCache.removeAll()
            self._activeRequests.values.forEach { $0.cancel() }
            self._activeRequests.removeAll()
        }
        
        GameLogger.shared.logInfo("로그아웃 완료", category: .network)
    }
    
    // ✅ 토큰 갱신
    func refreshToken() async throws -> AuthResponse {
        let response: AuthResponse = try await makeRequest(
            endpoint: "/auth/refresh",
            method: .POST,
            requiresAuth: true,
            responseType: AuthResponse.self
        )
        
        if response.success, let authData = response.data {
            let token = authData.token
            await MainActor.run {
                self.authToken = token
            }
        }
        
        return response
    }
}

// MARK: - Game Data API
extension NetworkManager {
    func getPlayerData() async throws -> PlayerDataResponse {
        return try await makeRequest(
            endpoint: "/player/profile",
            requiresAuth: true,
            responseType: PlayerDataResponse.self,
            useCache: true
        )
    }

    // MARK: - Player Profile API
    func createPlayerProfile(name: String, age: Int, gender: String, personality: String) async throws -> ProfileCreationResponse {
        let body = [
            "name": name,
            "age": age,
            "gender": gender,
            "personality": personality
        ] as [String : Any]

        return try await makeRequest(
            endpoint: "/player/create-profile",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: ProfileCreationResponse.self
        )
    }

    func updatePlayerProfile(name: String? = nil, age: Int? = nil, gender: String? = nil, personality: String? = nil) async throws -> ProfileUpdateResponse {
        var body: [String: Any] = [:]

        if let name = name { body["name"] = name }
        if let age = age { body["age"] = age }
        if let gender = gender { body["gender"] = gender }
        if let personality = personality { body["personality"] = personality }

        return try await makeRequest(
            endpoint: "/player/profile",
            method: .PUT,
            body: body,
            requiresAuth: true,
            responseType: ProfileUpdateResponse.self
        )
    }

    func fetchPlayerProfile() async throws -> PlayerProfileResponse {
        return try await makeRequest(
            endpoint: "/player/profile",
            method: .GET,
            requiresAuth: true,
            responseType: PlayerProfileResponse.self,
            useCache: true
        )
    }
    
    func updatePlayerLocation(latitude: Double, longitude: Double) async throws -> BaseResponse {
        let body = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        return try await makeRequest(
            endpoint: "/player/location",
            method: .PUT,
            body: body,
            requiresAuth: true,
            responseType: BaseResponse.self
        )
    }
    
    func getMarketPrices() async throws -> MarketPricesResponse {
        return try await makeRequest(
            endpoint: "/market/prices",
            requiresAuth: true,
            responseType: MarketPricesResponse.self,
            useCache: true
        )
    }
    
    func getMerchants(latitude: Double? = nil, longitude: Double? = nil) async throws -> MerchantsResponse {
        var endpoint = "/merchants"

        if let lat = latitude, let lng = longitude {
            endpoint += "?lat=\(lat)&lng=\(lng)"
        }

        return try await makeRequest(
            endpoint: endpoint,
            requiresAuth: true,
            responseType: MerchantsResponse.self,
            useCache: true
        )
    }

    func getMerchantDetail(merchantId: String) async throws -> MerchantDetailResponse {
        return try await makeRequest(
            endpoint: "/merchants/\(merchantId)",
            requiresAuth: true,
            responseType: MerchantDetailResponse.self,
            useCache: true
        )
    }

    func getNearbyMerchants(latitude: Double, longitude: Double, radius: Double = 1000) async throws -> NearbyMerchantsResponse {
        return try await makeRequest(
            endpoint: "/merchants/nearby?lat=\(latitude)&lng=\(longitude)&radius=\(radius)",
            requiresAuth: true,
            responseType: NearbyMerchantsResponse.self,
            useCache: true
        )
    }
    
    // ✅ 거래 API
    func buyItem(merchantId: String, itemName: String) async throws -> TradeResponse {
        let body = [
            "merchantId": merchantId,
            "itemName": itemName
        ]
        
        return try await makeRequest(
            endpoint: "/trade/buy",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: TradeResponse.self
        )
    }
    
    func sellItem(itemId: String, merchantId: String) async throws -> TradeResponse {
        let body = [
            "itemId": itemId,
            "merchantId": merchantId
        ]
        
        return try await makeRequest(
            endpoint: "/trade/sell",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: TradeResponse.self
        )
    }
    
    func getTradeHistory(limit: Int = 20, offset: Int = 0) async throws -> TradeHistoryResponse {
        return try await makeRequest(
            endpoint: "/trade/history?limit=\(limit)&offset=\(offset)",
            requiresAuth: true,
            responseType: TradeHistoryResponse.self,
            useCache: true
        )
    }

    // MARK: - Story API Methods
    /// Get story dialogue for a merchant
    func getMerchantStory(merchantId: String) async throws -> StoryDialogueResponse {
        return try await makeRequest(
            endpoint: "/api/merchants/\(merchantId)/story",
            requiresAuth: true,
            responseType: StoryDialogueResponse.self,
            useCache: false  // Story progress shouldn't be cached
        )
    }

    /// Progress through story dialogue with choice
    func progressMerchantStory(merchantId: String, nodeId: String, choiceId: String?) async throws -> StoryProgressResponse {
        var body: [String: Any] = ["nodeId": nodeId]
        if let choice = choiceId {
            body["choiceId"] = choice
        }

        return try await makeRequest(
            endpoint: "/api/merchants/\(merchantId)/story/progress",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: StoryProgressResponse.self
        )
    }

    func getMerchantStoryChapters(merchantId: String) async throws -> MerchantStoryChaptersResponse {
        return try await makeRequest(
            endpoint: "/merchants/\(merchantId)/stories/chapters",
            method: .GET,
            requiresAuth: true,
            responseType: MerchantStoryChaptersResponse.self,
            useCache: false
        )
    }

    func claimChapterReward(request: ChapterRewardClaimRequest) async throws -> ChapterRewardClaimResponse {
        return try await makeRequest(
            endpoint: "/story/chapter/reward",
            method: .POST,
            body: [
                "chapterId": request.chapterId,
                "money": request.money as Any,
                "experience": request.experience as Any,
                "keyItemName": request.keyItemName as Any,
                "personalItemTemplateId": request.personalItemTemplateId as Any
            ].compactMapValues { $0 },
            requiresAuth: true,
            responseType: ChapterRewardClaimResponse.self
        )
    }

    // MARK: - Quest API Methods
    func getQuests() async throws -> QuestListResponse {
        return try await makeRequest(
            endpoint: "/quests",
            method: .GET,
            requiresAuth: true,
            responseType: QuestListResponse.self,
            useCache: true
        )
    }
    
    func acceptQuest(questId: String) async throws -> QuestActionResponse {
        return try await makeRequest(
            endpoint: "/quests/\(questId)/accept",
            method: .POST,
            requiresAuth: true,
            responseType: QuestActionResponse.self
        )
    }
    
    func claimQuestReward(questId: String) async throws -> QuestRewardResponse {
        return try await makeRequest(
            endpoint: "/quests/\(questId)/claim",
            method: .POST,
            requiresAuth: true,
            responseType: QuestRewardResponse.self
        )
    }
    
    func updateQuestProgress(actionType: String, actionData: [String: Any]) async throws -> QuestProgressResponse {
        let body: [String: Any] = [
            "actionType": actionType,
            "actionData": actionData
        ]
        
        return try await makeRequest(
            endpoint: "/quests/progress",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: QuestProgressResponse.self
        )
    }
    
    func getQuestHistory(limit: Int = 20, offset: Int = 0) async throws -> QuestHistoryResponse {
        return try await makeRequest(
            endpoint: "/quests/history?limit=\(limit)&offset=\(offset)",
            requiresAuth: true,
            responseType: QuestHistoryResponse.self,
            useCache: true
        )
    }

    // MARK: - Personal Items API Methods
    func getPersonalItems() async throws -> PersonalItemsResponse {
        return try await makeRequest(
            endpoint: "/personal-items",
            method: .GET,
            requiresAuth: true,
            responseType: PersonalItemsResponse.self,
            useCache: true
        )
    }

    func usePersonalItem(itemId: String, targetId: String? = nil) async throws -> PersonalItemActionResponse {
        var body: [String: Any] = ["itemId": itemId]
        if let targetId = targetId {
            body["targetId"] = targetId
        }

        return try await makeRequest(
            endpoint: "/personal-items/use",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: PersonalItemActionResponse.self
        )
    }

    func equipPersonalItem(itemId: String) async throws -> PersonalItemActionResponse {
        let body = ["itemId": itemId]

        return try await makeRequest(
            endpoint: "/personal-items/equip",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: PersonalItemActionResponse.self
        )
    }

    func unequipPersonalItem(itemId: String) async throws -> PersonalItemActionResponse {
        let body = ["itemId": itemId]

        return try await makeRequest(
            endpoint: "/personal-items/unequip",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: PersonalItemActionResponse.self
        )
    }

    func getActiveEffects() async throws -> ActiveEffectsResponse {
        return try await makeRequest(
            endpoint: "/personal-items/effects",
            method: .GET,
            requiresAuth: true,
            responseType: ActiveEffectsResponse.self,
            useCache: true
        )
    }
}

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}


// MARK: - Response Models
struct BaseResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

// EmptyData는 APIResponse.swift에 정의됨

// AuthResponse는 AuthManager.swift에 정의됨

struct PlayerDataResponse: Codable {
    let success: Bool
    let data: PlayerDetail?
    let error: String?
}

struct MarketPricesResponse: Codable {
    let success: Bool
    let data: [MarketPrice]?
    let error: String?
}

struct MerchantsResponse: Codable {
    let success: Bool
    let data: [MerchantData]?
    let error: String?
}

struct TradeResponse: Codable {
    let success: Bool
    let data: TradeResult?
    let error: String?
}

struct TradeHistoryResponse: Codable {
    let success: Bool
    let data: TradeHistoryData?
    let error: String?
}

// MARK: - Data Models
struct UserInfo: Codable {
    let id: String
    let email: String
}

struct PlayerInfo: Codable {
    let id: String
    let name: String
    let money: Int
    let trustPoints: Int
    let currentLicense: Int
    let maxInventorySize: Int
}

struct PlayerDetail: Codable {
    let id: String
    let name: String
    let level: Int
    let experience: Int
    let money: Int
    let trustPoints: Int
    let reputation: Int
    let currentLicense: Int
    let maxInventorySize: Int
    let maxStorageSize: Int
    let statPoints: Int
    let skillPoints: Int
    let strength: Int
    let intelligence: Int
    let charisma: Int
    let luck: Int
    let tradingSkill: Int
    let negotiationSkill: Int
    let appraisalSkill: Int
    let currentLocation: LocationData?
    let totalTrades: Int
    let totalProfit: Int
    let createdAt: String
    let lastActive: String
    let totalPlayTime: Int
    let inventoryCount: Int
    let storageCount: Int
    let inventory: [InventoryItem]
    let storageItems: [InventoryItem]
    let recentTrades: [RecentTrade]

    enum CodingKeys: String, CodingKey {
        case id, name, level, experience, money
        case trustPoints = "trustPoints"
        case reputation
        case currentLicense = "currentLicense"
        case maxInventorySize = "maxInventorySize"
        case maxStorageSize = "maxStorageSize"
        case statPoints = "statPoints"
        case skillPoints = "skillPoints"
        case strength, intelligence, charisma, luck
        case tradingSkill = "tradingSkill"
        case negotiationSkill = "negotiationSkill"
        case appraisalSkill = "appraisalSkill"
        case currentLocation = "currentLocation"
        case totalTrades = "totalTrades"
        case totalProfit = "totalProfit"
        case createdAt = "createdAt"
        case lastActive = "lastActive"
        case totalPlayTime = "totalPlayTime"
        case inventoryCount = "inventoryCount"
        case storageCount = "storageCount"
        case inventory
        case storageItems
        case recentTrades
    }
}

// LocationData는 APIResponse.swift에 정의됨

struct InventoryItem: Codable {
    let id: String
    let itemTemplateId: String?
    let name: String
    let category: String
    let basePrice: Int
    let currentPrice: Int?
    let grade: String
    let requiredLicense: Int
    let quantity: Int
    let acquiredAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case itemTemplateId = "item_template_id"
        case name
        case category
        case basePrice = "base_price"
        case currentPrice = "current_price"
        case grade
        case requiredLicense = "required_license"
        case quantity
        case acquiredAt = "acquired_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        itemTemplateId = try container.decodeIfPresent(String.self, forKey: .itemTemplateId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        basePrice = try container.decodeIfPresent(Int.self, forKey: .basePrice) ?? 0
        currentPrice = try container.decodeIfPresent(Int.self, forKey: .currentPrice)
        requiredLicense = try container.decodeIfPresent(Int.self, forKey: .requiredLicense) ?? 0
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 0
        acquiredAt = try container.decodeIfPresent(String.self, forKey: .acquiredAt)

        if let gradeInt = try? container.decode(Int.self, forKey: .grade) {
            grade = InventoryItem.gradeName(for: gradeInt)
        } else if let gradeString = try? container.decode(String.self, forKey: .grade) {
            grade = gradeString
        } else {
            grade = "common"
        }
    }

    private static func gradeName(for value: Int) -> String {
        switch value {
        case 0: return "common"
        case 1: return "intermediate"
        case 2: return "advanced"
        case 3: return "rare"
        case 4: return "legendary"
        default: return "common"
        }
    }
}

struct RecentTrade: Codable {
    let id: String
    let tradeType: String?
    let itemName: String?
    let merchantName: String?
    let quantity: Int?
    let totalPrice: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case tradeType = "trade_type"
        case itemName = "item_name"
        case merchantName = "merchant_name"
        case quantity
        case totalPrice = "total_price"
        case createdAt = "created_at"
    }
}

struct MarketPrice: Codable {
    let id: String
    let itemName: String
    let basePrice: Int
    let currentPrice: Int
    let lastUpdated: String
}

struct MerchantData: Codable {
    let id: String
    let name: String
    let type: String
    let district: String
    let location: LocationData
    let requiredLicense: Int
    let inventory: [TradeItem]
    let distance: Double?
}

// TradeResult는 TradeManager.swift에 정의됨

struct PurchasedItem: Codable {
    let id: String
    let name: String
    let category: String
    let purchasePrice: Int
    let grade: String
}

struct SoldItem: Codable {
    let name: String
    let category: String
    let sellPrice: Int
}

struct TradeHistoryData: Codable {
    let trades: [TradeRecord]
    let pagination: PaginationInfo
}


struct PaginationInfo: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
}

// MARK: - Quest Response Models
// MARK: - Personal Items Response Models
// PersonalItemActionResponse and PersonalItemActionData are defined in PersonalItem.swift

// MARK: - Profile Response Models
struct ProfileCreationResponse: Codable {
    let success: Bool
    let data: ProfileCreationData?
    let message: String?
    let error: String?
}

struct ProfileCreationData: Codable {
    let name: String
    let age: Int
    let gender: String
    let personality: String
    let profileCompleted: Bool
}

struct ProfileUpdateResponse: Codable {
    let success: Bool
    let data: ProfileUpdateData?
    let message: String?
    let error: String?
}

struct ProfileUpdateData: Codable {
    let name: String
    let age: Int
    let gender: String
    let personality: String
}

struct PlayerProfileResponse: Codable {
    let success: Bool
    let data: PlayerDetail?
    let error: String?
}

// MARK: - Story Response Models
struct StoryDialogueResponse: Codable {
    let success: Bool
    let data: StoryDialogueData?
    let error: String?
}

struct StoryDialogueData: Codable {
    let node: StoryNode
    let merchantName: String
}

struct StoryNode: Codable {
    let id: String
    let type: String  // dialogue, decision, quest_gate
    let content: StoryNodeContent
    let choices: [StoryChoice]?
}

struct StoryNodeContent: Codable {
    let speaker: String
    let text: String
    let emotion: String?
}

struct StoryChoice: Codable {
    let id: String
    let text: String
    let nextNode: String?

    enum CodingKeys: String, CodingKey {
        case id, text
        case nextNode = "next_node"
    }
}

struct StoryProgressResponse: Codable {
    let success: Bool
    let data: StoryProgressData?
    let error: String?
}

struct StoryProgressData: Codable {
    let completedNode: String
    let rewards: StoryRewards?
    let nextNode: StoryNode?

    enum CodingKeys: String, CodingKey {
        case completedNode = "completedNode"
        case rewards
        case nextNode
    }
}

struct StoryRewards: Codable {
    let exp: Int?
    let reputation: Int?
    let money: Int?
}
