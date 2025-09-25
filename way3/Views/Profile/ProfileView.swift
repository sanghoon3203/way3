//
//  ProfileView.swift
//  way3
//
//  Created by Claude on 17/09/2025.
//  프로필 뷰 - 서버 연동 플레이어 정보 표시
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var gameManager: GameManager
    @State private var showingProfileEditor = false
    @State private var isRefreshing = false

    // 현재 플레이어 정보 (서버 데이터 기반)
    private var currentPlayer: Player? {
        return gameManager.currentPlayer
    }

    var body: some View {
        NavigationView {
            Group {
                switch gameManager.profileViewState {
                case .loading:
                    ProfileLoadingView()
                case .loaded:
                    ProfileContentView(
                        player: currentPlayer,
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
                        player: currentPlayer,
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
            if let player = currentPlayer {
                ProfileEditorView(player: player) { updatedPlayer in
                    updateProfile(updatedPlayer)
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

    private func updateProfile(_ updatedPlayer: Player) {
        // 로컬 업데이트
        gameManager.currentPlayer = updatedPlayer

        // 서버 비동기 업데이트
        Task {
            do {
                let networkManager = NetworkManager.shared
                let _ = try await networkManager.updatePlayerProfile(
                    name: updatedPlayer.core.name,
                    age: updatedPlayer.core.age,
                    gender: updatedPlayer.core.gender,
                    personality: updatedPlayer.core.personality
                )
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
                .foregroundColor(.cyberpunkTextAccent)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cyberpunkDarkBg)
    }
}

// MARK: - Profile Content View
struct ProfileContentView: View {
    let player: Player?
    let isRefreshing: Bool
    let onRefresh: () async -> Void
    let onEditProfile: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let player = player {
                    // Refresh Indicator
                    if isRefreshing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("업데이트 중...")
                                .font(.cyberpunkCaption())
                                .foregroundColor(.cyberpunkTextAccent)
                        }
                        .padding(.top, 10)
                    }

                    // Cyberpunk Profile Header
                    CyberpunkProfileHeader(
                        profile: player,
                        onEditProfile: onEditProfile
                    )

                    // Cyberpunk Trading Dashboard
                    CyberpunkTradingDashboard(profile: player)

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
                .foregroundColor(.cyberpunkError)

            // Error Title
            Text("연결 오류")
                .font(.cyberpunkHeading())
                .foregroundColor(.cyberpunkError)

            // Error Message
            Text(message)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextAccent)
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
                    .foregroundColor(.cyberpunkTextAccent)
                Text("잠시 후 다시 시도해주세요")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkTextAccent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cyberpunkDarkBg)
    }
}

// MARK: - Profile Editor View
struct ProfileEditorView: View {
    let player: Player
    @Environment(\.presentationMode) var presentationMode
    @State private var editedPlayer: Player
    let onSave: (Player) -> Void

    init(player: Player, onSave: @escaping (Player) -> Void) {
        self.player = player
        self._editedPlayer = State(initialValue: player)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section("기본 정보") {
                    HStack {
                        Text("이름")
                        TextField("이름을 입력하세요", text: $editedPlayer.core.name)
                            .font(.chosunBody)
                    }

                    HStack {
                        Text("나이")
                        TextField("나이", value: $editedPlayer.core.age, format: .number)
                            .keyboardType(.numberPad)
                            .font(.chosunBody)
                    }

                    HStack {
                        Text("성별")
                        TextField("성별", text: $editedPlayer.core.gender)
                            .font(.chosunBody)
                    }
                }

                Section("개인 스토리") {
                    VStack(alignment: .leading) {
                        Text("당신만의 무역 이야기를 들려주세요")
                            .font(.chosunCaption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $editedPlayer.core.personality)
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
                        onSave(editedPlayer)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
