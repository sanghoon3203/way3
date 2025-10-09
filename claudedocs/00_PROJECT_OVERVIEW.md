# Way3 - Location-Based Trading Game

## 📱 Project Overview

**Way3** is an iOS location-based trading game that combines real-world geography with virtual commerce mechanics. Players explore their real-world surroundings to discover merchants, trade items, and build their trading empire - similar to Pokemon GO but focused on trading and economic gameplay.

### 🎯 Core Concept

Players become virtual traders navigating the real streets of Seoul (and potentially other cities). Using their physical location, they interact with virtual merchants, buy and sell goods, manage inventory, and compete with other players in real-time markets.

## 🏗️ Technical Stack

### Platform & Languages
- **Platform**: iOS (SwiftUI)
- **Language**: Swift 5+
- **Minimum iOS**: iOS 16.0+
- **Architecture**: MVVM with modular component design

### Core Frameworks
- **SwiftUI**: Modern declarative UI framework
- **CoreLocation**: GPS and location services
- **MapboxMaps**: Interactive maps and location visualization
- **SocketIO**: Real-time multiplayer communication
- **Combine**: Reactive programming for data flow

### Dependencies
```swift
// Package Dependencies
- MapboxMaps (~> 11.0)
- SocketIO (~> 16.0)
```

## 🎮 Key Features

### 1. Location-Based Gameplay
- Real-world GPS integration
- District-based pricing mechanics (Seoul regions)
- Distance affects item availability and pricing
- Virtual merchants positioned at real locations

### 2. Trading System
- Buy/Sell/Exchange mechanics
- Dynamic pricing based on:
  - District/region multipliers
  - Market demand fluctuations
  - Distance from player location
- License-gated high-value items
- Profit calculation and tracking

### 3. Player Progression
- **5-Component Modular System**:
  - `PlayerCore`: Identity, money, level, experience
  - `PlayerStats`: Skills, attributes, carrying capacity
  - `PlayerInventory`: Items, equipment, storage
  - `PlayerRelationships`: Friends, merchants, guilds
  - `PlayerAchievements`: Progress tracking, milestones

- **License System**: Beginner → Intermediate → Advanced → Expert → Master
- **Skill Development**: Trading, Negotiation, Navigation, etc.
- **Achievement System**: Milestone tracking and rewards

### 4. Real-Time Multiplayer
- Nearby player discovery (Pokemon GO style)
- Real-time trade activity feed
- Live market price updates
- Player-to-player trade offers
- Guild/social features

### 5. Auction System
- Real-time bidding on rare items
- Auction hall with live updates
- Competitive marketplace

### 6. Cyberpunk/JRPG Aesthetic
- Custom design system inspired by cyberpunk themes
- Neon color palette (cyan, yellow, gold accents)
- Angular UI with technical/monospace typography
- Custom font system (ChosunCentennial)
- JRPG-style character progression

## 📦 Project Structure

```
way3/
├── Core/                          # Core managers and game logic
│   ├── AuthManager.swift         # Authentication
│   ├── DataManager.swift         # Game data coordination
│   ├── SocketManager.swift       # Real-time networking
│   ├── AuctionManager.swift      # Auction system
│   ├── DistrictManager.swift     # Location/district logic
│   ├── GameLogger.swift          # Logging system
│   └── ErrorAlert.swift          # Error handling
│
├── Models/                        # Data models
│   ├── Player.swift              # Unified player model
│   ├── Player/                   # Modular player components
│   │   ├── PlayerCore.swift
│   │   ├── PlayerStats.swift
│   │   ├── PlayerInventory.swift
│   │   ├── PlayerRelationships.swift
│   │   ├── PlayerAchievements.swift
│   │   └── PlayerDataManager.swift
│   ├── TradeItem.swift           # Trading items
│   ├── Achievement.swift         # Achievement definitions
│   └── GameEnums.swift           # Game enumerations
│
├── Views/                         # SwiftUI views
│   ├── Auth/                     # Login/registration
│   ├── Game/                     # Main game screens
│   ├── Map/                      # Map and location views
│   ├── Trade/                    # Trading interfaces
│   ├── Auction/                  # Auction hall
│   ├── Shop/                     # Shop views
│   ├── Player/                   # Player screens (inventory, skills)
│   ├── Quest/                    # Quest/achievement views
│   └── Components/               # Shared UI components
│
├── Components/                    # Reusable UI components
│   ├── CyberpunkComponents.swift
│   ├── CyberpunkDesignSystem.swift
│   ├── EnhancedFontSystem.swift
│   ├── LocationTrackingButton.swift
│   ├── EnhancedItemCard.swift
│   └── ItemDetailCard.swift
│
├── Utils/                         # Utility classes
│   ├── CyberpunkDesignSystem.swift
│   └── JRPGScreenManager.swift
│
├── Security/                      # Security features
│   └── SecureStorage.swift       # Keychain integration
│
├── Extensions/                    # Swift extensions
│   ├── Font+ChosunSystem.swift
│   ├── Color+GameColors.swift
│   └── CLLocationCoordinate2D+Codable.swift
│
├── Resources/                     # Assets and resources
│   ├── ChosunCentennial_otf.otf # Custom font
│   ├── Bgmv/                    # Background videos
│   └── 3D_Models/               # 3D character models
│
└── ContentView.swift              # Main app entry point
```

## 🔄 Data Flow Architecture

```
User Action → View (SwiftUI)
    ↓
EnvironmentObject/StateObject (Player, GameManager, etc.)
    ↓
Core Managers (DataManager, SocketManager)
    ↓
Network Layer / Local Storage
    ↓
Server / Device Storage
```

## 🌐 Network Architecture

### Real-Time Features (Socket.IO)
- Connection management with auto-reconnection
- Event-based communication
- Real-time updates for:
  - Nearby players
  - Trade activity
  - Price changes
  - Trade offers
  - Auction bids

### REST API (NetworkManager)
- Player data synchronization
- Market data fetching
- Merchant information
- Authentication

## 💾 Data Persistence

### Local Storage
- **PlayerDataManager**: Automatic save/load system
- Auto-save every 5 minutes
- Scene phase detection (background/foreground)
- Backup system with version tracking

### Secure Storage
- **SecureStorage**: Keychain-based security
- Authentication tokens
- Sensitive player data

## 🎨 Design System

### Color Palette
- **Primary**: Cyberpunk Yellow (`#FFD700`)
- **Accent**: Cyberpunk Cyan (`#00E5E5`)
- **Success**: Neon Green (`#00FF4D`)
- **Background**: Dark (`#0D0D14`)
- **Cards**: Dark Gray (`#26303A`)

### Typography
- **Custom Font**: ChosunCentennial (Korean traditional)
- **System Fonts**: Monospace design for technical UI
- **Font Sizes**: 10pt (technical) → 24pt (titles)

### UI Principles
- Angular, technical aesthetic
- Neon borders and glows
- High contrast for readability
- JRPG-style information density

## 🚀 Key Workflows

### Player Session Flow
```
1. App Launch → StartView (background video)
2. Authentication → LoginView
3. Game Entry → MainTabView
4. Location Tracking Start
5. Real-time Connection (Socket.IO)
6. Player Data Load (local + server sync)
7. Auto-save initialization
8. Game Loop → Trading/Exploration
9. Background Save → Session End
```

### Trading Flow
```
1. Player discovers merchant (location-based)
2. View merchant inventory
3. Select item → Check requirements (license, funds)
4. Negotiate/Buy → Transaction processing
5. Update inventory and stats
6. Experience gain, skill improvement
7. Relationship tracking with merchant
8. Achievement progress update
9. Broadcast trade to nearby players
10. Auto-save changes
```

### Real-Time Multiplayer Flow
```
1. Player location update → Socket emission
2. Server processes → Nearby player query
3. Socket broadcast → NearbyPlayersUpdate event
4. Client receives → UI updates
5. Trade activity → Broadcast to district group
6. Price changes → Market update events
7. Trade offers → Direct player messaging
```

## 📊 Performance Considerations

### Optimization Strategies
- **Lazy Loading**: Items and merchants loaded on-demand
- **Caching**: Frequent data cached locally
- **Distance Culling**: Only process nearby entities
- **Price Rounding**: 100-won increments for simplicity
- **Socket Throttling**: Location updates limited to prevent spam
- **Auto-save Batching**: Saves batched every 5 minutes

### Resource Management
- Background scene phase detection
- Memory cleanup on logout
- Socket reconnection logic
- Timer invalidation on deinit

## 🧪 Testing Infrastructure

### Test Suites
- **way3Tests**: Core functionality unit tests
  - Security tests (SecureStorageTests)
  - Core logic tests (AuthManagerTests)
- **way3UITests**: UI automation tests
  - Launch tests
  - User flow tests

## 🔐 Security Features

### Data Protection
- Keychain integration for sensitive data
- Secure token storage
- Authentication state management
- Network security (HTTPS)

### Privacy
- Location permission handling
- User data encryption
- Offline mode support

## 📱 Build Configuration

### Target Information
- **Product Name**: way3
- **Bundle Identifier**: com.yourcompany.way3
- **Deployment Target**: iOS 16.0+
- **Supported Devices**: iPhone, iPad
- **Entitlements**: Location services, network access

### Build Scripts
- `start_server.sh`: Development server startup

## 🎯 Future Roadmap

### Planned Features
- Global expansion (beyond Seoul)
- More merchant types and categories
- Crafting system
- Player housing/storage facilities
- Seasonal events
- Cross-platform support (Android)
- AR integration for merchant discovery

## 📚 Documentation Structure

This documentation is organized into the following guides:

1. **00_PROJECT_OVERVIEW.md** (This file) - High-level overview
2. **01_ARCHITECTURE.md** - Detailed architecture and patterns
3. **02_PLAYER_SYSTEM.md** - Player model and components
4. **03_GAME_FEATURES.md** - Trading, achievements, progression
5. **04_NETWORK_REALTIME.md** - Socket.IO and networking
6. **05_UI_DESIGN_SYSTEM.md** - Cyberpunk UI components
7. **06_DATA_MODELS.md** - Enums, structs, data types
8. **07_DEVELOPER_GUIDE.md** - Setup, build, integration

## 🤝 Contributing

### Code Style
- SwiftUI best practices
- MVVM architecture adherence
- Modular component design
- Comprehensive code comments
- Type-safe enumerations

### Development Workflow
1. Feature branch creation
2. Implementation with tests
3. Code review
4. Integration testing
5. Merge to main

---

**Version**: 1.0
**Last Updated**: 2025-10-05
**Platform**: iOS 16.0+
**Status**: Active Development
