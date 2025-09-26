//
//  RegisterView.swift
//  way3 - Way Trading Game
//
//  네오-서울 테마 회원가입 화면
//  실시간 유효성 검사 + 서버 중복 체크 + 개인정보 약관
//

import SwiftUI
import AVKit

struct RegisterView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var authManager: AuthManager

    // 폼 데이터
    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var email = ""
    @State private var termsAccepted = false

    // 유효성 검사 상태
    @State private var nameValid = false
    @State private var usernameValid = false
    @State private var usernameAvailable: Bool? = nil
    @State private var passwordValid = false
    @State private var passwordsMatch = false
    @State private var emailValid = false

    // UI 상태
    @State private var showPassword = false
    @State private var showPasswordConfirm = false
    @State private var isCheckingUsername = false
    @State private var showTermsModal = false
    @State private var showSuccessModal = false
    @State private var isRegistering = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // 배경 영상 + 블러 (LoginView와 동일)
            BackgroundVideoLayer()
            BlurOverlayLayer()

            // 컨텐츠
            ContentLayer2

            // 성공 모달
            if showSuccessModal {
                SuccessModal
            }

            // 로딩 오버레이
            if isRegistering {
                LoadingOverlay
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTermsModal) {
            TermsModal
        }
    }
}

// MARK: - Content Layer
extension RegisterView {
    var ContentLayer2: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 뒤로가기 + 헤더
                HeaderComponent

                // 회원가입 폼
                RegisterFormComponent
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Header Component
    var HeaderComponent: some View {
        HStack {
            // 뒤로가기 버튼
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

            // 제목
            Text("회원가입")
                .font(.chosunOrFallback(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // 빈 공간 (대칭을 위해)
            Color.clear.frame(width: 80)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Register Form Component
    var RegisterFormComponent: some View {
        VStack(spacing: 20) {
            // 이름 필드
            NameField

            // 아이디 필드 + 중복 확인
            UsernameField

            // 비밀번호 필드
            PasswordField

            // 비밀번호 확인 필드
            PasswordConfirmField

            // 복구 이메일 필드
            EmailField

            // 개인정보 약관 체크박스
            TermsCheckbox

            // 에러 메시지
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.chosunOrFallback(size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // 회원가입 버튼
            RegisterButton
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

    // MARK: - Name Field
    var NameField: some View {
        VStack(alignment: .leading, spacing: 5) {
            IDTextField(
                text: $name,
                placeholder: "이름",
                icon: "person.fill"
            )
            .onChange(of: name) { _ in
                validateName()
            }

            if !name.isEmpty && !nameValid {
                Text("이름은 2-10자의 한글 또는 영문이어야 합니다")
                    .font(.chosunOrFallback(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 16)
            }
        }
    }

    // MARK: - Username Field
    var UsernameField: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 12) {
                IDTextField(
                    text: $username,
                    placeholder: "아이디",
                    icon: "at"
                )
                .onChange(of: username) { _ in
                    validateUsername()
                    usernameAvailable = nil // 입력 변경 시 중복 확인 상태 초기화
                }

                // 중복 확인 버튼
                Button(action: {
                    Task {
                        await checkUsernameAvailability()
                    }
                }) {
                    HStack {
                        if isCheckingUsername {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else if let available = usernameAvailable {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(available ? .green : .red)
                        } else {
                            Text("중복확인")
                                .font(.chosunOrFallback(size: 12))
                        }
                    }
                    .foregroundColor(usernameValid ? .cyan : .gray)
                    .frame(width: 70, height: 35)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
                }
                .disabled(!usernameValid || isCheckingUsername)
            }

            // 아이디 유효성 메시지
            if !username.isEmpty && !usernameValid {
                Text("아이디는 4-20자의 영문과 숫자 조합이어야 합니다")
                    .font(.chosunOrFallback(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 16)
            } else if let available = usernameAvailable, !available {
                Text("이미 사용 중인 아이디입니다")
                    .font(.chosunOrFallback(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 16)
            }
        }
    }

    // MARK: - Password Field
    var PasswordField: some View {
        VStack(alignment: .leading, spacing: 5) {
            NeoSeoulSecureField(
                text: $password,
                placeholder: "비밀번호",
                showPassword: $showPassword
            )
            .onChange(of: password) { _ in
                validatePassword()
                validatePasswordMatch()
            }

            if !password.isEmpty && !passwordValid {
                Text("비밀번호는 8자 이상, 영문+숫자+특수문자 조합이어야 합니다")
                    .font(.chosunOrFallback(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 16)
            }
        }
    }

    // MARK: - Password Confirm Field
    var PasswordConfirmField: some View {
        VStack(alignment: .leading, spacing: 5) {
            NeoSeoulSecureField(
                text: $passwordConfirm,
                placeholder: "비밀번호 확인",
                showPassword: $showPasswordConfirm
            )
            .onChange(of: passwordConfirm) { _ in
                validatePasswordMatch()
            }

            if !passwordConfirm.isEmpty {
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

    // MARK: - Email Field
    var EmailField: some View {
        VStack(alignment: .leading, spacing: 5) {
            IDTextField(
                text: $email,
                placeholder: "이메일",
                icon: "envelope.fill"
            )
            .onChange(of: email) { _ in
                validateEmail()
            }

            if !email.isEmpty && !emailValid {
                Text("올바른 이메일 형식을 입력해주세요")
                    .font(.chosunOrFallback(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 16)
            }
        }
    }

    // MARK: - Terms Checkbox
    var TermsCheckbox: some View {
        HStack {
            Button(action: {
                termsAccepted.toggle()
            }) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                            .frame(width: 20, height: 20)

                        if termsAccepted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                    }

                    Text("개인정보 이용약관에 동의합니다")
                        .font(.chosunOrFallback(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            Button("보기") {
                showTermsModal = true
            }
            .font(.chosunOrFallback(size: 12))
            .foregroundColor(.cyan)
            .underline()
        }
    }

    // MARK: - Register Button
    var RegisterButton: some View {
        Button(action: {
            Task {
                await performRegistration()
            }
        }) {
            HStack {
                if isRegistering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "person.badge.plus")
                        .font(.title2)
                }

                Text(isRegistering ? "계정 생성 중..." : "회원가입")
                    .font(.chosunOrFallback(size: 16, weight: .semibold))
            }
            .foregroundColor(isFormValid ? .black : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isFormValid ? Color.cyan : Color.gray.opacity(0.3))
            )
        }
        .disabled(!isFormValid || isRegistering)
        .padding(.top, 10)
    }
}

// MARK: - Validation Logic
extension RegisterView {
    private var isFormValid: Bool {
        return nameValid &&
               passwordValid &&
               passwordsMatch &&
               emailValid &&
               termsAccepted
    }

    private func validateName() {
        let nameRegex = "^[가-힣a-zA-Z]{2,20}$"
        nameValid = NSPredicate(format: "SELF MATCHES %@", nameRegex).evaluate(with: name)
    }

    private func validateUsername() {
        let usernameRegex = "^[a-zA-Z0-9]{4,20}$"
        usernameValid = NSPredicate(format: "SELF MATCHES %@", usernameRegex).evaluate(with: username)
    }

    private func validatePassword() {
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$"
        passwordValid = NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }

    private func validatePasswordMatch() {
        passwordsMatch = !password.isEmpty && !passwordConfirm.isEmpty && password == passwordConfirm
    }

    private func validateEmail() {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        emailValid = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func checkUsernameAvailability() async {
        isCheckingUsername = true

        // TODO: 실제 서버 API 호출
        // 임시로 딜레이 추가
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // 임시 로직: "test"는 이미 사용 중으로 처리
        usernameAvailable = username != "test"
        isCheckingUsername = false
    }

    private func performRegistration() async {
        guard !isRegistering else { return }

        await MainActor.run {
            isRegistering = true
            errorMessage = ""
        }

        await authManager.register(email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                    password: password,
                                    playerName: name.trimmingCharacters(in: .whitespacesAndNewlines))

        await MainActor.run {
            isRegistering = false

            if authManager.isAuthenticated {
                errorMessage = ""
                showSuccessModal = true
            } else {
                errorMessage = authManager.errorMessage.isEmpty
                    ? "회원가입에 실패했습니다. 잠시 후 다시 시도해주세요."
                    : authManager.errorMessage
            }
        }
    }
}

// MARK: - Modals
extension RegisterView {
    var SuccessModal: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // 성공 아이콘
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(1.0)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            // 애니메이션 효과
                        }
                    }

                Text("성공적으로 회원가입이 완료되었습니다")
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Button("확인") {
                    showSuccessModal = false
                    isPresented = false
                }
                .font(.chosunOrFallback(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 120, height: 45)
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

    var TermsModal: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("개인정보 이용약관")
                        .font(.chosunOrFallback(size: 20, weight: .bold))
                        .padding(.bottom, 10)

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

                    4. 개인정보 처리 위탁
                    - 서버 운영 및 관리: AWS Korea
                    - 데이터 분석: 내부 처리

                    5. 개인정보의 제3자 제공
                    - 원칙적으로 제공하지 않음
                    - 법령에 의한 경우 예외

                    본 약관에 동의하지 않으실 경우 회원가입이 제한될 수 있습니다.
                    """)
                        .font(.chosunOrFallback(size: 14))
                        .lineSpacing(4)
                }
                .padding()
            }
            .navigationTitle("약관")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        showTermsModal = false
                    }
                }
            }
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

                Text("계정 생성 중...")
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
    RegisterView(isPresented: .constant(true))
        .environmentObject(AuthManager.shared)
}
