// 📁 Core/NotificationManager.swift - 푸시 알림 및 로컬 알림 관리자
import Foundation
import UserNotifications
import UIKit

/**
 * NotificationManager
 *
 * 게임 내 알림 시스템의 중앙 관리자
 * - APNs (Apple Push Notification service) 연동
 * - 로컬 알림 스케줄링
 * - 알림 권한 관리
 * - 게임 특화 알림 타입
 * - 백그라운드 알림 처리
 */
@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var notificationSettings: UNNotificationSettings?
    @Published var deviceToken: String?
    @Published var pendingNotifications: [GameNotification] = []

    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Notification Categories
    private let notificationCategories: Set<UNNotificationCategory> = {
        // 거래 완료 알림 카테고리
        let tradeCompleteCategory = UNNotificationCategory(
            identifier: NotificationCategory.tradeComplete.rawValue,
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_TRADE",
                    title: "거래 내역 보기",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "VIEW_INVENTORY",
                    title: "인벤토리 확인",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        // 근처 플레이어 알림 카테고리
        let nearbyPlayerCategory = UNNotificationCategory(
            identifier: NotificationCategory.nearbyPlayer.rawValue,
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_PLAYER",
                    title: "플레이어 보기",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "무시",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        // 이벤트 알림 카테고리
        let eventCategory = UNNotificationCategory(
            identifier: NotificationCategory.event.rawValue,
            actions: [
                UNNotificationAction(
                    identifier: "PARTICIPATE",
                    title: "참여하기",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "REMIND_LATER",
                    title: "나중에 알림",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        return [tradeCompleteCategory, nearbyPlayerCategory, eventCategory]
    }()

    override init() {
        super.init()
        setupNotificationCenter()
        checkNotificationAuthorization()
    }

    // MARK: - 초기 설정

    private func setupNotificationCenter() {
        notificationCenter.delegate = self

        // 알림 카테고리 등록
        notificationCenter.setNotificationCategories(notificationCategories)

        print("📱 NotificationManager: 알림 센터 설정 완료")
    }

    // MARK: - 권한 관리

    /**
     * 알림 권한 요청
     */
    func requestNotificationPermission() async -> Bool {
        do {
            let authorized = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional, .criticalAlert]
            )

            await updateAuthorizationStatus()

            if authorized {
                await registerForRemoteNotifications()
                print("✅ NotificationManager: 알림 권한 허용됨")
            } else {
                print("❌ NotificationManager: 알림 권한 거부됨")
            }

            return authorized

        } catch {
            GameLogger.shared.logError(error, context: "NotificationManager.requestPermission")
            return false
        }
    }

    /**
     * 현재 알림 권한 상태 확인
     */
    func checkNotificationAuthorization() {
        Task {
            await updateAuthorizationStatus()
        }
    }

    private func updateAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()

        self.notificationSettings = settings
        self.authorizationStatus = settings.authorizationStatus
        self.isAuthorized = settings.authorizationStatus == .authorized ||
                          settings.authorizationStatus == .provisional

        print("📱 NotificationManager: 권한 상태 - \(authorizationStatus.description)")
    }

    // MARK: - 원격 알림 등록

    /**
     * APNs 등록
     */
    func registerForRemoteNotifications() async {
        guard isAuthorized else {
            print("⚠️ NotificationManager: 알림 권한이 없어 원격 알림 등록 불가")
            return
        }

        await UIApplication.shared.registerForRemoteNotifications()
        print("📡 NotificationManager: 원격 알림 등록 요청됨")
    }

    /**
     * 디바이스 토큰 설정
     */
    func setDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        print("📱 NotificationManager: 디바이스 토큰 등록됨")
        GameLogger.shared.logSystemEvent(.deviceTokenReceived, details: ["token_length": tokenString.count])

        // 서버에 디바이스 토큰 전송
        Task {
            await sendDeviceTokenToServer(tokenString)
        }
    }

    /**
     * 원격 알림 등록 실패 처리
     */
    func handleRemoteNotificationRegistrationError(_ error: Error) {
        print("❌ NotificationManager: 원격 알림 등록 실패 - \(error)")
        GameLogger.shared.logError(error, context: "RemoteNotificationRegistration")
    }

    // MARK: - 로컬 알림

    /**
     * 로컬 알림 스케줄링
     */
    func scheduleLocalNotification(_ notification: GameNotification) async {
        let content = createNotificationContent(from: notification)
        let trigger = createNotificationTrigger(for: notification)

        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("📅 NotificationManager: 로컬 알림 스케줄됨 - \(notification.title)")

            GameLogger.shared.logUserAction(.scheduleNotification, parameters: [
                "notification_id": notification.id,
                "type": notification.type.rawValue,
                "scheduled_time": notification.scheduledTime?.timeIntervalSince1970 ?? 0
            ])

        } catch {
            GameLogger.shared.logError(error, context: "ScheduleLocalNotification")
        }
    }

    /**
     * 게임 특화 알림 생성
     */
    func createGameNotification(
        type: NotificationType,
        title: String,
        body: String,
        data: [String: Any] = [:],
        scheduledTime: Date? = nil
    ) -> GameNotification {

        return GameNotification(
            id: UUID().uuidString,
            type: type,
            title: title,
            body: body,
            data: data,
            scheduledTime: scheduledTime,
            createdAt: Date()
        )
    }

    /**
     * 거래 완료 알림
     */
    func sendTradeCompleteNotification(
        itemName: String,
        profit: Int,
        merchantName: String
    ) async {
        let notification = createGameNotification(
            type: .tradeComplete,
            title: "거래 완료! 💰",
            body: "\(itemName)을(를) \(merchantName)에게 판매하여 \(profit)원의 수익을 얻었습니다!"
        )

        await scheduleLocalNotification(notification)
    }

    /**
     * 근처 플레이어 알림
     */
    func sendNearbyPlayerNotification(playerName: String, distance: Int) async {
        guard distance <= 100 else { return } // 100m 이내만

        let notification = createGameNotification(
            type: .nearbyPlayer,
            title: "근처에 플레이어 발견! 👥",
            body: "\(playerName)님이 \(distance)m 거리에 있습니다."
        )

        await scheduleLocalNotification(notification)
    }

    /**
     * 이벤트 알림
     */
    func sendEventNotification(
        eventTitle: String,
        eventDescription: String,
        startTime: Date
    ) async {
        let notification = createGameNotification(
            type: .event,
            title: "이벤트 시작! 🎉",
            body: "\(eventTitle): \(eventDescription)",
            scheduledTime: startTime.addingTimeInterval(-300) // 5분 전 알림
        )

        await scheduleLocalNotification(notification)
    }

    /**
     * 퀘스트 완료 알림
     */
    func sendQuestCompleteNotification(questTitle: String, reward: String) async {
        let notification = createGameNotification(
            type: .questComplete,
            title: "퀘스트 완료! ✅",
            body: "\(questTitle) 완료! 보상: \(reward)"
        )

        await scheduleLocalNotification(notification)
    }

    // MARK: - 알림 관리

    /**
     * 예약된 알림 목록 조회
     */
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    /**
     * 특정 알림 취소
     */
    func cancelNotification(withId identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ NotificationManager: 알림 취소됨 - \(identifier)")
    }

    /**
     * 모든 알림 취소
     */
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ NotificationManager: 모든 알림 취소됨")
    }

    /**
     * 배지 카운트 설정
     */
    func setBadgeCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }

    /**
     * 배지 카운트 제거
     */
    func clearBadgeCount() {
        setBadgeCount(0)
    }

    // MARK: - 백그라운드 알림 처리

    /**
     * 백그라운드에서 받은 원격 알림 처리
     */
    func handleBackgroundNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📱 NotificationManager: 백그라운드 알림 수신")

        // 알림 데이터 파싱
        guard let notificationData = parseNotificationData(userInfo) else {
            completionHandler(.failed)
            return
        }

        // 게임 데이터 업데이트
        Task {
            do {
                let result = try await processBackgroundNotification(notificationData)
                completionHandler(result)
            } catch {
                GameLogger.shared.logError(error, context: "BackgroundNotificationProcessing")
                completionHandler(.failed)
            }
        }
    }

    // MARK: - Private Helper Methods

    private func createNotificationContent(from notification: GameNotification) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.categoryIdentifier = notification.type.category.rawValue

        // 배지 카운트 증가
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)

        // 커스텀 데이터 추가
        if !notification.data.isEmpty {
            content.userInfo = notification.data
        }

        // 알림 타입별 특별 설정
        switch notification.type {
        case .tradeComplete:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("trade_complete.wav"))
        case .nearbyPlayer:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("nearby_player.wav"))
        case .event:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("event.wav"))
        default:
            content.sound = .default
        }

        return content
    }

    private func createNotificationTrigger(for notification: GameNotification) -> UNNotificationTrigger? {
        guard let scheduledTime = notification.scheduledTime else {
            // 즉시 전송
            return UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        }

        let timeInterval = scheduledTime.timeIntervalSinceNow
        guard timeInterval > 0 else {
            // 과거 시간이면 즉시 전송
            return UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        }

        return UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
    }

    private func parseNotificationData(_ userInfo: [AnyHashable: Any]) -> NotificationData? {
        // 서버에서 보낸 알림 데이터 파싱
        guard let type = userInfo["type"] as? String,
              let title = userInfo["title"] as? String,
              let body = userInfo["body"] as? String else {
            return nil
        }

        return NotificationData(
            type: NotificationType(rawValue: type) ?? .general,
            title: title,
            body: body,
            data: userInfo["data"] as? [String: Any] ?? [:]
        )
    }

    private func processBackgroundNotification(_ data: NotificationData) async throws -> UIBackgroundFetchResult {
        // 백그라운드에서 게임 데이터 업데이트
        switch data.type {
        case .tradeComplete:
            // 거래 데이터 동기화
            try await syncTradeData()
            return .newData

        case .nearbyPlayer:
            // 근처 플레이어 정보 업데이트
            try await updateNearbyPlayers()
            return .newData

        case .event:
            // 이벤트 정보 업데이트
            try await updateEventInfo()
            return .newData

        default:
            return .noData
        }
    }

    private func syncTradeData() async throws {
        // NetworkManager를 통한 거래 데이터 동기화
        print("🔄 NotificationManager: 거래 데이터 동기화 중...")
    }

    private func updateNearbyPlayers() async throws {
        // 근처 플레이어 정보 업데이트
        print("🔄 NotificationManager: 근처 플레이어 정보 업데이트 중...")
    }

    private func updateEventInfo() async throws {
        // 이벤트 정보 업데이트
        print("🔄 NotificationManager: 이벤트 정보 업데이트 중...")
    }

    private func sendDeviceTokenToServer(_ token: String) async {
        // 서버에 디바이스 토큰 전송
        do {
            // NetworkManager를 통한 토큰 전송
            print("📡 NotificationManager: 서버에 디바이스 토큰 전송 중...")

            GameLogger.shared.logSystemEvent(.deviceTokenSent, details: [
                "token_length": token.count,
                "timestamp": Date().timeIntervalSince1970
            ])

        } catch {
            GameLogger.shared.logError(error, context: "SendDeviceTokenToServer")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /**
     * 포그라운드에서 알림 수신 시 처리
     */
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 NotificationManager: 포그라운드 알림 수신 - \(notification.request.content.title)")

        // 포그라운드에서도 배너, 사운드, 배지 표시
        completionHandler([.banner, .sound, .badge])
    }

    /**
     * 알림 탭/액션 처리
     */
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let notification = response.notification
        let actionIdentifier = response.actionIdentifier

        print("📱 NotificationManager: 알림 액션 - \(actionIdentifier)")

        // 알림 액션 처리
        handleNotificationAction(actionIdentifier, notification: notification)

        // 배지 카운트 감소
        setBadgeCount(max(0, UIApplication.shared.applicationIconBadgeNumber - 1))

        GameLogger.shared.logUserAction(.notificationTapped, parameters: [
            "action": actionIdentifier,
            "notification_id": notification.request.identifier,
            "category": notification.request.content.categoryIdentifier
        ])

        completionHandler()
    }

    private func handleNotificationAction(_ actionIdentifier: String, notification: UNNotification) {
        switch actionIdentifier {
        case "VIEW_TRADE":
            // 거래 내역 화면으로 이동
            NotificationCenter.default.post(name: .navigateToTradeHistory, object: nil)

        case "VIEW_INVENTORY":
            // 인벤토리 화면으로 이동
            NotificationCenter.default.post(name: .navigateToInventory, object: nil)

        case "VIEW_PLAYER":
            // 플레이어 정보 화면으로 이동
            if let playerData = notification.request.content.userInfo["player_data"] as? [String: Any] {
                NotificationCenter.default.post(name: .navigateToPlayer, object: playerData)
            }

        case "PARTICIPATE":
            // 이벤트 참여
            if let eventData = notification.request.content.userInfo["event_data"] as? [String: Any] {
                NotificationCenter.default.post(name: .participateInEvent, object: eventData)
            }

        case "REMIND_LATER":
            // 나중에 알림 (1시간 후)
            Task {
                let reminderNotification = createGameNotification(
                    type: .event,
                    title: notification.request.content.title,
                    body: "이벤트가 곧 시작됩니다!",
                    scheduledTime: Date().addingTimeInterval(3600)
                )
                await scheduleLocalNotification(reminderNotification)
            }

        case UNNotificationDefaultActionIdentifier:
            // 기본 탭 액션 (알림 자체를 탭)
            handleDefaultNotificationTap(notification)

        default:
            break
        }
    }

    private func handleDefaultNotificationTap(_ notification: UNNotification) {
        let categoryId = notification.request.content.categoryIdentifier

        switch categoryId {
        case NotificationCategory.tradeComplete.rawValue:
            NotificationCenter.default.post(name: .navigateToTradeHistory, object: nil)

        case NotificationCategory.nearbyPlayer.rawValue:
            NotificationCenter.default.post(name: .navigateToMap, object: nil)

        case NotificationCategory.event.rawValue:
            NotificationCenter.default.post(name: .navigateToEvents, object: nil)

        default:
            // 메인 화면으로 이동
            NotificationCenter.default.post(name: .navigateToMain, object: nil)
        }
    }
}

// MARK: - 데이터 구조체들

struct GameNotification {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let data: [String: Any]
    let scheduledTime: Date?
    let createdAt: Date
}

struct NotificationData {
    let type: NotificationType
    let title: String
    let body: String
    let data: [String: Any]
}

// MARK: - 열거형들

enum NotificationType: String, CaseIterable {
    case tradeComplete = "trade_complete"
    case nearbyPlayer = "nearby_player"
    case event = "event"
    case questComplete = "quest_complete"
    case levelUp = "level_up"
    case general = "general"

    var category: NotificationCategory {
        switch self {
        case .tradeComplete, .questComplete, .levelUp:
            return .tradeComplete
        case .nearbyPlayer:
            return .nearbyPlayer
        case .event:
            return .event
        case .general:
            return .general
        }
    }
}

enum NotificationCategory: String, CaseIterable {
    case tradeComplete = "TRADE_COMPLETE"
    case nearbyPlayer = "NEARBY_PLAYER"
    case event = "EVENT"
    case general = "GENERAL"
}

// MARK: - 확장들

extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}

extension Notification.Name {
    static let navigateToTradeHistory = Notification.Name("navigateToTradeHistory")
    static let navigateToInventory = Notification.Name("navigateToInventory")
    static let navigateToPlayer = Notification.Name("navigateToPlayer")
    static let navigateToMap = Notification.Name("navigateToMap")
    static let navigateToEvents = Notification.Name("navigateToEvents")
    static let navigateToMain = Notification.Name("navigateToMain")
    static let participateInEvent = Notification.Name("participateInEvent")
}

// GameLogger 확장 (알림 관련 이벤트)
extension GameLogger {
    func logSystemEvent(_ event: SystemEvent, details: [String: Any] = [:]) {
        systemLogger.info("🔧 System: \(event.rawValue) | \(details)")
    }
}

enum SystemEvent: String {
    case deviceTokenReceived = "device_token_received"
    case deviceTokenSent = "device_token_sent"
}

// UserAction 확장 (알림 관련 액션)
extension UserAction {
    static let scheduleNotification = UserAction(rawValue: "schedule_notification")!
    static let notificationTapped = UserAction(rawValue: "notification_tapped")!
}