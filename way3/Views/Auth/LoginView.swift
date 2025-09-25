//
//  LoginView.swift
//  way3 - Way Trading Game
//
//  네오-서울 테마 로그인 화면
//  배경 영상 + 블러 + 인증 시스템
//

import SwiftUI
import AVKit

struct LoginView: View {
    @Binding var showLoginView: Bool
    @EnvironmentObject var authManager: AuthManager

    // 폼 상태
    @State private var username = ""
    @State private var password = ""
    @State private var isAutoLoginEnabled = false
    @State private var showPassword = false

    // UI 상태
    @State private var loginState: LoginState = .idle
    @State private var showRegisterView = false
    @State private var showForgotPasswordView = false

    var body: some View {
        ZStack {
            // 1. 배경 영상 레이어 (StartView와 동일)
            BackgroundVideoLayer()

            // 2. 블러 오버레이 (얇은 블러)
            BlurOverlayLayer()

            // 3. 컨텐츠 레이어
            ContentLayer()

            // 4. 로딩 오버레이
            if loginState == .authenticating {
                LoadingOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadAutoLoginPreference()
        }
    }
}


// MARK: - Blur Overlay Layer
struct BlurOverlayLayer: View {
    var body: some View {
        ZStack {
            // 얇은 블러 효과
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .opacity(0.3)

            // 추가적인 어두운 오버레이
            Color.black.opacity(0.2)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Content Layer
extension LoginView {
    func ContentLayer() -> some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer(minLength: 60)

                // 로고 컴포넌트
                LogoComponent

                // 로그인 폼
                LoginFormComponent

                // 액션 버튼들
                ActionButtonsComponent

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Logo Component
    var LogoComponent: some View {
        VStack(spacing: 12) {
            Text("네오-서울")
                .font(.chosunOrFallback(size: 32, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .cyan.opacity(0.5), radius: 8, x: 0, y: 0)

            Text("트레이딩 게임")
                .font(.chosunOrFallback(size: 16, weight: .medium))
                .foregroundColor(.cyan)
                .shadow(color: .cyan.opacity(0.3), radius: 5, x: 0, y: 0)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Login Form Component
    var LoginFormComponent: some View {
        VStack(spacing: 20) {
            // 아이디 입력 필드
            IDTextField(
                text: $username,
                placeholder: "아이디",
                icon: "person.fill"
            )

            // 비밀번호 입력 필드
            NeoSeoulSecureField(
                text: $password,
                placeholder: "비밀번호",
                showPassword: $showPassword
            )

            // 자동 로그인 체크박스
            AutoLoginToggle

            // 로그인 버튼
            LoginButton
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Auto Login Toggle
    var AutoLoginToggle: some View {
        HStack {
            Button(action: {
                isAutoLoginEnabled.toggle()
                saveAutoLoginPreference()
            }) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                            .frame(width: 20, height: 20)

                        if isAutoLoginEnabled {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                    }

                    Text("자동 로그인")
                        .font(.chosunOrFallback(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()
        }
    }

    // MARK: - Login Button
    var LoginButton: some View {
        Button(action: {
            Task {
                await performLogin()
            }
        }) {
            HStack {
                if loginState == .authenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                }

                Text(loginButtonText)
                    .font(.chosunOrFallback(size: 16, weight: .semibold))
            }
            .foregroundColor(isLoginButtonActive ? .black : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isLoginButtonActive ? Color.cyan : Color.gray.opacity(0.3))
            )
        }
        .disabled(!isLoginButtonActive || loginState == .authenticating)
        .padding(.top, 10)
    }

    // MARK: - Action Buttons Component
    var ActionButtonsComponent: some View {
        VStack(spacing: 16) {
            // 회원가입 버튼
            Button("회원가입") {
                showRegisterView = true
            }
            .font(.chosunOrFallback(size: 16))
            .foregroundColor(.cyan)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                    .background(Color.clear)
            )

            // 비밀번호 찾기 버튼
            Button("비밀번호 찾기") {
                showForgotPasswordView = true
            }
            .font(.chosunOrFallback(size: 14))
            .foregroundColor(.white.opacity(0.7))
            .underline()
        }
        .padding(.horizontal, 20)
        .fullScreenCover(isPresented: $showRegisterView) {
            RegisterView(isPresented: $showRegisterView)
                .environmentObject(authManager)
        }
        .fullScreenCover(isPresented: $showForgotPasswordView) {
            ForgotPasswordView(isPresented: $showForgotPasswordView)
        }
    }
}

// MARK: - Custom Text Fields
struct IDTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan.opacity(0.7))
                .frame(width: 25)

            TextField(placeholder, text: $text)
                .font(.chosunOrFallback(size: 16))
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct NeoSeoulSecureField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(.cyan.opacity(0.7))
                .frame(width: 25)

            if showPassword {
                TextField(placeholder, text: $text)
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(PlainTextFieldStyle())
            } else {
                SecureField(placeholder, text: $text)
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)
                    .textFieldStyle(PlainTextFieldStyle())
            }

            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Loading Overlay
extension LoginView {
    var LoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                    .scaleEffect(1.5)

                Text("로그인 중...")
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Helper Components
struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

// MARK: - State & Logic
extension LoginView {
    enum LoginState: Equatable {
        case idle
        case validating
        case authenticating
        case success
        case failed(String)
    }

    private var isLoginButtonActive: Bool {
        !username.isEmpty && !password.isEmpty && loginState != .authenticating
    }

    private var loginButtonText: String {
        switch loginState {
        case .idle, .validating:
            return "로그인"
        case .authenticating:
            return "로그인 중..."
        case .success:
            return "성공"
        case .failed:
            return "다시 시도"
        }
    }

    private func performLogin() async {
        loginState = .authenticating

        // TODO: 실제 서버 API 호출
        // 임시로 딜레이 추가
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // 로그인 성공 시
        if username == "test" && password == "test" {
            loginState = .success

            // 자동 로그인 설정 저장
            if isAutoLoginEnabled {
                UserDefaults.standard.set(true, forKey: "autoLogin")
                UserDefaults.standard.set(username, forKey: "savedUsername")
            }

            // LoginView 닫기
            showLoginView = false
        } else {
            loginState = .failed("아이디 또는 비밀번호가 올바르지 않습니다.")

            // 2초 후 상태 초기화
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                loginState = .idle
            }
        }
    }

    private func loadAutoLoginPreference() {
        isAutoLoginEnabled = UserDefaults.standard.bool(forKey: "autoLogin")
        if isAutoLoginEnabled {
            username = UserDefaults.standard.string(forKey: "savedUsername") ?? ""
        }
    }

    private func saveAutoLoginPreference() {
        UserDefaults.standard.set(isAutoLoginEnabled, forKey: "autoLogin")
        if !isAutoLoginEnabled {
            UserDefaults.standard.removeObject(forKey: "savedUsername")
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView(showLoginView: .constant(true))
        .environmentObject(AuthManager.shared)
}
