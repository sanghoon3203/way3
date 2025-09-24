//
//  CyberpunkQuestComponents.swift
//  way3 - Way Trading Game
//
//  사이버펑크 스타일 퀘스트 컴포넌트들
//  서버 QuestData 규격에 맞춘 컴포넌트
//

import SwiftUI

// MARK: - Cyberpunk Quest Card (서버 데이터 사용)
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
                    Text(quest.title.uppercased())
                        .font(.cyberpunkHeading(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.cyberpunkTextPrimary)

                    Text("CATEGORY: \(quest.category.uppercased())")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)
                }

                Spacer()

                // Status Badge
                HStack(spacing: 8) {
                    // Difficulty Badge
                    Text(difficultyText)
                        .font(.cyberpunkTechnical())
                        .fontWeight(.medium)
                        .foregroundColor(.cyberpunkDarkBg)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor)

                    // Status Badge
                    Text(questStatusText)
                        .font(.cyberpunkTechnical())
                        .fontWeight(.medium)
                        .foregroundColor(.cyberpunkDarkBg)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(questStatusColor)
                }
            }

            // Quest Description
            Text(quest.description)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            // Progress (for active quests)
            if quest.status == "active" {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("PROGRESS")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkTextSecondary)

                        Spacer()

                        Text("\(quest.currentProgress)/\(quest.maxProgress)")
                            .font(.cyberpunkCaption())
                            .fontWeight(.medium)
                            .foregroundColor(.cyberpunkCyan)
                    }

                    CyberpunkProgressBar(
                        progress: progressPercentage,
                        color: .cyberpunkCyan,
                        height: 4
                    )
                }
            }

            // Reward Info
            VStack(alignment: .leading, spacing: 4) {
                Text("REWARD_PACKAGE:")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Text(rewardDisplayString)
                    .font(.cyberpunkCaption())
                    .fontWeight(.medium)
                    .foregroundColor(.cyberpunkGold)
                    .lineLimit(2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(Color.cyberpunkDarkBg.opacity(0.6))

            // Action Button
            CyberpunkButton(
                title: actionButtonText,
                style: buttonStyle,
                action: {
                    showActionAlert = true
                }
            )
            .disabled(!canPerformAction)
        }
        .padding(16)
        .cyberpunkCard()
        .alert(alertTitle, isPresented: $showActionAlert) {
            Button("CANCEL", role: .cancel) { }
            Button("CONFIRM") {
                performAction()
            }
        } message: {
            Text(alertMessage)
                .font(.cyberpunkBody())
        }
    }

    // MARK: - Computed Properties
    private var difficultyText: String {
        switch quest.priority {
        case 1: return "EASY"
        case 2: return "NORMAL"
        case 3...Int.max: return "HARD"
        default: return "UNKNOWN"
        }
    }

    private var difficultyColor: Color {
        switch quest.priority {
        case 1: return .cyberpunkGreen
        case 2: return .cyberpunkYellow
        case 3...Int.max: return .cyberpunkError
        default: return .cyberpunkTextSecondary
        }
    }

    private var questStatusText: String {
        switch quest.status {
        case "available": return "AVAILABLE"
        case "active": return "ACTIVE"
        case "completed": return quest.rewardClaimed ? "CLAIMED" : "COMPLETE"
        default: return "UNKNOWN"
        }
    }

    private var questStatusColor: Color {
        switch quest.status {
        case "available": return .cyberpunkGreen
        case "active": return .cyberpunkCyan
        case "completed": return quest.rewardClaimed ? .cyberpunkTextSecondary : .cyberpunkGold
        default: return .cyberpunkTextSecondary
        }
    }

    private var progressPercentage: Double {
        guard quest.maxProgress > 0 else { return 0.0 }
        return Double(quest.currentProgress) / Double(quest.maxProgress)
    }

    private var actionButtonText: String {
        if isProcessing {
            return "PROCESSING..."
        }

        switch quest.status {
        case "available": return "ACCEPT_MISSION"
        case "active": return "IN_PROGRESS"
        case "completed": return quest.rewardClaimed ? "CLAIMED" : "CLAIM_REWARD"
        default: return "UNAVAILABLE"
        }
    }

    private var buttonStyle: CyberpunkButtonStyle {
        switch quest.status {
        case "available": return .primary
        case "active": return .secondary
        case "completed": return quest.rewardClaimed ? .disabled : .success
        default: return .disabled
        }
    }

    private var canPerformAction: Bool {
        if isProcessing {
            return false
        }

        switch quest.status {
        case "available": return true
        case "active": return false
        case "completed": return !quest.rewardClaimed
        default: return false
        }
    }

    private var rewardDisplayString: String {
        var rewardStrings: [String] = []

        if quest.rewards.money > 0 {
            rewardStrings.append("₩\(quest.rewards.money)")
        }
        if quest.rewards.experience > 0 {
            rewardStrings.append("EXP +\(quest.rewards.experience)")
        }
        if quest.rewards.trustPoints > 0 {
            rewardStrings.append("TRUST +\(quest.rewards.trustPoints)")
        }
        if let items = quest.rewards.items, !items.isEmpty {
            for item in items {
                rewardStrings.append("\(item.itemId) x\(item.quantity)")
            }
        }

        return rewardStrings.isEmpty ? "NO_REWARD" : rewardStrings.joined(separator: " | ")
    }

    private var alertTitle: String {
        switch quest.status {
        case "available": return "ACCEPT_MISSION?"
        case "completed": return "CLAIM_REWARD?"
        default: return "CONFIRM_ACTION"
        }
    }

    private var alertMessage: String {
        switch quest.status {
        case "available": return "Accept mission '\(quest.title)'? Time limit will be enforced."
        case "completed": return "Claim reward: \(rewardDisplayString)"
        default: return ""
        }
    }

    // MARK: - Actions
    private func performAction() {
        isProcessing = true

        Task {
            // UI 피드백을 위한 약간의 지연
            try? await Task.sleep(nanoseconds: 300_000_000)

            await MainActor.run {
                onAction()
                isProcessing = false
            }
        }
    }
}

// MARK: - Mission Status Indicator
struct CyberpunkMissionStatusIndicator: View {
    let isActive: Bool
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 8) {
            // Status LED
            Circle()
                .fill(isActive ? Color.cyberpunkGreen : Color.cyberpunkError)
                .frame(width: 8, height: 8)

            Text(isActive ? "MISSION_SYSTEM_ACTIVE" : "DAILY_LIMIT_REACHED")
                .font(.cyberpunkTechnical())
                .foregroundColor(isActive ? .cyberpunkGreen : .cyberpunkError)

            Spacer()

            // Progress indicator
            Text("\(completedCount)/\(totalCount)")
                .font(.cyberpunkCaption())
                .foregroundColor(.cyberpunkCyan)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .cyberpunkPanel()
        .overlay(
            Rectangle()
                .stroke(isActive ? Color.cyberpunkGreen : Color.cyberpunkError, lineWidth: 1)
        )
    }
}

// MARK: - Cyberpunk Progress Bar for Quests
struct CyberpunkQuestProgressBar: View {
    let currentQuests: Int
    let maxQuests: Int

    private var progress: Double {
        return Double(currentQuests) / Double(maxQuests)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("DAILY_QUEST_PROGRESS")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Spacer()

                Text("\(currentQuests)/\(maxQuests)")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkCyan)
                    .fontWeight(.semibold)
            }

            CyberpunkProgressBar(
                progress: progress,
                color: .cyberpunkGreen,
                height: 6
            )
        }
    }
}
