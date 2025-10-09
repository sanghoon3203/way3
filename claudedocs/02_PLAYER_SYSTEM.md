# Player System Deep Dive

## 🎮 Overview

The Player system in Way3 uses a **modular component architecture** where player data is separated into 5 specialized components, each responsible for a specific domain. This design provides separation of concerns, testability, and scalability.

## 🏗️ Architecture

### Component Hierarchy

```swift
@MainActor
class Player: ObservableObject {
    // 5 Core Components
    @Published var core: PlayerCore
    @Published var stats: PlayerStats
    @Published var inventory: PlayerInventory
    @Published var relationships: PlayerRelationships
    @Published var achievements: PlayerAchievements

    // High-level coordinating state
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentDistrict: String
    @Published var gameMode: GameMode
    @Published var isOnline: Bool

    // Coordinating methods that work across components
    func performTrade(...)
    func allocateStatPoint(...)
    func shareItemWithFriend(...)
}
```

### Design Philosophy

**Why Modular Components?**

1. **Single Responsibility**: Each component has one clear purpose
2. **Independent Testing**: Test components in isolation
3. **Parallel Development**: Multiple developers can work on different components
4. **Reduced Coupling**: Changes to one component rarely affect others
5. **Easy Extension**: Add new components without modifying existing ones

## 📦 Component 1: PlayerCore

**File**: `Models/Player/PlayerCore.swift`

**Purpose**: Core identity, finances, and progression

### Data Model

```swift
class PlayerCore: Codable {
    // Identity
    let id: String
    var userId: String?
    var name: String
    var email: String?

    // Profile
    var age: Int
    var gender: String
    var personality: String

    // Financial System
    var money: Int

    // Progression
    var level: Int
    var experience: Int
    var currentLicense: LicenseLevel

    // Resource Pools
    var statPoints: Int
    var skillPoints: Int

    // Time Tracking
    var totalPlayTime: TimeInterval
    var dailyPlayTime: TimeInterval
    var joinDate: Date
    var lastLoginDate: Date
}
```

### Key Methods

#### Financial Operations

```swift
// Money Management
func earnMoney(_ amount: Int) {
    money += amount
}

func spendMoney(_ amount: Int) -> Bool {
    guard money >= amount else { return false }
    money -= amount
    return true
}

func canAfford(_ amount: Int) -> Bool {
    return money >= amount
}
```

#### Experience & Leveling

```swift
func gainExperience(_ amount: Int) {
    experience += amount

    // Level up check
    while experience >= experienceNeededForNextLevel {
        levelUp()
    }
}

private func levelUp() {
    level += 1
    experience -= experienceNeededForNextLevel

    // Reward resources
    statPoints += 3
    skillPoints += 1

    // Check license upgrade eligibility
    checkLicenseUpgrade()
}

private var experienceNeededForNextLevel: Int {
    return 100 * level // Linear scaling: 100, 200, 300...
}
```

#### License System

```swift
func upgradeLicense() -> Bool {
    guard let nextLicense = LicenseLevel(rawValue: currentLicense.rawValue + 1),
          level >= nextLicense.requiredLevel,
          canAfford(nextLicense.requiredMoney) else {
        return false
    }

    _ = spendMoney(nextLicense.requiredMoney)
    currentLicense = nextLicense
    return true
}

func canUpgradeLicense() -> Bool {
    guard let nextLicense = LicenseLevel(rawValue: currentLicense.rawValue + 1) else {
        return false // Already at max
    }
    return level >= nextLicense.requiredLevel &&
           canAfford(nextLicense.requiredMoney)
}
```

### License Progression Table

| License | Level Required | Cost | Max Inventory Bonus | Trust Required |
|---------|---------------|------|---------------------|----------------|
| Beginner | 1 | 0원 | +0 | 0 |
| Intermediate | 5 | 10,000원 | +5 | 100 |
| Advanced | 15 | 50,000원 | +10 | 500 |
| Expert | 30 | 200,000원 | +20 | 2,000 |
| Master | 50 | 1,000,000원 | +30 | 10,000 |

## 📊 Component 2: PlayerStats

**File**: `Models/Player/PlayerStats.swift`

**Purpose**: Character attributes and skills

### Data Model

```swift
class PlayerStats: Codable {
    // Primary Attributes
    var strength: Int       // Carrying capacity
    var agility: Int        // Movement speed, dodge
    var intelligence: Int   // Better appraisal, learning
    var charisma: Int       // Better prices, relationships

    // Skills (0-100 scale)
    var tradingSkill: Int       // General trading proficiency
    var negotiationSkill: Int   // Price negotiation
    var appraisalSkill: Int     // Item value assessment
    var navigationSkill: Int    // Map efficiency, route planning
}
```

### Derived Stats

```swift
var carryingCapacity: Int {
    return 5 + (strength * 2)  // Base 5 + 2 per strength
}

var negotiationBonus: Double {
    return Double(charisma + negotiationSkill) / 200.0  // Up to 50% bonus
}

var appraisalAccuracy: Double {
    return Double(intelligence + appraisalSkill) / 200.0  // How accurate item values are
}

var totalStatPoints: Int {
    return strength + agility + intelligence + charisma
}

var averageSkillLevel: Double {
    let skills = [tradingSkill, negotiationSkill, appraisalSkill, navigationSkill]
    return Double(skills.reduce(0, +)) / Double(skills.count)
}
```

### Stat Allocation

```swift
func allocateStatPoint(to stat: StatType) -> Bool {
    guard stat.currentValue < stat.maxValue else { return false }

    switch stat {
    case .strength:
        strength += 1
    case .agility:
        agility += 1
    case .intelligence:
        intelligence += 1
    case .charisma:
        charisma += 1
    }

    return true
}
```

### Skill Improvement

```swift
func improveSkill(_ skill: SkillType, by amount: Int) {
    let currentValue: Int

    switch skill {
    case .trading:
        currentValue = tradingSkill
        tradingSkill = min(100, tradingSkill + amount)
    case .negotiation:
        currentValue = negotiationSkill
        negotiationSkill = min(100, negotiationSkill + amount)
    case .appraisal:
        currentValue = appraisalSkill
        appraisalSkill = min(100, appraisalSkill + amount)
    case .navigation:
        currentValue = navigationSkill
        navigationSkill = min(100, navigationSkill + amount)
    }

    // Skills cap at 100
}
```

### Stat Types

```swift
enum StatType {
    case strength, agility, intelligence, charisma

    var displayName: String {
        switch self {
        case .strength: return "힘"
        case .agility: return "민첩"
        case .intelligence: return "지능"
        case .charisma: return "매력"
        }
    }

    var description: String {
        switch self {
        case .strength: return "운반 용량 증가"
        case .agility: return "이동 속도, 회피율"
        case .intelligence: return "감정가 정확도, 학습 속도"
        case .charisma: return "거래 가격, 관계 형성"
        }
    }
}

enum SkillType {
    case trading, negotiation, appraisal, navigation
}
```

## 🎒 Component 3: PlayerInventory

**File**: `Models/Player/PlayerInventory.swift`

**Purpose**: Item storage and equipment management

### Data Model

```swift
class PlayerInventory: Codable {
    var inventory: [TradeItem]
    var equippedItems: [String: TradeItem]  // slot -> item
    var maxInventorySize: Int

    var isFull: Bool {
        return inventory.count >= maxInventorySize
    }

    var totalWeight: Double {
        return inventory.reduce(0) { $0 + $1.weight * Double($1.quantity) }
    }
}
```

### Item Operations

```swift
// Add Item
func addItem(_ item: TradeItem) -> Bool {
    guard !isFull else { return false }

    // Check for stackable items (same itemId)
    if let existingIndex = inventory.firstIndex(where: { $0.itemId == item.itemId }) {
        inventory[existingIndex].quantity += item.quantity
    } else {
        inventory.append(item)
    }

    return true
}

// Remove Item
func removeItem(_ item: TradeItem) -> Bool {
    guard let index = inventory.firstIndex(where: { $0.id == item.id }) else {
        return false
    }

    if inventory[index].quantity > 1 {
        inventory[index].quantity -= 1
    } else {
        inventory.remove(at: index)
    }

    return true
}

// Find Item
func findItem(by id: String) -> TradeItem? {
    return inventory.first { $0.id == id }
}

func findItems(by category: String) -> [TradeItem] {
    return inventory.filter { $0.category == category }
}
```

### Inventory Sorting

```swift
func sortInventory(by sortType: InventorySortType) {
    switch sortType {
    case .name:
        inventory.sort { $0.name < $1.name }
    case .grade:
        inventory.sort { $0.grade.rawValue > $1.grade.rawValue }
    case .price:
        inventory.sort { $0.currentPrice > $1.currentPrice }
    case .category:
        inventory.sort { $0.category < $1.category }
    case .dateAcquired:
        inventory.sort { ($0.purchaseDate ?? Date.distantPast) > ($1.purchaseDate ?? Date.distantPast) }
    }
}

enum InventorySortType {
    case name, grade, price, category, dateAcquired
}
```

### Equipment System

```swift
var equipmentSlots: [EquipmentSlot] {
    [.weapon, .armor, .accessory1, .accessory2]
}

func equipItem(_ item: TradeItem, slot: EquipmentSlot) -> Bool {
    guard item.isEquippable,
          item.equipmentSlot == slot,
          inventory.contains(where: { $0.id == item.id }) else {
        return false
    }

    // Unequip existing item in slot
    if let existing = equippedItems[slot.rawValue] {
        _ = addItem(existing)
    }

    // Equip new item
    equippedItems[slot.rawValue] = item
    _ = removeItem(item)

    return true
}

func unequipItem(slot: EquipmentSlot) -> Bool {
    guard let item = equippedItems[slot.rawValue],
          !isFull else {
        return false
    }

    equippedItems.removeValue(forKey: slot.rawValue)
    return addItem(item)
}

var totalEquipmentStats: [String: Int] {
    var stats: [String: Int] = [:]

    for (_, item) in equippedItems {
        // Aggregate equipment bonuses
        // (Future: items will have stat bonuses)
    }

    return stats
}
```

## 👥 Component 4: PlayerRelationships

**File**: `Models/Player/PlayerRelationships.swift`

**Purpose**: Social features and NPC relationships

### Data Model

```swift
class PlayerRelationships: Codable {
    // Friend System
    var friends: [Friend]
    var friendRequests: [FriendRequest]

    // Merchant Relationships
    var merchantRelationships: [String: MerchantRelationship]  // merchantId -> relationship

    // Guild System
    var guildMembership: GuildMembership?

    // Reputation
    var reputationScore: Int
    var trustLevel: TrustLevel

    // Trade History
    var tradeHistory: [TradeRecord]
}
```

### Friend System

```swift
struct Friend: Codable {
    let playerId: String
    let playerName: String
    let friendshipLevel: Int  // 0-100
    let friendsSince: Date
}

func addFriend(_ playerId: String, name: String) {
    let friend = Friend(
        playerId: playerId,
        playerName: name,
        friendshipLevel: 1,
        friendsSince: Date()
    )
    friends.append(friend)
}

func removeFriend(_ playerId: String) {
    friends.removeAll { $0.playerId == playerId }
}
```

### Merchant Relationships

```swift
struct MerchantRelationship: Codable {
    let merchantId: String
    let merchantName: String
    var friendshipPoints: Int       // Accumulated trust
    var tradeCount: Int             // Total trades
    var totalTradeValue: Int        // Total money spent/earned
    var lastTradeDate: Date?
    var specialDiscounts: Double    // 0.0 - 0.3 (up to 30% discount)

    var relationshipLevel: RelationshipLevel {
        switch friendshipPoints {
        case 0..<100: return .stranger
        case 100..<500: return .acquaintance
        case 500..<2000: return .friend
        case 2000..<5000: return .trusted
        default: return .partner
        }
    }
}

enum RelationshipLevel {
    case stranger, acquaintance, friend, trusted, partner

    var discountBonus: Double {
        switch self {
        case .stranger: return 0.0
        case .acquaintance: return 0.05
        case .friend: return 0.10
        case .trusted: return 0.15
        case .partner: return 0.20
        }
    }
}

func recordTrade(
    with merchantId: String,
    itemName: String,
    tradeType: TradeType,
    amount: Int,
    satisfaction: Int
) {
    var relationship = merchantRelationships[merchantId] ?? MerchantRelationship(
        merchantId: merchantId,
        merchantName: "Unknown",
        friendshipPoints: 0,
        tradeCount: 0,
        totalTradeValue: 0
    )

    relationship.tradeCount += 1
    relationship.totalTradeValue += amount
    relationship.friendshipPoints += satisfaction * 10
    relationship.lastTradeDate = Date()

    merchantRelationships[merchantId] = relationship

    // Record in trade history
    let record = TradeRecord(
        merchantId: merchantId,
        itemName: itemName,
        tradeType: tradeType,
        amount: amount,
        timestamp: Date()
    )
    tradeHistory.append(record)
}
```

### Guild System

```swift
struct GuildMembership: Codable {
    let guildId: String
    let guildName: String
    let joinDate: Date
    var role: GuildRole
    var contributionPoints: Int
}

enum GuildRole: String, Codable {
    case member, officer, leader
}

struct GuildBenefits {
    let tradeBonus: Double          // % bonus on trades
    let storageBonus: Int           // Extra inventory slots
    let experienceBonus: Double     // % XP boost
}

var guildBenefits: GuildBenefits? {
    guard let membership = guildMembership else { return nil }

    // Calculate benefits based on guild level and player role
    return GuildBenefits(
        tradeBonus: 0.1,
        storageBonus: 10,
        experienceBonus: 0.15
    )
}
```

### Trust System

```swift
enum TrustLevel: String, Codable {
    case untrusted, neutral, trusted, highlyTrusted, legendary

    var threshold: Int {
        switch self {
        case .untrusted: return 0
        case .neutral: return 100
        case .trusted: return 500
        case .highlyTrusted: return 2000
        case .legendary: return 10000
        }
    }

    static func fromScore(_ score: Int) -> TrustLevel {
        if score >= 10000 { return .legendary }
        if score >= 2000 { return .highlyTrusted }
        if score >= 500 { return .trusted }
        if score >= 100 { return .neutral }
        return .untrusted
    }
}

func updateTrustLevel() {
    trustLevel = TrustLevel.fromScore(reputationScore)
}
```

## 🏆 Component 5: PlayerAchievements

**File**: `Models/Player/PlayerAchievements.swift`

**Purpose**: Progress tracking and milestone rewards

### Data Model

```swift
class PlayerAchievements: Codable {
    var unlockedAchievements: [Achievement]
    var achievementProgress: [String: Int]  // achievementId -> progress
    var achievementPoints: Int

    // Milestone Systems
    var tradingMilestone: TradingMilestone
    var explorationMilestone: ExplorationMilestone
    var socialMilestone: SocialMilestone
}
```

### Achievement System

```swift
func checkAchievement(_ achievementId: String) {
    guard !isUnlocked(achievementId),
          let achievement = Achievement.all.first(where: { $0.id == achievementId }),
          hasMetRequirements(achievement) else {
        return
    }

    unlockAchievement(achievement)
}

func unlockAchievement(_ achievement: Achievement) {
    unlockedAchievements.append(achievement)
    achievementPoints += achievement.points

    // Grant rewards
    achievement.rewards.forEach { reward in
        applyReward(reward)
    }
}

private func applyReward(_ reward: AchievementReward) {
    switch reward {
    case .money(let amount):
        // Player.core.earnMoney(amount)
        break
    case .experience(let amount):
        // Player.core.gainExperience(amount)
        break
    case .item(let itemId):
        // Player.inventory.addItem(...)
        break
    case .title(let title):
        // Unlock cosmetic title
        break
    }
}
```

### Milestone Tracking

```swift
struct TradingMilestone: Codable {
    var totalTrades: Int
    var totalProfit: Int
    var biggestDeal: Int
    var perfectNegotiations: Int

    mutating func recordTrade(profit: Int, isPerfect: Bool) {
        totalTrades += 1
        totalProfit += profit
        biggestDeal = max(biggestDeal, profit)
        if isPerfect { perfectNegotiations += 1 }
    }
}

struct ExplorationMilestone: Codable {
    var uniqueLocationsVisited: Int
    var totalDistanceTraveled: Double
    var districtsExplored: [String]

    mutating func recordLocation(district: String, distance: Double) {
        uniqueLocationsVisited += 1
        totalDistanceTraveled += distance
        if !districtsExplored.contains(district) {
            districtsExplored.append(district)
        }
    }
}

struct SocialMilestone: Codable {
    var friendsMade: Int
    var tradesWithPlayers: Int
    var guildContributions: Int
}
```

### Progress Updates

```swift
func updateProgress(_ achievementId: String, progress: Int) {
    let currentProgress = achievementProgress[achievementId] ?? 0
    achievementProgress[achievementId] = currentProgress + progress

    // Check if achievement is complete
    if let achievement = Achievement.all.first(where: { $0.id == achievementId }),
       achievementProgress[achievementId] ?? 0 >= achievement.requirement {
        checkAchievement(achievementId)
    }
}

var completionRate: Double {
    let total = Achievement.all.count
    let unlocked = unlockedAchievements.count
    return Double(unlocked) / Double(total)
}
```

## 🔗 Component Integration

### Cross-Component Operations

The `Player` class coordinates operations that span multiple components:

#### Trading Operation

```swift
func performTrade(
    with merchantId: String,
    item: TradeItem,
    tradeType: TradeType,
    finalPrice: Int
) -> PlayerTradeResult {
    // 1. Financial check (PlayerCore)
    guard core.canAfford(finalPrice) else {
        return .failure(.insufficientFunds)
    }

    // 2. Inventory check (PlayerInventory)
    guard !inventory.isFull else {
        return .failure(.inventoryFull)
    }

    // 3. Execute trade
    if core.spendMoney(finalPrice) && inventory.addItem(item) {
        // 4. Experience gain (PlayerCore)
        core.gainExperience(finalPrice / 100)

        // 5. Skill improvement (PlayerStats)
        stats.improveSkill(.trading, by: 1)

        // 6. Relationship update (PlayerRelationships)
        relationships.recordTrade(
            with: merchantId,
            itemName: item.name,
            tradeType: tradeType,
            amount: finalPrice,
            satisfaction: 5
        )

        // 7. Achievement progress (PlayerAchievements)
        achievements.updateProgress("first_trade", progress: 1)
        achievements.updateTradingMilestone(
            tradeCount: 1,
            profit: finalPrice - item.basePrice
        )

        return .success(finalPrice)
    }

    return .failure(.unknown)
}
```

### Stat Point Allocation (Cross-Component)

```swift
func allocateStatPoint(to stat: StatType) -> Bool {
    // 1. Check if player has points (PlayerCore)
    guard core.statPoints > 0 else { return false }

    // 2. Allocate to stat (PlayerStats)
    guard stats.allocateStatPoint(to: stat) else { return false }

    // 3. Deduct point (PlayerCore)
    core.statPoints -= 1

    // 4. Update derived values (PlayerInventory)
    if stat == .strength {
        inventory.maxInventorySize = 5 + stats.carryingCapacity
    }

    return true
}
```

## 💾 Persistence

### Codable Implementation

All components are `Codable` for easy serialization:

```swift
class Player: ObservableObject, Codable {
    enum CodingKeys: String, CodingKey {
        case core, stats, inventory, relationships, achievements
        case currentLocation, currentDistrict, gameMode
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        core = try container.decode(PlayerCore.self, forKey: .core)
        stats = try container.decode(PlayerStats.self, forKey: .stats)
        inventory = try container.decode(PlayerInventory.self, forKey: .inventory)
        relationships = try container.decode(PlayerRelationships.self, forKey: .relationships)
        achievements = try container.decode(PlayerAchievements.self, forKey: .achievements)
        // ... decode other properties
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(core, forKey: .core)
        try container.encode(stats, forKey: .stats)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(relationships, forKey: .relationships)
        try container.encode(achievements, forKey: .achievements)
        // ... encode other properties
    }
}
```

### Save/Load Methods

```swift
// Player.swift extension
extension Player {
    func save() async -> Bool {
        return await PlayerDataManager.shared.savePlayer(self)
    }

    static func load() async -> Player? {
        return await PlayerDataManager.shared.loadPlayer()
    }

    func startAutoSave() {
        PlayerDataManager.shared.startAutoSave(for: self)
    }

    static func hasSavedData() -> Bool {
        return PlayerDataManager.shared.hasSavedData()
    }
}
```

## 📊 Analytics

### Player Summary

```swift
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

var overallPower: Int {
    let statPower = stats.totalStatPoints / 4
    let skillPower = Int(stats.averageSkillLevel)
    let equipmentPower = inventory.totalEquipmentStats.values.reduce(0, +)
    let achievementPower = achievements.achievementPoints / 10

    return statPower + skillPower + equipmentPower + achievementPower
}
```

---

**Next**: [03_GAME_FEATURES.md](03_GAME_FEATURES.md) - Trading, progression, and gameplay mechanics
