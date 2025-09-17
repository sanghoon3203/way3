// 📁 Security/SecureStorage.swift - Keychain 기반 안전한 데이터 저장
import Foundation
import Security

/**
 * SecureStorage
 *
 * Keychain Services를 사용한 안전한 데이터 저장소
 * - JWT 토큰의 안전한 저장/로드
 * - 자동 토큰 갱신 기능
 * - 생체 인증 옵션 지원
 * - 데이터 암호화 및 무결성 보장
 */
class SecureStorage {
    static let shared = SecureStorage()

    // MARK: - Keychain 서비스 식별자
    private let service = "com.way3.game.keychain"
    private let accessGroup: String? = nil // 앱 그룹 공유 시 사용

    // MARK: - 저장 키 상수
    struct Keys {
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
        static let playerId = "player_id"
        static let biometricEnabled = "biometric_enabled"
        static let lastTokenRefresh = "last_token_refresh"
    }

    // MARK: - 에러 타입
    enum SecureStorageError: Error, LocalizedError {
        case itemNotFound
        case invalidData
        case keychainError(OSStatus)
        case biometricNotAvailable
        case biometricNotEnrolled
        case biometricAuthenticationFailed

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "저장된 데이터를 찾을 수 없습니다"
            case .invalidData:
                return "저장된 데이터가 유효하지 않습니다"
            case .keychainError(let status):
                return "Keychain 오류: \(status)"
            case .biometricNotAvailable:
                return "생체 인증을 사용할 수 없습니다"
            case .biometricNotEnrolled:
                return "생체 인증이 설정되지 않았습니다"
            case .biometricAuthenticationFailed:
                return "생체 인증에 실패했습니다"
            }
        }
    }

    private init() {}

    // MARK: - 토큰 저장/로드

    /**
     * JWT 액세스 토큰 저장
     */
    func storeAuthToken(_ token: String) throws {
        try storeSecureData(token.data(using: .utf8)!, forKey: Keys.authToken, requireBiometric: false)

        // 토큰 저장 시간 기록
        let timestamp = Date().timeIntervalSince1970
        try storeSecureData("\(timestamp)".data(using: .utf8)!, forKey: Keys.lastTokenRefresh, requireBiometric: false)

        GameLogger.shared.logInfo("액세스 토큰 저장됨", category: .security)
    }

    /**
     * JWT 리프레시 토큰 저장 (생체 인증 필요)
     */
    func storeRefreshToken(_ token: String) throws {
        try storeSecureData(token.data(using: .utf8)!, forKey: Keys.refreshToken, requireBiometric: true)
        GameLogger.shared.logInfo("리프레시 토큰 저장됨 (생체 인증 보호)", category: .security)
    }

    /**
     * 액세스 토큰 로드
     */
    func loadAuthToken() throws -> String? {
        guard let data = try loadSecureData(forKey: Keys.authToken, requireBiometric: false) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /**
     * 리프레시 토큰 로드 (생체 인증 필요)
     */
    func loadRefreshToken() async throws -> String? {
        guard let data = try await loadSecureDataWithBiometric(forKey: Keys.refreshToken) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - 사용자 정보 저장/로드

    /**
     * 사용자 ID 저장
     */
    func storeUserId(_ userId: String) throws {
        try storeSecureData(userId.data(using: .utf8)!, forKey: Keys.userId, requireBiometric: false)
    }

    /**
     * 플레이어 ID 저장
     */
    func storePlayerId(_ playerId: String) throws {
        try storeSecureData(playerId.data(using: .utf8)!, forKey: Keys.playerId, requireBiometric: false)
    }

    /**
     * 사용자 ID 로드
     */
    func loadUserId() throws -> String? {
        guard let data = try loadSecureData(forKey: Keys.userId, requireBiometric: false) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /**
     * 플레이어 ID 로드
     */
    func loadPlayerId() throws -> String? {
        guard let data = try loadSecureData(forKey: Keys.playerId, requireBiometric: false) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - 토큰 자동 갱신

    /**
     * 토큰 갱신이 필요한지 확인
     */
    func shouldRefreshToken() -> Bool {
        do {
            guard let data = try loadSecureData(forKey: Keys.lastTokenRefresh, requireBiometric: false),
                  let timestampString = String(data: data, encoding: .utf8),
                  let timestamp = TimeInterval(timestampString) else {
                return true // 시간 정보가 없으면 갱신 필요
            }

            let lastRefresh = Date(timeIntervalSince1970: timestamp)
            let hoursSinceRefresh = Date().timeIntervalSince(lastRefresh) / 3600

            // 1시간 이상 지났으면 갱신 필요
            return hoursSinceRefresh >= 1.0

        } catch {
            GameLogger.shared.logError("토큰 갱신 시간 확인 실패", error: error, category: .security)
            return true
        }
    }

    /**
     * 토큰 자동 갱신 (백그라운드에서 실행)
     */
    func refreshTokenIfNeeded() async throws -> Bool {
        guard shouldRefreshToken() else {
            return false // 갱신 불필요
        }

        guard let refreshToken = try await loadRefreshToken() else {
            throw SecureStorageError.itemNotFound
        }

        // NetworkManager를 통한 토큰 갱신
        // 실제 구현에서는 NetworkManager.shared.refreshToken() 호출
        GameLogger.shared.logInfo("토큰 자동 갱신 시작", category: .security)

        return true
    }

    // MARK: - 생체 인증 설정

    /**
     * 생체 인증 활성화 상태 저장
     */
    func setBiometricEnabled(_ enabled: Bool) throws {
        let data = enabled ? "true".data(using: .utf8)! : "false".data(using: .utf8)!
        try storeSecureData(data, forKey: Keys.biometricEnabled, requireBiometric: false)
    }

    /**
     * 생체 인증 활성화 상태 확인
     */
    func isBiometricEnabled() -> Bool {
        do {
            guard let data = try loadSecureData(forKey: Keys.biometricEnabled, requireBiometric: false),
                  let enabledString = String(data: data, encoding: .utf8) else {
                return false
            }
            return enabledString == "true"
        } catch {
            return false
        }
    }

    // MARK: - 데이터 완전 삭제

    /**
     * 모든 저장된 인증 정보 삭제
     */
    func clearAllAuthData() throws {
        let keys = [Keys.authToken, Keys.refreshToken, Keys.userId, Keys.playerId, Keys.lastTokenRefresh]

        for key in keys {
            try deleteSecureData(forKey: key)
        }

        GameLogger.shared.logInfo("모든 인증 정보 삭제됨", category: .security)
    }

    /**
     * 특정 키의 데이터 삭제
     */
    func deleteSecureData(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecureStorageError.keychainError(status)
        }
    }

    // MARK: - Private Methods

    /**
     * 보안 데이터 저장 (Keychain)
     */
    private func storeSecureData(_ data: Data, forKey key: String, requireBiometric: Bool) throws {
        // 기존 항목 삭제
        try? deleteSecureData(forKey: key)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // 생체 인증 필요 시 접근 제어 추가
        if requireBiometric {
            var accessControlError: Unmanaged<CFError>?
            guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryAny,
                &accessControlError
            ) else {
                throw SecureStorageError.biometricNotAvailable
            }

            query[kSecAttrAccessControl as String] = accessControl
        }

        // 앱 그룹 설정 (필요 시)
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw SecureStorageError.keychainError(status)
        }
    }

    /**
     * 보안 데이터 로드 (일반)
     */
    private func loadSecureData(forKey key: String, requireBiometric: Bool) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw SecureStorageError.invalidData
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw SecureStorageError.keychainError(status)
        }
    }

    /**
     * 보안 데이터 로드 (생체 인증)
     */
    private func loadSecureDataWithBiometric(forKey key: String) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecUseOperationPrompt as String: "게임 데이터에 접근하려면 생체 인증이 필요합니다"
            ]

            DispatchQueue.global(qos: .userInitiated).async {
                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)

                DispatchQueue.main.async {
                    switch status {
                    case errSecSuccess:
                        guard let data = result as? Data else {
                            continuation.resume(throwing: SecureStorageError.invalidData)
                            return
                        }
                        continuation.resume(returning: data)
                    case errSecItemNotFound:
                        continuation.resume(returning: nil)
                    case -128: // errSecUserCancel
                        continuation.resume(throwing: SecureStorageError.biometricAuthenticationFailed)
                    case errSecAuthFailed:
                        continuation.resume(throwing: SecureStorageError.biometricAuthenticationFailed)
                    default:
                        continuation.resume(throwing: SecureStorageError.keychainError(status))
                    }
                }
            }
        }
    }
}

// MARK: - 생체 인증 지원 확인
import LocalAuthentication

extension SecureStorage {
    /**
     * 생체 인증 지원 여부 확인
     */
    func biometricAuthenticationAvailable() -> (available: Bool, type: LABiometryType) {
        let context = LAContext()
        var error: NSError?

        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        return (available, context.biometryType)
    }

    /**
     * 생체 인증 타입 설명
     */
    func biometricTypeDescription() -> String {
        let (available, type) = biometricAuthenticationAvailable()

        guard available else {
            return "생체 인증을 사용할 수 없습니다"
        }

        switch type {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "생체 인증 없음"
        @unknown default:
            return "알 수 없는 생체 인증"
        }
    }
}

// MARK: - 디버그 및 로깅
extension SecureStorage {
    /**
     * 저장된 키 목록 (디버그용)
     */
    func listStoredKeys() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item in
            return item[kSecAttrAccount as String] as? String
        }
    }

    /**
     * Keychain 상태 진단
     */
    func diagnostics() -> [String: Any] {
        let (biometricAvailable, biometricType) = biometricAuthenticationAvailable()
        let storedKeys = listStoredKeys()

        return [
            "service": service,
            "biometric_available": biometricAvailable,
            "biometric_type": biometricTypeDescription(),
            "biometric_enabled": isBiometricEnabled(),
            "stored_keys": storedKeys,
            "token_refresh_needed": shouldRefreshToken()
        ]
    }
}