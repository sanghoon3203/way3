//
//  CyberpunkQuestComponents.swift
//  way3 - Way Trading Game
//
//  사이버펑크 스타일 퀘스트 컴포넌트들
//  기존 QuestView 기능을 완전히 유지하면서 사이버펑크 테마 적용
//

import SwiftUI
import Foundation

// MARK: - Cyberpunk Quest Card
struct CyberpunkQuestCard: View {
    let quest: Quest
    let onAccept: () -> Void
    @State private var showAcceptAlert = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quest Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("MISSION")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkTextSecondary)

                        Rectangle()
                            .fill(Color.cyberpunkYellow)
                            .frame(width: 16, height: 1)

                        Text(quest.name.uppercased())
                            .font(.cyberpunkHeading(size: 16))
                            .foregroundColor(.cyberpunkTextPrimary)
                            .fontWeight(.bold)
                    }

                    Text("LOCATION: \(quest.merchantLocation.uppercased())")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)

                    Text("CLIENT: \(quest.merchantName.uppercased())")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkCyan)
                }

                Spacer()

                // Difficulty Badge
                VStack(spacing: 4) {
                    Text("DIFFICULTY")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)

                    Text(quest.difficulty.rawValue.uppercased())
                        .font(.cyberpunkCaption())
                        .fontWeight(.semibold)
                        .foregroundColor(.cyberpunkTextPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Rectangle()
                                .fill(quest.difficulty.cyberpunkColor.opacity(0.2))
                                .overlay(
                                    Rectangle()
                                        .stroke(quest.difficulty.cyberpunkColor, lineWidth: 1)
                                )
                        )
                }
            }

            // Mission Briefing
            VStack(alignment: .leading, spacing: 8) {
                Text("MISSION_BRIEFING:")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Text(quest.description)
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkTextPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Mission Specs
            VStack(spacing: 4) {
                HStack {
                    Text("TIME_LIMIT:")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)

                    Spacer()

                    Text(formatTimeLimit(quest.timeLimit))
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkYellow)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("REWARD_PACKAGE:")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)

                    Spacer()

                    Text(quest.reward.displayString.uppercased())
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkGreen)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(Color.cyberpunkDarkBg.opacity(0.6))

            // Accept Button
            CyberpunkButton(
                title: "ACCEPT_MISSION",
                style: .primary
            ) {
                showAcceptAlert = true
            }
        }
        .padding(16)
        .cyberpunkCard(isActive: isPressed)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: CGFloat.infinity, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        }, perform: {})
        .alert("MISSION_CONFIRMATION", isPresented: $showAcceptAlert) {
            Button("CANCEL", role: .cancel) { }
            Button("ACCEPT") {
                onAccept()
            }
        } message: {
            Text("Accept mission '\(quest.name.uppercased())'? Time limit will be enforced.")
                .font(.cyberpunkBody())
        }
    }

    private func formatTimeLimit(_ timeLimit: TimeInterval) -> String {
        let hours = Int(timeLimit) / 3600
        return "\(hours)H"
    }
}

// MARK: - Extensions for Quest.QuestDifficulty
extension Quest.QuestDifficulty {
    var cyberpunkColor: Color {
        switch self {
        case .easy:
            return .cyberpunkGreen
        case .normal:
            return .cyberpunkYellow
        case .hard:
            return .cyberpunkError
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
                .animation(CyberpunkAnimations.slowGlow, value: isActive)

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
        .background(Color.cyberpunkPanelBg)
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