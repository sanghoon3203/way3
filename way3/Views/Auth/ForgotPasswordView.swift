//
//  ForgotPasswordView.swift
//  way3 - Way Trading Game
//
//  네오-서울 테마 비밀번호 찾기 화면
//  2단계 이메일 인증 + 비밀번호 재설정
//

import SwiftUI
import AVKit

struct ForgotPasswordView: View {
    @Binding var isPresented: Bool

    // 현재 단계
    @State private var currentStep: ForgotPasswordStep = .accountVerification

    // Step 1 데이터
    @State private var username = ""
    @State private var recoveryEmail = ""

    // Step 2 데이터
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    // UI 상태
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var resendCooldown = 0
    @State private var resendCount = 0
    @State private var showSuccessModal = false

    // 유효성 검사
    @State private var passwordValid = false
    @State private var passwordsMatch = false
    @State private var maskedEmail = ""

    var body: some View {
        ZStack {
            // 배경 영상 + 블러 (LoginView와 동일)
            BackgroundVideoLayer()
            BlurOverlayLayer()

            // 컨텐츠
            ContentLayer1

            // 성공 모달
            if showSuccessModal {
                SuccessModal
            }

            // 로딩 오버레이
            if isLoading {
                LoadingOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startCooldownTimer()
        }
    }
}

// MARK: - Content Layer
extension ForgotPasswordView {
    var ContentLayer1: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 헤더
                HeaderComponent

                // 단계별 컨텐츠
                if currentStep == .accountVerification {
                    Step1Component
                } else {
                    Step2Component
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Header Component
    var HeaderComponent: some View {
        VStack(spacing: 20) {
            // 뒤로가기 + 제목
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.title2)

                        Text("로그인")
                            .font(.chosunOrFallback(size: 16))
                    }
                    .foregroundColor(.cyan)
                }

                Spacer()

                Text("비밀번호 찾기")
                    .font(.chosunOrFallback(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Color.clear.frame(width: 80)
            }

            // 진행 상황 표시
            ProgressIndicator
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Progress Indicator
    var ProgressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                Text(currentStep == .accountVerification ? "계정 확인 (1/2)" : "비밀번호 재설정 (2/2)")
                    .font(.chosunOrFallback(size: 14))
                    .foregroundColor(.cyan)

                Spacer()
            }

            // 진행 바
            HStack(spacing: 4) {
                Rectangle()
                    .fill(Color.cyan)
                    .frame(height: 3)

                Rectangle()
                    .fill(currentStep == .passwordReset ? Color.cyan : Color.gray.opacity(0.3))
                    .frame(height: 3)
            }
            .cornerRadius(1.5)
        }
    }

    // MARK: - Step 1 Component (계정 확인)
    var Step1Component: some View {
        VStack(spacing: 25) {
            // 설명
            VStack(spacing: 12) {
                Text("계정 정보를 확인해주세요")
                    .font(.chosunOrFallback(size: 18, weight: .medium))
                    .foregroundColor(.white)

                Text("가입하신 정보를 입력하시면\n인증번호를 전송해드립니다")
                    .font(.chosunOrFallback(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            // 폼
            VStack(spacing: 20) {
                // 아이디 입력
                IDTextField(
                    text: $username,
                    placeholder: "아이디",
                    icon: "person.fill"
                )

                // 복구 이메일 입력
                IDTextField(
                    text: $recoveryEmail,
                    placeholder: "가입 시 등록한 복구 이메일",
                    icon: "envelope.fill"
                )

                // 에러 메시지
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.chosunOrFallback(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                // 인증번호 전송 버튼
                SendCodeButton
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
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Send Code Button
    var SendCodeButton: some View {
        Button(action: {
            Task {
                await sendVerificationCode()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                }

                Text(isLoading ? "전송 중..." : "인증번호 전송")
                    .font(.chosunOrFallback(size: 16, weight: .semibold))
            }
            .foregroundColor(isStep1Valid ? .black : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isStep1Valid ? Color.cyan : Color.gray.opacity(0.3))
            )
        }
        .disabled(!isStep1Valid || isLoading)
    }

    // MARK: - Step 2 Component (비밀번호 재설정)
    var Step2Component: some View {
        VStack(spacing: 25) {
            // 설명
            VStack(spacing: 12) {
                Text("이메일로 전송된 인증번호를 입력하고\n새 비밀번호를 설정해주세요")
                    .font(.chosunOrFallback(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("인증번호가 \(maskedEmail)으로 전송되었습니다")
                    .font(.chosunOrFallback(size: 14))
                    .foregroundColor(.cyan)
                    .multilineTextAlignment(.center)
            }

            // 폼
            VStack(spacing: 20) {
                // 인증번호 입력
                VerificationCodeField

                // 새 비밀번호 입력
                NewPasswordField

                // 비밀번호 확인
                ConfirmPasswordField

                // 에러 메시지
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.chosunOrFallback(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                // 비밀번호 변경 버튼
                ResetPasswordButton
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

            // 재전송 버튼
            ResendCodeButton
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Verification Code Field
    var VerificationCodeField: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 12) {
                Image(systemName: "number.circle.fill")
                    .font(.title2)
                    .foregroundColor(.cyan.opacity(0.7))
                    .frame(width: 25)

                TextField("인증번호 6자리", text: $verificationCode)
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)
                    .keyboardType(.numberPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: verificationCode) { newValue in
                        // 6자리 숫자만 허용
                        let filtered = String(newValue.prefix(6).filter { $0.isNumber })
                        if filtered != newValue {
                            verificationCode = filtered
                        }
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

    // MARK: - New Password Field
    var NewPasswordField: some View {
        VStack(alignment: .leading, spacing: 5) {
            NeoSeoulSecureField(
                text: $newPassword,
                placeholder: "새 비밀번호",
                showPassword: $showPassword
            )
            .onChange(of: newPassword) { _ in
                validateNewPassword()
                validatePasswordMatch()
            }

            if !newPassword.isEmpty && !passwordValid {
                Text("비밀번호는 8자 이상, 영문+숫자+특수문자 조합이어야 합니다")
                    .font(.chosunOrFallback(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 16)
            }
        }
    }

    // MARK: - Confirm Password Field
    var ConfirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 5) {
            NeoSeoulSecureField(
                text: $confirmPassword,
                placeholder: "새 비밀번호 확인",
                showPassword: $showConfirmPassword
            )
            .onChange(of: confirmPassword) { _ in
                validatePasswordMatch()
            }

            if !confirmPassword.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(passwordsMatch ? .green : .red)

                    Text(passwordsMatch ? "비밀번호가 일치합니다" : "비밀번호가 일치하지 않습니다")
                        .font(.chosunOrFallback(size: 12))
                        .foregroundColor(passwordsMatch ? .green : .red)
                }
                .padding(.leading, 16)
            }
        }
    }

    // MARK: - Reset Password Button
    var ResetPasswordButton: some View {
        Button(action: {
            Task {
                await resetPassword()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "key.fill")
                        .font(.title2)
                }

                Text(isLoading ? "변경 중..." : "비밀번호 변경")
                    .font(.chosunOrFallback(size: 16, weight: .semibold))
            }
            .foregroundColor(isStep2Valid ? .black : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isStep2Valid ? Color.cyan : Color.gray.opacity(0.3))
            )
        }
        .disabled(!isStep2Valid || isLoading)
    }

    // MARK: - Resend Code Button
    var ResendCodeButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                Task {
                    await resendVerificationCode()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)

                    if resendCooldown > 0 {
                        Text("재전송 (\(resendCooldown)초 후 가능)")
                            .font(.chosunOrFallback(size: 14))
                    } else {
                        Text("인증번호 재전송")
                            .font(.chosunOrFallback(size: 14))
                    }
                }
                .foregroundColor(canResend ? .cyan : .gray)
                .underline()
            }
            .disabled(!canResend || isLoading)

            if resendCount > 0 {
                Text("재전송 \(resendCount)/3")
                    .font(.chosunOrFallback(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Validation & Logic
extension ForgotPasswordView {
    enum ForgotPasswordStep {
        case accountVerification
        case passwordReset
    }

    private var isStep1Valid: Bool {
        !username.isEmpty && !recoveryEmail.isEmpty && recoveryEmail.contains("@")
    }

    private var isStep2Valid: Bool {
        verificationCode.count == 6 && passwordValid && passwordsMatch
    }

    private var canResend: Bool {
        resendCooldown == 0 && resendCount < 3
    }

    private func validateNewPassword() {
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$"
        passwordValid = NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: newPassword)
    }

    private func validatePasswordMatch() {
        passwordsMatch = !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword == confirmPassword
    }

    private func sendVerificationCode() async {
        isLoading = true
        errorMessage = ""

        // TODO: 실제 서버 API 호출
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // 임시 성공 처리
        isLoading = false
        currentStep = .passwordReset
        maskedEmail = maskEmail(recoveryEmail)
        resendCooldown = 30
        resendCount = 1
    }

    private func resendVerificationCode() async {
        if !canResend { return }

        isLoading = true
        errorMessage = ""

        // TODO: 실제 서버 API 호출
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        isLoading = false
        resendCount += 1
        resendCooldown = 30
    }

    private func resetPassword() async {
        isLoading = true
        errorMessage = ""

        // TODO: 실제 서버 API 호출
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // 임시 성공 처리
        isLoading = false
        showSuccessModal = true
    }

    private func maskEmail(_ email: String) -> String {
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else { return email }

        let username = components[0]
        let domain = components[1]

        let maskedUsername = username.count > 2 ?
            String(username.prefix(2)) + String(repeating: "*", count: username.count - 2) :
            String(repeating: "*", count: username.count)

        return "\(maskedUsername)@\(domain)"
    }

    private func startCooldownTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Modals & Overlays
extension ForgotPasswordView {
    var SuccessModal: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("비밀번호가 성공적으로 변경되었습니다")
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Button("로그인하러 가기") {
                    showSuccessModal = false
                    isPresented = false
                }
                .font(.chosunOrFallback(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 160, height: 45)
                .background(
                    RoundedRectangle(cornerRadius: 22.5)
                        .fill(Color.cyan)
                )
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
        }
    }

    var LoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                    .scaleEffect(1.5)

                Text(currentStep == .accountVerification ? "계정 확인 중..." : "비밀번호 변경 중...")
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

#Preview {
    ForgotPasswordView(isPresented: .constant(true))
}
