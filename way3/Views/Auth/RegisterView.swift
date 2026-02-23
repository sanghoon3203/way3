//
//  RegisterView.swift
//  way3 - connect:seoul
//
//  조선사이버펑크 회원가입 화면 (Pretendard 전면 적용)
//

import SwiftUI
import AVKit

struct RegisterView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var authManager: AuthManager

    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var email = ""
    @State private var termsAccepted = false

    @State private var nameValid = false
    @State private var usernameValid = false
    @State private var usernameAvailable: Bool? = nil
    @State private var passwordValid = false
    @State private var passwordsMatch = false
    @State private var emailValid = false

    @State private var showPassword = false
    @State private var showPasswordConfirm = false
    @State private var isCheckingUsername = false
    @State private var showTermsModal = false
    @State private var showSuccessModal = false
    @State private var isRegistering = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            BackgroundVideoLayer()
            BlurOverlayLayer()
            contentLayer
            if showSuccessModal { successModal }
            if isRegistering { loadingOverlay }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTermsModal) { termsSheet }
    }
}

// MARK: - Content

extension RegisterView {
    var contentLayer: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 56)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                formCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Header
    var headerBar: some View {
        HStack(alignment: .center) {
            Button(action: { isPresented = false }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("로그인")
                        .font(.custom("Pretendard-Medium", size: 14))
                }
                .foregroundColor(.joseonCheong)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("회원가입")
                    .font(.custom("Pretendard-SemiBold", size: 18))
                    .foregroundColor(.white)
                Text("NEW ACCOUNT")
                    .font(.custom("Pretendard-Light", size: 10))
                    .tracking(3)
                    .foregroundColor(Color.joseonBaek.opacity(0.4))
            }

            Spacer()

            // 스텝 인디케이터
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i == 0 ? Color.joseonHwang : Color.joseonBaek.opacity(0.2))
                        .frame(width: i == 0 ? 20 : 6, height: 6)
                }
            }
        }
    }

    // MARK: - Form Card
    var formCard: some View {
        VStack(spacing: 26) {
            // 이름
            regField(
                text: $name,
                labelEn: "NAME",
                placeholder: "이름",
                icon: "person",
                isValid: name.isEmpty ? nil : nameValid,
                errorText: "2~20자 한글 또는 영문"
            )
            .onChange(of: name) { _ in validateName() }

            // 아이디 (중복 확인 포함)
            usernameRow

            // 비밀번호
            regSecureField(
                text: $password,
                labelEn: "PASSWORD",
                placeholder: "비밀번호",
                showPassword: $showPassword,
                isValid: password.isEmpty ? nil : passwordValid,
                errorText: "8자 이상, 영문+숫자+특수문자"
            )
            .onChange(of: password) { _ in validatePassword(); validatePasswordMatch() }

            // 비밀번호 확인
            regSecureField(
                text: $passwordConfirm,
                labelEn: "CONFIRM",
                placeholder: "비밀번호 확인",
                showPassword: $showPasswordConfirm,
                isValid: passwordConfirm.isEmpty ? nil : passwordsMatch,
                successText: "비밀번호 일치",
                errorText: "비밀번호가 일치하지 않습니다"
            )
            .onChange(of: passwordConfirm) { _ in validatePasswordMatch() }

            // 이메일
            regField(
                text: $email,
                labelEn: "EMAIL",
                placeholder: "이메일",
                icon: "envelope",
                keyboardType: .emailAddress,
                isValid: email.isEmpty ? nil : emailValid,
                errorText: "올바른 이메일 형식을 입력해주세요"
            )
            .onChange(of: email) { _ in validateEmail() }

            // 구분선
            Rectangle()
                .fill(Color.joseonBorderDim)
                .frame(height: 1)

            // 약관 동의
            termsRow

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

            // 가입 버튼
            registerButton
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.joseonCard.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.joseonHwang.opacity(0.3),
                                    Color.joseonBorderDim,
                                    Color.joseonCheong.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Username Row
    var usernameRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACCOUNT ID")
                .font(.custom("Pretendard-Medium", size: 10))
                .tracking(2.5)
                .foregroundColor(Color.joseonBaek.opacity(0.4))

            HStack(spacing: 12) {
                Image(systemName: "at")
                    .font(.system(size: 14))
                    .foregroundColor(Color.joseonBaek.opacity(0.4))
                    .frame(width: 20)

                TextField("아이디", text: $username)
                    .font(.custom("Pretendard-Regular", size: 15))
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accentColor(.joseonCheong)
                    .onChange(of: username) { _ in
                        validateUsername()
                        usernameAvailable = nil
                    }

                // 중복 확인 버튼
                Button(action: {
                    Task { await checkUsernameAvailability() }
                }) {
                    Group {
                        if isCheckingUsername {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .joseonCheong))
                                .scaleEffect(0.7)
                        } else if let avail = usernameAvailable {
                            Image(systemName: avail ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(avail ? .joseonCheong : .joseonJeok)
                        } else {
                            Text("확인")
                                .font(.custom("Pretendard-Medium", size: 12))
                                .foregroundColor(usernameValid ? .joseonCheong : Color.joseonBaek.opacity(0.3))
                        }
                    }
                    .frame(width: 44, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                usernameValid ? Color.joseonCheong.opacity(0.5) : Color.joseonBaek.opacity(0.15),
                                lineWidth: 1
                            )
                    )
                }
                .disabled(!usernameValid || isCheckingUsername)
            }
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.joseonBaek.opacity(0.2))
                    .frame(height: 1)
            }

            if !username.isEmpty && !usernameValid {
                validLabel("4~20자 영문+숫자 조합", ok: false)
            } else if let avail = usernameAvailable {
                validLabel(avail ? "사용 가능한 아이디입니다" : "이미 사용 중인 아이디입니다", ok: avail)
            }
        }
    }

    // MARK: - Terms Row
    var termsRow: some View {
        HStack {
            Button(action: { termsAccepted.toggle() }) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(
                                termsAccepted ? Color.joseonHwang : Color.joseonBaek.opacity(0.3),
                                lineWidth: 1.5
                            )
                            .frame(width: 18, height: 18)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(termsAccepted ? Color.joseonHwang.opacity(0.12) : .clear)
                            )
                        if termsAccepted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.joseonHwang)
                        }
                    }
                    Text("개인정보 이용약관에 동의합니다")
                        .font(.custom("Pretendard-Regular", size: 13))
                        .foregroundColor(Color.joseonBaek.opacity(0.7))
                }
            }

            Spacer()

            Button("약관 보기") { showTermsModal = true }
                .font(.custom("Pretendard-Medium", size: 12))
                .foregroundColor(.joseonCheong)
        }
    }

    // MARK: - Register Button
    var registerButton: some View {
        Button(action: { Task { await performRegistration() } }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isFormValid
                            ? LinearGradient(colors: [.joseonHwang, .cyberpunkGold],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.03)],
                                             startPoint: .leading, endPoint: .trailing)
                    )
                if isRegistering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.85)
                } else {
                    HStack(spacing: 8) {
                        Text("계정 생성")
                            .font(.custom("Pretendard-SemiBold", size: 16))
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(isFormValid ? .black : Color.joseonBaek.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .disabled(!isFormValid || isRegistering)
    }

    // MARK: - Helpers
    func validLabel(_ text: String, ok: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 11))
            Text(text)
                .font(.custom("Pretendard-Regular", size: 12))
        }
        .foregroundColor(ok ? .joseonCheong : .joseonJeok)
    }

    // 일반 텍스트 필드 (라인 스타일)
    func regField(
        text: Binding<String>,
        labelEn: String,
        placeholder: String,
        icon: String,
        keyboardType: UIKeyboardType = .default,
        isValid: Bool?,
        successText: String? = nil,
        errorText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(labelEn)
                .font(.custom("Pretendard-Medium", size: 10))
                .tracking(2.5)
                .foregroundColor(Color.joseonBaek.opacity(0.4))

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color.joseonBaek.opacity(0.4))
                    .frame(width: 20)

                TextField(placeholder, text: text)
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
                    .fill(
                        isValid == false
                            ? Color.joseonJeok.opacity(0.8)
                            : Color.joseonBaek.opacity(0.2)
                    )
                    .frame(height: 1)
            }

            if let valid = isValid {
                validLabel(valid ? (successText ?? placeholder) : errorText, ok: valid)
            }
        }
    }

    // 보안 텍스트 필드 (라인 스타일)
    func regSecureField(
        text: Binding<String>,
        labelEn: String,
        placeholder: String,
        showPassword: Binding<Bool>,
        isValid: Bool?,
        successText: String? = nil,
        errorText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(labelEn)
                .font(.custom("Pretendard-Medium", size: 10))
                .tracking(2.5)
                .foregroundColor(Color.joseonBaek.opacity(0.4))

            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .font(.system(size: 14))
                    .foregroundColor(Color.joseonBaek.opacity(0.4))
                    .frame(width: 20)

                Group {
                    if showPassword.wrappedValue {
                        TextField(placeholder, text: text)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                }
                .font(.custom("Pretendard-Regular", size: 15))
                .foregroundColor(.white)
                .accentColor(.joseonCheong)

                Button(action: { showPassword.wrappedValue.toggle() }) {
                    Image(systemName: showPassword.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(Color.joseonBaek.opacity(0.4))
                }
            }
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(
                        isValid == false
                            ? Color.joseonJeok.opacity(0.8)
                            : Color.joseonBaek.opacity(0.2)
                    )
                    .frame(height: 1)
            }

            if let valid = isValid {
                validLabel(valid ? (successText ?? placeholder) : errorText, ok: valid)
            }
        }
    }
}

// MARK: - Modals

extension RegisterView {
    var successModal: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.joseonCheong.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.joseonCheong)
                }

                VStack(spacing: 6) {
                    Text("가입 완료")
                        .font(.custom("Pretendard-Bold", size: 20))
                        .foregroundColor(.white)
                    Text("네오-서울에 오신 것을 환영합니다")
                        .font(.custom("Pretendard-Regular", size: 14))
                        .foregroundColor(Color.joseonBaek.opacity(0.6))
                }

                Button(action: {
                    showSuccessModal = false
                    isPresented = false
                }) {
                    Text("게임 시작")
                        .font(.custom("Pretendard-SemiBold", size: 16))
                        .foregroundColor(.black)
                        .frame(width: 160, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(
                                    colors: [.joseonHwang, .cyberpunkGold],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                        )
                }
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.joseonPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.joseonBorderGlow, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
        }
    }

    var termsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("개인정보 이용약관")
                        .font(.custom("Pretendard-Bold", size: 20))
                        .padding(.bottom, 8)

                    Text("""
                    1. 개인정보의 수집 및 이용 목적
                    - 회원 가입 및 관리
                    - 게임 서비스 제공
                    - 고객 지원 및 문의 응답

                    2. 수집하는 개인정보 항목
                    - 필수: 이름, 비밀번호, 이메일
                    - 선택: 게임 플레이 기록, 위치 정보

                    3. 개인정보의 보유 및 이용 기간
                    - 회원 탈퇴 시까지
                    - 법령에서 정한 보존 기간이 있는 경우 해당 기간

                    4. 개인정보의 제3자 제공
                    - 원칙적으로 제공하지 않음
                    - 법령에 의한 경우 예외

                    본 약관에 동의하지 않으실 경우 회원가입이 제한될 수 있습니다.
                    """)
                        .font(.custom("Pretendard-Regular", size: 14))
                        .foregroundColor(.primary)
                        .lineSpacing(5)
                }
                .padding()
            }
            .navigationTitle("약관")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { showTermsModal = false }
                        .font(.custom("Pretendard-Medium", size: 14))
                }
            }
        }
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .joseonCheong))
                    .scaleEffect(1.4)
                Text("계정 생성 중...")
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

// MARK: - Validation Logic

extension RegisterView {
    private var isFormValid: Bool {
        nameValid && passwordValid && passwordsMatch && emailValid && termsAccepted
    }

    private func validateName() {
        nameValid = NSPredicate(format: "SELF MATCHES %@", "^[가-힣a-zA-Z]{2,20}$").evaluate(with: name)
    }

    private func validateUsername() {
        usernameValid = NSPredicate(format: "SELF MATCHES %@", "^[a-zA-Z0-9]{4,20}$").evaluate(with: username)
    }

    private func validatePassword() {
        passwordValid = NSPredicate(
            format: "SELF MATCHES %@",
            "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$"
        ).evaluate(with: password)
    }

    private func validatePasswordMatch() {
        passwordsMatch = !password.isEmpty && !passwordConfirm.isEmpty && password == passwordConfirm
    }

    private func validateEmail() {
        emailValid = NSPredicate(
            format: "SELF MATCHES %@",
            "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        ).evaluate(with: email)
    }

    private func checkUsernameAvailability() async {
        isCheckingUsername = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        usernameAvailable = username != "test"
        isCheckingUsername = false
    }

    private func performRegistration() async {
        guard !isRegistering else { return }
        await MainActor.run { isRegistering = true; errorMessage = "" }

        await authManager.register(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            playerName: name.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        await MainActor.run {
            isRegistering = false
            if authManager.isAuthenticated {
                showSuccessModal = true
            } else {
                errorMessage = authManager.errorMessage.isEmpty
                    ? "회원가입에 실패했습니다. 잠시 후 다시 시도해주세요."
                    : authManager.errorMessage
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RegisterView(isPresented: .constant(true))
        .environmentObject(AuthManager.shared)
}
