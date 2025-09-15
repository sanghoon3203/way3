// 📁 Models/Player.swift - 확장된 버전
import Foundation
import UIKit
import CoreLocation

// MARK: - Supporting Types
enum EquipmentSlot: CaseIterable, Codable {
    case head, chest, legs, feet, weapon, accessory
}

struct EquipmentItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let slot: EquipmentSlot
    let stats: [String: Int]
}

struct Property: Identifiable, Codable {
    let id = UUID()
    let name: String
    let location: String
    let value: Int
}

struct Vehicle: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: String
    let capacity: Int
}

struct Pet: Identifiable, Codable {
    let id = UUID()
    let name: String
    let species: String
    let level: Int
}

class Player: ObservableObject, Codable {
    // MARK: - 기본 정보
    @Published var id: String
    @Published var userId: String?
    @Published var name: String = ""
    @Published var email: String?
    
    // MARK: - 게임 기본 스탯
    @Published var money: Int = 50000
    @Published var trustPoints: Int = 0
    @Published var reputation: Int = 0
    @Published var currentLicense: LicenseLevel = .beginner
    @Published var maxInventorySize: Int = 5
    
    // MARK: - 캐릭터 레벨 시스템
    @Published var level: Int = 1
    @Published var experience: Int = 0
    @Published var statPoints: Int = 0
    @Published var skillPoints: Int = 0
    
    // MARK: - 캐릭터 스탯
    @Published var strength: Int = 10        // 힘 (무거운 아이템 운반)
    @Published var intelligence: Int = 10    // 지능 (아이템 감정, 시장 분석)
    @Published var charisma: Int = 10       // 매력 (거래 가격, 상인 친밀도)
    @Published var luck: Int = 10           // 행운 (희귀 아이템 발견, 크리티컬)
    
    // MARK: - 거래 기술
    @Published var tradingSkill: Int = 1     // 거래 기술
    @Published var negotiationSkill: Int = 1 // 협상 기술
    @Published var appraisalSkill: Int = 1   // 감정 기술
    
    // MARK: - 인벤토리 시스템 (분리)
    @Published var inventory: [TradeItem] = []                    // 거래품 인벤토리
    @Published var equippedItems: [EquipmentSlot: EquipmentItem] = [:]  // 착용품
    @Published var equipmentStorage: [EquipmentItem] = []         // 착용품 창고
    @Published var storageItems: [TradeItem] = []                 // 거래품 창고
    @Published var maxStorageSize: Int = 50
    
    // MARK: - 소유 자산
    @Published var ownedProperties: [Property] = []
    @Published var vehicles: [Vehicle] = []
    @Published var pets: [Pet] = []
    
    // MARK: - 스킬 시스템
    @Published var learnedSkills: Set<String> = []
    @Published var activeSkillEffects: [SkillEffect] = []
    
    // MARK: - 캐릭터 외형
    @Published var appearance: CharacterAppearance = CharacterAppearance()
    @Published var cosmetics: [CharacterCosmetic] = []
    
    // MARK: - 위치 정보
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var lastKnownLocation: CLLocationCoordinate2D?
    @Published var homeLocation: CLLocationCoordinate2D?
    
    // MARK: - 관계 시스템
    @Published var merchantRelationships: [String: MerchantRelationship] = [:]
    @Published var guildMembership: GuildMembership?
    
    // MARK: - 업적 시스템
    @Published var achievements: [PlayerAchievement] = []
    @Published var completedAchievements: Set<String> = []
    
    // MARK: - 거래 기록
    @Published var tradeHistory: [TradeRecord] = []
    @Published var totalTrades: Int = 0
    @Published var totalProfit: Int = 0
    @Published var bestDeal: TradeRecord? = nil
    // MARK: - 시간 정보
    @Published var createdAt: Date = Date()
    @Published var lastActive: Date = Date()
    @Published var totalPlayTime: TimeInterval = 0
    @Published var dailyPlayTime: TimeInterval = 0
    
    // MARK: - 게임 설정
    @Published var gameSettings: GameSettings = GameSettings()
    @Published var preferences: PlayerPreferences = PlayerPreferences()
    
    // MARK: - 보험 및 서비스
    @Published var insurancePolicies: [InsurancePolicy] = []
    @Published var activeContracts: [TradeContract] = []
    
    // MARK: - 초기화
    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        name: String = "",
        email: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.email = email
    }
    // MARK: - 보험
    enum InsuranceType: String, CaseIterable, Codable {
        case theft = "theft"
        case damage = "damage"
        case price = "price"
        case travel = "travel"
        
        var displayName: String {
            switch self {
            case .theft: return "도난 보험"
            case .damage: return "손상 보험"
            case .price: return "가격 보험"
            case .travel: return "여행 보험"
            }
        }
    }
    // MARK: - Codable 구현
    enum CodingKeys: String, CodingKey {
        case id, userId, name, email, money, trustPoints, reputation
        case currentLicense, maxInventorySize, level, experience
        case statPoints, skillPoints, strength, intelligence, charisma, luck
        case tradingSkill, negotiationSkill, appraisalSkill
        case inventory, equippedItems, storageItems, maxStorageSize
        case learnedSkills, activeSkillEffects
        case ownedProperties, vehicles, pets, appearance, cosmetics
        case merchantRelationships, guildMembership, achievements
        case completedAchievements, tradeHistory, totalTrades, totalProfit
        case createdAt, lastActive, totalPlayTime, dailyPlayTime
        case gameSettings, preferences, insurancePolicies, activeContracts
        case currentLocationLat, currentLocationLng
        case lastKnownLocationLat, lastKnownLocationLng
        case homeLocationLat, homeLocationLng
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        money = try container.decode(Int.self, forKey: .money)
        trustPoints = try container.decode(Int.self, forKey: .trustPoints)
        reputation = try container.decode(Int.self, forKey: .reputation)
        currentLicense = try container.decode(LicenseLevel.self, forKey: .currentLicense)
        maxInventorySize = try container.decode(Int.self, forKey: .maxInventorySize)
        level = try container.decode(Int.self, forKey: .level)
        experience = try container.decode(Int.self, forKey: .experience)
        statPoints = try container.decode(Int.self, forKey: .statPoints)
        skillPoints = try container.decode(Int.self, forKey: .skillPoints)
        strength = try container.decode(Int.self, forKey: .strength)
        intelligence = try container.decode(Int.self, forKey: .intelligence)
        charisma = try container.decode(Int.self, forKey: .charisma)
        luck = try container.decode(Int.self, forKey: .luck)
        tradingSkill = try container.decode(Int.self, forKey: .tradingSkill)
        negotiationSkill = try container.decode(Int.self, forKey: .negotiationSkill)
        appraisalSkill = try container.decode(Int.self, forKey: .appraisalSkill)
        inventory = try container.decode([TradeItem].self, forKey: .inventory)
        equippedItems = try container.decode([EquipmentSlot: EquipmentItem].self, forKey: .equippedItems)
        storageItems = try container.decode([TradeItem].self, forKey: .storageItems)
        maxStorageSize = try container.decode(Int.self, forKey: .maxStorageSize)
        ownedProperties = try container.decode([Property].self, forKey: .ownedProperties)
        vehicles = try container.decode([Vehicle].self, forKey: .vehicles)
        pets = try container.decode([Pet].self, forKey: .pets)
        appearance = try container.decode(CharacterAppearance.self, forKey: .appearance)
        cosmetics = try container.decode([CharacterCosmetic].self, forKey: .cosmetics)
        merchantRelationships = try container.decode([String: MerchantRelationship].self, forKey: .merchantRelationships)
        guildMembership = try container.decodeIfPresent(GuildMembership.self, forKey: .guildMembership)
        achievements = try container.decode([PlayerAchievement].self, forKey: .achievements)
        completedAchievements = try container.decode(Set<String>.self, forKey: .completedAchievements)
        tradeHistory = try container.decode([TradeRecord].self, forKey: .tradeHistory)
        totalTrades = try container.decode(Int.self, forKey: .totalTrades)
        totalProfit = try container.decode(Int.self, forKey: .totalProfit)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastActive = try container.decode(Date.self, forKey: .lastActive)
        totalPlayTime = try container.decode(TimeInterval.self, forKey: .totalPlayTime)
        dailyPlayTime = try container.decode(TimeInterval.self, forKey: .dailyPlayTime)
        gameSettings = try container.decode(GameSettings.self, forKey: .gameSettings)
        preferences = try container.decode(PlayerPreferences.self, forKey: .preferences)
        insurancePolicies = try container.decode([InsurancePolicy].self, forKey: .insurancePolicies)
        activeContracts = try container.decode([TradeContract].self, forKey: .activeContracts)
        
        // 위치 정보 복원
        if let lat = try container.decodeIfPresent(Double.self, forKey: .currentLocationLat),
           let lng = try container.decodeIfPresent(Double.self, forKey: .currentLocationLng) {
            currentLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        
        if let lat = try container.decodeIfPresent(Double.self, forKey: .lastKnownLocationLat),
           let lng = try container.decodeIfPresent(Double.self, forKey: .lastKnownLocationLng) {
            lastKnownLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        
        if let lat = try container.decodeIfPresent(Double.self, forKey: .homeLocationLat),
           let lng = try container.decodeIfPresent(Double.self, forKey: .homeLocationLng) {
            homeLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(money, forKey: .money)
        try container.encode(trustPoints, forKey: .trustPoints)
        try container.encode(reputation, forKey: .reputation)
        try container.encode(currentLicense, forKey: .currentLicense)
        try container.encode(maxInventorySize, forKey: .maxInventorySize)
        try container.encode(level, forKey: .level)
        try container.encode(experience, forKey: .experience)
        try container.encode(statPoints, forKey: .statPoints)
        try container.encode(skillPoints, forKey: .skillPoints)
        try container.encode(strength, forKey: .strength)
        try container.encode(intelligence, forKey: .intelligence)
        try container.encode(charisma, forKey: .charisma)
        try container.encode(luck, forKey: .luck)
        try container.encode(tradingSkill, forKey: .tradingSkill)
        try container.encode(negotiationSkill, forKey: .negotiationSkill)
        try container.encode(appraisalSkill, forKey: .appraisalSkill)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(equippedItems, forKey: .equippedItems)
        try container.encode(storageItems, forKey: .storageItems)
        try container.encode(maxStorageSize, forKey: .maxStorageSize)
        try container.encode(ownedProperties, forKey: .ownedProperties)
        try container.encode(vehicles, forKey: .vehicles)
        try container.encode(pets, forKey: .pets)
        try container.encode(appearance, forKey: .appearance)
        try container.encode(cosmetics, forKey: .cosmetics)
        try container.encode(merchantRelationships, forKey: .merchantRelationships)
        try container.encodeIfPresent(guildMembership, forKey: .guildMembership)
        try container.encode(achievements, forKey: .achievements)
        try container.encode(completedAchievements, forKey: .completedAchievements)
        try container.encode(tradeHistory, forKey: .tradeHistory)
        try container.encode(totalTrades, forKey: .totalTrades)
        try container.encode(totalProfit, forKey: .totalProfit)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastActive, forKey: .lastActive)
        try container.encode(totalPlayTime, forKey: .totalPlayTime)
        try container.encode(dailyPlayTime, forKey: .dailyPlayTime)
        try container.encode(gameSettings, forKey: .gameSettings)
        try container.encode(preferences, forKey: .preferences)
        try container.encode(insurancePolicies, forKey: .insurancePolicies)
        try container.encode(activeContracts, forKey: .activeContracts)
        
        // 위치 정보 저장
        try container.encodeIfPresent(currentLocation?.latitude, forKey: .currentLocationLat)
        try container.encodeIfPresent(currentLocation?.longitude, forKey: .currentLocationLng)
        try container.encodeIfPresent(lastKnownLocation?.latitude, forKey: .lastKnownLocationLat)
        try container.encodeIfPresent(lastKnownLocation?.longitude, forKey: .lastKnownLocationLng)
        try container.encodeIfPresent(homeLocation?.latitude, forKey: .homeLocationLat)
        try container.encodeIfPresent(homeLocation?.longitude, forKey: .homeLocationLng)
    }
    
    // MARK: - 서버 응답용 초기화
    convenience init(from serverPlayer: ServerPlayerResponse) {
        self.init(
            id: serverPlayer.id,
            userId: serverPlayer.userId,
            name: serverPlayer.name,
            email: serverPlayer.email
        )
        
        self.money = serverPlayer.money
        self.trustPoints = serverPlayer.trustPoints
        self.reputation = serverPlayer.reputation
        self.currentLicense = LicenseLevel(rawValue: serverPlayer.currentLicense) ?? .beginner
        self.maxInventorySize = serverPlayer.maxInventorySize
        self.level = serverPlayer.level
        self.experience = serverPlayer.experience
        self.statPoints = serverPlayer.statPoints
        self.skillPoints = serverPlayer.skillPoints
        self.strength = serverPlayer.strength
        self.intelligence = serverPlayer.intelligence
        self.charisma = serverPlayer.charisma
        self.luck = serverPlayer.luck
        self.tradingSkill = serverPlayer.tradingSkill
        self.negotiationSkill = serverPlayer.negotiationSkill
        self.appraisalSkill = serverPlayer.appraisalSkill
        self.inventory = serverPlayer.inventory.map { TradeItem(from: $0) }
        // 장비 시스템은 현재 사용하지 않음
        self.equippedItems = [:]
        // self.equippedItems = serverPlayer.equippedItems.reduce(into: [:]) { result, pair in
        //     if let slot = EquipmentSlot(rawValue: pair.key) {
        //         result[slot] = EquipmentItem(from: pair.value)
        //     }
        // }
        self.storageItems = serverPlayer.storageItems.map { TradeItem(from: $0) }
        self.maxStorageSize = serverPlayer.maxStorageSize
        // 위치 정보 설정
        if let location = serverPlayer.lastLocation {
            self.currentLocation = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
            self.lastKnownLocation = self.currentLocation
        }
        self.createdAt = Date(timeIntervalSince1970: serverPlayer.createdAt)
        self.lastActive = Date(timeIntervalSince1970: serverPlayer.lastActive)
    }
    
    // MARK: - 레벨 시스템
    func canUpgradeLicense() -> Bool {
        let nextLevel = LicenseLevel(rawValue: currentLicense.rawValue + 1)
        guard let next = nextLevel else { return false }
        
        return money >= next.requiredMoney && trustPoints >= next.requiredTrust
    }
    
    func upgradeLicense() -> Bool {
        guard canUpgradeLicense() else { return false }
        
        guard let nextLevel = LicenseLevel(rawValue: currentLicense.rawValue + 1) else { return false }
        money -= nextLevel.requiredMoney
        currentLicense = nextLevel
        maxInventorySize += 2
        
        return true
    }
    
    func addExperience(_ amount: Int) {
        experience += amount
        checkLevelUp()
    }
    
    private func checkLevelUp() {
        let requiredExp = calculateRequiredExperience(for: level + 1)
        
        while experience >= requiredExp {
            levelUp()
        }
    }
    
    private func levelUp() {
        level += 1
        let requiredExp = calculateRequiredExperience(for: level)
        experience -= requiredExp
        
        // 레벨업 보상
        statPoints += 2
        skillPoints += 1
        money += level * 1000
        
        // 특정 레벨에서 추가 보상
        switch level {
        case 5: maxInventorySize += 5
        case 10: maxStorageSize += 25
        case 15: maxInventorySize += 5
        case 20: maxStorageSize += 25
        default: break
        }
    }
    
    private func calculateRequiredExperience(for level: Int) -> Int {
        return level * 100 + (level - 1) * 50
    }
    
    // MARK: - 스탯 관리
    func canIncreaseStat(_ stat: StatType) -> Bool {
        return statPoints > 0 && getStatValue(stat) < 100
    }
    
    func increaseStat(_ stat: StatType) -> Bool {
        guard canIncreaseStat(stat) else { return false }
        
        statPoints -= 1
        
        switch stat {
        case .strength: strength += 1
        case .intelligence: intelligence += 1
        case .charisma: charisma += 1
        case .luck: luck += 1
        }
        
        return true
    }
    
    func getStatValue(_ stat: StatType) -> Int {
        switch stat {
        case .strength: return strength
        case .intelligence: return intelligence
        case .charisma: return charisma
        case .luck: return luck
        }
    }
    
    func getTotalStats() -> ItemStats {
        var totalStats = ItemStats(
            strength: strength,
            intelligence: intelligence,
            charisma: charisma,
            luck: luck,
            tradingBonus: tradingSkill,
            negotiationBonus: negotiationSkill,
            appraisalBonus: appraisalSkill
        )
        
        // 장착 아이템에서 스탯 추가
        // 장비 시스템이 비활성화되어 있으므로 기본 스탯만 반환
        // for (_, item) in equippedItems {
        //     totalStats = totalStats.adding(item.statBonus)
        // }
        
        return totalStats
    }
    
    // MARK: - 기술 관리
    func canIncreaseSkill(_ skill: SkillType) -> Bool {
        return skillPoints > 0 && getSkillValue(skill) < 100
    }
    
    func increaseSkill(_ skill: SkillType) -> Bool {
        guard canIncreaseSkill(skill) else { return false }
        
        skillPoints -= 1
        
        switch skill {
        case .trading: tradingSkill += 1
        case .negotiation: negotiationSkill += 1
        case .appraisal: appraisalSkill += 1
        }
        
        return true
    }
    
    func getSkillValue(_ skill: SkillType) -> Int {
        switch skill {
        case .trading: return tradingSkill
        case .negotiation: return negotiationSkill
        case .appraisal: return appraisalSkill
        }
    }
    
    // MARK: - 인벤토리 관리
    func canAddItem(_ item: TradeItem) -> Bool {
        // 단순화: 모든 아이템은 개별적으로 인벤토리에 추가됨
        return inventory.count < maxInventorySize
    }
    
    func addItem(_ item: TradeItem) -> Bool {
        guard canAddItem(item) else { return false }
        
        // 단순화: 모든 아이템을 새로운 항목으로 추가
        inventory.append(item)
        
        return true
    }
    
    func removeItem(withId itemId: String, quantity: Int = 1) -> Bool {
        guard let index = inventory.firstIndex(where: { $0.id == itemId }) else {
            return false
        }
        
        if inventory[index].quantity > quantity {
            inventory[index].quantity -= quantity
        } else {
            inventory.remove(at: index)
        }
        
        return true
    }
    
    // 장비 시스템은 현재 사용하지 않음 (TradeItem/EquipmentItem 분리로 인해 비활성화)
    /*
    func equipItem(_ item: EquipmentItem) -> Bool {
        // 장비 시스템 구현 예정
        return false
    }
    
    func unequipItem(from slot: EquipmentSlot) -> Bool {
        // 장비 시스템 구현 예정
        return false
    }
    */
    
    // MARK: - 상인 관계 관리
    func getRelationship(with merchantId: String) -> MerchantRelationship? {
        return merchantRelationships[merchantId]
    }
    
    func updateRelationship(with merchantId: String, friendshipChange: Int, trustChange: Int) {
        if var relationship = merchantRelationships[merchantId] {
            relationship.friendshipPoints += friendshipChange
            relationship.trustLevel += trustChange
            relationship.lastInteraction = Date()
            merchantRelationships[merchantId] = relationship
        } else {
            merchantRelationships[merchantId] = MerchantRelationship(
                merchantId: merchantId,
                friendshipPoints: max(0, friendshipChange),
                trustLevel: max(0, trustChange),
                totalTrades: 0,
                totalSpent: 0,
                lastInteraction: Date()
            )
        }
    }
    
    // MARK: - 업적 관리
    func checkAchievements() {
        // 업적 달성 조건 체크 (간단한 예시)
        checkTradeCountAchievements()
        checkMoneyAchievements()
        checkLevelAchievements()
    }
    
    private func checkTradeCountAchievements() {
        let milestones = [1, 10, 50, 100, 500, 1000]
        
        for milestone in milestones {
            let achievementId = "trades_\(milestone)"
            
            if totalTrades >= milestone && !completedAchievements.contains(achievementId) {
                completeAchievement(achievementId)
            }
        }
    }
    
    private func checkMoneyAchievements() {
        let milestones = [100000, 500000, 1000000, 5000000, 10000000]
        
        for milestone in milestones {
            let achievementId = "money_\(milestone)"
            
            if money >= milestone && !completedAchievements.contains(achievementId) {
                completeAchievement(achievementId)
            }
        }
    }
    
    private func checkLevelAchievements() {
        let milestones = [5, 10, 20, 30, 50]
        
        for milestone in milestones {
            let achievementId = "level_\(milestone)"
            
            if level >= milestone && !completedAchievements.contains(achievementId) {
                completeAchievement(achievementId)
            }
        }
    }
    
    private func completeAchievement(_ achievementId: String) {
        completedAchievements.insert(achievementId)
        
        // 업적 보상 지급 (예시)
        switch achievementId {
        case "trades_1":
            money += 5000
            addExperience(50)
        case "trades_10":
            money += 10000
            addExperience(100)
        case "money_100000":
            maxInventorySize += 2
        default:
            addExperience(25)
        }
    }
    
    // MARK: - 위치 관리
    func updateLocation(_ location: CLLocationCoordinate2D) {
        lastKnownLocation = currentLocation
        currentLocation = location
        lastActive = Date()
    }
    
    func getDistanceToHome() -> Double? {
        guard let home = homeLocation, let current = currentLocation else { return nil }
        
        let homeLocation = CLLocation(latitude: home.latitude, longitude: home.longitude)
        let currentLocationCL = CLLocation(latitude: current.latitude, longitude: current.longitude)
        
        return homeLocation.distance(from: currentLocationCL) / 1000 // km 단위
    }
    
    // MARK: - 보험 관리
    func hasInsurance(for type: InsuranceType) -> Bool {
        return insurancePolicies.contains { $0.type.rawValue == type.rawValue && $0.isActive }
    }
    
    func addInsurancePolicy(_ policy: InsurancePolicy) {
        insurancePolicies.append(policy)
    }
}

// MARK: - 지원 구조체들
enum StatType: String, CaseIterable {
    case strength = "strength"
    case intelligence = "intelligence"
    case charisma = "charisma"
    case luck = "luck"
    
    var displayName: String {
        switch self {
        case .strength: return "힘"
        case .intelligence: return "지능"
        case .charisma: return "매력"
        case .luck: return "행운"
        }
    }
    
    var description: String {
        switch self {
        case .strength: return "무거운 아이템을 운반하고 물리적 작업에 도움"
        case .intelligence: return "아이템 감정과 시장 분석 능력 향상"
        case .charisma: return "상인과의 거래 가격 협상에 유리"
        case .luck: return "희귀 아이템 발견과 크리티컬 확률 증가"
        }
    }
}

enum SkillType: String, CaseIterable {
    case trading = "trading"
    case negotiation = "negotiation"
    case appraisal = "appraisal"
    
    var displayName: String {
        switch self {
        case .trading: return "거래 기술"
        case .negotiation: return "협상 기술"
        case .appraisal: return "감정 기술"
        }
    }
    
    var description: String {
        switch self {
        case .trading: return "전반적인 거래 능력과 수익률 향상"
        case .negotiation: return "상인과의 가격 협상 성공률 증가"
        case .appraisal: return "아이템의 정확한 가치 평가 능력"
        }
    }
}

struct CharacterAppearance: Codable {
    var hairStyle: Int = 1
    var hairColor: Int = 1
    var faceType: Int = 1
    var eyeType: Int = 1
    var skinTone: Int = 1
    var outfitId: Int = 1
    var accessoryId: Int?
}

struct CharacterCosmetic: Identifiable, Codable {
    let id: String
    let cosmeticType: CosmeticType
    let cosmeticId: Int
    let name: String
    let rarity: ItemRarity
    var isEquipped: Bool = false
    let acquiredAt: Date
    
    // 초기화 메서드 추가
    init(cosmeticType: CosmeticType, cosmeticId: Int, name: String, rarity: ItemRarity, isEquipped: Bool = false, acquiredAt: Date = Date()) {
        self.id = UUID().uuidString
        self.cosmeticType = cosmeticType
        self.cosmeticId = cosmeticId
        self.name = name
        self.rarity = rarity
        self.isEquipped = isEquipped
        self.acquiredAt = acquiredAt
    }
    
    enum CosmeticType: String, CaseIterable, Codable {
        case hair = "hair"
        case face = "face"
        case outfit = "outfit"
        case accessory = "accessory"
        case weapon = "weapon"
        case pet = "pet"
    }
}

struct MerchantRelationship: Codable {
    let merchantId: String
    var friendshipPoints: Int
    var trustLevel: Int
    var totalTrades: Int
    var totalSpent: Int
    var lastInteraction: Date
    var notes: String?
}

struct GuildMembership: Codable {
    let guildId: String
    let guildName: String
    var rank: GuildRank
    var contributionPoints: Int
    var joinedAt: Date
    var lastActive: Date
    
    enum GuildRank: String, CaseIterable, Codable {
        case member = "member"
        case officer = "officer"
        case leader = "leader"
        
        var displayName: String {
            switch self {
            case .member: return "조합원"
            case .officer: return "간부"
            case .leader: return "조합장"
            }
        }
    }
}

struct PlayerAchievement: Identifiable, Codable {
    let id: String
    let achievementId: String
    var progress: Int
    var isCompleted: Bool
    var completedAt: Date?
    var claimed: Bool
    
    // 초기화 메서드 추가
    init(achievementId: String, progress: Int = 0, isCompleted: Bool = false, completedAt: Date? = nil, claimed: Bool = false) {
        self.id = UUID().uuidString
        self.achievementId = achievementId
        self.progress = progress
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.claimed = claimed
    }
}
struct GameSettings: Codable {
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var notificationsEnabled: Bool = true
    var autoSave: Bool = true
    var graphicsQuality: GraphicsQuality = .medium
    var language: String = "ko"
    
    enum GraphicsQuality: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .low: return "낮음"
            case .medium: return "보통"
            case .high: return "높음"
            }
        }
    }
}

struct PlayerPreferences: Codable {
    var preferredCategories: [String] = []
    var blacklistedMerchants: [String] = []
    var favoriteLocations: [String] = []
    var tradingStyle: TradingStyle = .balanced
    
    enum TradingStyle: String, CaseIterable, Codable {
        case conservative = "conservative"
        case balanced = "balanced"
        case aggressive = "aggressive"
        
        var displayName: String {
            switch self {
            case .conservative: return "안전한 거래"
            case .balanced: return "균형 잡힌 거래"
            case .aggressive: return "공격적 거래"
            }
        }
    }
}

struct InsurancePolicy: Identifiable, Codable {
    let id: String
    let type: InsuranceType
    let coverageAmount: Int
    let premiumRate: Double
    var isActive: Bool
    let startDate: Date
    let endDate: Date
    
    // 초기화 메서드 추가
    init(type: InsuranceType, coverageAmount: Int, premiumRate: Double, isActive: Bool = true, startDate: Date = Date(), endDate: Date) {
        self.id = UUID().uuidString
        self.type = type
        self.coverageAmount = coverageAmount
        self.premiumRate = premiumRate
        self.isActive = isActive
        self.startDate = startDate
        self.endDate = endDate
    }
    
    enum InsuranceType: String, CaseIterable, Codable {
        case theft = "theft"
        case damage = "damage"
        case price = "price"
        case travel = "travel"
        
        var displayName: String {
            switch self {
            case .theft: return "도난 보험"
            case .damage: return "손상 보험"
            case .price: return "가격 보험"
            case .travel: return "여행 보험"
            }
        }
    }
}

struct TradeContract: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let requiredItems: [String]
    let rewardGold: Int
    let rewardItems: [String]
    let deadline: Date
    var progress: ContractProgress
    
    // 초기화 메서드 추가
    init(title: String, description: String, requiredItems: [String], rewardGold: Int, rewardItems: [String], deadline: Date, progress: ContractProgress = .available) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.requiredItems = requiredItems
        self.rewardGold = rewardGold
        self.rewardItems = rewardItems
        self.deadline = deadline
        self.progress = progress
    }
    
    enum ContractProgress: String, CaseIterable, Codable {
        case available = "available"
        case accepted = "accepted"
        case inProgress = "inProgress"
        case completed = "completed"
        case failed = "failed"
        
        var displayName: String {
            switch self {
            case .available: return "수락 가능"
            case .accepted: return "수락됨"
            case .inProgress: return "진행 중"
            case .completed: return "완료"
            case .failed: return "실패"
            }
        }
    }
}


// MARK: - 서버 응답 모델
struct ServerPlayerResponse: Codable {
    let id: String
    let userId: String?
    let name: String
    let email: String?
    let money: Int
    let trustPoints: Int
    let reputation: Int
    let currentLicense: Int
    let maxInventorySize: Int
    let level: Int
    let experience: Int
    let statPoints: Int
    let skillPoints: Int
    let strength: Int
    let intelligence: Int
    let charisma: Int
    let luck: Int
    let tradingSkill: Int
    let negotiationSkill: Int
    let appraisalSkill: Int
    let inventory: [ServerItemResponse]
    let equippedItems: [String: ServerItemResponse]
    let storageItems: [ServerItemResponse]
    let maxStorageSize: Int
    let lastLocation: LocationData?
    let createdAt: TimeInterval
    let lastActive: TimeInterval
}

// MARK: - Missing Types

struct SkillEffect: Identifiable, Codable {
    let id: String
    let skillId: String
    let effectType: EffectType
    let magnitude: Double
    let duration: TimeInterval?
    let appliedAt: Date
    
    enum EffectType: String, Codable, CaseIterable {
        case priceReduction = "price_reduction"
        case negotiationBonus = "negotiation_bonus"
        case appraisalBonus = "appraisal_bonus"
        case experienceBonus = "experience_bonus"
        case movementSpeed = "movement_speed"
        case carryCapacity = "carry_capacity"
    }
    
    init(skillId: String, effectType: EffectType, magnitude: Double, duration: TimeInterval? = nil) {
        self.id = UUID().uuidString
        self.skillId = skillId
        self.effectType = effectType
        self.magnitude = magnitude
        self.duration = duration
        self.appliedAt = Date()
    }
}

struct TradeRecord: Identifiable, Codable {
    let id: String
    let itemId: String
    let itemName: String
    let merchantId: String
    let merchantName: String
    let buyPrice: Int
    let sellPrice: Int?
    let profit: Int?
    let timestamp: Date
    let tradeType: TradeType
    let location: LocationData?
    
    enum TradeType: String, Codable, CaseIterable {
        case buy = "buy"
        case sell = "sell"
        case auction = "auction"
        case gift = "gift"
    }
    
    init(itemId: String, itemName: String, merchantId: String, merchantName: String, buyPrice: Int, sellPrice: Int? = nil, tradeType: TradeType, location: LocationData? = nil) {
        self.id = UUID().uuidString
        self.itemId = itemId
        self.itemName = itemName
        self.merchantId = merchantId
        self.merchantName = merchantName
        self.buyPrice = buyPrice
        self.sellPrice = sellPrice
        self.profit = sellPrice != nil ? (sellPrice! - buyPrice) : nil
        self.timestamp = Date()
        self.tradeType = tradeType
        self.location = location
    }
}

struct ItemStats: Codable {
    var strength: Int = 0
    var intelligence: Int = 0
    var charisma: Int = 0
    var luck: Int = 0
    var tradingBonus: Int = 0
    var negotiationBonus: Int = 0
    var appraisalBonus: Int = 0
    var carryCapacity: Int = 0
    var movementSpeed: Double = 1.0
    
    mutating func add(_ other: ItemStats) {
        strength += other.strength
        intelligence += other.intelligence
        charisma += other.charisma
        luck += other.luck
        tradingBonus += other.tradingBonus
        negotiationBonus += other.negotiationBonus
        appraisalBonus += other.appraisalBonus
        carryCapacity += other.carryCapacity
        movementSpeed += other.movementSpeed
    }
}

enum ItemRarity: String, Codable, CaseIterable {
    case common = "common"
    case uncommon = "uncommon"  
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    case mythical = "mythical"
    
    var displayName: String {
        switch self {
        case .common: return "일반"
        case .uncommon: return "고급"
        case .rare: return "희귀"
        case .epic: return "영웅"
        case .legendary: return "전설"
        case .mythical: return "신화"
        }
    }
    
    var color: UIColor {
        switch self {
        case .common: return .systemGray
        case .uncommon: return .systemGreen
        case .rare: return .systemBlue
        case .epic: return .systemPurple
        case .legendary: return .systemOrange
        case .mythical: return .systemRed
        }
    }
    
    var dropRate: Double {
        switch self {
        case .common: return 0.60
        case .uncommon: return 0.25
        case .rare: return 0.10
        case .epic: return 0.04
        case .legendary: return 0.009
        case .mythical: return 0.001
        }
    }
}
