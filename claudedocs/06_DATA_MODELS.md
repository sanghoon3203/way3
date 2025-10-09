# Data Models Reference

## 📋 Overview

Complete reference for all data models, enumerations, and structures used in Way3.

## 🎮 Core Enumerations

### ItemGrade

**File**: `Models/GameEnums.swift`

```swift
enum ItemGrade: Int, CaseIterable, Codable {
    case common = 0
    case intermediate = 1
    case advanced = 2
    case rare = 3
    case legendary = 4
}
```

**Properties**:
- `displayName: String` - Korean name ("일반", "중급", "고급", "희귀", "전설")
- `color: Color` - Standard color (gray, blue, green, purple, orange)
- `cyberpunkColor: Color` - Theme-specific color
- `shortDisplayName: String` - Abbreviated display name

**Methods**:
- `static func fromServerGrade(_ serverGrade: Int) -> ItemGrade`

### LicenseLevel

```swift
enum LicenseLevel: Int, CaseIterable, Codable {
    case beginner = 0
    case intermediate = 1
    case advanced = 2
    case expert = 3
    case master = 4
}
```

**Properties**:
- `displayName: String` - "초급상인", "중급상인", etc.
- `requiredLevel: Int` - Minimum player level (1, 5, 15, 30, 50)
- `requiredMoney: Int` - Upgrade cost (0, 10K, 50K, 200K, 1M)
- `requiredTrust: Int` - Trust points needed
- `maxInventoryBonus: Int` - Extra slots (0, 5, 10, 20, 30)
- `color: Color` - Visual representation

### ItemCategory

```swift
enum ItemCategory: String, CaseIterable, Codable {
    case food = "식료품"
    case craft = "공예품"
    case luxury = "명품"
    case general = "일반품"
    case electronics = "전자제품"
    // ... 15+ more categories
}
```

**Properties**:
- `displayName: String` - Korean display name
- `iconName: String` - SF Symbol icon name
- `color: Color` - Category color

### SeoulDistrict

```swift
enum SeoulDistrict: String, CaseIterable, Codable {
    case gangnam = "강남구"
    case songpa = "송파구"
    case seocho = "서초구"
    case jongno = "종로구"
    case jung = "중구"
    case gangdong = "강동구"
    case dongjak = "동작구"
    case gwanak = "관악구"
    case seoungnam = "성남시"
    case yongsan = "용산구"
}
```

**Properties**:
- `displayName: String` - Korean district name
- `coordinate: (lat: Double, lng: Double)` - GPS coordinates

**Methods**:
- `func priceMultiplier(for category: String) -> Double` - Category-specific pricing
- `static func fromCoordinate(lat: Double, lng: Double) -> SeoulDistrict` - Location resolution

**Price Multipliers**:
```swift
// Example: Gangnam
luxury: 1.3x, electronics: 1.2x, food: 0.9x

// Example: Jongno
antiques: 1.4x, books: 1.2x, electronics: 0.8x
```

### GameMode

**File**: `Models/Player.swift`

```swift
enum GameMode: String, Codable {
    case exploration = "exploration"
    case trading = "trading"
    case social = "social"
}
```

**Properties**:
- `displayName: String` - "탐험", "거래", "소셜"

### TradeType

```swift
enum TradeType: String, Codable {
    case buy, sell, exchange
}
```

## 🎯 Core Data Models

### TradeItem

**File**: `Models/TradeItem.swift`

```swift
struct TradeItem: Identifiable, Codable, Equatable {
    // Identity
    let id: String               // UUID
    let itemId: String           // Server item ID
    let name: String
    let category: String

    // Grade & Requirements
    let grade: ItemGrade
    let requiredLicense: LicenseLevel

    // Pricing
    let basePrice: Int
    var currentPrice: Int
    var marketValue: Int?
    var purchasePrice: Int?      // For profit tracking
    var purchaseDate: Date?

    // Properties
    let weight: Double
    var quantity: Int
    let description: String
    let iconId: Int
}
```

**Computed Properties**:
- `displayPrice: Int` - Rounded to 100원
- `displayBasePrice: Int` - Base price rounded
- `iconName: String` - SF Symbol based on category

**Methods**:
- `func calculateProfit(sellPrice: Int) -> ProfitInfo`
- `mutating func updatePrice(for region: SeoulDistrict)`
- `mutating func updatePriceWithDistance(...)`
- `mutating func setPurchaseInfo(price: Int, date: Date)`
- `func canUse(by player: Player) -> Bool`

### ProfitInfo

```swift
struct ProfitInfo {
    let profit: Int
    let profitPercentage: Double
    let isProfitable: Bool

    var displayProfit: Int           // Rounded
    var formattedProfitPercentage: String
    var profitDescription: String
}
```

### Player

**File**: `Models/Player.swift`

```swift
@MainActor
class Player: ObservableObject, Codable {
    // Component References
    @Published var core: PlayerCore
    @Published var stats: PlayerStats
    @Published var inventory: PlayerInventory
    @Published var relationships: PlayerRelationships
    @Published var achievements: PlayerAchievements

    // Game State
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentDistrict: String
    @Published var gameMode: GameMode
    @Published var isOnline: Bool
    @Published var lastSaveTime: Date

    // Session Data
    @Published var sessionStartTime: Date
    @Published var todayPlayTime: TimeInterval
}
```

**Key Methods**:
- `func performTrade(...) -> PlayerTradeResult`
- `func allocateStatPoint(to stat: StatType) -> Bool`
- `func updateLocation(_ coordinate: CLLocationCoordinate2D, district: String)`
- `func startSession()` / `func endSession()`
- `func save() async -> Bool`
- `static func load() async -> Player?`

## 👤 Player Component Models

### PlayerCore

```swift
class PlayerCore: Codable {
    let id: String
    var userId: String?
    var name: String
    var email: String?

    var age: Int
    var gender: String
    var personality: String

    var money: Int
    var level: Int
    var experience: Int
    var currentLicense: LicenseLevel

    var statPoints: Int
    var skillPoints: Int

    var totalPlayTime: TimeInterval
    var dailyPlayTime: TimeInterval
    var joinDate: Date
    var lastLoginDate: Date
}
```

**Methods**:
- `func earnMoney(_ amount: Int)`
- `func spendMoney(_ amount: Int) -> Bool`
- `func canAfford(_ amount: Int) -> Bool`
- `func gainExperience(_ amount: Int)`
- `func upgradeLicense() -> Bool`

### PlayerStats

```swift
class PlayerStats: Codable {
    var strength: Int
    var agility: Int
    var intelligence: Int
    var charisma: Int

    var tradingSkill: Int
    var negotiationSkill: Int
    var appraisalSkill: Int
    var navigationSkill: Int
}
```

**Computed Properties**:
- `carryingCapacity: Int` - 5 + (strength * 2)
- `negotiationBonus: Double` - (charisma + negotiation) / 200
- `appraisalAccuracy: Double`
- `totalStatPoints: Int`
- `averageSkillLevel: Double`

### PlayerInventory

```swift
class PlayerInventory: Codable {
    var inventory: [TradeItem]
    var equippedItems: [String: TradeItem]
    var maxInventorySize: Int
}
```

**Computed Properties**:
- `isFull: Bool`
- `totalWeight: Double`
- `totalEquipmentStats: [String: Int]`

**Methods**:
- `func addItem(_ item: TradeItem) -> Bool`
- `func removeItem(_ item: TradeItem) -> Bool`
- `func findItem(by id: String) -> TradeItem?`
- `func sortInventory(by sortType: InventorySortType)`
- `func equipItem(_ item: TradeItem, slot: EquipmentSlot) -> Bool`

### PlayerRelationships

```swift
class PlayerRelationships: Codable {
    var friends: [Friend]
    var friendRequests: [FriendRequest]
    var merchantRelationships: [String: MerchantRelationship]
    var guildMembership: GuildMembership?
    var reputationScore: Int
    var trustLevel: TrustLevel
    var tradeHistory: [TradeRecord]
}
```

**Supporting Structures**:

```swift
struct Friend: Codable {
    let playerId: String
    let playerName: String
    let friendshipLevel: Int
    let friendsSince: Date
}

struct MerchantRelationship: Codable {
    let merchantId: String
    let merchantName: String
    var friendshipPoints: Int
    var tradeCount: Int
    var totalTradeValue: Int
    var lastTradeDate: Date?
    var specialDiscounts: Double

    var relationshipLevel: RelationshipLevel
}

enum RelationshipLevel {
    case stranger, acquaintance, friend, trusted, partner

    var discountBonus: Double
}

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
```

### PlayerAchievements

```swift
class PlayerAchievements: Codable {
    var unlockedAchievements: [Achievement]
    var achievementProgress: [String: Int]
    var achievementPoints: Int

    var tradingMilestone: TradingMilestone
    var explorationMilestone: ExplorationMilestone
    var socialMilestone: SocialMilestone
}
```

**Milestone Structures**:

```swift
struct TradingMilestone: Codable {
    var totalTrades: Int
    var totalProfit: Int
    var biggestDeal: Int
    var perfectNegotiations: Int
}

struct ExplorationMilestone: Codable {
    var uniqueLocationsVisited: Int
    var totalDistanceTraveled: Double
    var districtsExplored: [String]
}

struct SocialMilestone: Codable {
    var friendsMade: Int
    var tradesWithPlayers: Int
    var guildContributions: Int
}
```

## 🌐 Network Models

### Socket.IO Data Models

```swift
struct NearbyPlayer: Identifiable {
    let id: String
    let name: String
    let level: Int
    let location: CLLocationCoordinate2D
    let distance: Double

    var distanceText: String
}

struct TradeActivity: Identifiable {
    let id: UUID
    let playerId: String
    let playerName: String
    let merchantName: String
    let itemName: String
    let tradeType: String
    let isProfit: Bool
    let timestamp: Date

    var timeText: String
    var timeAgo: String
}

struct PriceUpdate: Identifiable {
    let id: UUID
    let itemName: String
    let oldPrice: Int
    let newPrice: Int
    let district: String
    let changePercent: Double
    let timestamp: Date

    var changeDirection: PriceDirection

    enum PriceDirection {
        case up, down, stable
        var color: Color
        var icon: String
    }
}

struct TradeOffer: Identifiable {
    let id: String
    let fromPlayerId: String
    let fromPlayerName: String
    let toPlayerId: String
    let toPlayerName: String
    let itemsOffered: [String]
    let itemsRequested: [String]
    let message: String?
    let timestamp: Date
    let status: OfferStatus

    enum OfferStatus {
        case pending, accepted, rejected, expired
        var color: Color
    }
}
```

### API Response Models

```swift
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let timestamp: Date?
}

struct ServerItemResponse: Codable {
    let id: String
    let name: String
    let category: String
    let grade: String           // "common", "rare", etc.
    let requiredLicense: Int
    let basePrice: Int
    let currentPrice: Int?
    let description: String?
    let iconId: Int?
}

struct MerchantData: Codable {
    let id: String
    let name: String
    let type: String
    let district: String
    let location: LocationData
    let requiredLicense: String
    let inventory: [String]
}

struct LocationData: Codable {
    let lat: Double
    let lng: Double
}

struct MarketPrice: Codable {
    let itemName: String
    let currentPrice: Int
    let district: String
    let timestamp: Date
}
```

## 🏪 Merchant Models

```swift
struct Merchant {
    let id: String
    let name: String
    let type: MerchantType
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    let requiredLicense: LicenseLevel
    var inventory: [String]
}

enum MerchantType: String, Codable {
    case retail
    case wholesale
    case specialty
    case blackMarket
}
```

## 🏆 Achievement Models

```swift
struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: AchievementCategory
    let requirement: Int
    let points: Int
    let rewards: [AchievementReward]
    let iconName: String
}

enum AchievementCategory: String, Codable {
    case trading, exploration, social, combat, collection
}

enum AchievementReward {
    case money(Int)
    case experience(Int)
    case item(String)
    case title(String)
}
```

## 📊 Analytics Models

```swift
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
```

## 🔐 Security Models

```swift
// SecureStorage.swift
class SecureStorage {
    func save(key: String, value: String) -> Bool
    func retrieve(key: String) -> String?
    func delete(key: String) -> Bool
}
```

## 🎯 Enumerations Summary

| Enum | Values | Purpose |
|------|--------|---------|
| ItemGrade | 5 levels | Item rarity/quality |
| LicenseLevel | 5 levels | Player trading authorization |
| ItemCategory | 20+ categories | Item classification |
| SeoulDistrict | 10 districts | Location-based pricing |
| GameMode | 3 modes | Player activity state |
| TradeType | 3 types | Transaction classification |
| MerchantType | 4 types | Merchant classification |
| RelationshipLevel | 5 levels | NPC relationship status |
| TrustLevel | 5 levels | Player reputation |
| AchievementCategory | 5 categories | Achievement grouping |
| ConnectionStatus | 5 states | Socket connection state |

## 🗂️ Codable Implementations

All core models implement `Codable` for serialization:

**Player Persistence**:
```swift
class Player: ObservableObject, Codable {
    enum CodingKeys: String, CodingKey {
        case core, stats, inventory, relationships, achievements
        case currentLocation, currentDistrict, gameMode, isOnline, lastSaveTime
    }

    required init(from decoder: Decoder) throws { /* ... */ }
    func encode(to encoder: Encoder) throws { /* ... */ }
}
```

**Location Encoding**:
```swift
// CLLocationCoordinate2D is not Codable by default
// Converted to/from LocationData for serialization
if let location = currentLocation {
    let locationData = LocationData(lat: location.latitude, lng: location.longitude)
    let data = try JSONEncoder().encode(locationData)
    try container.encode(data, forKey: .currentLocation)
}
```

---

**Next**: [07_DEVELOPER_GUIDE.md](07_DEVELOPER_GUIDE.md) - Setup and development guide
