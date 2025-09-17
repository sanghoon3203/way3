//
//  Player.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 2024-12-26.
//  통합 플레이어 모델 - 모듈별로 분리된 컴포넌트들의 통합 관리
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Main Player Class (Unified Interface)
@MainActor
class Player: ObservableObject, Codable {
    // MARK: - Component References
    @Published var core: PlayerCore
    @Published var stats: PlayerStats
    @Published var inventory: PlayerInventory
    @Published var relationships: PlayerRelationships
    @Published var achievements: PlayerAchievements

    // MARK: - Game State (High-level state that affects all components)
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentDistrict: String = "서울 중구"
    @Published var gameMode: GameMode = .exploration
    @Published var isOnline: Bool = false
    @Published var lastSaveTime: Date = Date()

    // MARK: - Session Data (Runtime only, not saved)
    @Published var sessionStartTime: Date = Date()
    @Published var todayPlayTime: TimeInterval = 0

    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        name: String = "",
        email: String? = nil
    ) {
        self.core = PlayerCore(id: id, userId: userId, name: name, email: email)
        self.stats = PlayerStats()
        self.inventory = PlayerInventory()
        self.relationships = PlayerRelationships()
        self.achievements = PlayerAchievements() // @MainActor 초기화
    }

    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case core, stats, inventory, relationships, achievements
        case currentLocation, currentDistrict, gameMode, isOnline, lastSaveTime
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        core = try container.decode(PlayerCore.self, forKey: .core)
        stats = try container.decode(PlayerStats.self, forKey: .stats)
        inventory = try container.decode(PlayerInventory.self, forKey: .inventory)
        relationships = try container.decode(PlayerRelationships.self, forKey: .relationships)
        achievements = try container.decode(PlayerAchievements.self, forKey: .achievements)

        // Location handling
        if let locationData = try container.decodeIfPresent(Data.self, forKey: .currentLocation) {
            let location = try JSONDecoder().decode(LocationData.self, from: locationData)
            currentLocation = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
        }

        currentDistrict = try container.decode(String.self, forKey: .currentDistrict)
        gameMode = try container.decode(GameMode.self, forKey: .gameMode)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        lastSaveTime = try container.decode(Date.self, forKey: .lastSaveTime)

        // Runtime data initialization
        sessionStartTime = Date()
        todayPlayTime = 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(core, forKey: .core)
        try container.encode(stats, forKey: .stats)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(achievements, forKey: .achievements)

        // Location handling
        if let location = currentLocation {
            let locationData = LocationData(lat: location.latitude, lng: location.longitude)
            let data = try JSONEncoder().encode(locationData)
            try container.encode(data, forKey: .currentLocation)
        }

        try container.encode(currentDistrict, forKey: .currentDistrict)
        try container.encode(gameMode, forKey: .gameMode)
        try container.encode(isOnline, forKey: .isOnline)
        try container.encode(lastSaveTime, forKey: .lastSaveTime)
    }
}

// MARK: - Unified Player Actions (High-level operations that coordinate between components)
extension Player {
    // MARK: - Trading Operations
    func performTrade(with merchantId: String, item: TradeItem, tradeType: TradeType, finalPrice: Int) -> PlayerTradeResult {
        // 1. 자금 확인 (매수인 경우)
        if tradeType == .buy && !core.canAfford(finalPrice) {
            return .failure(.insufficientFunds)
        }

        // 2. 인벤토리 공간 확인 (매수인 경우)
        if tradeType == .buy && inventory.isFull {
            return .failure(.inventoryFull)
        }

        // 3. 아이템 존재 확인 (매도인 경우)
        if tradeType == .sell && inventory.findItem(by: item.id) == nil {
            return .failure(.itemNotFound)
        }

        // 4. 거래 실행
        switch tradeType {
        case .buy:
            if core.spendMoney(finalPrice) && inventory.addItem(item) {
                processSuccessfulTrade(merchantId: merchantId, item: item, tradeType: tradeType, amount: finalPrice)
                return .success(finalPrice)
            }
        case .sell:
            if inventory.removeItem(item) {
                core.earnMoney(finalPrice)
                processSuccessfulTrade(merchantId: merchantId, item: item, tradeType: tradeType, amount: finalPrice)
                return .success(finalPrice)
            }
        case .exchange:
            // 교환 로직 (더 복잡한 구현 필요)
            break
        }

        return .failure(.unknown)
    }

    private func processSuccessfulTrade(merchantId: String, item: TradeItem, tradeType: TradeType, amount: Int) {
        // 경험치 획득
        let expGain = amount / 100
        core.gainExperience(expGain)

        // 스킬 향상
        stats.improveSkill(.trading, by: 1)
        if tradeType == .buy {
            stats.improveSkill(.negotiation, by: 1)
        }

        // 상인 관계 기록
        let satisfaction = calculateTradeSatisfaction(item: item, finalPrice: amount, tradeType: tradeType)
        relationships.recordTrade(with: merchantId, itemName: item.name, tradeType: tradeType, amount: amount, satisfaction: satisfaction)

        // 업적 진행도 업데이트
        achievements.updateTradingMilestone(tradeCount: 1, profit: tradeType == .sell ? amount - item.basePrice : 0)
        achievements.updateProgress("first_trade", progress: 1)

        if relationships.tradeHistory.count >= 100 {
            achievements.checkAchievement("hundred_trades")
        }
    }

    private func calculateTradeSatisfaction(item: TradeItem, finalPrice: Int, tradeType: TradeType) -> Int {
        let fairPrice = item.basePrice
        let priceRatio = Double(finalPrice) / Double(fairPrice)

        switch tradeType {
        case .buy:
            // 매수 시: 저렴하게 살수록 만족도 높음
            if priceRatio <= 0.8 { return 5 }
            else if priceRatio <= 0.9 { return 4 }
            else if priceRatio <= 1.1 { return 3 }
            else if priceRatio <= 1.2 { return 2 }
            else { return 1 }
        case .sell:
            // 매도 시: 비싸게 팔수록 만족도 높음
            if priceRatio >= 1.2 { return 5 }
            else if priceRatio >= 1.1 { return 4 }
            else if priceRatio >= 0.9 { return 3 }
            else if priceRatio >= 0.8 { return 2 }
            else { return 1 }
        case .exchange:
            return 3 // 중립
        }
    }
}

// MARK: - Location & Movement
extension Player {
    func updateLocation(_ coordinate: CLLocationCoordinate2D, district: String) {
        currentLocation = coordinate
        currentDistrict = district

        // 탐험 마일스톤 업데이트 (거리 계산은 실제 구현에서)
        achievements.updateExplorationMilestone(locationsVisited: 1, distance: 0.0)

        // 위치 기반 업적 체크
        achievements.updateProgress("explorer", progress: 1)
    }

    func changeGameMode(_ newMode: GameMode) {
        gameMode = newMode

        // 게임 모드에 따른 효과 적용
        switch newMode {
        case .exploration:
            break
        case .trading:
            // 거래 모드 특수 효과
            break
        case .social:
            // 소셜 모드 특수 효과
            break
        }
    }
}

// MARK: - Character Development
extension Player {
    // 스탯 포인트 할당 (통합 관리)
    func allocateStatPoint(to stat: StatType) -> Bool {
        guard core.statPoints > 0 else { return false }

        if stats.allocateStatPoint(to: stat) {
            core.statPoints -= 1

            // 스탯 변경에 따른 인벤토리 용량 업데이트
            if stat == .strength {
                inventory.maxInventorySize = 5 + stats.carryingCapacity - 5
            }

            return true
        }

        return false
    }

    // 스킬 포인트 사용
    func useSkillPoint(for skill: SkillType) -> Bool {
        guard core.skillPoints > 0 else { return false }

        stats.improveSkill(skill, by: 5) // 스킬 포인트로 더 많은 향상
        core.skillPoints -= 1

        return true
    }

    // 종합 능력치 계산
    var overallPower: Int {
        let statPower = stats.totalStatPoints / 4
        let skillPower = Int(stats.averageSkillLevel)
        let equipmentPower = inventory.totalEquipmentStats.values.reduce(0, +)
        let achievementPower = achievements.achievementPoints / 10

        return statPower + skillPower + equipmentPower + achievementPower
    }
}

// MARK: - Session Management
extension Player {
    func startSession() {
        sessionStartTime = Date()
        isOnline = true

        // 일일 리셋 체크
        checkDailyReset()
    }

    func endSession() {
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        core.addPlayTime(sessionDuration)
        todayPlayTime += sessionDuration

        isOnline = false
        lastSaveTime = Date()
    }

    private func checkDailyReset() {
        let calendar = Calendar.current
        let today = Date()

        if !calendar.isDate(lastSaveTime, inSameDayAs: today) {
            // 새로운 날 - 일일 플레이 시간 리셋
            core.resetDailyPlayTime()
            todayPlayTime = 0

            // 일일 업적 리셋 등...
        }
    }

    // 자동 저장 주기 체크
    var needsAutoSave: Bool {
        let autoSaveInterval: TimeInterval = 300 // 5분
        return Date().timeIntervalSince(lastSaveTime) >= autoSaveInterval
    }
}

// MARK: - Social Features Integration
extension Player {
    // 친구와 아이템 공유
    func shareItemWithFriend(_ itemId: String, friendId: String) -> Bool {
        guard let item = inventory.findItem(by: itemId),
              relationships.friends.contains(where: { $0.playerId == friendId }) else {
            return false
        }

        if inventory.removeItem(item) {
            // 실제로는 서버를 통해 친구에게 전송
            achievements.updateProgress("generous_trader", progress: 1)
            return true
        }

        return false
    }

    // 길드 혜택 적용
    func applyGuildBenefits() -> (tradeBonus: Double, storageBonus: Int, expBonus: Double) {
        if let benefits = relationships.guildBenefits {
            return (benefits.tradeBonus, benefits.storageBonus, benefits.experienceBonus)
        }
        return (0.0, 0, 0.0)
    }
}

// MARK: - Analytics & Metrics
extension Player {
    // 플레이어 통계 요약
    var playerSummary: PlayerSummary {
        return PlayerSummary(
            level: core.level,
            totalPlayTime: core.formattedTotalPlayTime,
            totalTrades: relationships.tradeHistory.count,
            achievementsUnlocked: achievements.unlockedAchievements.count,
            overallPower: overallPower,
            trustLevel: relationships.trustLevel,
            guildName: relationships.guildMembership?.guildName
        )
    }

    // 진행도 분석
    var progressAnalysis: ProgressAnalysis {
        return ProgressAnalysis(
            levelProgress: core.levelProgress,
            achievementCompletion: achievements.completionRate,
            skillAverageLevel: stats.averageSkillLevel,
            inventoryUtilization: Double(inventory.inventory.count) / Double(inventory.maxInventorySize),
            relationshipScore: Double(relationships.merchantRelationships.values.map { $0.relationshipScore }.reduce(0, +))
        )
    }
}

// MARK: - Support Structures
// LocationData는 APIResponse.swift에 정의됨

enum GameMode: String, Codable {
    case exploration = "exploration"
    case trading = "trading"
    case social = "social"

    var displayName: String {
        switch self {
        case .exploration: return "탐험"
        case .trading: return "거래"
        case .social: return "소셜"
        }
    }
}

enum PlayerTradeResult {
    case success(Int)
    case failure(TradeError)
}

enum TradeError {
    case insufficientFunds
    case inventoryFull
    case itemNotFound
    case unknown

    var localizedDescription: String {
        switch self {
        case .insufficientFunds: return "자금이 부족합니다"
        case .inventoryFull: return "인벤토리가 가득 찼습니다"
        case .itemNotFound: return "아이템을 찾을 수 없습니다"
        case .unknown: return "알 수 없는 오류가 발생했습니다"
        }
    }
}

struct PlayerSummary {
    let level: Int
    let totalPlayTime: String
    let totalTrades: Int
    let achievementsUnlocked: Int
    let overallPower: Int
    let trustLevel: TrustLevel
    let guildName: String?
}

struct ProgressAnalysis {
    let levelProgress: Double
    let achievementCompletion: Double
    let skillAverageLevel: Double
    let inventoryUtilization: Double
    let relationshipScore: Double
}

// MARK: - Player Extensions for Legacy Compatibility
extension Player {
    // 기존 코드와의 호환성을 위한 convenience 프로퍼티들
    var id: String { core.id }
    var userId: String? { core.userId }
    var name: String {
        get { core.name }
        set { core.name = newValue }
    }
    var email: String? {
        get { core.email }
        set { core.email = newValue }
    }
    var money: Int {
        get { core.money }
        set { core.money = newValue }
    }
    var level: Int { core.level }
    var experience: Int { core.experience }
    var reputation: Int { relationships.reputationScore }
    var currentLicense: LicenseLevel { core.currentLicense }

    // 자주 사용되는 메서드들의 convenience wrapper
    func gainExperience(_ amount: Int) {
        core.gainExperience(amount)
    }

    func earnMoney(_ amount: Int) {
        core.earnMoney(amount)
    }

    func spendMoney(_ amount: Int) -> Bool {
        return core.spendMoney(amount)
    }

    func canAfford(_ amount: Int) -> Bool {
        return core.canAfford(amount)
    }

    // 기본 플레이어 인스턴스 생성 (기존 코드 호환성)
    static func createDefault() -> Player {
        return Player()
    }
}