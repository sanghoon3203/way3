//
//  ProfileInputView.swift
//  way3 - Way Trading Game
//
//  첫 로그인시 해치와의 JRPG 대화를 통한 프로필 설정
//  네오-서울 세계관 소개 및 플레이어 정보 수집
//

import SwiftUI

struct ProfileInputView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var player: Player
    @ObservedObject private var networkManager = NetworkManager.shared

    // 대화 상태
    @State private var currentStep: ProfileStep = .name
    @State private var displayedText = ""
    @State private var isTypingComplete = false
    @State private var showNextArrow = false

    // 입력 데이터
    @State private var playerName = ""
    @State private var playerAge = ""
    @State private var selectedPersonality = ""
    @State private var selectedGender = ""
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false

    // UI 상태
    @State private var showConfirmationPopup = false
    @State private var showCorrectionDialog = false

    // 서버 연동 상태
    @State private var isSavingProfile = false
    @State private var saveError: String? = nil
    @State private var showErrorAlert = false
    @State private var saveTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            // 1. 검정보라색 울렁거리는 애니메이션 배경
            AnimatedPurpleBackground()

            // 2. 해치 캐릭터와 대화창 레이아웃
            HStack(spacing: 0) {
                // 좌측: 해치 캐릭터
                VStack {
                    Spacer()
                    HachyCharacterView
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width * 0.4)

                // 우측: 대화창 영역
                VStack {
                    Spacer()
                    DialogueBoxView
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width * 0.6)
            }

            // 3. 확인 팝업
            if showConfirmationPopup {
                ConfirmationPopupView
            }

            // 4. 수정 대화창
            if showCorrectionDialog {
                CorrectionDialogView
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $profileImage)
        }
        .alert("프로필 저장 오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {
                // 오류 발생 시에도 화면은 닫기 (로컬 저장은 되었으므로)
                isPresented = false
            }
        } message: {
            Text(saveError ?? "알 수 없는 오류가 발생했습니다")
        }
        .onAppear {
            startTypingDialogue()
        }
        .onDisappear {
            saveTask?.cancel()
        }
    }
}

// MARK: - 애니메이션 배경
struct AnimatedPurpleBackground: View {
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // 기본 검정색 배경
            Color.black
                .ignoresSafeArea()

            // 울렁거리는 보라색 애니메이션 레이어들
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.3),
                                Color.purple.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .center,
                            endPoint: .leading
                        )
                    )
                    .frame(width: 400 + CGFloat(index * 100), height: 400 + CGFloat(index * 100))
                    .blur(radius: 20 + CGFloat(index * 10))
                    .offset(x: animationOffset + CGFloat(index * 50), y: sin(animationOffset * 0.01 + CGFloat(index)) * 30)
                    .animation(.easeInOut(duration: 3 + Double(index)).repeatForever(autoreverses: true), value: animationOffset)
            }
        }
        .onAppear {
            animationOffset = 200
        }
    }
}

// MARK: - 해치 캐릭터
extension ProfileInputView {
    var HachyCharacterView: some View {
        VStack(spacing: 12) {
            // 해치 캐릭터 이미지 (실제 이미지 파일로 교체 예정)
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.2),
                                Color.purple.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 180)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.cyan.opacity(0.6), lineWidth: 2)
                    )

                // 임시 해치 캐릭터 (실제 이미지로 교체)
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)

                    Text("해치")
                        .font(.chosunOrFallback(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - 대화창
    var DialogueBoxView: some View {
        ZStack {
            // 대화창 배경
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.cyan.opacity(0.6), lineWidth: 2)
                )

            VStack(spacing: 16) {
                // 대화 텍스트
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("해치")
                            .font(.chosunOrFallback(size: 16, weight: .bold))
                            .foregroundColor(.cyan)

                        Text(displayedText)
                            .font(.chosunOrFallback(size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }

                // 입력 필드 (필요한 단계에서만)
                if needsInput {
                    InputFieldView
                }

                // 선택 옵션 (필요한 단계에서만)
                if needsSelection {
                    SelectionView
                }

                // 다음 화살표
                HStack {
                    Spacer()
                    if showNextArrow {
                        Button(action: proceedToNext) {
                            HStack(spacing: 8) {
                                Text("다음")
                                    .font(.chosunOrFallback(size: 14))
                                    .foregroundColor(.cyan)

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.cyan)
                                    .opacity(canProceed ? 1.0 : 0.3)
                            }
                        }
                        .disabled(!canProceed)
                        .opacity(isTypingComplete ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: isTypingComplete)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 200)
        .padding(.horizontal, 20)
    }

    // MARK: - 입력 필드
    var InputFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if currentStep == .name {
                NeoSeoulTextField(
                    text: $playerName,
                    placeholder: "이름을 입력해주세요",
                    icon: "person.fill"
                )
            } else if currentStep == .age {
                NeoSeoulTextField(
                    text: $playerAge,
                    placeholder: "나이를 입력해주세요",
                    icon: "calendar"
                )
                .keyboardType(.numberPad)
            }
        }
    }

    // MARK: - 선택 옵션
    var SelectionView: some View {
        VStack(spacing: 12) {
            if currentStep == .personality {
                ForEach(PersonalityType.allCases, id: \.self) { personality in
                    SelectionButton(
                        title: personality.displayName,
                        isSelected: selectedPersonality == personality.rawValue,
                        action: { selectedPersonality = personality.rawValue }
                    )
                }
            } else if currentStep == .gender {
                ForEach(GenderType.allCases, id: \.self) { gender in
                    SelectionButton(
                        title: gender.displayName,
                        isSelected: selectedGender == gender.rawValue,
                        action: { selectedGender = gender.rawValue }
                    )
                }
            } else if currentStep == .profileImage {
                VStack(spacing: 12) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.cyan, lineWidth: 2))
                    }

                    Button("프로필 사진 선택") {
                        showImagePicker = true
                    }
                    .font(.chosunOrFallback(size: 14))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                    )

                    Button("기본 이미지 사용") {
                        profileImage = nil
                        // selectedGender는 유지 (서버 규격에 맞지 않는 "default" 제거)
                    }
                    .font(.chosunOrFallback(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - 대화 시스템 로직
extension ProfileInputView {
    private var needsInput: Bool {
        currentStep == .name || currentStep == .age
    }

    private var needsSelection: Bool {
        currentStep == .personality || currentStep == .gender || currentStep == .profileImage
    }

    private var canProceed: Bool {
        switch currentStep {
        case .name: return !playerName.isEmpty
        case .age: return !playerAge.isEmpty && Int(playerAge) != nil
        case .personality: return !selectedPersonality.isEmpty
        case .gender: return !selectedGender.isEmpty
        case .profileImage: return true // 프로필 사진은 선택사항
        case .completion: return false // 완료 단계에서는 다음 버튼 사용 안함
        }
    }

    private func startTypingDialogue() {
        typeDialogue(currentStep.dialogueText)
    }

    private func typeDialogue(_ text: String) {
        displayedText = ""
        isTypingComplete = false
        showNextArrow = false

        let characters = Array(text)
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedText += String(characters[currentIndex])
                currentIndex += 1

                if currentIndex % 4 == 0 {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } else {
                timer.invalidate()
                isTypingComplete = true

                // 잠시 후 화살표 표시
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showNextArrow = true
                    }
                }
            }
        }
    }

    private func proceedToNext() {
        guard canProceed else { return }

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        saveCurrentStepData()

        if let nextStep = currentStep.nextStep {
            currentStep = nextStep
            startTypingDialogue()
        } else {
            showConfirmationPopup = true
        }
    }

    private func saveCurrentStepData() {
        // 모든 데이터는 서버 연동 시에만 업데이트
    }
}

// MARK: - 확인 팝업
extension ProfileInputView {
    var ConfirmationPopupView: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    // 빈 영역 터치 시 팝업 유지
                }

            VStack(spacing: 20) {
                Text("프로필 확인")
                    .font(.chosunOrFallback(size: 20, weight: .bold))
                    .foregroundColor(.cyan)

                VStack(alignment: .leading, spacing: 12) {
                    Text("이름: \(playerName)")
                        .foregroundColor(.white)
                    Text("나이: \(playerAge)세")
                        .foregroundColor(.white)
                    Text("성격: \(PersonalityType.allCases.first(where: { $0.rawValue == selectedPersonality })?.displayName ?? "")")
                        .foregroundColor(.white)
                    Text("성별: \(GenderType.allCases.first(where: { $0.rawValue == selectedGender })?.displayName ?? "")")
                        .foregroundColor(.white)
                }
                .font(.chosunOrFallback(size: 16))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                )

                Text("이 정보가 맞나요?")
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)

                HStack(spacing: 20) {
                    Button("아니야") {
                        showConfirmationPopup = false
                        showCorrectionDialog = true
                    }
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )

                    Button("맞아") {
                        completeProfileSetup()
                    }
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSavingProfile ? Color.gray : Color.cyan)
                    )
                    .disabled(isSavingProfile)
                    .overlay(
                        Group {
                            if isSavingProfile {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                        }
                    )
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 40)
        }
    }

    var CorrectionDialogView: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("뭘 수정할까?")
                    .font(.chosunOrFallback(size: 18, weight: .bold))
                    .foregroundColor(.cyan)

                VStack(spacing: 12) {
                    ForEach(["이름", "나이", "성격", "성별"], id: \.self) { field in
                        Button(field) {
                            showCorrectionDialog = false
                            goBackToStep(for: field)
                        }
                        .font(.chosunOrFallback(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }

                Button("취소") {
                    showCorrectionDialog = false
                    showConfirmationPopup = true
                }
                .font(.chosunOrFallback(size: 14))
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 40)
        }
    }

    private func goBackToStep(for field: String) {
        switch field {
        case "이름":
            currentStep = .name
        case "나이":
            currentStep = .age
        case "성격":
            currentStep = .personality
        case "성별":
            currentStep = .gender
        default:
            return
        }
        startTypingDialogue()
    }

    private func completeProfileSetup() {
        showConfirmationPopup = false

        // 최종 인사 대화 표시
        currentStep = .completion
        startTypingDialogue()

        // 서버에 프로필 저장 (실제 구현)
        saveProfileToServer()

        // 3초 후 화면 전환
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                isPresented = false
            }
        }
    }

    private func saveProfileToServer() {
        // 입력 유효성 검사
        let validationError = validateInputs()
        if let error = validationError {
            saveError = error
            showErrorAlert = true
            return
        }

        guard let age = Int(playerAge) else {
            saveError = "나이는 숫자로 입력해주세요"
            showErrorAlert = true
            return
        }

        isSavingProfile = true
        saveError = nil

        saveTask = Task {
            do {
                let response = try await networkManager.createPlayerProfile(
                    name: playerName,
                    age: age,
                    gender: selectedGender,
                    personality: selectedPersonality
                )

                await MainActor.run {
                    isSavingProfile = false
                    handleServerResponse(response)
                }
            } catch {
                await MainActor.run {
                    isSavingProfile = false
                    handleNetworkError(error)
                }
            }
        }
    }

    private func validateInputs() -> String? {
        if playerName.isEmpty {
            return "이름을 입력해주세요"
        }
        if playerName.count < 2 || playerName.count > 20 {
            return "이름은 2-20자 사이로 입력해주세요"
        }
        if playerAge.isEmpty {
            return "나이를 입력해주세요"
        }
        if let age = Int(playerAge), (age < 16 || age > 100) {
            return "나이는 16-100세 사이로 입력해주세요"
        }
        if selectedPersonality.isEmpty {
            return "성격을 선택해주세요"
        }
        if selectedGender.isEmpty {
            return "성별을 선택해주세요"
        }
        return nil
    }

    private func handleServerResponse(_ response: ProfileCreationResponse) {
        if response.success {
            saveToLocalBackup(syncedWithServer: true)
            updatePlayerWithServerData(response.data)
            GameLogger.shared.logInfo("프로필 생성 성공: \(playerName)", category: .network)
        } else {
            let errorMessage = response.error ?? "프로필 저장에 실패했습니다"
            saveError = getLocalizedErrorMessage(errorMessage)
            showErrorAlert = true
            GameLogger.shared.logError("프로필 생성 실패: \(errorMessage)", category: .network)
        }
    }

    private func handleNetworkError(_ error: Error) {
        let errorMessage = "네트워크 연결을 확인해주세요"
        saveError = errorMessage
        showErrorAlert = true
        GameLogger.shared.logError("프로필 생성 네트워크 오류: \(error)", category: .network)

        // 오프라인 모드로 로컬 저장
        saveToLocalBackup(syncedWithServer: false)
    }

    private func saveToLocalBackup(syncedWithServer: Bool) {
        UserDefaults.standard.set(playerName, forKey: "playerName")
        UserDefaults.standard.set(playerAge, forKey: "playerAge")
        UserDefaults.standard.set(selectedPersonality, forKey: "playerPersonality")
        UserDefaults.standard.set(selectedGender, forKey: "playerGender")
        UserDefaults.standard.set(syncedWithServer, forKey: "profileCompleted")
    }

    private func getLocalizedErrorMessage(_ serverError: String) -> String {
        // 서버 에러를 사용자 친화적 메시지로 변환
        if serverError.contains("name") {
            return "이름 형식이 올바르지 않습니다"
        } else if serverError.contains("age") {
            return "나이 정보가 올바르지 않습니다"
        } else if serverError.contains("gender") {
            return "성별 정보가 올바르지 않습니다"
        } else if serverError.contains("personality") {
            return "성격 정보가 올바르지 않습니다"
        } else if serverError.contains("already") {
            return "이미 설정된 프로필이 있습니다"
        } else {
            return "프로필 저장 중 오류가 발생했습니다"
        }
    }

    private func updatePlayerWithServerData(_ data: ProfileCreationData?) {
        guard let data = data else { return }

        // Player 객체 기본 정보만 업데이트
        player.core.name = data.name

        // 나머지 상세 정보는 서버에서 관리되므로 로컬에 중복 저장하지 않음
    }
}

// MARK: - 데이터 모델
enum ProfileStep: CaseIterable {
    case name
    case age
    case personality
    case gender
    case profileImage
    case completion

    var dialogueText: String {
        switch self {
        case .name:
            return "안녕! 난 해치야. 네오-서울의 세계에 온 걸 환영해!\n\n이곳은 미래의 도시, 온갖 상인들이 모여 거래하는 곳이지. 너도 이제 우리 중 하나가 되는 거야.\n\n먼저, 너의 이름은 뭐야?"

        case .age:
            return "좋은 이름이네! 기억해둘게.\n\n그럼 나이는 어떻게 돼? 네오-서울에서는 나이에 관계없이 누구나 성공할 수 있어."

        case .personality:
            return "흠, 그렇구나. 나이는 숫자일 뿐이지!\n\n그런데 네 성격은 어떤 편이야? 거래할 때 성격이 중요하거든. 아래 중에서 골라봐."

        case .gender:
            return "성격을 알겠어! 그런 타입이구나.\n\n마지막으로, 네 성별은 어떻게 돼? 네오-서울에서는 모든 성별을 존중해."

        case .profileImage:
            return "알겠어! 이제 거의 다 끝났어.\n\n프로필 사진을 하나 골라줄래? 다른 상인들이 널 알아볼 수 있게 말이야. 안 고르면 기본 이미지로 설정할게."

        case .completion:
            return "\(playerName)! 이제 모든 준비가 끝났어.\n\n네오-서울에서 잘 살아남길 바래! 이곳은 위험하지만 기회도 많은 곳이야.\n\n다시 또 보자!"
        }
    }

    var nextStep: ProfileStep? {
        switch self {
        case .name: return .age
        case .age: return .personality
        case .personality: return .gender
        case .gender: return .profileImage
        case .profileImage: return nil // 확인 팝업으로 이동
        case .completion: return nil
        }
    }
}

enum PersonalityType: String, CaseIterable {
    case aggressive = "aggressive"
    case careful = "careful"
    case balanced = "balanced"
    case adventurous = "adventurous"
    case analytical = "analytical"

    var displayName: String {
        switch self {
        case .aggressive: return "공격적"
        case .careful: return "신중함"
        case .balanced: return "균형잡힌"
        case .adventurous: return "모험적"
        case .analytical: return "분석적"
        }
    }
}

enum GenderType: String, CaseIterable {
    case male = "male"
    case female = "female"

    var displayName: String {
        switch self {
        case .male: return "남자"
        case .female: return "여자"
        }
    }
}

// MARK: - 헬퍼 컴포넌트들
struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(isSelected ? Color.cyan : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.cyan, lineWidth: 2)
                    )

                Text(title)
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.cyan.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.cyan : Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct NeoSeoulTextField: View {
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

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileInputView(isPresented: .constant(true))
        .environmentObject(AuthManager.shared)
        .environmentObject(Player.createDefault())
}
