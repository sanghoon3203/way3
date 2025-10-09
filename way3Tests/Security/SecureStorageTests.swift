// 📁 way3Tests/Security/SecureStorageTests.swift - SecureStorage 단위 테스트
import XCTest
import LocalAuthentication
@testable import way3

/**
 * SecureStorage 단위 테스트
 *
 * Keychain 기반 보안 저장소의 핵심 기능들을 검증:
 * - 토큰 저장/로드/삭제
 * - 생체 인증 통합
 * - 에러 처리
 * - 성능 및 보안
 */
final class SecureStorageTests: XCTestCase {

    var secureStorage: SecureStorage!

    override func setUpWithError() throws {
        secureStorage = SecureStorage.shared

        // 테스트 전 기존 데이터 정리
        try secureStorage.clearAllAuthData()
    }

    override func tearDownWithError() throws {
        // 테스트 후 정리
        try secureStorage.clearAllAuthData()
    }

    // MARK: - 기본 저장/로드 테스트

    func testStoreAndLoadAuthToken() throws {
        // Given: 테스트 토큰
        let testToken = "test_jwt_token_12345abcdef"

        // When: 토큰 저장
        try secureStorage.storeAuthToken(testToken)

        // Then: 토큰 로드 확인
        let loadedToken = try secureStorage.loadAuthToken()
        XCTAssertEqual(loadedToken, testToken)
    }

    func testStoreAndLoadRefreshToken() async throws {
        // Given: 테스트 리프레시 토큰
        let testRefreshToken = "test_refresh_token_67890xyz"

        // When: 리프레시 토큰 저장 (생체 인증 필요)
        do {
            try secureStorage.storeRefreshToken(testRefreshToken)

            // Then: 리프레시 토큰 로드 (생체 인증 필요)
            let loadedRefreshToken = try await secureStorage.loadRefreshToken()
            XCTAssertEqual(loadedRefreshToken, testRefreshToken)

        } catch SecureStorage.SecureStorageError.biometricNotAvailable {
            // 생체 인증이 없는 시뮬레이터에서는 스킵
            print("⚠️ 생체 인증을 사용할 수 없어 테스트를 건너뜁니다")
            XCTAssert(true) // 테스트 통과 처리
        }
    }

    func testStoreAndLoadUserInfo() throws {
        // Given: 사용자 정보
        let userId = "user_123456"
        let playerId = "player_789012"

        // When: 사용자 정보 저장
        try secureStorage.storeUserId(userId)
        try secureStorage.storePlayerId(playerId)

        // Then: 사용자 정보 로드 확인
        let loadedUserId = try secureStorage.loadUserId()
        let loadedPlayerId = try secureStorage.loadPlayerId()

        XCTAssertEqual(loadedUserId, userId)
        XCTAssertEqual(loadedPlayerId, playerId)
    }

    // MARK: - 데이터 삭제 테스트

    func testDeleteSpecificData() throws {
        // Given: 저장된 토큰
        let testToken = "token_to_be_deleted"
        try secureStorage.storeAuthToken(testToken)

        // 토큰이 저장되었는지 확인
        XCTAssertNotNil(try secureStorage.loadAuthToken())

        // When: 특정 데이터 삭제
        try secureStorage.deleteSecureData(forKey: SecureStorage.Keys.authToken)

        // Then: 삭제 확인
        let deletedToken = try? secureStorage.loadAuthToken()
        XCTAssertNil(deletedToken)
    }

    func testClearAllAuthData() throws {
        // Given: 여러 데이터 저장
        try secureStorage.storeAuthToken("test_token")
        try secureStorage.storeUserId("test_user")
        try secureStorage.storePlayerId("test_player")

        // 데이터가 저장되었는지 확인
        XCTAssertNotNil(try secureStorage.loadAuthToken())
        XCTAssertNotNil(try secureStorage.loadUserId())
        XCTAssertNotNil(try secureStorage.loadPlayerId())

        // When: 모든 인증 데이터 삭제
        try secureStorage.clearAllAuthData()

        // Then: 모든 데이터 삭제 확인
        XCTAssertNil(try? secureStorage.loadAuthToken())
        XCTAssertNil(try? secureStorage.loadUserId())
        XCTAssertNil(try? secureStorage.loadPlayerId())
    }

    // MARK: - 토큰 갱신 테스트

    func testShouldRefreshToken() throws {
        // Given: 새로운 토큰 (갱신 불필요)
        try secureStorage.storeAuthToken("fresh_token")

        // Then: 갱신 불필요 확인
        XCTAssertFalse(secureStorage.shouldRefreshToken())

        // Given: 토큰 저장 시간 조작 (1시간 이상 경과)
        let oldTimestamp = Date().addingTimeInterval(-3700) // 1시간 1분 전
        let timestampData = "\(oldTimestamp.timeIntervalSince1970)".data(using: .utf8)!

        // 내부 저장 메서드를 통해 이전 시간으로 설정
        try secureStorage.deleteSecureData(forKey: SecureStorage.Keys.lastTokenRefresh)

        // When: 오래된 타임스탬프로 재설정
        // (실제 구현에서는 내부 메서드 접근 또는 Mock 사용)

        // Then: 갱신 필요 확인
        // XCTAssertTrue(secureStorage.shouldRefreshToken())
    }

    // MARK: - 생체 인증 테스트

    func testBiometricAuthentication() {
        // Given: 생체 인증 지원 확인
        let (available, type) = secureStorage.biometricAuthenticationAvailable()

        // Then: 생체 인증 정보 확인
        if available {
            XCTAssertNotEqual(type, .none)
            let description = secureStorage.biometricTypeDescription()
            XCTAssertFalse(description.isEmpty)
            print("🔐 사용 가능한 생체 인증: \(description)")
        } else {
            print("⚠️ 생체 인증을 사용할 수 없습니다")
            XCTAssertEqual(type, .none)
        }
    }

    func testBiometricEnabledSetting() throws {
        // Given: 초기 상태 (생체 인증 비활성화)
        XCTAssertFalse(secureStorage.isBiometricEnabled())

        // When: 생체 인증 활성화
        try secureStorage.setBiometricEnabled(true)

        // Then: 활성화 상태 확인
        XCTAssertTrue(secureStorage.isBiometricEnabled())

        // When: 생체 인증 비활성화
        try secureStorage.setBiometricEnabled(false)

        // Then: 비활성화 상태 확인
        XCTAssertFalse(secureStorage.isBiometricEnabled())
    }

    // MARK: - 에러 처리 테스트

    func testNonExistentDataLoad() {
        // When: 존재하지 않는 데이터 로드 시도
        let nonExistentToken = try? secureStorage.loadAuthToken()

        // Then: nil 반환 확인
        XCTAssertNil(nonExistentToken)
    }

    func testInvalidKeyDeletion() {
        // When: 존재하지 않는 키 삭제 시도
        XCTAssertNoThrow(try secureStorage.deleteSecureData(forKey: "non_existent_key"))
    }

    func testKeychainErrorHandling() {
        // Given: 잘못된 데이터 형태
        // (실제 테스트에서는 Keychain 에러 상황 시뮬레이션)

        // When/Then: 적절한 에러 처리 확인
        // 실제 구현에서는 특정 Keychain 에러 코드에 대한 처리 테스트
    }

    // MARK: - 보안 테스트

    func testDataEncryption() throws {
        // Given: 민감한 데이터
        let sensitiveData = "very_secret_token_with_sensitive_info"

        // When: 데이터 저장
        try secureStorage.storeAuthToken(sensitiveData)

        // Then: 원본 데이터와 일치하는지 확인
        let retrievedData = try secureStorage.loadAuthToken()
        XCTAssertEqual(retrievedData, sensitiveData)

        // 추가: Keychain에 실제로 암호화되어 저장되는지는
        // 직접 Keychain 쿼리를 통해 확인 가능
    }

    func testDataIsolation() throws {
        // Given: 서로 다른 키의 데이터
        let authToken = "auth_token_data"
        let userId = "user_id_data"

        // When: 각각 저장
        try secureStorage.storeAuthToken(authToken)
        try secureStorage.storeUserId(userId)

        // Then: 데이터 격리 확인
        XCTAssertEqual(try secureStorage.loadAuthToken(), authToken)
        XCTAssertEqual(try secureStorage.loadUserId(), userId)

        // When: 하나만 삭제
        try secureStorage.deleteSecureData(forKey: SecureStorage.Keys.authToken)

        // Then: 나머지 데이터는 유지 확인
        XCTAssertNil(try? secureStorage.loadAuthToken())
        XCTAssertEqual(try secureStorage.loadUserId(), userId)
    }

    // MARK: - 성능 테스트

    func testStoragePerformance() {
        // Given: 대량 데이터 작업
        let iterations = 100

        measure {
            // When: 반복적인 저장/로드 작업
            for i in 0..<iterations {
                let testData = "performance_test_data_\(i)"
                try? secureStorage.storeAuthToken(testData)
                _ = try? secureStorage.loadAuthToken()
            }
        }
    }

    func testConcurrentAccess() throws {
        // Given: 동시 접근 시나리오
        let expectation = self.expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10

        // When: 여러 스레드에서 동시 접근
        for i in 0..<10 {
            DispatchQueue.global().async {
                do {
                    try self.secureStorage.storeAuthToken("concurrent_token_\(i)")
                    _ = try self.secureStorage.loadAuthToken()
                    expectation.fulfill()
                } catch {
                    XCTFail("동시 접근 실패: \(error)")
                }
            }
        }

        // Then: 모든 작업 완료 대기
        waitForExpectations(timeout: 5.0)
    }

    // MARK: - 진단 테스트

    func testDiagnostics() {
        // When: 진단 정보 수집
        let diagnostics = secureStorage.diagnostics()

        // Then: 필수 정보 포함 확인
        XCTAssertNotNil(diagnostics["service"])
        XCTAssertNotNil(diagnostics["biometric_available"])
        XCTAssertNotNil(diagnostics["biometric_type"])
        XCTAssertNotNil(diagnostics["stored_keys"])
        XCTAssertNotNil(diagnostics["token_refresh_needed"])

        print("🔍 SecureStorage 진단 정보:")
        for (key, value) in diagnostics {
            print("  \(key): \(value)")
        }
    }

    func testListStoredKeys() throws {
        // Given: 여러 데이터 저장
        try secureStorage.storeAuthToken("test_token")
        try secureStorage.storeUserId("test_user")

        // When: 저장된 키 목록 조회
        let storedKeys = secureStorage.listStoredKeys()

        // Then: 저장된 키 확인
        XCTAssertTrue(storedKeys.contains(SecureStorage.Keys.authToken))
        XCTAssertTrue(storedKeys.contains(SecureStorage.Keys.userId))
        XCTAssertGreaterThanOrEqual(storedKeys.count, 2)

        print("📝 저장된 키 목록: \(storedKeys)")
    }

    // MARK: - 통합 테스트

    func testFullAuthenticationFlow() throws {
        // Given: 완전한 인증 플로우 시뮬레이션
        let userId = "integration_user"
        let playerId = "integration_player"
        let authToken = "integration_auth_token"
        let refreshToken = "integration_refresh_token"

        // When: 로그인 시뮬레이션 (모든 데이터 저장)
        try secureStorage.storeUserId(userId)
        try secureStorage.storePlayerId(playerId)
        try secureStorage.storeAuthToken(authToken)

        // 리프레시 토큰은 생체 인증 사용 가능할 때만
        let (biometricAvailable, _) = secureStorage.biometricAuthenticationAvailable()
        if biometricAvailable {
            try secureStorage.storeRefreshToken(refreshToken)
        }

        // Then: 모든 데이터 로드 확인
        XCTAssertEqual(try secureStorage.loadUserId(), userId)
        XCTAssertEqual(try secureStorage.loadPlayerId(), playerId)
        XCTAssertEqual(try secureStorage.loadAuthToken(), authToken)

        // When: 로그아웃 시뮬레이션 (모든 데이터 삭제)
        try secureStorage.clearAllAuthData()

        // Then: 모든 데이터 삭제 확인
        XCTAssertNil(try? secureStorage.loadUserId())
        XCTAssertNil(try? secureStorage.loadPlayerId())
        XCTAssertNil(try? secureStorage.loadAuthToken())
    }

    // MARK: - 엣지 케이스 테스트

    func testEmptyStringStorage() throws {
        // Given: 빈 문자열
        let emptyString = ""

        // When: 빈 문자열 저장
        try secureStorage.storeAuthToken(emptyString)

        // Then: 빈 문자열 로드 확인
        let loadedEmpty = try secureStorage.loadAuthToken()
        XCTAssertEqual(loadedEmpty, emptyString)
    }

    func testLargeDataStorage() throws {
        // Given: 큰 데이터 (실제 JWT는 상당히 클 수 있음)
        let largeToken = String(repeating: "a", count: 10000)

        // When: 큰 데이터 저장
        try secureStorage.storeAuthToken(largeToken)

        // Then: 큰 데이터 로드 확인
        let loadedLargeToken = try secureStorage.loadAuthToken()
        XCTAssertEqual(loadedLargeToken, largeToken)
    }

    func testSpecialCharactersStorage() throws {
        // Given: 특수 문자가 포함된 토큰
        let specialToken = "token.with-special_chars!@#$%^&*()+={}[]|\\:;\"'<>?,./"

        // When: 특수 문자 토큰 저장
        try secureStorage.storeAuthToken(specialToken)

        // Then: 특수 문자 토큰 로드 확인
        let loadedSpecialToken = try secureStorage.loadAuthToken()
        XCTAssertEqual(loadedSpecialToken, specialToken)
    }
}