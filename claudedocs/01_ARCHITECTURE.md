# Way3 Architecture Guide

## 📐 System Architecture

### High-Level Architecture Pattern

Way3 follows a **Modular MVVM (Model-View-ViewModel)** architecture with reactive state management using SwiftUI and Combine.

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI Views Layer                   │
│  (ContentView, MainTabView, Trading, Map, Profile...)    │
└───────────────────┬─────────────────────────────────────┘
                    │ @EnvironmentObject / @StateObject
                    │
┌───────────────────▼─────────────────────────────────────┐
│              ViewModels / State Objects                  │
│   Player, GameManager, AuthManager, LocationManager      │
└───────────────────┬─────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
┌───────▼──────┐ ┌─▼────────┐ ┌▼──────────────┐
│ Core Managers│ │  Models  │ │ Network Layer │
│              │ │          │ │               │
│ DataManager  │ │  Player  │ │ SocketManager │
│ AuctionMgr   │ │TradeItem │ │ NetworkMgr    │
│ DistrictMgr  │ │Achievement│ │               │
└──────────────┘ └──────────┘ └───────┬───────┘
                                       │
                              ┌────────▼────────┐
                              │   Server API    │
                              │   Socket.IO     │
                              └─────────────────┘
```

## 🧩 Core Components

### 1. Player System (Modular Architecture)

The Player system uses a **Component-Based Design** pattern where player data is separated into 5 independent modules:

```swift
@MainActor
class Player: ObservableObject {
    @Published var core: PlayerCore              // Identity, money, level
    @Published var stats: PlayerStats            // Skills, attributes
    @Published var inventory: PlayerInventory    // Items, equipment
    @Published var relationships: PlayerRelationships  // Social
    @Published var achievements: PlayerAchievements    // Progress

    // High-level coordinating methods...
}
```

**Benefits**:
- **Separation of Concerns**: Each component handles one domain
- **Testability**: Components can be tested independently
- **Maintainability**: Changes to one component don't affect others
- **Scalability**: Easy to add new components (e.g., PlayerQuests)

#### Component Responsibilities

**PlayerCore** (`PlayerCore.swift`)
- Player identity (id, userId, name, email)
- Financial system (money, spending, earning)
- Progression (level, experience, license)
- Time tracking (totalPlayTime, dailyPlayTime)
- Stat/skill points allocation pool

**PlayerStats** (`PlayerStats.swift`)
- Attributes (strength, agility, intelligence, charisma)
- Skills (trading, negotiation, navigation, appraisal)
- Derived stats (carryingCapacity from strength)
- Stat point allocation logic

**PlayerInventory** (`PlayerInventory.swift`)
- Item storage (inventory array)
- Equipment management (equipped items)
- Capacity tracking (maxInventorySize)
- Item operations (add, remove, find, sort)
- Equipment stat bonuses

**PlayerRelationships** (`PlayerRelationships.swift`)
- Friend system (friend list, requests)
- Merchant relationships (trust levels, trade history)
- Guild membership (benefits, roles)
- Reputation system (trust levels, social standing)

**PlayerAchievements** (`PlayerAchievements.swift`)
- Achievement tracking (unlocked, in-progress)
- Milestone systems (trading, exploration, social)
- Progress updates (achievements, milestones)
- Completion rates and statistics

### 2. Manager Layer

#### DataManager (`Core/DataManager.swift`)

**Responsibilities**:
- Game data coordination
- Market data synchronization
- Merchant management
- Price board updates
- Offline data generation

**Key Methods**:
```swift
func loadOnlineGameData() async
func updateMerchants(_ merchantData: [MerchantData])
func updateMarketPrices(_ prices: [MarketPrice])
func applyPriceUpdates(_ updates: [String: Int])
```

**Pattern**: Singleton with delegate pattern for communication
```swift
class DataManager: ObservableObject {
    weak var delegate: DataManagerDelegate?

    protocol DataManagerDelegate: AnyObject {
        func onPlayerDataReceived(_ data: PlayerDetail) async
        func onDataRefresh()
    }
}
```

#### SocketManager (`Core/SocketManager.swift`)

**Responsibilities**:
- Real-time WebSocket communication
- Connection state management
- Auto-reconnection logic
- Event handling and broadcasting
- Player location updates

**Connection Management**:
```swift
enum ConnectionStatus {
    case disconnected, connecting, connected, reconnecting, failed
}

// Auto-reconnection with exponential backoff
private var reconnectionAttempts = 0
private let maxReconnectionAttempts = 5
private let reconnectionDelay: TimeInterval = 5.0
```

**Event Handlers**:
- `nearbyPlayersUpdate`: Discover players within radius
- `tradeActivity`: Live trade feed
- `priceUpdate`: Market price changes
- `tradeOffer`: P2P trade proposals
- `auctionBid`: Real-time auction updates

#### AuctionManager (`Core/AuctionManager.swift`)

**Responsibilities**:
- Auction system coordination
- Bid management
- Auction lifecycle (active, completed, expired)
- Socket integration for real-time bidding

#### DistrictManager (`Core/DistrictManager.swift`)

**Responsibilities**:
- Seoul district mapping
- Location-to-district resolution
- District-based pricing multipliers
- Coordinate calculations

### 3. View Layer Architecture

#### EnvironmentObject Injection Pattern

```swift
struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var gameManager = GameManager.shared
    @StateObject private var player = Player.createDefault()

    var body: some View {
        MainTabView(selectedTab: $selectedTab)
            .environmentObject(authManager)
            .environmentObject(gameManager)
            .environmentObject(locationManager)
            .environmentObject(player)
    }
}
```

**Benefits**:
- Global state accessibility
- Automatic view updates (@Published → UI refresh)
- Dependency injection for testing
- Clear data flow hierarchy

#### View Organization

```
Views/
├── Auth/           # Authentication flow
│   ├── StartView.swift        # Onboarding with video
│   └── LoginView.swift        # Authentication
│
├── Game/           # Main game screens
│   └── MainTabView.swift      # Tab navigation root
│
├── Map/            # Location-based views
│   ├── PlayerInfoOverlayMoneyInfo.swift
│   └── PlayerInfoOverlayLisenceInfo.swift
│
├── Trade/          # Trading interfaces
│   └── TradeActivityView.swift
│
├── Auction/        # Auction system
│   ├── AuctionHallView.swift
│   └── AuctionDetailView.swift
│
├── Shop/           # Shopping
│   └── ShopView.swift
│
├── Player/         # Player management
│   ├── InventoryView.swift
│   ├── SkillTreeView.swift
│   └── NearbyPlayersView.swift
│
└── Quest/          # Achievements/quests
    └── QuestView.swift
```

## 🔄 Data Flow Patterns

### 1. Player Data Flow

```
User Interaction (Trade, Movement, etc.)
    ↓
View calls Player method (player.performTrade(...))
    ↓
Player coordinates between components:
    - core.spendMoney(amount)
    - inventory.addItem(item)
    - stats.improveSkill(.trading, by: 1)
    - relationships.recordTrade(...)
    - achievements.updateProgress(...)
    ↓
@Published properties change
    ↓
SwiftUI views auto-refresh
    ↓
PlayerDataManager auto-saves (5-minute interval)
```

### 2. Real-Time Data Flow

```
Server Event (Socket.IO)
    ↓
SocketManager receives event
    ↓
Handler processes data (handleNearbyPlayersUpdate)
    ↓
@Published property updated (nearbyPlayers = ...)
    ↓
DispatchQueue.main.async ensures main thread
    ↓
SwiftUI views observing SocketManager refresh
    ↓
UI displays real-time data
```

### 3. Location-Based Data Flow

```
CoreLocation updates (GPS)
    ↓
LocationManager processes
    ↓
Coordinate → SeoulDistrict resolution
    ↓
Player.updateLocation(coordinate, district)
    ↓
Multiple updates triggered:
    - District-based price calculations
    - Merchant proximity checks
    - Socket location broadcast
    - Achievement progress (exploration)
    ↓
Views refresh with location-aware data
```

## 🎯 Design Patterns

### 1. Singleton Pattern

Used for managers that require single source of truth:

```swift
class SocketManager: ObservableObject {
    static let shared = SocketManager()
    private init() { setupSocket() }
}

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private init() { /* ... */ }
}
```

**Use Cases**:
- Network managers (prevent multiple connections)
- Authentication (single auth state)
- Loggers (centralized logging)

### 2. Delegate Pattern

Used for loose coupling between managers:

```swift
protocol DataManagerDelegate: AnyObject {
    func onPlayerDataReceived(_ data: PlayerDetail) async
    func onDataRefresh()
}

class DataManager: ObservableObject {
    weak var delegate: DataManagerDelegate?

    private func loadPlayerData() async {
        let data = try await networkManager.getPlayerData()
        await delegate?.onPlayerDataReceived(data)
    }
}
```

**Benefits**:
- Avoids circular dependencies
- Clear communication contracts
- Easy to mock for testing

### 3. Observer Pattern (Combine)

SwiftUI's `@Published` + Combine for reactive updates:

```swift
class Player: ObservableObject {
    @Published var core: PlayerCore {
        didSet { markAsChanged() }
    }

    @Published var money: Int {
        didSet {
            if money != oldValue {
                Task { await save() }
            }
        }
    }
}
```

### 4. Strategy Pattern

Item grade and license levels use strategy pattern:

```swift
enum ItemGrade: Int {
    case common, intermediate, advanced, rare, legendary

    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .purple
        // Different visual strategy per grade
        }
    }

    var cyberpunkColor: Color {
        switch self {
        case .common: return .cyberpunkTextSecondary
        case .legendary: return .cyberpunkGold
        // Different cyberpunk theme strategy
        }
    }
}
```

### 5. Builder Pattern

Player initialization with builder-style API:

```swift
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
    self.achievements = PlayerAchievements()
}
```

## 📦 State Management

### Local State

**@State**: View-local state
```swift
struct InventoryView: View {
    @State private var selectedItem: TradeItem?
    @State private var showingDetail = false
}
```

### Shared State

**@EnvironmentObject**: Globally shared state
```swift
struct MapView: View {
    @EnvironmentObject var player: Player
    @EnvironmentObject var locationManager: LocationManager
}
```

### State Object Lifecycle

```swift
struct ContentView: View {
    @StateObject private var player = Player.createDefault()
    // StateObject persists for view's lifetime
    // Only created once, even on view re-renders
}
```

## 🔐 Security Architecture

### Secure Storage Layer

```swift
class SecureStorage {
    // Keychain-based storage
    func save(key: String, value: String) -> Bool
    func retrieve(key: String) -> String?
    func delete(key: String) -> Bool
}
```

**Use Cases**:
- Authentication tokens
- User credentials (if local auth)
- Sensitive player data

### Network Security

- HTTPS for all API calls
- Token-based authentication
- Socket.IO secure connections
- Input validation before server submission

## 💾 Persistence Architecture

### PlayerDataManager

**Auto-Save System**:
```swift
class PlayerDataManager {
    static let shared = PlayerDataManager()

    private var autoSaveTimer: Timer?
    private let autoSaveInterval: TimeInterval = 300 // 5 minutes

    func startAutoSave(for player: Player) {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval) {
            Task { await player.save() }
        }
    }
}
```

**Scene Phase Detection**:
```swift
.onChange(of: scenePhase) { phase in
    switch phase {
    case .background:
        savePlayerData() // Save when backgrounded
    case .active:
        loadPlayerData() // Restore when active
    }
}
```

**Backup System**:
- Primary save location
- Backup rotation (keep last N backups)
- Version tracking
- Corruption detection

## 🌐 Network Architecture

### REST API Layer

```swift
class NetworkManager {
    func getPlayerData() async throws -> APIResponse<PlayerDetail>
    func getMarketPrices() async throws -> APIResponse<[MarketPrice]>
    func getMerchants() async throws -> APIResponse<[MerchantData]>
}
```

**Pattern**: Async/await with structured error handling

### WebSocket Layer

```swift
class SocketManager {
    private var socket: SocketIOClient?

    // Event Emission
    func updatePlayerLocation(coordinate: CLLocationCoordinate2D, playerId: String)
    func sendTradeOffer(to playerId: String, ...)
    func submitAuctionBid(auctionId: String, bidAmount: Int)

    // Event Reception
    private func handleNearbyPlayersUpdate(data: [Any])
    private func handleTradeActivity(data: [Any])
    private func handlePriceUpdate(data: [Any])
}
```

**Reconnection Logic**:
```
Connection Lost
    ↓
Start Reconnection Timer (5s delay)
    ↓
Attempt Reconnection (max 5 attempts)
    ↓
Success → Reset counter
Failure → Increment counter
    ↓
Max Attempts → ConnectionStatus.failed
```

## 🎨 UI Architecture

### Design System Organization

```
Components/
├── CyberpunkDesignSystem.swift   # Core design tokens
├── CyberpunkComponents.swift     # Reusable components
├── EnhancedFontSystem.swift      # Typography system
└── Specialized components...

Utils/
└── JRPGScreenManager.swift       # Screen transitions
```

### Component Reusability

```swift
// Atomic Components
Button → CyberpunkButton
Card → CyberpunkCard
Input → CyberpunkTextField

// Molecular Components
ItemCard (uses CyberpunkCard + typography)
PlayerInfoOverlay (uses multiple atoms)

// Organism Components
InventoryGrid (uses ItemCards)
TradeActivityFeed (uses Cards + animations)
```

## 🧪 Testing Architecture

### Test Organization

```
way3Tests/
├── Core/
│   └── AuthManagerTests.swift
├── Security/
│   └── SecureStorageTests.swift
└── way3Tests.swift

way3UITests/
├── way3UITests.swift
└── way3UITestsLaunchTests.swift
```

### Testing Strategy

- **Unit Tests**: Core logic, managers, data models
- **Integration Tests**: Component interactions
- **UI Tests**: User flows, critical paths
- **Security Tests**: Keychain, auth, data protection

## 📊 Performance Optimization

### Lazy Loading

```swift
// Only load items when needed
var filteredItems: [TradeItem] {
    availableItems.filter { item in
        player.currentLicense >= item.requiredLicense
    }
}
```

### Price Rounding

```swift
// Simplify calculations with 100-won increments
var displayPrice: Int {
    return ((currentPrice + 50) / 100) * 100
}
```

### Distance Culling

```swift
// Only process nearby entities
func searchNearbyPlayers(radius: Double) {
    socket?.emit("searchNearbyPlayers", [
        "lat": lat,
        "lng": lng,
        "radius": radius  // Limit search area
    ])
}
```

### Main Thread Enforcement

```swift
@MainActor
class Player: ObservableObject {
    // All UI updates on main thread
}

DispatchQueue.main.async {
    self.nearbyPlayers = players
}
```

## 🔧 Configuration Management

### NetworkConfiguration

```swift
struct NetworkConfiguration {
    static let baseURL = "https://your-server.com"
    static let socketURL = "wss://your-server.com"
    static let timeout: TimeInterval = 30.0
}
```

### Game Configuration

```swift
struct GameConfiguration {
    static let autoSaveInterval: TimeInterval = 300
    static let maxInventorySize = 50
    static let experiencePerLevel = 100
    static let priceUpdateInterval: TimeInterval = 3600
}
```

## 📈 Scalability Considerations

### Horizontal Scaling

- Stateless server design (for future backend)
- Socket.IO room-based segmentation (by district)
- Distributed player data (separate services for auth, trading, social)

### Vertical Scaling

- Efficient data structures (dictionaries for O(1) lookups)
- Lazy evaluation where possible
- Resource cleanup (timers, socket connections)

### Code Organization for Scale

- Modular player system (easy to extend)
- Protocol-based abstractions
- Clear separation of concerns
- Dependency injection

---

**Next**: [02_PLAYER_SYSTEM.md](02_PLAYER_SYSTEM.md) - Deep dive into player components
