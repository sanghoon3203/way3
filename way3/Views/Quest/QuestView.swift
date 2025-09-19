//
//  QuestView.swift
//  way3
//
//  Created by Claude on 17/09/2025.
//  오늘의 퀘스트 시스템 - 근처 상인 기반 랜덤 퀘스트
//

import SwiftUI

// MARK: - Quest Model
struct Quest: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let reward: QuestReward
    let merchantName: String
    let merchantLocation: String
    let difficulty: QuestDifficulty
    let timeLimit: TimeInterval // seconds
    let isAccepted: Bool

    enum QuestDifficulty: String, CaseIterable, Codable {
        case easy = "쉬움"
        case normal = "보통"
        case hard = "어려움"

        var color: Color {
            switch self {
            case .easy: return .green
            case .normal: return .orange
            case .hard: return .red
            }
        }
    }
}

struct QuestReward: Codable {
    let money: Int
    let experience: Int
    let items: [String] // 아이템 이름들

    var displayString: String {
        var rewards: [String] = []
        if money > 0 {
            rewards.append("₩\(money)")
        }
        if experience > 0 {
            rewards.append("경험치 \(experience)")
        }
        if !items.isEmpty {
            rewards.append(contentsOf: items)
        }
        return rewards.joined(separator: ", ")
    }
}

// MARK: - Quest Manager
class QuestManager: ObservableObject {
    static let shared = QuestManager()

    @Published var currentQuests: [Quest] = []
    @Published var dailyQuestCount: Int = 0
    @Published var lastQuestRefreshTime: Date = Date()
    @Published var nextRefreshTime: Date = Date()

    private let maxDailyQuests = 3
    private let questRefreshInterval: TimeInterval = 3 * 60 * 60 // 3시간

    private init() {
        loadQuestsFromServer()
    }

    func loadQuestsFromServer() {
        // 실제 서버에서 근처 상인 기반 퀘스트 불러오기
        // 현재는 샘플 데이터 사용
        generateSampleQuests()
    }

    private func generateSampleQuests() {
        let sampleQuests = [
            Quest(
                name: "고급 차잎 배송",
                description: "동대문시장의 김상인에게 고급 차잎 10개를 배송하세요.",
                reward: QuestReward(money: 50000, experience: 100, items: ["희귀한 차도구"]),
                merchantName: "김상인",
                merchantLocation: "동대문시장",
                difficulty: .normal,
                timeLimit: 2 * 60 * 60, // 2시간
                isAccepted: false
            ),
            Quest(
                name: "전통 약재 수집",
                description: "인근 약국을 방문하여 전통 약재 5종을 수집해 오세요.",
                reward: QuestReward(money: 75000, experience: 150, items: ["신비한 약초", "건강 물약"]),
                merchantName: "한약상",
                merchantLocation: "종로 한약방",
                difficulty: .hard,
                timeLimit: 4 * 60 * 60, // 4시간
                isAccepted: false
            ),
            Quest(
                name: "서울 특산품 홍보",
                description: "명동에서 서울 특산품을 3명 이상에게 소개하고 판매하세요.",
                reward: QuestReward(money: 30000, experience: 80, items: ["홍보 배지"]),
                merchantName: "박상인",
                merchantLocation: "명동 상점가",
                difficulty: .easy,
                timeLimit: 1 * 60 * 60, // 1시간
                isAccepted: false
            )
        ]

        currentQuests = Array(sampleQuests.shuffled().prefix(2))
        updateRefreshTimer()
    }

    func refreshQuests() {
        generateSampleQuests()
        lastQuestRefreshTime = Date()
    }

    func canAcceptQuest() -> Bool {
        return dailyQuestCount < maxDailyQuests
    }

    func acceptQuest(_ quest: Quest) {
        if canAcceptQuest() {
            dailyQuestCount += 1
            // TODO: 서버에 퀘스트 수락 전송
        }
    }

    private func updateRefreshTimer() {
        nextRefreshTime = lastQuestRefreshTime.addingTimeInterval(questRefreshInterval)
    }

    func timeUntilRefresh() -> String {
        let now = Date()
        let timeRemaining = nextRefreshTime.timeIntervalSince(now)

        if timeRemaining <= 0 {
            return "새로고침 가능"
        }

        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Quest Box Component
struct QuestBoxView: View {
    let quest: Quest
    let onAccept: () -> Void
    @State private var showAcceptAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quest Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.name)
                        .font(.chosunH3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(quest.merchantLocation)
                        .font(.chosunCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Difficulty Badge
                Text(quest.difficulty.rawValue)
                    .font(.chosunSmall)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(quest.difficulty.color)
                    )
            }

            // Quest Description
            Text(quest.description)
                .font(.chosunBody)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Reward Info
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))

                Text("보상:")
                    .font(.chosunCaption)
                    .foregroundColor(.secondary)

                Text(quest.reward.displayString)
                    .font(.chosunCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .lineLimit(1)
            }

            // Accept Button
            Button(action: {
                showAcceptAlert = true
            }) {
                Text("수락")
                    .font(.chosunButton)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            }
            .alert("\(quest.name)을 수락하시겠습니까?", isPresented: $showAcceptAlert) {
                Button("아니오", role: .cancel) { }
                Button("예") {
                    onAccept()
                }
            } message: {
                Text("퀘스트를 수락하면 제한 시간 내에 완료해야 합니다.")
            }
        }
        .padding(16)
        .frame(width: 320, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Main Quest View
struct QuestView: View {
    @StateObject private var questManager = QuestManager.shared
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
                            subtitle: "DAILY_QUEST_SYSTEM_V3.2",
                            rightContent: "REFRESH: \(questManager.timeUntilRefresh())"
                        )
                        .padding(.top, 10)

                        // Daily Quest Progress - 사이버펑크 스타일
                        CyberpunkStatusPanel(
                            title: "DAILY_PROGRESS",
                            statusItems: [
                                ("COMPLETED", "\(questManager.dailyQuestCount)/3", .cyberpunkGreen),
                                ("STATUS", questManager.canAcceptQuest() ? "ACTIVE" : "LIMIT_REACHED", questManager.canAcceptQuest() ? .cyberpunkGreen : .cyberpunkError),
                                ("RESET_TIME", "00:00 KST", .cyberpunkCyan)
                            ]
                        )
                        .padding(.horizontal, CyberpunkLayout.screenPadding)

                        // Quest Cards - 사이버펑크 스타일
                        LazyVStack(spacing: 16) {
                            ForEach(questManager.currentQuests) { quest in
                                CyberpunkQuestCard(quest: quest) {
                                    if questManager.canAcceptQuest() {
                                        questManager.acceptQuest(quest)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, CyberpunkLayout.screenPadding)

                        // Refresh Button (if refresh time passed) - 사이버펑크 스타일
                        if questManager.timeUntilRefresh() == "새로고침 가능" {
                            CyberpunkButton(
                                title: "REFRESH_MISSIONS",
                                style: .primary
                            ) {
                                questManager.refreshQuests()
                            }
                            .padding(.horizontal, CyberpunkLayout.screenPadding)
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
        }
        .onDisappear {
            stopTimer()
        }
    }

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

#Preview {
    QuestView()
}