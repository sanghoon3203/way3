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
        // TODO: 서버에서 상인 위치 정보를 제공하면 업데이트
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

// MARK: - Cyberpunk Quest Card Component
struct CyberpunkQuestCard: View {
    let quest: QuestData
    let onAction: () -> Void
    @State private var showActionAlert = false
    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quest Header with status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.chosunH3)
                        .fontWeight(.bold)
                        .foregroundColor(.cyberpunkPrimary)

                    Text(quest.locationText)
                        .font(.chosunCaption)
                        .foregroundColor(.cyberpunkSecondary)
                }

                Spacer()

                // Status Badge
                HStack(spacing: 8) {
                    // Difficulty Badge
                    Text(quest.difficultyText)
                        .font(.chosunSmall)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(quest.difficultyColor)
                        .cornerRadius(8)

                    // Status Badge
                    Text(questStatusText)
                        .font(.chosunSmall)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(questStatusColor)
                        .cornerRadius(8)
                }
            }

            // Quest Description
            Text(quest.description)
                .font(.chosunBody)
                .foregroundColor(.cyberpunkText)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            // Progress (for active quests)
            if quest.status == "active" {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("진행도")
                            .font(.chosunCaption)
                            .foregroundColor(.cyberpunkSecondary)

                        Spacer()

                        Text("\(quest.currentProgress)/\(quest.maxProgress)")
                            .font(.chosunCaption)
                            .fontWeight(.medium)
                            .foregroundColor(.cyberpunkCyan)
                    }

                    ProgressView(value: quest.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .cyberpunkCyan))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }

            // Reward Info
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.cyberpunkGold)
                    .font(.system(size: 16))

                Text("보상:")
                    .font(.chosunCaption)
                    .foregroundColor(.cyberpunkSecondary)

                Text(quest.rewardDisplayString)
                    .font(.chosunCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.cyberpunkGold)
                    .lineLimit(1)
            }

            // Action Button
            Button(action: {
                showActionAlert = true
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }

                    Text(actionButtonText)
                        .font(.chosunButton)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: actionButtonColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            }
            .disabled(isProcessing || !canPerformAction)
            .alert(alertTitle, isPresented: $showActionAlert) {
                Button("취소", role: .cancel) { }
                Button("확인") {
                    performAction()
                }
            } message: {
                Text(alertMessage)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cyberpunkCardBg)
                .stroke(Color.cyberpunkBorder, lineWidth: 1)
        )
        .shadow(color: .cyberpunkGlow.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    // MARK: - Computed Properties
    private var questStatusText: String {
        switch quest.status {
        case "available": return "사용 가능"
        case "active": return "진행 중"
        case "completed": return quest.rewardClaimed ? "완료됨" : "보상 대기"
        default: return "알 수 없음"
        }
    }

    private var questStatusColor: Color {
        switch quest.status {
        case "available": return .cyberpunkGreen
        case "active": return .cyberpunkCyan
        case "completed": return quest.rewardClaimed ? .cyberpunkSecondary : .cyberpunkGold
        default: return .gray
        }
    }

    private var actionButtonText: String {
        switch quest.status {
        case "available": return "수락"
        case "active": return "진행 중"
        case "completed": return quest.rewardClaimed ? "완료됨" : "보상 수령"
        default: return "사용 불가"
        }
    }

    private var actionButtonColors: [Color] {
        switch quest.status {
        case "available": return [.cyberpunkPrimary, .cyberpunkPrimary.opacity(0.8)]
        case "active": return [.cyberpunkSecondary, .cyberpunkSecondary.opacity(0.8)]
        case "completed":
            return quest.rewardClaimed ?
                [.cyberpunkSecondary, .cyberpunkSecondary.opacity(0.8)] :
                [.cyberpunkGold, .cyberpunkGold.opacity(0.8)]
        default: return [.gray, .gray.opacity(0.8)]
        }
    }

    private var canPerformAction: Bool {
        switch quest.status {
        case "available": return true
        case "active": return false
        case "completed": return quest.canClaimReward
        default: return false
        }
    }

    private var alertTitle: String {
        switch quest.status {
        case "available": return "\(quest.title)을 수락하시겠습니까?"
        case "completed": return "퀘스트 보상을 수령하시겠습니까?"
        default: return "작업 확인"
        }
    }

    private var alertMessage: String {
        switch quest.status {
        case "available": return "퀘스트를 수락하면 제한 시간 내에 완료해야 합니다."
        case "completed": return "보상: \(quest.rewardDisplayString)"
        default: return ""
        }
    }

    // MARK: - Actions
    private func performAction() {
        isProcessing = true

        Task {
            // 약간의 지연으로 UI 피드백 제공
            try? await Task.sleep(nanoseconds: 300_000_000)

            await MainActor.run {
                onAction()
                isProcessing = false
            }
        }
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

                        case .acceptingQuest(let quest):
                            QuestActionContent(actionText: "퀘스트 '\(quest.title)' 수락 중...")

                        case .claimingReward(let quest):
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
        case .acceptingQuest: return "ACCEPTING..."
        case .claimingReward: return "CLAIMING..."
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
                .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkPrimary))
                .scaleEffect(1.5)

            Text("LOADING_MISSIONS")
                .font(.chosunH3)
                .foregroundColor(.cyberpunkPrimary)
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
                .foregroundColor(.cyberpunkText)
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
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkPrimary))
                        Text("REFRESHING...")
                            .font(.chosunCaption)
                            .foregroundColor(.cyberpunkPrimary)
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
                    .foregroundColor(.cyberpunkPrimary)

                Spacer()

                Text("\(quests.count)")
                    .font(.chosunH3)
                    .fontWeight(.medium)
                    .foregroundColor(.cyberpunkSecondary)
            }
            .padding(.horizontal, CyberpunkLayout.screenPadding)

            // Quest Cards
            LazyVStack(spacing: 16) {
                ForEach(quests) { quest in
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