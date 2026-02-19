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
        HStack(spacing: 0) {
            // 퀘스트 타입 색상 바
            Rectangle()
                .fill(questTypeAccentColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 16) {
                // Quest Header with status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quest.title)
                            .font(.cyberpunkHeading(size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.cyberpunkTextPrimary)

                        Text("분류 · \(quest.category)")
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
                            Text("진행도")
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
                    Text("보상 :")
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
            .padding(CyberpunkLayout.cardPadding)
        }
        .cyberpunkCard()
        .alert(alertTitle, isPresented: $showActionAlert) {
            Button("취소", role: .cancel) { }
            Button("확인") {
                performAction()
            }
        } message: {
            Text(alertMessage)
                .font(.cyberpunkBody())
        }
    }

    // MARK: - Computed Properties
    private var questTypeAccentColor: Color {
        switch quest.category.lowercased() {
        case "dialogue", "대화": return .joseonCheong
        case "delivery", "배달": return .joseonJeok
        case "trading", "거래":  return .joseonHwang
        default: return .cyberpunkBorder
        }
    }

    private var difficultyText: String {
        switch quest.priority {
        case 1: return "쉬움"
        case 2: return "보통"
        case 3...Int.max: return "어려움"
        default: return "알 수 없음"
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
        case "available": return "수락 가능"
        case "active": return "진행중"
        case "completed": return quest.rewardClaimed ? "수령 완료" : "완료"
        default: return "알 수 없음"
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
            return "처리중..."
        }

        switch quest.status {
        case "available": return "의뢰 수락"
        case "active": return "진행중"
        case "completed": return quest.rewardClaimed ? "수령 완료" : "보상 수령"
        default: return "수락 불가"
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

        if let money = quest.rewards.money {
            rewardStrings.append("₩\(money)")
        }
        if let exp = quest.rewards.exp ?? quest.rewards.experience {
            rewardStrings.append("경험치 +\(exp)")
        }
        if let trust = quest.rewards.trustPoints {
            rewardStrings.append("신뢰 +\(trust)")
        }
        if let items = quest.rewards.items, !items.isEmpty {
            for item in items {
                rewardStrings.append("\(item.itemId) x\(item.quantity)")
            }
        }

        return rewardStrings.isEmpty ? "보상 없음" : rewardStrings.joined(separator: " | ")
    }

    private var alertTitle: String {
        switch quest.status {
        case "available": return "의뢰 수락?"
        case "completed": return "보상 수령?"
        default: return "확인"
        }
    }

    private var alertMessage: String {
        switch quest.status {
        case "available": return "'\(quest.title)' 의뢰를 수락하시겠습니까? 제한 시간이 적용됩니다."
        case "completed": return "보상을 수령하시겠습니까? \(rewardDisplayString)"
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

