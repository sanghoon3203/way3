//
//  LoginView.swift
//  way3 - connect:seoul
//
//  조선사이버펑크 로그인 화면 (Pretendard 전면 적용)
//

import SwiftUI
import AVKit
import UIKit

struct LoginView: View {
    @Binding var showLoginView: Bool
    @EnvironmentObject var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var isAutoLoginEnabled = false
    @State private var showPassword = false
    @State private var loginState: LoginState = .idle
    @State private var showRegisterView = false
    @State private var showForgotPasswordView = false
    @State private var errorMessage = ""
    @State private var focusedField: LoginField? = nil

    enum LoginField { case email, password }

    var body: some View {
        ZStack {
            BackgroundVideoLayer()
            BlurOverlayLayer()
            contentLayer
            if loginState == .authenticating { loadingOverlay }
        }
        .navigationBarHidden(true)
        .onAppear { loadAutoLoginPreference() }
    }
}

// MARK: - Content

extension LoginView {
    var contentLayer: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                brandSection
                    .padding(.top, 80)
                    .padding(.bottom, 48)

                formCard
                    .padding(.horizontal, 24)

                bottomLinks
                    .padding(.top, 28)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .fullScreenCover(isPresented: $showRegisterView) {
            RegisterView(isPresented: $showRegisterView)
                .environmentObject(authManager)
        }
        .fullScreenCover(isPresented: $showForgotPasswordView) {
            ForgotPasswordView(isPresented: $showForgotPasswordView)
                .environmentObject(authManager)
        }
    }

    // MARK: - Brand Section
    var brandSection: some View {
        VStack(spacing: 10) {
            Text("접속:서울")
                .font(.chosunTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.joseonCheong, .joseonHwang],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.joseonCheong.opacity(0.6), radius: 12)

            Text("connect:seoul")
                .font(.custom("Pretendard-Light", size: 13))
                .tracking(6)
                .foregroundColor(Color.joseonBaek.opacity(0.45))

            HStack(spacing: 12) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color.joseonCheong.opacity(0.45)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)

                Text("경성 2087")
                    .font(.custom("Pretendard-Medium", size: 11))
                    .tracking(3)
                    .foregroundColor(Color.joseonHwang.opacity(0.7))

                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.joseonCheong.opacity(0.45), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
            }
            .padding(.top, 6)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Form Card
    var formCard: some View {
        VStack(spacing: 0) {
            // 카드 헤더
            HStack {
                Text("로그인")
                    .font(.custom("Pretendard-SemiBold", size: 18))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.joseonCheong)
                        .frame(width: 6, height: 6)
                    Text("보안 연결")
                        .font(.custom("Pretendard-Regular", size: 11))
                        .foregroundColor(.joseonCheong)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)

            Rectangle()
                .fill(Color.joseonBorderDim)
                .frame(height: 1)
                .padding(.horizontal, 24)

            VStack(spacing: 24) {
                // 이메일 필드
                AuthLineTextField(
                    text: $email,
                    placeholder: "이메일 주소",
                    labelEn: "EMAIL",
                    icon: "envelope",
                    keyboardType: .emailAddress,
                    isFocused: focusedField == .email
                )
                .onTapGesture { focusedField = .email }
                .onChange(of: email) { _ in clearLoginError() }

                // 비밀번호 필드
                AuthLineSecureField(
                    text: $password,
                    placeholder: "비밀번호",
                    labelEn: "PASSWORD",
                    showPassword: $showPassword,
                    isFocused: focusedField == .password
                )
                .onTapGesture { focusedField = .password }
                .onChange(of: password) { _ in clearLoginError() }

                // 자동 로그인
                HStack {
                    Button(action: {
                        isAutoLoginEnabled.toggle()
                        saveAutoLoginPreference()
                    }) {
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(
                                        isAutoLoginEnabled
                                            ? Color.joseonCheong
                                            : Color.joseonBaek.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                                    .frame(width: 18, height: 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(isAutoLoginEnabled
                                                  ? Color.joseonCheong.opacity(0.12)
                                                  : .clear)
                                    )

                                if isAutoLoginEnabled {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.joseonCheong)
                                }
                            }

                            Text("자동 로그인")
                                .font(.custom("Pretendard-Regular", size: 13))
                                .foregroundColor(Color.joseonBaek.opacity(0.6))
                        }
                    }
                    Spacer()
                }

                // 에러 메시지
                if !errorMessage.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(errorMessage)
                            .font(.custom("Pretendard-Regular", size: 13))
                    }
                    .foregroundColor(.joseonJeok)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 로그인 버튼
                loginButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.joseonCard.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.joseonCheong.opacity(0.4),
                                    Color.joseonBorderDim,
                                    Color.joseonHwang.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Login Button
    var loginButton: some View {
        Button(action: { Task { await performLogin() } }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isLoginButtonActive
                            ? LinearGradient(
                                colors: [.joseonHwang, .cyberpunkGold],
                                startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(
                                colors: [Color.white.opacity(0.07), Color.white.opacity(0.03)],
                                startPoint: .leading, endPoint: .trailing)
                    )

                if loginState == .authenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.85)
                } else {
                    HStack(spacing: 8) {
                        Text("로그인")
                            .font(.custom("Pretendard-SemiBold", size: 16))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(isLoginButtonActive ? .black : Color.joseonBaek.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .disabled(!isLoginButtonActive || loginState == .authenticating)
    }

    // MARK: - Bottom Links
    var bottomLinks: some View {
        VStack(spacing: 16) {
            Button(action: { showRegisterView = true }) {
                HStack(spacing: 6) {
                    Text("계정이 없으신가요?")
                        .font(.custom("Pretendard-Regular", size: 14))
                        .foregroundColor(Color.joseonBaek.opacity(0.5))
                    Text("회원가입")
                        .font(.custom("Pretendard-SemiBold", size: 14))
                        .foregroundColor(.joseonCheong)
                }
            }

            Button(action: { showForgotPasswordView = true }) {
                Text("비밀번호를 잊으셨나요?")
                    .font(.custom("Pretendard-Regular", size: 13))
                    .foregroundColor(Color.joseonBaek.opacity(0.35))
                    .underline()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Loading Overlay
    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .joseonCheong))
                    .scaleEffect(1.4)
                Text("로그인 중...")
                    .font(.custom("Pretendard-Medium", size: 15))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.joseonPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.joseonBorderGlow, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - State & Logic

extension LoginView {
    enum LoginState: Equatable {
        case idle, validating, authenticating, success
        case failed(String)
    }

    private var isLoginButtonActive: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty && loginState != .authenticating
    }

    private func performLogin() async {
        loginState = .authenticating
        errorMessage = ""
        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        await authManager.login(email: sanitizedEmail, password: password)

        await MainActor.run {
            if authManager.isAuthenticated {
                loginState = .success
                if isAutoLoginEnabled {
                    UserDefaults.standard.set(true, forKey: "autoLogin")
                    UserDefaults.standard.set(sanitizedEmail, forKey: "savedEmail")
                } else {
                    UserDefaults.standard.removeObject(forKey: "savedEmail")
                }
                showLoginView = false
            } else {
                let msg = authManager.errorMessage.isEmpty
                    ? "이메일 또는 비밀번호가 올바르지 않습니다."
                    : authManager.errorMessage
                errorMessage = msg
                loginState = .failed(msg)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    Task { @MainActor in
                        if case .failed = loginState { loginState = .idle }
                    }
                }
            }
        }
    }

    private func loadAutoLoginPreference() {
        isAutoLoginEnabled = UserDefaults.standard.bool(forKey: "autoLogin")
        if isAutoLoginEnabled {
            email = UserDefaults.standard.string(forKey: "savedEmail")
                ?? UserDefaults.standard.string(forKey: "savedUsername")
                ?? ""
        }
    }

    private func saveAutoLoginPreference() {
        UserDefaults.standard.set(isAutoLoginEnabled, forKey: "autoLogin")
        if isAutoLoginEnabled {
            UserDefaults.standard.set(
                email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                forKey: "savedEmail"
            )
        } else {
            UserDefaults.standard.removeObject(forKey: "savedEmail")
            UserDefaults.standard.removeObject(forKey: "savedUsername")
        }
    }

    private func clearLoginError() {
        if case .failed = loginState { loginState = .idle }
        errorMessage = ""
    }
}

// MARK: - 공유 필드 컴포넌트

/// 라인 스타일 텍스트 필드 (Auth 전용)
struct AuthLineTextField: View {
    @Binding var text: String
    let placeholder: String
    let labelEn: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isFocused: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(labelEn)
                .font(.custom("Pretendard-Medium", size: 10))
                .tracking(2.5)
                .foregroundColor(isFocused ? .joseonCheong : Color.joseonBaek.opacity(0.4))

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isFocused ? .joseonCheong : Color.joseonBaek.opacity(0.4))
                    .frame(width: 20)

                TextField(placeholder, text: $text)
                    .font(.custom("Pretendard-Regular", size: 15))
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(keyboardType)
                    .accentColor(.joseonCheong)
            }
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isFocused ? Color.joseonCheong : Color.joseonBaek.opacity(0.2))
                    .frame(height: isFocused ? 1.5 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
    }
}

/// 라인 스타일 보안 필드 (Auth 전용)
struct AuthLineSecureField: View {
    @Binding var text: String
    let placeholder: String
    let labelEn: String
    @Binding var showPassword: Bool
    var isFocused: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(labelEn)
                .font(.custom("Pretendard-Medium", size: 10))
                .tracking(2.5)
                .foregroundColor(isFocused ? .joseonCheong : Color.joseonBaek.opacity(0.4))

            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .font(.system(size: 14))
                    .foregroundColor(isFocused ? .joseonCheong : Color.joseonBaek.opacity(0.4))
                    .frame(width: 20)

                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.custom("Pretendard-Regular", size: 15))
                .foregroundColor(.white)
                .accentColor(.joseonCheong)

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(Color.joseonBaek.opacity(0.4))
                }
            }
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isFocused ? Color.joseonCheong : Color.joseonBaek.opacity(0.2))
                    .frame(height: isFocused ? 1.5 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
    }
}

// MARK: - Blur Overlay

struct BlurOverlayLayer: View {
    var body: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .opacity(0.35)
            Color.black.opacity(0.25)
        }
        .ignoresSafeArea()
    }
}

struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: effect) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = effect }
}

// MARK: - Preview

#Preview {
    LoginView(showLoginView: .constant(true))
        .environmentObject(AuthManager.shared)
}
