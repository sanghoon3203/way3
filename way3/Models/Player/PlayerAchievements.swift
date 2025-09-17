// 📁 Models/Player/PlayerAchievements.swift - 플레이어 업적 관리
import Foundation
import SwiftUI

@MainActor
class PlayerAchievements: ObservableObject, Codable {
    @Published var unlockedAchievements: [Achievement] = []
    @Published var achievementProgress: [String: Int] = [:]
    @Published var totalAchievementPoints: Int = 0

    enum CodingKeys: String, CodingKey {
        case unlockedAchievements, achievementProgress, totalAchievementPoints
    }

    init() {
        // 기본 초기화
    }

    // MARK: - Codable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unlockedAchievements = try container.decode([Achievement].self, forKey: .unlockedAchievements)
        achievementProgress = try container.decode([String: Int].self, forKey: .achievementProgress)
        totalAchievementPoints = try container.decode(Int.self, forKey: .totalAchievementPoints)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(unlockedAchievements, forKey: .unlockedAchievements)
        try container.encode(achievementProgress, forKey: .achievementProgress)
        try container.encode(totalAchievementPoints, forKey: .totalAchievementPoints)
    }

    // MARK: - Achievement Management
    func unlockAchievement(_ achievement: Achievement) {
        guard !unlockedAchievements.contains(where: { $0.id == achievement.id }) else { return }

        unlockedAchievements.append(achievement)
        totalAchievementPoints += 10 // 기본 포인트

        // 업적 해금 알림
        print("🏆 업적 해금: \(achievement.name)")
    }

    func updateProgress(_ achievementId: String, progress: Int) {
        achievementProgress[achievementId] = progress
    }

    func getProgress(_ achievementId: String) -> Int {
        return achievementProgress[achievementId] ?? 0
    }

    var achievementCount: Int {
        return unlockedAchievements.count
    }

    // MARK: - Missing Methods
    func updateTradingMilestone(tradeCount: Int, profit: Int) {
        updateProgress("first_trade", progress: tradeCount)
        updateProgress("money_maker_1", progress: profit)
    }

    func updateExplorationMilestone(locationsVisited: Int, distance: Double) {
        updateProgress("explorer", progress: locationsVisited)
    }

    func checkAchievement(_ achievementId: String) {
        // Check if achievement should be unlocked
        if let progress = achievementProgress[achievementId],
           let achievement = Achievement.sampleAchievements.first(where: { $0.id == achievementId }) {
            if progress >= achievement.conditionValue && !unlockedAchievements.contains(where: { $0.id == achievementId }) {
                unlockAchievement(achievement)
            }
        }
    }

    var completionRate: Double {
        let totalAchievements = Achievement.sampleAchievements.count
        guard totalAchievements > 0 else { return 0.0 }
        return Double(unlockedAchievements.count) / Double(totalAchievements)
    }

    var achievementPoints: Int {
        return totalAchievementPoints
    }
}