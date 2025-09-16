// 📁 Core/GameLogger.swift - 게임 전용 로깅 및 모니터링 시스템
import Foundation
import OSLog

/**
 * GameLogger
 *
 * 게임 이벤트 및 시스템 로깅을 위한 중앙화된 로거
 * - OSLog 기반 구조화된 로깅
 * - 카테고리별 로그 분류
 * - 성능 측정 및 모니터링
 * - 개발/운영 환경별 로그 레벨 관리
 */
class GameLogger {
    static let shared = GameLogger()

    // MARK: - 로그 카테고리
    private let authLogger = Logger(subsystem: "com.way3.game", category: "authentication")
    private let networkLogger = Logger(subsystem: "com.way3.game", category: "network")
    private let gameplayLogger = Logger(subsystem: "com.way3.game", category: "gameplay")
    private let performanceLogger = Logger(subsystem: "com.way3.game", category: "performance")
    private let securityLogger = Logger(subsystem: "com.way3.game", category: "security")
    private let errorLogger = Logger(subsystem: "com.way3.game", category: "error")
    private let systemLogger = Logger(subsystem: "com.way3.game", category: "system")

    // MARK: - 로그 레벨 설정
    private var currentLogLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }()

    enum LogLevel: Int, CaseIterable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4

        var description: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            case .critical: return "CRITICAL"
            }
        }
    }

    // MARK: - 게임 이벤트 로깅

    /**
     * 사용자 행동 로깅
     */
    func logUserAction(_ action: UserAction, parameters: [String: Any] = [:]) {
        guard shouldLog(.info) else { return }

        let logData = createLogData(action: action.rawValue, parameters: parameters)
        gameplayLogger.info("👤 User Action: \(action.rawValue) | Data: \(logData)")

        // 중요한 사용자 행동은 원격 분석에도 전송
        if action.isImportant {
            sendToAnalytics(event: "user_action", data: logData)
        }
    }

    /**
     * 게임플레이 이벤트 로깅
     */
    func logGameplayEvent(_ event: GameplayEvent, details: [String: Any] = [:]) {
        guard shouldLog(.info) else { return }

        let logData = createLogData(action: event.rawValue, parameters: details)
        gameplayLogger.info("🎮 Gameplay: \(event.rawValue) | Details: \(logData)")

        // 게임 밸런싱 관련 이벤트는 별도 처리
        if event.isBalanceRelated {
            logBalancingData(event: event, details: details)
        }
    }

    /**
     * 거래 로깅
     */
    func logTradeEvent(_ event: TradeEvent, tradeData: TradeLogData) {
        guard shouldLog(.info) else { return }

        let logMessage = """
        💰 Trade: \(event.rawValue)
        📦 Item: \(tradeData.itemName) (Grade: \(tradeData.itemGrade))
        💵 Price: \(tradeData.price) (Profit: \(tradeData.profit ?? 0))
        🏪 Merchant: \(tradeData.merchantId)
        📍 Location: \(tradeData.location)
        """

        gameplayLogger.info("\(logMessage)")

        // 거래 데이터 분석을 위해 구조화된 데이터 저장
        let analyticsData: [String: Any] = [
            "event": event.rawValue,
            "item_name": tradeData.itemName,
            "item_grade": tradeData.itemGrade,
            "price": tradeData.price,
            "profit": tradeData.profit ?? 0,
            "merchant_id": tradeData.merchantId,
            "player_level": tradeData.playerLevel,
            "session_id": getCurrentSessionId()
        ]

        sendToAnalytics(event: "trade_event", data: analyticsData)
    }

    // MARK: - 네트워크 로깅

    /**
     * API 요청 로깅
     */
    func logNetworkRequest(_ request: NetworkRequest) {
        guard shouldLog(.debug) else { return }

        let logMessage = """
        🌐 API Request: \(request.method) \(request.endpoint)
        📊 Headers: \(request.headers.count) items
        📦 Body Size: \(request.bodySize) bytes
        ⏱️ Timeout: \(request.timeout)s
        """

        networkLogger.debug("\(logMessage)")
    }

    /**
     * API 응답 로깅
     */
    func logNetworkResponse(_ response: NetworkResponse) {
        let logLevel: LogLevel = response.isSuccess ? .info : .warning

        guard shouldLog(logLevel) else { return }

        let logMessage = """
        📨 API Response: \(response.statusCode) | \(response.endpoint)
        ⏱️ Duration: \(String(format: "%.3f", response.duration))s
        📦 Size: \(response.dataSize) bytes
        ✅ Success: \(response.isSuccess)
        """

        if response.isSuccess {
            networkLogger.info("\(logMessage)")
        } else {
            networkLogger.warning("⚠️ \(logMessage) | Error: \(response.errorMessage ?? "Unknown")")
        }

        // 네트워크 성능 모니터링
        logNetworkPerformance(response)
    }

    /**
     * 네트워크 에러 로깅
     */
    func logNetworkError(_ error: NetworkError, context: NetworkContext) {
        let logMessage = """
        ❌ Network Error: \(error.localizedDescription)
        🔗 Endpoint: \(context.endpoint)
        🔄 Retry Count: \(context.retryCount)
        📱 Connection: \(context.connectionType)
        """

        errorLogger.error("\(logMessage)")

        // 네트워크 에러 패턴 분석을 위한 데이터 수집
        let errorData: [String: Any] = [
            "error_code": error.code,
            "error_description": error.localizedDescription,
            "endpoint": context.endpoint,
            "retry_count": context.retryCount,
            "connection_type": context.connectionType,
            "timestamp": Date().timeIntervalSince1970
        ]

        sendToAnalytics(event: "network_error", data: errorData)
    }

    // MARK: - 인증 및 보안 로깅

    /**
     * 인증 이벤트 로깅
     */
    func logAuthEvent(_ event: AuthEvent, details: [String: Any] = [:]) {
        let logLevel: LogLevel = event.isSecurityCritical ? .warning : .info

        guard shouldLog(logLevel) else { return }

        let logData = createLogData(action: event.rawValue, parameters: details)
        let logMessage = "🔐 Auth: \(event.rawValue) | \(logData)"

        if event.isSecurityCritical {
            securityLogger.warning("⚠️ \(logMessage)")
        } else {
            authLogger.info("\(logMessage)")
        }

        // 보안 중요 이벤트는 별도 모니터링
        if event.isSecurityCritical {
            logSecurityEvent(event: event, details: details)
        }
    }

    /**
     * 보안 이벤트 로깅
     */
    func logSecurityEvent(event: AuthEvent, details: [String: Any]) {
        let securityData: [String: Any] = [
            "event": event.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId(),
            "device_id": getDeviceId(),
            "details": details
        ]

        securityLogger.warning("🛡️ Security Event: \(event.rawValue)")

        // 보안 이벤트는 즉시 원격 전송
        sendToSecurityMonitoring(data: securityData)
    }

    // MARK: - 성능 모니터링

    /**
     * 성능 측정 시작
     */
    func startPerformanceMeasurement(_ identifier: String) -> PerformanceMeasurement {
        let measurement = PerformanceMeasurement(identifier: identifier)
        performanceLogger.debug("📊 Performance Start: \(identifier)")
        return measurement
    }

    /**
     * 성능 측정 완료
     */
    func endPerformanceMeasurement(_ measurement: PerformanceMeasurement, additionalData: [String: Any] = [:]) {
        let duration = measurement.end()

        let logMessage = """
        📊 Performance End: \(measurement.identifier)
        ⏱️ Duration: \(String(format: "%.3f", duration))s
        📈 Memory: \(getCurrentMemoryUsage())MB
        """

        if duration > 1.0 { // 1초 이상 걸린 작업은 경고
            performanceLogger.warning("⚠️ Slow Operation: \(logMessage)")
        } else {
            performanceLogger.info("\(logMessage)")
        }

        // 성능 데이터 수집
        var performanceData: [String: Any] = [
            "identifier": measurement.identifier,
            "duration": duration,
            "memory_usage": getCurrentMemoryUsage(),
            "timestamp": Date().timeIntervalSince1970
        ]

        performanceData.merge(additionalData) { _, new in new }
        sendToAnalytics(event: "performance_measurement", data: performanceData)
    }

    // MARK: - 에러 로깅

    /**
     * 일반 에러 로깅
     */
    func logError(_ error: Error, context: String = "", additionalInfo: [String: Any] = [:]) {
        let logMessage = """
        ❌ Error: \(error.localizedDescription)
        📍 Context: \(context)
        📝 Info: \(additionalInfo)
        🧵 Thread: \(Thread.isMainThread ? "Main" : "Background")
        """

        errorLogger.error("\(logMessage)")

        // 에러 패턴 분석을 위한 데이터 수집
        let errorData: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code,
            "context": context,
            "additional_info": additionalInfo,
            "is_main_thread": Thread.isMainThread,
            "timestamp": Date().timeIntervalSince1970
        ]

        sendToAnalytics(event: "error_occurred", data: errorData)
    }

    /**
     * 크리티컬 에러 로깅
     */
    func logCriticalError(_ error: Error, context: String = "", stackTrace: String? = nil) {
        let logMessage = """
        🚨 CRITICAL ERROR: \(error.localizedDescription)
        📍 Context: \(context)
        📚 Stack: \(stackTrace ?? "Not available")
        """

        errorLogger.critical("\(logMessage)")

        // 크리티컬 에러는 즉시 원격 전송
        let criticalData: [String: Any] = [
            "error": error.localizedDescription,
            "context": context,
            "stack_trace": stackTrace ?? "",
            "device_info": getDeviceInfo(),
            "app_version": getAppVersion(),
            "timestamp": Date().timeIntervalSince1970
        ]

        sendToCrashReporting(data: criticalData)
    }

    // MARK: - 시스템 로깅

    /**
     * 앱 라이프사이클 로깅
     */
    func logAppLifecycle(_ event: AppLifecycleEvent) {
        let logMessage = "📱 App Lifecycle: \(event.rawValue)"
        systemLogger.info("\(logMessage)")

        // 세션 관리 및 사용 시간 추적
        handleSessionEvent(event)
    }

    /**
     * 메모리 경고 로깅
     */
    func logMemoryWarning() {
        let memoryUsage = getCurrentMemoryUsage()
        let logMessage = "⚠️ Memory Warning | Current Usage: \(memoryUsage)MB"

        systemLogger.warning("\(logMessage)")

        // 메모리 사용 패턴 분석
        let memoryData: [String: Any] = [
            "memory_usage": memoryUsage,
            "available_memory": getAvailableMemory(),
            "timestamp": Date().timeIntervalSince1970
        ]

        sendToAnalytics(event: "memory_warning", data: memoryData)
    }

    // MARK: - Private Helper Methods

    private func shouldLog(_ level: LogLevel) -> Bool {
        return level.rawValue >= currentLogLevel.rawValue
    }

    private func createLogData(action: String, parameters: [String: Any]) -> String {
        guard !parameters.isEmpty else { return "{}" }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{\(parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", "))}"
        }
    }

    private func logBalancingData(event: GameplayEvent, details: [String: Any]) {
        // 게임 밸런싱 분석을 위한 특별한 로깅
        let balanceData: [String: Any] = [
            "event": event.rawValue,
            "player_level": details["player_level"] ?? 0,
            "player_money": details["player_money"] ?? 0,
            "session_playtime": getSessionPlaytime(),
            "details": details
        ]

        // 별도의 밸런싱 분석 시스템으로 전송
        sendToBalanceAnalytics(data: balanceData)
    }

    private func logNetworkPerformance(_ response: NetworkResponse) {
        // 네트워크 성능 벤치마킹
        if response.duration > 5.0 {
            performanceLogger.warning("🐌 Slow Network: \(response.endpoint) took \(response.duration)s")
        }

        // 네트워크 품질 데이터 수집
        let networkQualityData: [String: Any] = [
            "endpoint": response.endpoint,
            "duration": response.duration,
            "data_size": response.dataSize,
            "status_code": response.statusCode,
            "connection_type": getCurrentConnectionType()
        ]

        sendToAnalytics(event: "network_performance", data: networkQualityData)
    }

    // MARK: - 원격 전송 메서드들

    private func sendToAnalytics(event: String, data: [String: Any]) {
        // Firebase Analytics, Mixpanel 등으로 전송
        #if DEBUG
        print("📊 Analytics: \(event) | \(data)")
        #endif
    }

    private func sendToSecurityMonitoring(data: [String: Any]) {
        // 보안 모니터링 시스템으로 전송
        #if DEBUG
        print("🛡️ Security Monitor: \(data)")
        #endif
    }

    private func sendToCrashReporting(data: [String: Any]) {
        // Crashlytics, Sentry 등으로 전송
        #if DEBUG
        print("🚨 Crash Report: \(data)")
        #endif
    }

    private func sendToBalanceAnalytics(data: [String: Any]) {
        // 게임 밸런싱 분석 시스템으로 전송
        #if DEBUG
        print("⚖️ Balance Analytics: \(data)")
        #endif
    }

    // MARK: - 시스템 정보 수집

    private func getCurrentSessionId() -> String {
        // 현재 세션 ID 반환
        return UserDefaults.standard.string(forKey: "current_session_id") ?? UUID().uuidString
    }

    private func getDeviceId() -> String {
        // 디바이스 식별자 반환 (개인정보 비식별화)
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    private func getCurrentMemoryUsage() -> Int {
        // 현재 메모리 사용량 (MB)
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Int(info.resident_size) / (1024 * 1024)
        }
        return 0
    }

    private func getAvailableMemory() -> Int {
        // 사용 가능한 메모리 (MB)
        return Int(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024)
    }

    private func getDeviceInfo() -> [String: Any] {
        return [
            "model": UIDevice.current.model,
            "system_name": UIDevice.current.systemName,
            "system_version": UIDevice.current.systemVersion,
            "identifier_for_vendor": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ]
    }

    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    private func getCurrentConnectionType() -> String {
        // 네트워크 연결 타입 확인 (WiFi/Cellular)
        return "wifi" // 실제 구현에서는 Network Framework 사용
    }

    private func getSessionPlaytime() -> TimeInterval {
        // 현재 세션 플레이 시간
        let sessionStart = UserDefaults.standard.double(forKey: "session_start_time")
        return Date().timeIntervalSince1970 - sessionStart
    }

    private func handleSessionEvent(_ event: AppLifecycleEvent) {
        switch event {
        case .didBecomeActive:
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "session_start_time")
            UserDefaults.standard.set(UUID().uuidString, forKey: "current_session_id")
        case .didEnterBackground:
            let playtime = getSessionPlaytime()
            sendToAnalytics(event: "session_end", data: ["playtime": playtime])
        default:
            break
        }
    }

    init() {
        // 초기 설정
        #if DEBUG
        print("📝 GameLogger initialized with log level: \(currentLogLevel.description)")
        #endif
    }
}

// MARK: - 데이터 구조체들

struct PerformanceMeasurement {
    let identifier: String
    private let startTime: CFAbsoluteTime

    init(identifier: String) {
        self.identifier = identifier
        self.startTime = CFAbsoluteTimeGetCurrent()
    }

    func end() -> TimeInterval {
        return CFAbsoluteTimeGetCurrent() - startTime
    }
}

struct TradeLogData {
    let itemName: String
    let itemGrade: String
    let price: Int
    let profit: Int?
    let merchantId: String
    let location: String
    let playerLevel: Int
}

struct NetworkRequest {
    let method: String
    let endpoint: String
    let headers: [String: String]
    let bodySize: Int
    let timeout: TimeInterval
}

struct NetworkResponse {
    let endpoint: String
    let statusCode: Int
    let duration: TimeInterval
    let dataSize: Int
    let isSuccess: Bool
    let errorMessage: String?
}

struct NetworkContext {
    let endpoint: String
    let retryCount: Int
    let connectionType: String
}

// MARK: - 이벤트 열거형들

enum UserAction: String, CaseIterable {
    case login = "login"
    case logout = "logout"
    case tradeStart = "trade_start"
    case tradeComplete = "trade_complete"
    case mapOpen = "map_open"
    case inventoryOpen = "inventory_open"
    case skillUse = "skill_use"
    case questAccept = "quest_accept"
    case questComplete = "quest_complete"

    var isImportant: Bool {
        switch self {
        case .login, .logout, .tradeComplete, .questComplete:
            return true
        default:
            return false
        }
    }
}

enum GameplayEvent: String, CaseIterable {
    case levelUp = "level_up"
    case itemAcquired = "item_acquired"
    case moneyEarned = "money_earned"
    case skillLearned = "skill_learned"
    case merchantDiscovered = "merchant_discovered"
    case areaEntered = "area_entered"

    var isBalanceRelated: Bool {
        switch self {
        case .levelUp, .moneyEarned, .itemAcquired:
            return true
        default:
            return false
        }
    }
}

enum TradeEvent: String, CaseIterable {
    case tradeStarted = "trade_started"
    case tradeCompleted = "trade_completed"
    case tradeFailed = "trade_failed"
    case itemSold = "item_sold"
    case itemBought = "item_bought"
}

enum AuthEvent: String, CaseIterable {
    case loginAttempt = "login_attempt"
    case loginSuccess = "login_success"
    case loginFailed = "login_failed"
    case tokenRefresh = "token_refresh"
    case tokenExpired = "token_expired"
    case biometricAuthSuccess = "biometric_auth_success"
    case biometricAuthFailed = "biometric_auth_failed"
    case logoutInitiated = "logout_initiated"

    var isSecurityCritical: Bool {
        switch self {
        case .loginFailed, .tokenExpired, .biometricAuthFailed:
            return true
        default:
            return false
        }
    }
}

enum AppLifecycleEvent: String, CaseIterable {
    case didFinishLaunching = "did_finish_launching"
    case didBecomeActive = "did_become_active"
    case willResignActive = "will_resign_active"
    case didEnterBackground = "did_enter_background"
    case willEnterForeground = "will_enter_foreground"
    case willTerminate = "will_terminate"
}