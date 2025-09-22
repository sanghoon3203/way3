//
//  ProfileView.swift
//  way3
//
//  Created by Claude on 17/09/2025.
//  강화된 프로필 뷰 - 세계관 몰입과 캐릭터 커스터마이징
//

import SwiftUI

// MARK: - Player Profile Model
struct PlayerProfile: Codable {
    var name: String
    var age: Int
    var gender: PlayerGender
    var profileImage: String? // Base64 encoded or URL
    var backgroundStory: String
    var tradeLevel: Int
    var totalEarnings: Int
    var tradingDays: Int

    enum PlayerGender: String, CaseIterable, Codable {
        case male = "남성"
        case female = "여성"
        case nonBinary = "논바이너리"

        var displayName: String { rawValue }
    }
}

// MARK: - PlayerProfile Conversion Extensions
extension PlayerProfile {
    // Player 모델에서 PlayerProfile로 변환
    init(from player: Player) {
        self.name = player.core.name
        self.age = player.core.age
        self.gender = PlayerProfile.PlayerGender(rawValue: player.core.gender) ?? .male
        self.profileImage = nil // 추후 프로필 이미지 시스템 구현 시 연결
        self.backgroundStory = player.core.personality
        self.tradeLevel = player.core.level
        self.totalEarnings = player.core.money
        self.tradingDays = player.core.tradingDays
    }

    // 서버 API 응답에서 PlayerProfile로 변환
    static func from(apiResponse: PlayerDetail) -> PlayerProfile {
        return PlayerProfile(
            name: apiResponse.name,
            age: 28, // API에 age 필드 추가 필요하거나 기본값 사용
            gender: .male, // API에 gender 필드 추가 필요하거나 기본값 사용
            profileImage: nil,
            backgroundStory: "", // API에 backgroundStory 필드 추가 필요
            tradeLevel: apiResponse.level ?? 1,
            totalEarnings: apiResponse.money,
            tradingDays: calculateTradingDays(from: apiResponse) // 별도 계산 함수 필요
        )
    }

    // 거래 일수 계산 (임시 로직)
    private static func calculateTradingDays(from apiResponse: PlayerDetail) -> Int {
        // 실제로는 서버에서 제공하거나 로컬 계산 로직 구현
        return max(1, apiResponse.level ?? 1 * 3) // 레벨당 3일 정도로 추정
    }
}

// MARK: - Player Extension for ProfileView Integration
extension Player {
    // PlayerProfile 생성을 위한 convenience 프로퍼티
    var profileRepresentation: PlayerProfile {
        return PlayerProfile(from: self)
    }

    // PlayerProfile에서 Player 업데이트
    mutating func updateFrom(profile: PlayerProfile) {
        self.core.name = profile.name
        self.core.age = profile.age
        self.core.gender = profile.gender.rawValue
        self.core.personality = profile.backgroundStory
        // tradeLevel, totalEarnings, tradingDays는 게임 플레이로만 변경되어야 함
    }
}

// MARK: - Backstory Manager
class BackstoryManager: ObservableObject {
    static let shared = BackstoryManager()

    private let backstoryIntro = """
    🏛️ 조선시대 말, 개화기의 바람이 불어오던 시절...

    당신은 한때 번영했던 상인 가문의 후손입니다.
    하지만 일제강점기와 전쟁을 거치며 가문은 몰락했고,
    이제 오직 당신만이 가문의 영광을 되찾을 수 있습니다.

    "무역으로 돈을 벌어 집안을 일으켜 세우라!"
    할아버지의 유언이 귓가에 맴돕니다.

    현대의 서울에서, 당신은 새로운 무역 제국을 건설해야 합니다.
    작은 거래부터 시작해서 결국엔 동아시아 최고의 상인이 되는 것이 목표입니다.

    📜 가문의 계보:
    • 고조부: 조선 후기 대상인 (전국 상권 장악)
    • 증조부: 개화기 무역상 (해외 진출 시도)
    • 조부: 일제강점기 저항 상인 (민족 자본 수호)
    • 부친: 6.25 이후 재기 시도 (실패)
    • 당신: 현대의 무역 영웅 (미래 창조)

    지금부터 당신의 이야기가 시작됩니다!
    """

    func getBackstoryText() -> String {
        return backstoryIntro
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var gameManager: GameManager
    @StateObject private var backstoryManager = BackstoryManager.shared
    @State private var showingBackstory = false
    @State private var showingProfileEditor = false
    @State private var showingImagePicker = false
    @State private var pickedImage: UIImage?
    @State private var isRefreshing = false

    // 현재 플레이어 프로필 (서버 데이터 기반)
    private var currentProfile: PlayerProfile? {
        guard let player = gameManager.currentPlayer else { return nil }
        return player.profileRepresentation
    }

    var body: some View {
        NavigationView {
            Group {
                switch gameManager.profileViewState {
                case .loading:
                    ProfileLoadingView()
                case .loaded:
                    ProfileContentView(
                        profile: currentProfile,
                        isRefreshing: isRefreshing,
                        onRefresh: refreshProfile,
                        onEditProfile: { showingProfileEditor = true }
                    )
                case .error(let message):
                    ProfileErrorView(
                        message: message,
                        onRetry: loadProfile
                    )
                case .refreshing:
                    ProfileContentView(
                        profile: currentProfile,
                        isRefreshing: true,
                        onRefresh: refreshProfile,
                        onEditProfile: { showingProfileEditor = true }
                    )
                }
            }
            .background(Color.cyberpunkDarkBg)
            .navigationTitle("")
            .navigationBarHidden(true)
            .cyberpunkStatusBar(title: "OPERATIVE_PROFILE", status: "ONLINE")
        }
        .onAppear {
            loadProfile()
        }
        .refreshable {
            await refreshProfile()
        }
        .sheet(isPresented: $showingBackstory) {
            BackstoryView(backstory: backstoryManager.getBackstoryText())
        }
        .sheet(isPresented: $showingProfileEditor) {
            if let profile = currentProfile {
                ProfileEditorView(profile: .constant(profile)) { updatedProfile in
                    updateProfile(updatedProfile)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImage: $pickedImage)
        }
    }

    // MARK: - Helper Methods
    private func loadProfile() {
        Task {
            await gameManager.smartLoadProfile()
        }
    }

    private func refreshProfile() async {
        isRefreshing = true
        await gameManager.refreshProfileData()
        isRefreshing = false
    }

    private func updateProfile(_ updatedProfile: PlayerProfile) {
        guard var player = gameManager.currentPlayer else { return }
        player.updateFrom(profile: updatedProfile)
        gameManager.currentPlayer = player

        // 서버에 업데이트 전송 (추후 구현)
        Task {
            // await gameManager.updatePlayerProfile(updatedProfile)
        }
    }
}

// MARK: - Profile Loading View
struct ProfileLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkGreen))

            Text("프로필 로딩 중...")
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkGreen)

            Text("서버에서 최신 데이터를 가져오고 있습니다")
                .font(.cyberpunkCaption())
                .foregroundColor(.cyberpunkAccent)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cyberpunkDarkBg)
    }
}

// MARK: - Profile Content View
struct ProfileContentView: View {
    let profile: PlayerProfile?
    let isRefreshing: Bool
    let onRefresh: () async -> Void
    let onEditProfile: () -> Void

    @StateObject private var backstoryManager = BackstoryManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let profile = profile {
                    // Refresh Indicator
                    if isRefreshing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("업데이트 중...")
                                .font(.cyberpunkCaption())
                                .foregroundColor(.cyberpunkAccent)
                        }
                        .padding(.top, 10)
                    }

                    // Cyberpunk Profile Header
                    CyberpunkProfileHeader(
                        profile: profile,
                        onEditProfile: onEditProfile
                    )

                    // Cyberpunk Trading Dashboard
                    CyberpunkTradingDashboard(profile: profile)

                    // Cyberpunk Biography Panel
                    CyberpunkBiographyPanel(backgroundStory: backstoryManager.getBackstoryText())

                    // Cyberpunk Control Panel (Settings)
                    CyberpunkControlPanel()

                    Spacer(minLength: 100) // Tab bar spacing
                } else {
                    ProfileErrorView(
                        message: "프로필 데이터를 불러올 수 없습니다",
                        onRetry: {
                            Task { await onRefresh() }
                        }
                    )
                }
            }
        }
        .background(Color.cyberpunkDarkBg)
        .refreshable {
            await onRefresh()
        }
    }
}

// MARK: - Profile Error View
struct ProfileErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.cyberpunkRed)

            // Error Title
            Text("연결 오류")
                .font(.cyberpunkHeading())
                .foregroundColor(.cyberpunkRed)

            // Error Message
            Text(message)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkAccent)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            // Retry Button
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("다시 시도")
                }
                .font(.cyberpunkButton())
                .foregroundColor(.cyberpunkDarkBg)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyberpunkGreen)
                        .shadow(color: .cyberpunkGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Offline Notice
            VStack(spacing: 8) {
                Text("네트워크 연결을 확인하거나")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkAccent)
                Text("잠시 후 다시 시도해주세요")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkAccent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cyberpunkDarkBg)
    }
}
    }

    
// MARK: - Profile Image View
struct ProfileImageView: View {
    let profileImage: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let profileImage = profileImage {
                    // TODO: Load actual image
                    AsyncImage(url: URL(string: profileImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    // Default avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }

                // Camera icon overlay
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    )
                    .offset(x: 40, y: 40)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Profile Stat View
struct ProfileStatView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)

            Text(value)
                .font(.chosunSubhead)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(title)
                .font(.chosunSmall)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Trading Stat Card
struct TradingStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.chosunCaption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.chosunH2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(subtitle)
                    .font(.chosunSmall)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Settings Row View
struct SettingsRowView: View {
    let title: String
    let icon: String
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.chosunBody)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Backstory View
struct BackstoryView: View {
    let backstory: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)

                        Text("상인 가문의 유래")
                            .font(.chosunTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    // Backstory Content
                    Text(backstory)
                        .font(.chosunBody)
                        .lineSpacing(8)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)

                    // Call to Action
                    VStack(spacing: 16) {
                        Text("당신의 무역 제국을 건설하세요!")
                            .font(.chosunH2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("무역 시작하기")
                                .font(.chosunButton)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("가문의 역사")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Profile Editor View
struct ProfileEditorView: View {
    @Binding var profile: PlayerProfile
    @Environment(\.presentationMode) var presentationMode
    @State private var editedProfile: PlayerProfile
    let onSave: (PlayerProfile) -> Void

    init(profile: Binding<PlayerProfile>, onSave: @escaping (PlayerProfile) -> Void = { _ in }) {
        self._profile = profile
        self._editedProfile = State(initialValue: profile.wrappedValue)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section("기본 정보") {
                    HStack {
                        Text("이름")
                        TextField("이름을 입력하세요", text: $editedProfile.name)
                            .font(.chosunBody)
                    }

                    HStack {
                        Text("나이")
                        TextField("나이", value: $editedProfile.age, format: .number)
                            .keyboardType(.numberPad)
                            .font(.chosunBody)
                    }

                    HStack {
                        Text("성별")
                        Picker("성별", selection: $editedProfile.gender) {
                            ForEach(PlayerProfile.PlayerGender.allCases, id: \.self) { gender in
                                Text(gender.displayName)
                                    .font(.chosunBody)
                                    .tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                Section("개인 스토리") {
                    VStack(alignment: .leading) {
                        Text("당신만의 무역 이야기를 들려주세요")
                            .font(.chosunCaption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $editedProfile.backgroundStory)
                            .font(.chosunBody)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("프로필 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        profile = editedProfile
                        onSave(editedProfile)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}


