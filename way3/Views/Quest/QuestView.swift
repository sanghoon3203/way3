//
//  QuestView.swift
//  way3
//
//  Created by Claude on 17/09/2025.
//  오늘의 퀘스트 시스템 - 서버 연동 퀘스트 관리
//

import SwiftUI

// MARK: - QuestData Extensions for UI
extension QuestData {
    var difficultyColor: Color {
        switch priority {
        case 1: return .green      // 쉬움
        case 2: return .orange     // 보통
        case 3...Int.max: return .red  // 어려움
        default: return .gray
        }
    }

    var difficultyText: String {
        switch priority {
        case 1: return "쉬움"
        case 2: return "보통"
        case 3...Int.max: return "어려움"
        default: return "알 수 없음"
        }
    }

    var progressPercentage: Double {
        guard maxProgress > 0 else { return 0.0 }
        return Double(currentProgress) / Double(maxProgress)
    }

    var isCompleted: Bool {
        return currentProgress >= maxProgress && status == "completed"
    }

    var canClaimReward: Bool {
        return isCompleted && !rewardClaimed
    }

    var rewardDisplayString: String {
        var rewardStrings: [String] = []

        if rewards.money > 0 {
            rewardStrings.append("₩\(rewards.money)")
        }
        if rewards.experience > 0 {
            rewardStrings.append("경험치 \(rewards.experience)")
        }
        if rewards.trustPoints > 0 {
            rewardStrings.append("신뢰도 \(rewards.trustPoints)")
        }
        if let items = rewards.items, !items.isEmpty {
            for item in items {
                rewardStrings.append("\(item.itemId) x\(item.quantity)")
            }
        }

        return rewardStrings.isEmpty ? "보상 없음" : rewardStrings.joined(separator: ", ")
    }

    var locationText: String {
        return "근처 상인"
    }
}

// MARK: - Quest Helper Functions
extension QuestView {
    var allQuests: [QuestData] {
        return gameManager.availableQuests + gameManager.activeQuests + gameManager.completedQuests
    }

    var totalQuestCount: Int {
        return allQuests.count
    }

    var availableQuestCount: Int {
        return gameManager.availableQuests.count
    }

    var activeQuestCount: Int {
        return gameManager.activeQuests.count
    }

    var completedQuestCount: Int {
        return gameManager.completedQuests.count
    }

    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "새로고침 가능"
        }

        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}


// MARK: - Main Quest View
struct QuestView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var timer: Timer?
    @State private var currentTime = Date()

    var body: some View {
        NavigationView {
            ZStack {
                // 사이버펑크 배경
                Color.cyberpunkDarkBg
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Section - 사이버펑크 스타일
                        CyberpunkSectionHeader(
                            title: "MISSION_TERMINAL",
                            subtitle: "QUEST_SYSTEM_V3.2",
                            rightContent: questHeaderStatus
                        )
                        .padding(.top, 10)

                        // Quest State Content
                        switch gameManager.questsViewState {
                        case .loading:
                            QuestLoadingView()
                                .padding(.horizontal, CyberpunkLayout.screenPadding)

                        case .loaded:
                            QuestLoadedContent()

                        case .error(let message):
                            QuestErrorView(message: message) {
                                Task {
                                    await gameManager.refreshQuestsData()
                                }
                            }
                            .padding(.horizontal, CyberpunkLayout.screenPadding)

                        case .refreshing:
                            QuestRefreshingContent()

                        case .accepting(let quest):
                            QuestActionContent(actionText: "퀘스트 '\(quest.title)' 수락 중...")

                        case .claiming(let quest):
                            QuestActionContent(actionText: "'\(quest.title)' 보상 수령 중...")
                        }

                        Spacer(minLength: 100) // Extra space for tab bar
                    }
                }
                .navigationTitle("")
                .navigationBarHidden(true)
            }
        }
        .onAppear {
            startTimer()
            // 데이터가 없으면 자동 로드
            if gameManager.questsViewState == .loading {
                Task {
                    await gameManager.loadQuestsData()
                }
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Computed Properties
    private var questHeaderStatus: String {
        switch gameManager.questsViewState {
        case .loading: return "LOADING..."
        case .loaded: return "READY"
        case .error: return "ERROR"
        case .refreshing: return "REFRESHING..."
        case .accepting: return "ACCEPTING..."
        case .claiming: return "CLAIMING..."
        }
    }

    // MARK: - Content Views
    @ViewBuilder
    private func QuestLoadedContent() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Daily Quest Progress - 사이버펑크 스타일
            CyberpunkStatusPanel(
                title: "QUEST_STATUS",
                statusItems: [
                    ("AVAILABLE", "\(availableQuestCount)", .cyberpunkGreen),
                    ("ACTIVE", "\(activeQuestCount)", .cyberpunkCyan),
                    ("COMPLETED", "\(completedQuestCount)", .cyberpunkGold)
                ]
            )
            .padding(.horizontal, CyberpunkLayout.screenPadding)

            // Quest Sections
            if !gameManager.availableQuests.isEmpty {
                QuestSection(
                    title: "AVAILABLE_MISSIONS",
                    quests: gameManager.availableQuests,
                    onQuestAction: handleQuestAction
                )
            }

            if !gameManager.activeQuests.isEmpty {
                QuestSection(
                    title: "ACTIVE_MISSIONS",
                    quests: gameManager.activeQuests,
                    onQuestAction: handleQuestAction
                )
            }

            if !gameManager.completedQuests.isEmpty {
                QuestSection(
                    title: "COMPLETED_MISSIONS",
                    quests: gameManager.completedQuests,
                    onQuestAction: handleQuestAction
                )
            }

            // Refresh Button
            CyberpunkButton(
                title: "REFRESH_MISSIONS",
                style: .secondary
            ) {
                Task {
                    await gameManager.refreshQuestsData()
                }
            }
            .padding(.horizontal, CyberpunkLayout.screenPadding)
        }
    }

    @ViewBuilder
    private func QuestLoadingView() -> some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkCyan))
                .scaleEffect(1.5)

            Text("LOADING_MISSIONS")
                .font(.chosunH3)
                .foregroundColor(.cyberpunkTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    private func QuestErrorView(message: String, onRetry: @escaping () -> Void) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.cyberpunkError)

            Text("MISSION_ERROR")
                .font(.chosunH3)
                .foregroundColor(.cyberpunkError)

            Text(message)
                .font(.chosunBody)
                .foregroundColor(.cyberpunkTextPrimary)
                .multilineTextAlignment(.center)

            CyberpunkButton(
                title: "RETRY_CONNECTION",
                style: .primary
            ) {
                onRetry()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    private func QuestRefreshingContent() -> some View {
        QuestLoadedContent()
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkCyan))
                        Text("REFRESHING...")
                            .font(.chosunCaption)
                            .foregroundColor(.cyberpunkTextPrimary)
                    }
                    .padding()
                    .background(Color.cyberpunkCardBg)
                    .cornerRadius(12)
                    .padding()
                }
            )
    }

    @ViewBuilder
    private func QuestActionContent(actionText: String) -> some View {
        QuestLoadedContent()
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkGold))
                        Text(actionText)
                            .font(.chosunCaption)
                            .foregroundColor(.cyberpunkGold)
                    }
                    .padding()
                    .background(Color.cyberpunkCardBg)
                    .cornerRadius(12)
                    .padding()
                }
            )
    }

    // MARK: - Quest Actions
    private func handleQuestAction(quest: QuestData) {
        Task {
            switch quest.status {
            case "available":
                let success = await gameManager.acceptQuest(quest)
                if success {
                    // 성공 피드백은 GameManager에서 상태 변경으로 처리
                }

            case "completed":
                if quest.canClaimReward {
                    let success = await gameManager.claimQuestReward(quest)
                    if success {
                        // 성공 피드백은 GameManager에서 상태 변경으로 처리
                    }
                }

            default:
                break // active 상태는 액션 불가
            }
        }
    }

    // MARK: - Timer Functions
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Quest Section Component
struct QuestSection: View {
    let title: String
    let quests: [QuestData]
    let onQuestAction: (QuestData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text(title)
                    .font(.chosunH2)
                    .fontWeight(.bold)
                    .foregroundColor(.cyberpunkTextPrimary)

                Spacer()

                Text("\(quests.count)")
                    .font(.chosunH3)
                    .fontWeight(.medium)
                    .foregroundColor(.cyberpunkTextSecondary)
            }
            .padding(.horizontal, CyberpunkLayout.screenPadding)

            // Quest Cards
            LazyVStack(spacing: 16) {
                ForEach(quests, id: \.id) { quest in
                    CyberpunkQuestCard(quest: quest) {
                        onQuestAction(quest)
                    }
                }
            }
            .padding(.horizontal, CyberpunkLayout.screenPadding)
        }
    }
}

#Preview {
    QuestView()
        .environmentObject(GameManager.shared)
}