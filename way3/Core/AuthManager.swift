//
//  AuthManager.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  인증 관리자 - JWT 토큰 기반 인증 시스템
//

import Foundation
import SwiftUI
import Combine

// MARK: - 인증 관련 모델
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let playerName: String
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String?
    let data: AuthData?
    let error: String?
}

struct AuthData: Codable {
    let userId: String
    let playerId: String
    let token: String
    let refreshToken: String
    let player: PlayerData?
}

struct PlayerData: Codable {
    let id: String
    let name: String
    let level: Int
    let money: Double
    let currentLicense: Int
}

struct PasswordResetData: Codable {
    let maskedEmail: String?
    let expiresIn: Int?
    let verificationCode: String?
}

struct PasswordResetResponse: Codable {
    let success: Bool
    let message: String?
    let data: PasswordResetData?
    let error: String?
    let details: [ValidationErrorDetail]?
}

struct ValidationErrorDetail: Codable {
    let msg: String?
    let param: String?
}

private struct PasswordResetRequestBody: Codable {
    let email: String
}

private struct PasswordResetVerifyBody: Codable {
    let email: String
    let verificationCode: String
    let newPassword: String
}

// MARK: - 인증 매니저
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentPlayer: PlayerData?
    @Published var isLoading = false
    @Published var errorMessage = ""

    private var authToken: String?
    private var refreshToken: String?

    // Socket.IO 호환성을 위한 currentToken 프로퍼티
    var currentToken: String? {
        return authToken
    }
    private let baseURL = "\(NetworkConfiguration.baseURL)/api/auth"
    
    // UserDefaults 키
    private enum Keys {
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let playerData = "player_data"
    }
    
    init() {
        loadStoredCredentials()
    }
    
    // MARK: - 저장된 인증 정보 로드 (SecureStorage 사용)
    func loadStoredCredentials() {
        do {
            // SecureStorage에서 토큰 로드
            let token = try SecureStorage.shared.loadAuthToken()
            let userId = try SecureStorage.shared.loadUserId()
            let playerId = try SecureStorage.shared.loadPlayerId()

            // UserDefaults에서 플레이어 데이터 로드 (민감하지 않은 정보)
            if let token = token,
               let playerData = UserDefaults.standard.data(forKey: Keys.playerData) {

                self.authToken = token
                NetworkManager.shared.applyAuthTokens(accessToken: token, refreshToken: nil)

                do {
                    self.currentPlayer = try JSONDecoder().decode(PlayerData.self, from: playerData)
                    self.isAuthenticated = true

                    GameLogger.shared.logInfo("SecureStorage에서 인증 정보 복원됨", category: .authentication)
                } catch {
                    GameLogger.shared.logError("플레이어 데이터 로드 실패: \(error.localizedDescription)", category: .authentication)
                    clearStoredCredentials()
                }
            }
        } catch {
            GameLogger.shared.logError("SecureStorage 로드 실패: \(error.localizedDescription)", category: .authentication)
            // 기존 UserDefaults 방식으로 폴백
            loadLegacyCredentials()
        }
    }

    // 기존 UserDefaults 방식 (폴백용)
    private func loadLegacyCredentials() {
        if let token = UserDefaults.standard.string(forKey: Keys.authToken),
           let playerData = UserDefaults.standard.data(forKey: Keys.playerData) {

            self.authToken = token
            NetworkManager.shared.applyAuthTokens(accessToken: token, refreshToken: nil)

            do {
                self.currentPlayer = try JSONDecoder().decode(PlayerData.self, from: playerData)
                self.isAuthenticated = true

                // 기존 데이터를 SecureStorage로 마이그레이션
                migrateToSecureStorage()

            } catch {
                GameLogger.shared.logError("레거시 플레이어 데이터 로드 실패: \(error.localizedDescription)", category: .authentication)
                clearStoredCredentials()
            }
        }
    }
    
    // MARK: - 인증 정보 저장 (SecureStorage 사용)
    private func saveCredentials(authData: AuthData) {
        do {
            // SecureStorage에 보안 정보 저장
            try SecureStorage.shared.storeAuthToken(authData.token)
            try SecureStorage.shared.storeRefreshToken(authData.refreshToken)
            try SecureStorage.shared.storeUserId(authData.userId)
            try SecureStorage.shared.storePlayerId(authData.playerId)

            // UserDefaults에 민감하지 않은 플레이어 데이터 저장
            if let playerData = authData.player {
                do {
                    let encoded = try JSONEncoder().encode(playerData)
                    UserDefaults.standard.set(encoded, forKey: Keys.playerData)
                } catch {
                    GameLogger.shared.logError("플레이어 데이터 저장 실패: \(error.localizedDescription)", category: .authentication)
                }
            }

            self.authToken = authData.token
            self.refreshToken = authData.refreshToken
            self.currentPlayer = authData.player
            NetworkManager.shared.applyAuthTokens(accessToken: authData.token, refreshToken: authData.refreshToken)

            GameLogger.shared.logInfo("인증 정보가 SecureStorage에 저장됨", category: .authentication)

        } catch {
            GameLogger.shared.logError("SecureStorage 저장 실패: \(error.localizedDescription)", category: .authentication)
            // 폴백: UserDefaults 사용
            saveLegacyCredentials(authData: authData)
        }
    }

    // 기존 UserDefaults 방식 (폴백용)
    private func saveLegacyCredentials(authData: AuthData) {
        UserDefaults.standard.set(authData.token, forKey: Keys.authToken)
        UserDefaults.standard.set(authData.refreshToken, forKey: Keys.refreshToken)

        if let playerData = authData.player {
            do {
                let encoded = try JSONEncoder().encode(playerData)
                UserDefaults.standard.set(encoded, forKey: Keys.playerData)
            } catch {
                GameLogger.shared.logError("레거시 플레이어 데이터 저장 실패: \(error.localizedDescription)", category: .authentication)
            }
        }

        self.authToken = authData.token
        self.refreshToken = authData.refreshToken
        self.currentPlayer = authData.player
        NetworkManager.shared.applyAuthTokens(accessToken: authData.token, refreshToken: authData.refreshToken)

        GameLogger.shared.logInfo("레거시 방식으로 인증 정보 저장됨", category: .authentication)
    }
    
    // MARK: - 인증 정보 삭제 (SecureStorage 사용)
    private func clearStoredCredentials() {
        do {
            // SecureStorage에서 모든 인증 정보 삭제
            try SecureStorage.shared.clearAllAuthData()
        } catch {
            GameLogger.shared.logError("SecureStorage 삭제 실패: \(error.localizedDescription)", category: .authentication)
        }

        // UserDefaults에서 플레이어 데이터 삭제
        UserDefaults.standard.removeObject(forKey: Keys.authToken)
        UserDefaults.standard.removeObject(forKey: Keys.refreshToken)
        UserDefaults.standard.removeObject(forKey: Keys.playerData)

        self.authToken = nil
        self.refreshToken = nil
        self.currentPlayer = nil
        self.isAuthenticated = false
        NetworkManager.shared.applyAuthTokens(accessToken: nil, refreshToken: nil)
        NetworkManager.shared.applyAuthTokens(accessToken: nil, refreshToken: nil)

        GameLogger.shared.logInfo("모든 인증 정보 삭제됨", category: .authentication)
    }

    // MARK: - 데이터 마이그레이션

    /**
     * 기존 UserDefaults 데이터를 SecureStorage로 마이그레이션
     */
    private func migrateToSecureStorage() {
        guard let token = authToken else { return }

        do {
            // 현재 토큰을 SecureStorage에 저장
            try SecureStorage.shared.storeAuthToken(token)

            // 리프레시 토큰이 있으면 저장
            if let refreshToken = UserDefaults.standard.string(forKey: Keys.refreshToken) {
                try SecureStorage.shared.storeRefreshToken(refreshToken)
            }

            // 기존 UserDefaults의 토큰 정보 삭제
            UserDefaults.standard.removeObject(forKey: Keys.authToken)
            UserDefaults.standard.removeObject(forKey: Keys.refreshToken)

            GameLogger.shared.logInfo("SecureStorage로 마이그레이션 완료", category: .authentication)

        } catch {
            GameLogger.shared.logError("SecureStorage 마이그레이션 실패: \(error.localizedDescription)", category: .authentication)
        }
    }

    /**
     * 토큰 자동 갱신 (SecureStorage 사용)
     */
    func refreshTokenIfNeeded() async {
        do {
            let refreshed = try await SecureStorage.shared.refreshTokenIfNeeded()
            if refreshed {
                GameLogger.shared.logInfo("토큰 자동 갱신 완료", category: .authentication)
                // 갱신된 토큰으로 플레이어 데이터 다시 로드
                await refreshPlayerData()
            }
        } catch {
            GameLogger.shared.logError("토큰 자동 갱신 실패: \(error.localizedDescription)", category: .authentication)
            // 갱신 실패 시 로그아웃
            await logout()
        }
    }

    /**
     * 플레이어 데이터 새로고침
     */
    private func refreshPlayerData() async {
        // NetworkManager를 통해 최신 플레이어 데이터 로드
        // 실제 구현에서는 NetworkManager.shared.getPlayerData() 호출
    }
    
    // MARK: - 로그인
    func login(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let request = LoginRequest(email: email, password: password)
            let response: AuthResponse = try await performRequest(
                endpoint: "/login",
                method: "POST",
                body: request
            )
            
            await MainActor.run {
                if response.success, let authData = response.data {
                    saveCredentials(authData: authData)
                    isAuthenticated = true
                } else {
                    errorMessage = response.error ?? "로그인에 실패했습니다"
                }
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "네트워크 오류: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - 회원가입
    func register(email: String, password: String, playerName: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let request = RegisterRequest(email: email, password: password, playerName: playerName)
            let response: AuthResponse = try await performRequest(
                endpoint: "/register",
                method: "POST",
                body: request
            )
            
            await MainActor.run {
                if response.success, let authData = response.data {
                    saveCredentials(authData: authData)
                    isAuthenticated = true
                } else {
                    errorMessage = response.error ?? "회원가입에 실패했습니다"
                }
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "네트워크 오류: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - 비밀번호 재설정
    func requestPasswordReset(email: String) async throws -> PasswordResetResponse {
        let request = PasswordResetRequestBody(email: email)
        return try await performRequest(
            endpoint: "/password/reset/request",
            method: "POST",
            body: request
        )
    }
    
    func verifyPasswordReset(email: String, code: String, newPassword: String) async throws -> PasswordResetResponse {
        let request = PasswordResetVerifyBody(email: email, verificationCode: code, newPassword: newPassword)
        return try await performRequest(
            endpoint: "/password/reset/verify",
            method: "POST",
            body: request
        )
    }
    
    // MARK: - 로그아웃
    func logout() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let _: AuthResponse = try await performRequest(
                endpoint: "/logout",
                method: "POST",
                body: EmptyBody()
            )
        } catch {
            GameLogger.shared.logError("로그아웃 API 호출 실패: \(error.localizedDescription)", category: .authentication)
        }
        
        await MainActor.run {
            clearStoredCredentials()
            isLoading = false
        }
    }
    
    // MARK: - 토큰 갱신
    func refreshAuthToken() async -> Bool {
        guard let refreshToken = refreshToken else { return false }
        
        do {
            let request = ["refreshToken": refreshToken]
            let response: AuthResponse = try await performRequest(
                endpoint: "/refresh",
                method: "POST",
                body: request
            )
            
            if response.success, let newToken = response.data?.token {
                self.authToken = newToken
                UserDefaults.standard.set(newToken, forKey: Keys.authToken)
                return true
            }
            
        } catch {
            GameLogger.shared.logError("토큰 갱신 실패: \(error.localizedDescription)", category: .authentication)
        }
        
        // 토큰 갱신 실패시 로그아웃
        await logout()
        return false
    }
    
    // MARK: - 인증 헤더 가져오기
    func getAuthHeaders() -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
    
    // MARK: - 저장된 토큰 확인
    func hasStoredToken() -> Bool {
        return UserDefaults.standard.string(forKey: Keys.authToken) != nil
    }
}

// MARK: - 네트워크 요청 헬퍼
extension AuthManager {
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: String,
        body: T
    ) async throws -> U {
        guard let url = URL(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = getAuthHeaders()
        
        if !(body is EmptyBody) {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // 401 오류시 토큰 갱신 시도
        if httpResponse.statusCode == 401 && endpoint != "/refresh" {
            if await refreshAuthToken() {
                // 토큰 갱신 성공시 재시도
                request.allHTTPHeaderFields = getAuthHeaders()
                let (retryData, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode(U.self, from: retryData)
            } else {
                throw URLError(.userAuthenticationRequired)
            }
        }
        
        return try JSONDecoder().decode(U.self, from: data)
    }
}

// 빈 바디를 위한 구조체
private struct EmptyBody: Codable {}
