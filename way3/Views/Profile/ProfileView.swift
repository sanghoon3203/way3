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
    // 서버 API 응답에서 PlayerProfile로 변환
    static func from(apiResponse: PlayerDetail) -> PlayerProfile {
        return PlayerProfile(
            name: apiResponse.name,
            age: apiResponse.age ?? 25,
            gender: PlayerGender(rawValue: apiResponse.gender ?? "남성") ?? .male,
            profileImage: apiResponse.profileImage,
            backgroundStory: apiResponse.personality ?? "",
            tradeLevel: apiResponse.level ?? 1,
            totalEarnings: apiResponse.money,
            tradingDays: apiResponse.tradingDays ?? 1
        )
    }
}

// MARK: - Player Extension for ProfileView Integration
extension Player {
    // PlayerProfile 생성을 위한 convenience 프로퍼티
    var profileRepresentation: PlayerProfile {
        return PlayerProfile(
            name: self.core.name,
            age: self.core.age,
            gender: PlayerProfile.PlayerGender(rawValue: self.core.gender) ?? .male,
            profileImage: nil,
            backgroundStory: self.core.personality,
            tradeLevel: self.core.level,
            totalEarnings: self.core.money,
            tradingDays: self.core.tradingDays
        )
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
    @State private var showingProfileEditor = false
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
        .sheet(isPresented: $showingProfileEditor) {
            if let profile = currentProfile {
                ProfileEditorView(profile: .constant(profile)) { updatedProfile in
                    updateProfile(updatedProfile)
                }
            }
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
        guard var player = gameManager.currentPlayer else {
            print("⚠️ 현재 플레이어 없음 - 프로필 업데이트 실패")
            return
        }

        // 로컬 업데이튴
        player.updateFrom(profile: updatedProfile)
        gameManager.currentPlayer = player

        // 서버 비동기 업데이트
        Task {
            do {
                await gameManager.updatePlayerProfile(updatedProfile)
                print("✅ 프로필 업데이트 성공")
            } catch {
                print("❌ 프로필 업데이트 실패: \(error.localizedDescription)")
                // 실패 시 로컬 데이터는 이미 업데이트되었으므로 유지
            }
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


