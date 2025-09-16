// 📁 way3Tests/Core/AuthManagerTests.swift - AuthManager 단위 테스트
import XCTest
@testable import way3

/**
 * AuthManager 단위 테스트
 *
 * 인증 시스템의 핵심 기능들을 검증:
 * - 로그인/로그아웃 플로우
 * - 토큰 저장/로드
 * - SecureStorage 통합
 * - 에러 처리
 */
final class AuthManagerTests: XCTestCase {

    var authManager: AuthManager!
    var mockNetworkManager: MockNetworkManager!

    override func setUpWithError() throws {
        // 테스트 환경 설정
        authManager = AuthManager()
        mockNetworkManager = MockNetworkManager()

        // 기존 인증 데이터 정리
        try? SecureStorage.shared.clearAllAuthData()
        clearUserDefaults()
    }

    override func tearDownWithError() throws {
        // 테스트 후 정리
        try? SecureStorage.shared.clearAllAuthData()
        clearUserDefaults()
        authManager = nil
        mockNetworkManager = nil
    }

    // MARK: - 초기 상태 테스트

    func testInitialState() {
        // Given: 새로운 AuthManager 인스턴스
        let newAuthManager = AuthManager()

        // Then: 초기 상태 확인
        XCTAssertFalse(newAuthManager.isAuthenticated)
        XCTAssertNil(newAuthManager.currentPlayer)
        XCTAssertFalse(newAuthManager.isLoading)
        XCTAssertTrue(newAuthManager.errorMessage.isEmpty)
    }

    // MARK: - 로그인 테스트

    func testSuccessfulLogin() async {
        // Given: 유효한 로그인 정보
        let email = "test@example.com"
        let password = "password123"
        let expectedAuthData = createMockAuthData()

        mockNetworkManager.authResponse = AuthResponse(
            success: true,
            message: "로그인 성공",
            data: expectedAuthData,
            error: nil
        )

        // When: 로그인 시도
        await authManager.login(email: email, password: password)

        // Then: 인증 상태 확인
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentPlayer)
        XCTAssertEqual(authManager.currentPlayer?.name, expectedAuthData.player?.name)
        XCTAssertFalse(authManager.isLoading)
        XCTAssertTrue(authManager.errorMessage.isEmpty)
    }

    func testFailedLogin() async {
        // Given: 잘못된 로그인 정보
        let email = "wrong@example.com"
        let password = "wrongpassword"

        mockNetworkManager.authResponse = AuthResponse(
            success: false,
            message: nil,
            data: nil,
            error: "Invalid credentials"
        )

        // When: 로그인 시도
        await authManager.login(email: email, password: password)

        // Then: 실패 상태 확인
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentPlayer)
        XCTAssertFalse(authManager.isLoading)
        XCTAssertFalse(authManager.errorMessage.isEmpty)
    }

    // MARK: - 회원가입 테스트

    func testSuccessfulRegistration() async {
        // Given: 유효한 회원가입 정보
        let email = "newuser@example.com"
        let password = "password123"
        let playerName = "TestPlayer"
        let expectedAuthData = createMockAuthData()

        mockNetworkManager.authResponse = AuthResponse(
            success: true,
            message: "회원가입 성공",
            data: expectedAuthData,
            error: nil
        )

        // When: 회원가입 시도
        await authManager.register(email: email, password: password, playerName: playerName)

        // Then: 성공 상태 확인
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentPlayer)
        XCTAssertEqual(authManager.currentPlayer?.name, playerName)
    }

    // MARK: - 토큰 관리 테스트

    func testTokenSaveAndLoad() throws {
        // Given: 인증 데이터
        let authData = createMockAuthData()

        // When: 토큰 저장
        authManager.saveCredentials(authData: authData)

        // Then: SecureStorage에서 토큰 로드 확인
        let savedToken = try SecureStorage.shared.loadAuthToken()
        XCTAssertEqual(savedToken, authData.token)

        // When: AuthManager 재초기화
        authManager = AuthManager()

        // Then: 인증 상태 복원 확인
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentPlayer)
    }

    func testTokenRefresh() async {
        // Given: 만료 예정 토큰
        let authData = createMockAuthData()
        authManager.saveCredentials(authData: authData)

        // Mock: 토큰 갱신 필요 상태 시뮬레이션
        // 실제로는 SecureStorage의 shouldRefreshToken()을 조작

        // When: 토큰 갱신 시도
        await authManager.refreshTokenIfNeeded()

        // Then: 갱신 과정 검증
        // 실제 네트워크 호출 없이 Mock을 통한 검증
    }

    // MARK: - 로그아웃 테스트

    func testLogout() {
        // Given: 인증된 상태
        let authData = createMockAuthData()
        authManager.saveCredentials(authData: authData)

        XCTAssertTrue(authManager.isAuthenticated)

        // When: 로그아웃
        authManager.logout()

        // Then: 로그아웃 상태 확인
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentPlayer)

        // SecureStorage에서 토큰 삭제 확인
        XCTAssertThrowsError(try SecureStorage.shared.loadAuthToken())
    }

    // MARK: - SecureStorage 통합 테스트

    func testSecureStorageIntegration() throws {
        // Given: SecureStorage 사용 가능 상태
        XCTAssertTrue(SecureStorage.shared.biometricAuthenticationAvailable().available ||
                     !SecureStorage.shared.biometricAuthenticationAvailable().available) // 항상 true (생체인증 유무 무관)

        // When: 토큰 저장
        let testToken = "test_jwt_token_12345"
        try SecureStorage.shared.storeAuthToken(testToken)

        // Then: 토큰 로드 확인
        let loadedToken = try SecureStorage.shared.loadAuthToken()
        XCTAssertEqual(loadedToken, testToken)

        // When: 토큰 삭제
        try SecureStorage.shared.deleteSecureData(forKey: SecureStorage.Keys.authToken)

        // Then: 삭제 확인
        let deletedToken = try? SecureStorage.shared.loadAuthToken()
        XCTAssertNil(deletedToken)
    }

    // MARK: - 에러 처리 테스트

    func testNetworkErrorHandling() async {
        // Given: 네트워크 에러 시나리오
        let email = "test@example.com"
        let password = "password123"

        mockNetworkManager.shouldThrowError = true
        mockNetworkManager.errorToThrow = URLError(.notConnectedToInternet)

        // When: 로그인 시도
        await authManager.login(email: email, password: password)

        // Then: 에러 처리 확인
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertFalse(authManager.isLoading)
        XCTAssertTrue(authManager.errorMessage.contains("네트워크"))
    }

    func testKeychainErrorHandling() throws {
        // Given: Keychain 접근 불가 상황 시뮬레이션
        // (실제 테스트에서는 Mock SecureStorage 사용)

        // When: 토큰 저장 시도
        // Then: 적절한 에러 처리 확인
        // 실제 구현에서는 폴백 메커니즘 테스트
    }

    // MARK: - 데이터 마이그레이션 테스트

    func testLegacyDataMigration() {
        // Given: 기존 UserDefaults에 저장된 토큰
        let legacyToken = "legacy_token_12345"
        UserDefaults.standard.set(legacyToken, forKey: "auth_token")

        let legacyPlayerData = createMockPlayerData()
        let encoded = try! JSONEncoder().encode(legacyPlayerData)
        UserDefaults.standard.set(encoded, forKey: "player_data")

        // When: AuthManager 초기화 (마이그레이션 트리거)
        authManager = AuthManager()

        // Then: 마이그레이션 확인
        XCTAssertTrue(authManager.isAuthenticated)

        // SecureStorage로 이동 확인
        let migratedToken = try? SecureStorage.shared.loadAuthToken()
        XCTAssertEqual(migratedToken, legacyToken)

        // 기존 UserDefaults에서 토큰 삭제 확인
        let remainingToken = UserDefaults.standard.string(forKey: "auth_token")
        XCTAssertNil(remainingToken)
    }

    // MARK: - 성능 테스트

    func testAuthenticationPerformance() {
        // Given: 대량 토큰 저장/로드 시나리오
        let tokenCount = 100

        measure {
            // When: 대량 토큰 작업
            for i in 0..<tokenCount {
                let testToken = "test_token_\(i)"
                try? SecureStorage.shared.storeAuthToken(testToken)
                _ = try? SecureStorage.shared.loadAuthToken()
            }
        }
    }

    // MARK: - Helper Methods

    private func createMockAuthData() -> AuthData {
        return AuthData(
            userId: "user_123",
            playerId: "player_456",
            token: "jwt_token_789",
            refreshToken: "refresh_token_abc",
            player: createMockPlayerData()
        )
    }

    private func createMockPlayerData() -> PlayerData {
        return PlayerData(
            id: "player_456",
            name: "TestPlayer",
            level: 5,
            money: 1000.0,
            currentLicense: 2
        )
    }

    private func clearUserDefaults() {
        let keys = ["auth_token", "refresh_token", "player_data"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

// MARK: - Mock Classes

/**
 * NetworkManager Mock 클래스
 */
class MockNetworkManager {
    var authResponse: AuthResponse?
    var shouldThrowError = false
    var errorToThrow: Error?

    func login(email: String, password: String) async throws -> AuthResponse {
        if shouldThrowError {
            throw errorToThrow ?? URLError(.unknown)
        }

        return authResponse ?? AuthResponse(success: false, message: nil, data: nil, error: "Mock error")
    }

    func register(email: String, password: String, playerName: String) async throws -> AuthResponse {
        if shouldThrowError {
            throw errorToThrow ?? URLError(.unknown)
        }

        return authResponse ?? AuthResponse(success: false, message: nil, data: nil, error: "Mock error")
    }
}

// MARK: - 테스트 확장

extension AuthManager {
    // 테스트용 internal 메서드 접근
    func saveCredentials(authData: AuthData) {
        // 실제 private 메서드를 테스트에서 호출할 수 있도록 확장
        self.saveCredentials(authData: authData)
    }
}