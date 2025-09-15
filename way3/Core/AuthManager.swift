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

// MARK: - 인증 매니저
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentPlayer: PlayerData?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var authToken: String?
    private var refreshToken: String?
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
    
    // MARK: - 저장된 인증 정보 로드
    func loadStoredCredentials() {
        if let token = UserDefaults.standard.string(forKey: Keys.authToken),
           let refresh = UserDefaults.standard.string(forKey: Keys.refreshToken),
           let playerData = UserDefaults.standard.data(forKey: Keys.playerData) {
            
            self.authToken = token
            self.refreshToken = refresh
            
            do {
                self.currentPlayer = try JSONDecoder().decode(PlayerData.self, from: playerData)
                self.isAuthenticated = true
            } catch {
                print("플레이어 데이터 로드 실패: \(error)")
                clearStoredCredentials()
            }
        }
    }
    
    // MARK: - 인증 정보 저장
    private func saveCredentials(authData: AuthData) {
        UserDefaults.standard.set(authData.token, forKey: Keys.authToken)
        UserDefaults.standard.set(authData.refreshToken, forKey: Keys.refreshToken)
        
        if let playerData = authData.player {
            do {
                let encoded = try JSONEncoder().encode(playerData)
                UserDefaults.standard.set(encoded, forKey: Keys.playerData)
            } catch {
                print("플레이어 데이터 저장 실패: \(error)")
            }
        }
        
        self.authToken = authData.token
        self.refreshToken = authData.refreshToken
        self.currentPlayer = authData.player
    }
    
    // MARK: - 인증 정보 삭제
    private func clearStoredCredentials() {
        UserDefaults.standard.removeObject(forKey: Keys.authToken)
        UserDefaults.standard.removeObject(forKey: Keys.refreshToken)
        UserDefaults.standard.removeObject(forKey: Keys.playerData)
        
        self.authToken = nil
        self.refreshToken = nil
        self.currentPlayer = nil
        self.isAuthenticated = false
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
            print("로그아웃 API 호출 실패: \(error)")
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
            print("토큰 갱신 실패: \(error)")
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