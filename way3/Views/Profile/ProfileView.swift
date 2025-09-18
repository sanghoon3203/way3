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
    @StateObject private var backstoryManager = BackstoryManager.shared
    @State private var showingBackstory = false
    @State private var showingProfileEditor = false
    @State private var showingImagePicker = false
    @State private var pickedImage: UIImage?

    // Sample profile data (should come from authManager.currentPlayer)
    @State private var playerProfile = PlayerProfile(
        name: "김상인",
        age: 28,
        gender: .male,
        profileImage: nil,
        backgroundStory: "",
        tradeLevel: 15,
        totalEarnings: 2450000,
        tradingDays: 47
    )

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile Header
                    VStack(spacing: 20) {
                        // Profile Image
                        ProfileImageView(
                            profileImage: playerProfile.profileImage,
                            onTap: {
                                showingImagePicker = true
                            }
                        )

                        // Basic Info
                        VStack(spacing: 12) {
                            Text(playerProfile.name)
                                .font(.chosunTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            HStack(spacing: 30) {
                                ProfileStatView(
                                    title: "나이",
                                    value: "\(playerProfile.age)세",
                                    icon: "person.crop.circle"
                                )

                                ProfileStatView(
                                    title: "성별",
                                    value: playerProfile.gender.displayName,
                                    icon: "figure.dress.line.vertical.figure"
                                )

                                ProfileStatView(
                                    title: "거래 레벨",
                                    value: "Lv.\(playerProfile.tradeLevel)",
                                    icon: "star.fill"
                                )
                            }
                        }

                        // Edit Profile Button
                        Button(action: {
                            showingProfileEditor = true
                        }) {
                            Text("프로필 편집")
                                .font(.chosunButton)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    // Trading Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("거래 통계")
                            .font(.chosunH2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 16) {
                            TradingStatCard(
                                title: "총 수익",
                                value: "₩\(playerProfile.totalEarnings.formatted())",
                                subtitle: "무역으로 벌어들인 총 금액",
                                color: .green,
                                icon: "won.sign.circle.fill"
                            )

                            TradingStatCard(
                                title: "거래 일수",
                                value: "\(playerProfile.tradingDays)일",
                                subtitle: "활발한 무역 활동 기간",
                                color: .blue,
                                icon: "calendar.badge.clock"
                            )

                        }
                        .padding(.horizontal, 20)
                    }

                    // Backstory Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("가문의 역사")
                            .font(.chosunH2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        Button(action: {
                            showingBackstory = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "scroll.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("상인 가문의 유래")
                                        .font(.chosunH3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    Text("조선시대부터 이어진 무역의 전통을 확인하세요")
                                        .font(.chosunCaption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                    }

                    // Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("설정")
                            .font(.chosunH2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            SettingsRowView(
                                title: "알림 설정",
                                icon: "bell.fill",
                                action: {
                                    // TODO: Notification settings
                                }
                            )

                            SettingsRowView(
                                title: "언어 설정",
                                icon: "globe",
                                action: {
                                    // TODO: Language settings
                                }
                            )

                            SettingsRowView(
                                title: "도움말",
                                icon: "questionmark.circle.fill",
                                action: {
                                    // TODO: Help center
                                }
                            )

                            Divider()
                                .padding(.horizontal, 20)

                            SettingsRowView(
                                title: "로그아웃",
                                icon: "arrow.right.square.fill",
                                color: .red,
                                action: {
                                    Task {
                                        await authManager.logout()
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 100) // Tab bar spacing
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingBackstory) {
            BackstoryView(backstory: backstoryManager.getBackstoryText())
        }
        .sheet(isPresented: $showingProfileEditor) {
            ProfileEditorView(profile: $playerProfile)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView (selectedImage: $pickedImage)
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

    init(profile: Binding<PlayerProfile>) {
        self._profile = profile
        self._editedProfile = State(initialValue: profile.wrappedValue)
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
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}


