# Game Features Documentation

## 🎮 Core Gameplay Loop

```
Player Movement (GPS) → District Detection → Merchant Discovery
    ↓
View Merchant Inventory (License-gated items)
    ↓
Trade Decision (Buy/Sell/Exchange)
    ↓
Price Negotiation (Skill-based)
    ↓
Transaction Execution
    ↓
Rewards: Money + Experience + Skill Improvement + Relationship Points
    ↓
Achievement Progress + Milestone Tracking
```

## 💰 Trading System

### Trade Types

```swift
enum TradeType: String, Codable {
    case buy       // Purchase from merchant
    case sell      // Sell to merchant
    case exchange  // Item-for-item trade
}
```

### Trading Flow

**1. Discovery**
- Player enters merchant proximity (GPS-based)
- Merchant appears on map
- License requirement check

**2. Inventory View**
- Filter by player's license level
- Dynamic pricing based on:
  - Base price
  - District multiplier
  - Distance from player
  - Market fluctuations
  - Relationship discount

**3. Price Calculation**

```swift
// TradeItem.swift
mutating func updatePriceWithDistance(
    for region: SeoulDistrict,
    playerLocation: CLLocationCoordinate2D,
    merchantLocation: CLLocationCoordinate2D
) {
    let regionMultiplier = region.priceMultiplier(for: category)
    let distance = playerLocation.distance(to: merchantLocation)

    // Distance penalty: 2% per km, max 50%
    let distanceMultiplier = min(1.0 + (distance / 1000.0) * 0.02, 1.5)

    let rawPrice = Int(Double(basePrice) * regionMultiplier * distanceMultiplier)
    currentPrice = ((rawPrice + 50) / 100) * 100  // Round to 100원
}
```

**4. Transaction Execution**

```swift
// Player.swift
func performTrade(...) -> PlayerTradeResult {
    // Validation
    guard core.canAfford(finalPrice) else { return .failure(.insufficientFunds) }
    guard !inventory.isFull else { return .failure(.inventoryFull) }

    // Execute
    core.spendMoney(finalPrice)
    inventory.addItem(item)

    // Rewards & Updates
    processSuccessfulTrade(...)

    return .success(finalPrice)
}
```

### District Pricing

**Seoul District Multipliers**:

| District | Luxury Items | Food | Electronics | Antiques |
|----------|-------------|------|-------------|----------|
| Gangnam | 1.3x | 0.9x | 1.2x | 1.1x |
| Jongno | 1.0x | 1.0x | 0.8x | 1.4x |
| Songpa | 1.0x | 1.0x | 1.0x | 1.0x |

### Profit Tracking

```swift
struct ProfitInfo {
    let profit: Int
    let profitPercentage: Double
    let isProfitable: Bool

    var profitDescription: String {
        if isProfitable {
            return "이익 +\(displayProfit.formatted())원 (\(formattedProfitPercentage))"
        } else {
            return "손실 \(displayProfit.formatted())원 (\(formattedProfitPercentage))"
        }
    }
}
```

## 🎯 Progression Systems

### Level & Experience

**Level Curve**: Linear scaling
- Level 1 → 2: 100 XP
- Level 2 → 3: 200 XP
- Level N → N+1: N * 100 XP

**XP Sources**:
- Trading: `tradedAmount / 100` XP
- Achievements: Variable (50-1000 XP)
- Quests: Variable rewards
- Exploration: Distance-based

**Level Rewards**:
```swift
private func levelUp() {
    level += 1
    statPoints += 3      // 3 stat points per level
    skillPoints += 1     // 1 skill point per level
    checkLicenseUpgrade()
}
```

### License System

**Progression Path**:
```
Beginner (Lv1) → Intermediate (Lv5) → Advanced (Lv15) → Expert (Lv30) → Master (Lv50)
```

**Upgrade Requirements**:
1. Minimum player level
2. Required funds
3. Trust/reputation points (for higher tiers)

**Benefits**:
- Access to higher-grade items
- Inventory capacity bonus
- Better merchant relationships
- Exclusive trading opportunities

### Skill System

**Skills** (0-100 scale):
1. **Trading** - General proficiency, faster transactions
2. **Negotiation** - Better prices (up to 20% discount/profit)
3. **Appraisal** - Accurate item values, spot rare items
4. **Navigation** - Efficient routes, merchant discovery radius

**Improvement**:
```swift
// Organic improvement through gameplay
stats.improveSkill(.trading, by: 1)  // +1 per trade

// Manual improvement with skill points
func useSkillPoint(for skill: SkillType) -> Bool {
    guard core.skillPoints > 0 else { return false }
    stats.improveSkill(skill, by: 5)  // +5 with skill point
    core.skillPoints -= 1
    return true
}
```

### Stat System

**Primary Stats**:
- **Strength**: Carrying capacity (+2 slots per point)
- **Agility**: Movement speed, dodge chance
- **Intelligence**: Appraisal accuracy, learning speed
- **Charisma**: Price negotiation, relationship building

**Allocation**:
- Earn 3 stat points per level
- Allocate manually via skill tree interface
- Stats affect derived values (carrying capacity, etc.)

## 🏆 Achievement System

### Achievement Categories

**Trading Achievements**:
- First Trade
- 100 Trades Milestone
- Million Won Profit
- Perfect Negotiation Streak

**Exploration Achievements**:
- All Districts Visited
- 100km Traveled
- Remote Merchant Discovered

**Social Achievements**:
- 10 Friends Made
- Guild Member
- Trusted Merchant Status

### Milestone Tracking

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
```

### Rewards

**Achievement Rewards**:
- Money bonuses
- Experience points
- Exclusive items
- Cosmetic titles
- Achievement points (for leaderboards)

## 🎰 Auction System

### Auction Mechanics

**Auction Types**:
- **Timed Auctions**: Fixed end time
- **Live Auctions**: Real-time competitive bidding

**Bidding**:
```swift
// SocketManager.swift
func submitAuctionBid(auctionId: String, playerId: String, bidAmount: Int) {
    socket?.emit("submitAuctionBid", [
        "auctionId": auctionId,
        "playerId": playerId,
        "bidAmount": bidAmount
    ])
}
```

**Real-Time Updates**:
- New bid notifications
- Auction status changes
- Countdown timers
- Winner announcements

### Auction Items

**Sources**:
- Rare merchant inventory
- Player-created auctions
- Special event items

**Restrictions**:
- Minimum bid increments
- License requirements
- Reputation gates for premium auctions

## 🗺️ Location-Based Features

### District System

**10 Seoul Districts**:
- Gangnam, Songpa, Seocho, Jongno, Jung, Gangdong, Dongjak, Gwanak, Seongnam, Yongsan

**District Detection**:
```swift
// GameEnums.swift
static func fromCoordinate(lat: Double, lng: Double) -> SeoulDistrict {
    let targetLocation = CLLocation(latitude: lat, longitude: lng)

    var closestDistrict = SeoulDistrict.gangnam
    var minDistance = Double.infinity

    for district in SeoulDistrict.allCases {
        let districtLocation = CLLocation(latitude: district.coordinate.lat, longitude: district.coordinate.lng)
        let distance = targetLocation.distance(from: districtLocation)

        if distance < minDistance {
            minDistance = distance
            closestDistrict = district
        }
    }

    return closestDistrict
}
```

### Merchant Positioning

**Merchant Types**:
```swift
enum MerchantType: String, Codable {
    case retail       // General goods
    case wholesale    // Bulk items, better prices
    case specialty    // Rare/unique items
    case blackMarket  // High-risk, high-reward
}
```

**Location Mechanics**:
- Merchants positioned at real GPS coordinates
- Proximity detection (radius-based)
- License-gated access
- Dynamic inventory based on district

### Distance Impact

**Distance Multiplier**:
- 0-1km: Base price
- 1-5km: +2% per km
- 5-10km: +10% base + 3% per additional km
- 10km+: Capped at +50% maximum

**Benefits of Travel**:
- Exploration XP
- District discovery achievements
- Access to regional specialty items
- Merchant variety

## 🤝 Social Features

### Friend System

**Features**:
- Friend requests
- Friend list management
- Friendship levels (0-100)
- Item sharing/gifting
- Cooperative trading opportunities

**Implementation**:
```swift
func shareItemWithFriend(_ itemId: String, friendId: String) -> Bool {
    guard let item = inventory.findItem(by: itemId),
          relationships.friends.contains(where: { $0.playerId == friendId }) else {
        return false
    }

    if inventory.removeItem(item) {
        // Server handles transfer
        achievements.updateProgress("generous_trader", progress: 1)
        return true
    }
    return false
}
```

### Guild System

**Guild Benefits**:
- Trade bonus: +10% profit/discount
- Storage bonus: +10 inventory slots
- Experience bonus: +15% XP
- Guild-exclusive items/missions

**Guild Roles**:
- Member: Standard benefits
- Officer: Management permissions
- Leader: Full guild control

### Merchant Relationships

**Relationship Levels**:
```
Stranger (0-99) → Acquaintance (100-499) → Friend (500-1999) → Trusted (2000-4999) → Partner (5000+)
```

**Discount Progression**:
- Stranger: 0% discount
- Acquaintance: 5% discount
- Friend: 10% discount
- Trusted: 15% discount
- Partner: 20% discount

**Building Relationships**:
- Each trade: +10-50 friendship points (based on satisfaction)
- Trade value influences point gain
- Repeat business increases relationship faster
- Breaks in trading can decay relationship

## 📊 Statistics & Analytics

### Player Statistics

**Tracked Metrics**:
- Total trades (buy/sell/exchange)
- Total profit/loss
- Biggest single profit
- Average profit margin
- Trade success rate
- Perfect negotiation count

**Display**:
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
```

### Market Analytics

**Price Trends**:
- Historical price data
- District price comparisons
- Demand fluctuations
- Seasonal variations (future feature)

**Trade Activity Feed**:
- Real-time recent trades (last 50)
- Player anonymization option
- Profit/loss indicators
- Popular items tracking

---

**Next**: [04_NETWORK_REALTIME.md](04_NETWORK_REALTIME.md) - Socket.IO and real-time features
