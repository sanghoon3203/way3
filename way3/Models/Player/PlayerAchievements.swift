//
//  PlayerAchievements.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 2024-12-26.
//  플레이어 업적 및 스킬 시스템 - 도전 과제, 특수 능력, 마일스톤 관리
//

import Foundation
import SwiftUI

// MARK: - Player Achievements Class
class PlayerAchievements: ObservableObject, Codable {
    // MARK: - 업적 시스템
    @Published var unlockedAchievements: [String] = []
    @Published var achievementProgress: [String: Int] = [:]
    @Published var achievementPoints: Int = 0

    // MARK: - 특수 스킬 시스템
    @Published var specialSkills: [String: SpecialSkill] = [:]
    @Published var activeSkillCooldowns: [String: Date] = [:]

    // MARK: - 수집 시스템
    @Published var collections: [String: Collection] = [:]
    @Published var rareItemsFound: [String] = []

    // MARK: - 마일스톤 시스템
    @Published var tradingMilestones: TradingMilestones = TradingMilestones()
    @Published var explorationMilestones: ExplorationMilestones = ExplorationMilestones()

    // MARK: - 시즌 시스템
    @Published var currentSeason: String = "Season1"
    @Published var seasonProgress: SeasonProgress = SeasonProgress()
    @Published var seasonRewards: [String] = []

    // MARK: - 초기화
    init() {
        initializeDefaultSkills()
        initializeCollections()
    }

    // MARK: - Codable 구현
    enum CodingKeys: String, CodingKey {
        case unlockedAchievements, achievementProgress, achievementPoints
        case specialSkills, activeSkillCooldowns
        case collections, rareItemsFound
        case tradingMilestones, explorationMilestones
        case currentSeason, seasonProgress, seasonRewards
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        unlockedAchievements = try container.decode([String].self, forKey: .unlockedAchievements)
        achievementProgress = try container.decode([String: Int].self, forKey: .achievementProgress)
        achievementPoints = try container.decode(Int.self, forKey: .achievementPoints)
        specialSkills = try container.decode([String: SpecialSkill].self, forKey: .specialSkills)
        activeSkillCooldowns = try container.decode([String: Date].self, forKey: .activeSkillCooldowns)
        collections = try container.decode([String: Collection].self, forKey: .collections)
        rareItemsFound = try container.decode([String].self, forKey: .rareItemsFound)
        tradingMilestones = try container.decode(TradingMilestones.self, forKey: .tradingMilestones)
        explorationMilestones = try container.decode(ExplorationMilestones.self, forKey: .explorationMilestones)
        currentSeason = try container.decode(String.self, forKey: .currentSeason)
        seasonProgress = try container.decode(SeasonProgress.self, forKey: .seasonProgress)
        seasonRewards = try container.decode([String].self, forKey: .seasonRewards)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(unlockedAchievements, forKey: .unlockedAchievements)
        try container.encode(achievementProgress, forKey: .achievementProgress)
        try container.encode(achievementPoints, forKey: .achievementPoints)
        try container.encode(specialSkills, forKey: .specialSkills)
        try container.encode(activeSkillCooldowns, forKey: .activeSkillCooldowns)
        try container.encode(collections, forKey: .collections)
        try container.encode(rareItemsFound, forKey: .rareItemsFound)
        try container.encode(tradingMilestones, forKey: .tradingMilestones)
        try container.encode(explorationMilestones, forKey: .explorationMilestones)
        try container.encode(currentSeason, forKey: .currentSeason)
        try container.encode(seasonProgress, forKey: .seasonProgress)
        try container.encode(seasonRewards, forKey: .seasonRewards)
    }

    private func initializeDefaultSkills() {
        // 기본 특수 스킬들 초기화
        specialSkills = [
            "keen_eye": SpecialSkill(id: "keen_eye", name: "예리한 눈", level: 1, cooldown: 3600),
            "silver_tongue": SpecialSkill(id: "silver_tongue", name: "달변", level: 1, cooldown: 7200),
            "lucky_charm": SpecialSkill(id: "lucky_charm", name: "행운의 부적", level: 1, cooldown: 10800)
        ]
    }

    private func initializeCollections() {
        // 기본 수집 항목들 초기화
        collections = [
            "rare_gems": Collection(id: "rare_gems", name: "희귀 보석", description: "희귀한 보석들을 수집하세요"),
            "ancient_artifacts": Collection(id: "ancient_artifacts", name: "고대 유물", description: "고대의 신비로운 유물들"),
            "exotic_spices": Collection(id: "exotic_spices", name: "이국적 향신료", description: "세계 각지의 특별한 향신료들")
        ]
    }
}

// MARK: - 업적 관리 메서드
extension PlayerAchievements {
    // 업적 달성 확인 및 처리
    func checkAchievement(_ achievementId: String) -> Bool {
        guard !unlockedAchievements.contains(achievementId) else { return false }

        if let achievement = AchievementDatabase.achievements[achievementId],
           achievement.isCompleted(with: self) {
            unlockAchievement(achievementId)
            return true
        }
        return false
    }

    // 업적 해금
    private func unlockAchievement(_ achievementId: String) {
        unlockedAchievements.append(achievementId)

        if let achievement = AchievementDatabase.achievements[achievementId] {
            achievementPoints += achievement.points

            // 업적 보상 지급
            grantAchievementReward(achievement.reward)
        }
    }

    // 업적 진행도 업데이트
    func updateProgress(for achievementId: String, increment: Int = 1) {
        achievementProgress[achievementId, default: 0] += increment

        // 업적 달성 확인
        checkAchievement(achievementId)
    }

    // 업적 보상 지급
    private func grantAchievementReward(_ reward: AchievementReward) {
        switch reward {
        case .points(let amount):
            achievementPoints += amount
        case .skill(let skillId):
            unlockSpecialSkill(skillId)
        case .item(let itemId):
            // 아이템 보상은 인벤토리 시스템과 연동 필요
            print("아이템 보상 획득: \(itemId)")
        case .title(let title):
            // 타이틀 시스템과 연동
            print("타이틀 획득: \(title)")
        }
    }

    // 업적 완료율
    var completionRate: Double {
        let totalAchievements = AchievementDatabase.achievements.count
        guard totalAchievements > 0 else { return 0.0 }
        return Double(unlockedAchievements.count) / Double(totalAchievements)
    }
}

// MARK: - 특수 스킬 관리 메서드
extension PlayerAchievements {
    // 특수 스킬 해금
    func unlockSpecialSkill(_ skillId: String) {
        if specialSkills[skillId] == nil,
           let skillTemplate = SpecialSkillDatabase.skills[skillId] {
            specialSkills[skillId] = skillTemplate
        }
    }

    // 특수 스킬 사용
    func useSpecialSkill(_ skillId: String) -> Bool {
        guard let skill = specialSkills[skillId],
              canUseSkill(skillId) else { return false }

        // 쿨다운 설정
        let cooldownEnd = Date().addingTimeInterval(TimeInterval(skill.cooldown))
        activeSkillCooldowns[skillId] = cooldownEnd

        // 스킬 효과 적용
        applySkillEffect(skill)

        return true
    }

    // 스킬 사용 가능 여부 확인
    func canUseSkill(_ skillId: String) -> Bool {
        if let cooldownEnd = activeSkillCooldowns[skillId] {
            return Date() >= cooldownEnd
        }
        return true
    }

    // 스킬 쿨다운 시간
    func getSkillCooldownRemaining(_ skillId: String) -> TimeInterval {
        guard let cooldownEnd = activeSkillCooldowns[skillId] else { return 0 }
        return max(0, cooldownEnd.timeIntervalSince(Date()))
    }

    // 스킬 효과 적용
    private func applySkillEffect(_ skill: SpecialSkill) {
        switch skill.id {
        case "keen_eye":
            // 아이템 감정 능력 향상 (일정 시간)
            print("예리한 눈 스킬 활성화 - 아이템 가치 파악 능력 향상")
        case "silver_tongue":
            // 거래 가격 개선 (일정 시간)
            print("달변 스킬 활성화 - 거래 가격 10% 개선")
        case "lucky_charm":
            // 희귀 아이템 발견율 증가 (일정 시간)
            print("행운의 부적 활성화 - 희귀 아이템 발견율 증가")
        default:
            break
        }
    }

    // 스킬 레벨업
    func upgradeSkill(_ skillId: String) -> Bool {
        guard var skill = specialSkills[skillId],
              skill.level < skill.maxLevel else { return false }

        skill.level += 1
        specialSkills[skillId] = skill
        return true
    }
}

// MARK: - 수집 시스템 메서드
extension PlayerAchievements {
    // 아이템 수집
    func collectItem(_ itemId: String, collectionId: String) {
        guard var collection = collections[collectionId] else { return }

        if !collection.collectedItems.contains(itemId) {
            collection.collectedItems.append(itemId)
            collections[collectionId] = collection

            // 희귀 아이템 체크
            if ItemDatabase.isRareItem(itemId) {
                rareItemsFound.append(itemId)
                updateProgress(for: "rare_collector")
            }

            // 수집 관련 업적 체크
            checkCollectionAchievements(collectionId)
        }
    }

    // 수집 완성도
    func getCollectionCompletion(_ collectionId: String) -> Double {
        guard let collection = collections[collectionId] else { return 0.0 }
        let totalItems = ItemDatabase.getCollectionItems(collectionId).count
        guard totalItems > 0 else { return 0.0 }
        return Double(collection.collectedItems.count) / Double(totalItems)
    }

    // 수집 관련 업적 체크
    private func checkCollectionAchievements(_ collectionId: String) {
        let completion = getCollectionCompletion(collectionId)

        if completion >= 0.5 {
            updateProgress(for: "\(collectionId)_half_complete")
        }

        if completion >= 1.0 {
            updateProgress(for: "\(collectionId)_complete")
        }
    }
}

// MARK: - 마일스톤 관리 메서드
extension PlayerAchievements {
    // 거래 마일스톤 업데이트
    func updateTradingMilestone(tradeCount: Int, profit: Int) {
        tradingMilestones.totalTrades += tradeCount
        tradingMilestones.totalProfit += profit

        // 마일스톤 달성 체크
        checkTradingMilestones()
    }

    // 탐험 마일스톤 업데이트
    func updateExplorationMilestone(locationsVisited: Int, distance: Double) {
        explorationMilestones.locationsVisited += locationsVisited
        explorationMilestones.totalDistance += distance

        // 마일스톤 달성 체크
        checkExplorationMilestones()
    }

    private func checkTradingMilestones() {
        let milestones = [
            (100, "first_hundred_trades"),
            (1000, "thousand_trades"),
            (10000, "trading_master")
        ]

        for (threshold, achievementId) in milestones {
            if tradingMilestones.totalTrades >= threshold {
                checkAchievement(achievementId)
            }
        }
    }

    private func checkExplorationMilestones() {
        let milestones = [
            (10, "explorer"),
            (50, "world_traveler"),
            (100, "globe_trotter")
        ]

        for (threshold, achievementId) in milestones {
            if explorationMilestones.locationsVisited >= threshold {
                checkAchievement(achievementId)
            }
        }
    }
}

// MARK: - 시즌 시스템 메서드
extension PlayerAchievements {
    // 시즌 진행도 업데이트
    func updateSeasonProgress(experience: Int) {
        seasonProgress.currentXP += experience

        // 레벨업 체크
        while seasonProgress.currentXP >= seasonProgress.xpToNextLevel {
            levelUpSeason()
        }
    }

    // 시즌 레벨업
    private func levelUpSeason() {
        seasonProgress.currentXP -= seasonProgress.xpToNextLevel
        seasonProgress.currentLevel += 1
        seasonProgress.xpToNextLevel = calculateNextLevelXP(seasonProgress.currentLevel)

        // 시즌 보상 지급
        grantSeasonReward(seasonProgress.currentLevel)
    }

    // 시즌 보상 지급
    private func grantSeasonReward(_ level: Int) {
        let rewardId = "season_\(currentSeason)_level_\(level)"
        seasonRewards.append(rewardId)

        // 보상 내용은 게임 밸런스에 따라 결정
        print("시즌 보상 획득: 레벨 \(level)")
    }

    private func calculateNextLevelXP(_ level: Int) -> Int {
        return level * 1000 + (level - 1) * 200 // 점진적 증가
    }

    // 시즌 리셋
    func resetSeason(_ newSeason: String) {
        currentSeason = newSeason
        seasonProgress = SeasonProgress()
        seasonRewards = []
    }
}

// MARK: - 지원 구조체들
struct SpecialSkill: Identifiable, Codable {
    let id: String
    let name: String
    var level: Int
    let maxLevel: Int = 10
    let cooldown: Int // 초 단위
    let description: String

    init(id: String, name: String, level: Int = 1, cooldown: Int, description: String = "") {
        self.id = id
        self.name = name
        self.level = level
        self.cooldown = cooldown
        self.description = description
    }

    var isMaxLevel: Bool {
        return level >= maxLevel
    }
}

struct Collection: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    var collectedItems: [String] = []

    var completionRate: Double {
        let totalItems = ItemDatabase.getCollectionItems(id).count
        guard totalItems > 0 else { return 0.0 }
        return Double(collectedItems.count) / Double(totalItems)
    }
}

struct TradingMilestones: Codable {
    var totalTrades: Int = 0
    var totalProfit: Int = 0
    var bestSingleTrade: Int = 0
    var consecutiveProfitableTrades: Int = 0
}

struct ExplorationMilestones: Codable {
    var locationsVisited: Int = 0
    var totalDistance: Double = 0.0
    var uniqueRegionsExplored: Int = 0
    var hiddenLocationFound: Int = 0
}

struct SeasonProgress: Codable {
    var currentLevel: Int = 1
    var currentXP: Int = 0
    var xpToNextLevel: Int = 1000
}

// MARK: - 업적 데이터베이스 (예시)
struct AchievementDatabase {
    static let achievements: [String: Achievement] = [
        "first_trade": Achievement(
            id: "first_trade",
            name: "첫 거래",
            description: "첫 번째 거래를 완료하세요",
            points: 10,
            requirement: .tradeCount(1),
            reward: .points(10)
        ),
        "hundred_trades": Achievement(
            id: "hundred_trades",
            name: "거래왕",
            description: "100번의 거래를 완료하세요",
            points: 100,
            requirement: .tradeCount(100),
            reward: .skill("master_trader")
        ),
        "rare_collector": Achievement(
            id: "rare_collector",
            name: "희귀품 수집가",
            description: "희귀 아이템 10개를 발견하세요",
            points: 50,
            requirement: .rareItemCount(10),
            reward: .item("rare_detector")
        )
    ]
}

struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let points: Int
    let requirement: AchievementRequirement
    let reward: AchievementReward

    func isCompleted(with achievements: PlayerAchievements) -> Bool {
        switch requirement {
        case .tradeCount(let count):
            return achievements.tradingMilestones.totalTrades >= count
        case .rareItemCount(let count):
            return achievements.rareItemsFound.count >= count
        case .collectionComplete(let collectionId):
            return achievements.getCollectionCompletion(collectionId) >= 1.0
        }
    }
}

enum AchievementRequirement: Codable {
    case tradeCount(Int)
    case rareItemCount(Int)
    case collectionComplete(String)
}

enum AchievementReward: Codable {
    case points(Int)
    case skill(String)
    case item(String)
    case title(String)
}

// MARK: - 스킬 데이터베이스 (예시)
struct SpecialSkillDatabase {
    static let skills: [String: SpecialSkill] = [
        "keen_eye": SpecialSkill(
            id: "keen_eye",
            name: "예리한 눈",
            cooldown: 3600,
            description: "아이템의 진정한 가치를 파악합니다"
        ),
        "silver_tongue": SpecialSkill(
            id: "silver_tongue",
            name: "달변",
            cooldown: 7200,
            description: "거래 가격을 유리하게 조정합니다"
        ),
        "lucky_charm": SpecialSkill(
            id: "lucky_charm",
            name: "행운의 부적",
            cooldown: 10800,
            description: "희귀 아이템 발견 확률을 증가시킵니다"
        )
    ]
}

// MARK: - 아이템 데이터베이스 (예시)
struct ItemDatabase {
    static func isRareItem(_ itemId: String) -> Bool {
        // 실제 구현에서는 데이터베이스 조회
        return itemId.contains("rare") || itemId.contains("legendary")
    }

    static func getCollectionItems(_ collectionId: String) -> [String] {
        // 실제 구현에서는 데이터베이스 조회
        switch collectionId {
        case "rare_gems":
            return ["ruby", "sapphire", "emerald", "diamond", "pearl"]
        case "ancient_artifacts":
            return ["ancient_coin", "pottery", "sculpture", "manuscript", "relic"]
        case "exotic_spices":
            return ["saffron", "cardamom", "cinnamon", "vanilla", "black_pepper"]
        default:
            return []
        }
    }
}