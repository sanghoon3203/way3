# Network & Real-Time Communication

## 🌐 Network Architecture Overview

Way3 uses a **dual-network architecture**:

1. **REST API** (`NetworkManager`) - Traditional HTTP requests for static data
2. **WebSocket** (`SocketManager`) - Real-time bidirectional communication via Socket.IO

```
┌──────────────────────────────────────────┐
│          iOS Client (Way3)               │
├──────────────────┬───────────────────────┤
│  NetworkManager  │    SocketManager      │
│   (REST/HTTP)    │    (WebSocket)        │
└────────┬─────────┴──────────┬────────────┘
         │                    │
    ┌────▼────┐         ┌─────▼─────┐
    │ REST API│         │Socket.IO  │
    │ Server  │         │  Server   │
    └─────────┘         └───────────┘
```

## 📡 Socket.IO Integration

### SocketManager Architecture

**File**: `Core/SocketManager.swift`

**Singleton Pattern**:
```swift
class SocketManager: ObservableObject {
    static let shared = SocketManager()

    private var manager: SocketIO.SocketManager?
    private var socket: SocketIOClient?

    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected

    private init() {
        setupSocket()
    }
}
```

### Connection Management

#### Setup & Configuration

```swift
private func setupSocket() {
    guard let url = URL(string: NetworkConfiguration.baseURL) else {
        return
    }

    let config: SocketIOClientConfiguration = [
        .log(false),
        .compress,
        .connectParams(["platform": "ios"])
    ]

    manager = SocketIO.SocketManager(socketURL: url, config: config)
    socket = manager?.defaultSocket

    setupEventHandlers()
}
```

#### Connection States

```swift
enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed

    var description: String {
        switch self {
        case .disconnected: return "연결 끊김"
        case .connecting: return "연결 중..."
        case .connected: return "연결됨"
        case .reconnecting: return "재연결 중..."
        case .failed: return "연결 실패"
        }
    }

    var color: Color {
        switch self {
        case .disconnected, .failed: return .red
        case .connecting, .reconnecting: return .orange
        case .connected: return .green
        }
    }
}
```

### Auto-Reconnection System

**Strategy**: Exponential backoff with max attempts

```swift
private var reconnectionAttempts = 0
private let maxReconnectionAttempts = 5
private let reconnectionDelay: TimeInterval = 5.0

private func startReconnection() {
    guard !isReconnecting && reconnectionAttempts < maxReconnectionAttempts else {
        if reconnectionAttempts >= maxReconnectionAttempts {
            connectionStatus = .failed
        }
        return
    }

    isReconnecting = true
    connectionStatus = .reconnecting
    reconnectionAttempts += 1

    reconnectionTimer = Timer.scheduledTimer(
        withTimeInterval: reconnectionDelay,
        repeats: false
    ) { [weak self] _ in
        self?.attemptReconnection()
    }
}
```

**Reconnection Flow**:
```
Connection Lost
    ↓
Wait 5 seconds
    ↓
Attempt 1/5 reconnect
    ↓
Success → Reset counter, resume normal operation
Failure → Wait 5s, Attempt 2/5
    ↓
... repeat ...
    ↓
Failure at 5/5 → ConnectionStatus.failed
```

## 📨 Event Handling

### System Events

```swift
private func setupEventHandlers() {
    // Connection events
    socket?.on(clientEvent: .connect) { [weak self] data, ack in
        DispatchQueue.main.async {
            self?.isConnected = true
            self?.connectionStatus = .connected
            self?.resetReconnectionAttempts()
        }
    }

    socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
        DispatchQueue.main.async {
            self?.isConnected = false
            self?.connectionStatus = .disconnected
            self?.startReconnection()
        }
    }

    socket?.on(clientEvent: .error) { [weak self] data, ack in
        DispatchQueue.main.async {
            self?.connectionStatus = .failed
            self?.startReconnection()
        }
    }
}
```

### Custom Game Events

#### 1. Nearby Players Update

**Server → Client**:
```swift
socket?.on("nearbyPlayersUpdate") { [weak self] data, ack in
    self?.handleNearbyPlayersUpdate(data: data)
}

private func handleNearbyPlayersUpdate(data: [Any]) {
    guard let playersData = data[0] as? [[String: Any]] else { return }

    let players = playersData.compactMap { playerData -> NearbyPlayer? in
        guard let id = playerData["id"] as? String,
              let name = playerData["name"] as? String,
              let level = playerData["level"] as? Int,
              let lat = playerData["lat"] as? Double,
              let lng = playerData["lng"] as? Double,
              let distance = playerData["distance"] as? Double else {
            return nil
        }

        return NearbyPlayer(
            id: id,
            name: name,
            level: level,
            location: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            distance: distance
        )
    }

    DispatchQueue.main.async {
        self.nearbyPlayers = players
    }
}
```

**Data Model**:
```swift
struct NearbyPlayer: Identifiable {
    let id: String
    let name: String
    let level: Int
    let location: CLLocationCoordinate2D
    let distance: Double

    var distanceText: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}
```

#### 2. Trade Activity Feed

**Server → Client**:
```swift
socket?.on("tradeActivity") { [weak self] data, ack in
    self?.handleTradeActivity(data: data)
}

private func handleTradeActivity(data: [Any]) {
    guard let activityData = data[0] as? [String: Any],
          let playerId = activityData["playerId"] as? String,
          let playerName = activityData["playerName"] as? String,
          let merchantName = activityData["merchantName"] as? String,
          let itemName = activityData["itemName"] as? String,
          let tradeType = activityData["tradeType"] as? String,
          let isProfit = activityData["isProfit"] as? Bool else {
        return
    }

    let activity = TradeActivity(
        playerId: playerId,
        playerName: playerName,
        merchantName: merchantName,
        itemName: itemName,
        tradeType: tradeType,
        isProfit: isProfit,
        timestamp: Date()
    )

    DispatchQueue.main.async {
        self.recentTradeActivity.insert(activity, at: 0)
        if self.recentTradeActivity.count > 50 {
            self.recentTradeActivity = Array(self.recentTradeActivity.prefix(50))
        }
    }
}
```

#### 3. Market Price Updates

**Server → Client**:
```swift
socket?.on("priceUpdate") { [weak self] data, ack in
    self?.handlePriceUpdate(data: data)
}

private func handlePriceUpdate(data: [Any]) {
    guard let priceData = data[0] as? [String: Any],
          let itemName = priceData["itemName"] as? String,
          let oldPrice = priceData["oldPrice"] as? Int,
          let newPrice = priceData["newPrice"] as? Int,
          let district = priceData["district"] as? String else {
        return
    }

    let changePercent = Double(newPrice - oldPrice) / Double(oldPrice) * 100.0

    let update = PriceUpdate(
        itemName: itemName,
        oldPrice: oldPrice,
        newPrice: newPrice,
        district: district,
        changePercent: changePercent,
        timestamp: Date()
    )

    DispatchQueue.main.async {
        self.marketPriceUpdates.insert(update, at: 0)
        if self.marketPriceUpdates.count > 30 {
            self.marketPriceUpdates = Array(self.marketPriceUpdates.prefix(30))
        }
    }
}
```

#### 4. Trade Offers (P2P)

**Server → Client**:
```swift
socket?.on("tradeOffer") { [weak self] data, ack in
    self?.handleTradeOffer(data: data)
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
    }
}
```

## 📤 Client → Server Events

### Location Updates

```swift
func updatePlayerLocation(coordinate: CLLocationCoordinate2D, playerId: String) {
    socket?.emit("updateLocation", [
        "playerId": playerId,
        "lat": coordinate.latitude,
        "lng": coordinate.longitude
    ])
}
```

**Throttling**: To prevent spam, limit location updates to every 5-10 seconds

### Trade Offers

```swift
func sendTradeOffer(
    to playerId: String,
    playerName: String,
    offeredItems: [String],
    requestedItems: [String],
    message: String?
) {
    socket?.emit("sendTradeOffer", [
        "toPlayerId": playerId,
        "toPlayerName": playerName,
        "itemsOffered": offeredItems,
        "itemsRequested": requestedItems,
        "message": message ?? ""
    ])
}

func respondToTradeOffer(offerId: String, accept: Bool) {
    socket?.emit("respondToTradeOffer", [
        "offerId": offerId,
        "accept": accept
    ])
}
```

### Auction Bidding

```swift
func joinAuction(auctionId: String) {
    socket?.emit("joinAuction", [
        "auctionId": auctionId
    ])
}

func submitAuctionBid(auctionId: String, playerId: String, bidAmount: Int) {
    socket?.emit("submitAuctionBid", [
        "auctionId": auctionId,
        "playerId": playerId,
        "bidAmount": bidAmount
    ])
}
```

### Location Groups (Rooms)

**Purpose**: Segment real-time updates by district

```swift
func joinLocationGroup(district: String) {
    socket?.emit("joinLocationGroup", district)
}

func leaveLocationGroup(district: String) {
    socket?.emit("leaveLocationGroup", district)
}
```

**Use Case**:
- Player enters Gangnam → `joinLocationGroup("강남구")`
- Receives only Gangnam-relevant updates (trades, prices, players)
- Player leaves → `leaveLocationGroup("강남구")`

### Nearby Player Search

```swift
func searchNearbyPlayers(lat: Double, lng: Double, radius: Double) {
    socket?.emit("searchNearbyPlayers", [
        "lat": lat,
        "lng": lng,
        "radius": radius  // meters
    ])
}
```

## 🔄 REST API Integration

### NetworkManager

**File**: `Core/NetworkManager.swift` (referenced, implementation similar to below)

```swift
class NetworkManager {
    static let shared = NetworkManager()

    private let baseURL = NetworkConfiguration.baseURL
    private let session = URLSession.shared

    func getPlayerData() async throws -> APIResponse<PlayerDetail> {
        let url = URL(string: "\(baseURL)/api/player")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APIResponse<PlayerDetail>.self, from: data)
    }

    func getMarketPrices() async throws -> APIResponse<[MarketPrice]> {
        let url = URL(string: "\(baseURL)/api/market/prices")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APIResponse<[MarketPrice]>.self, from: data)
    }

    func getMerchants() async throws -> APIResponse<[MerchantData]> {
        let url = URL(string: "\(baseURL)/api/merchants")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(APIResponse<[MerchantData]>.self, from: data)
    }
}
```

### API Response Format

```swift
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let timestamp: Date?
}
```

## 🔐 Authentication

### Token-Based Auth

```swift
func connect(with token: String? = nil) {
    if let token = token {
        socket?.connect(withPayload: ["token": token])
    } else {
        socket?.connect()
    }
}
```

**Flow**:
1. User logs in via REST API → receives JWT token
2. Store token in `SecureStorage` (Keychain)
3. Connect socket with token in payload
4. Server validates token, establishes authenticated connection

## 📊 Data Synchronization

### Load Game Data

```swift
// DataManager.swift
func loadOnlineGameData() async {
    async let playerData = loadPlayerData()
    async let marketData = loadMarketData()
    async let merchantData = loadMerchantData()

    let (_, _, _) = await (playerData, marketData, merchantData)
}
```

**Strategy**: Parallel loading with async/await for performance

### Real-Time Updates

**Price Board Update**:
```swift
func applyPriceUpdates(_ updates: [String: Int]) {
    for (itemName, newPrice) in updates {
        if let existingItem = priceBoard[itemName] {
            priceBoard[itemName] = (district: existingItem.district, price: newPrice)
        }
    }
}
```

## ⚡ Performance Optimization

### Throttling & Debouncing

**Location Updates**:
```swift
private var lastLocationUpdate: Date = Date.distantPast
private let locationUpdateInterval: TimeInterval = 10.0

func updateLocation(_ coordinate: CLLocationCoordinate2D) {
    let now = Date()
    guard now.timeIntervalSince(lastLocationUpdate) >= locationUpdateInterval else {
        return  // Throttle: skip update
    }

    lastLocationUpdate = now
    socketManager.updatePlayerLocation(coordinate: coordinate, playerId: playerId)
}
```

### Data Limiting

**Trade Activity Feed**:
```swift
if self.recentTradeActivity.count > 50 {
    self.recentTradeActivity = Array(self.recentTradeActivity.prefix(50))
}
```

**Price Updates**:
```swift
if self.marketPriceUpdates.count > 30 {
    self.marketPriceUpdates = Array(self.marketPriceUpdates.prefix(30))
}
```

### Main Thread Safety

**All UI updates on main thread**:
```swift
DispatchQueue.main.async {
    self.nearbyPlayers = players
    self.recentTradeActivity.insert(activity, at: 0)
}
```

## 🧪 Error Handling

### Connection Errors

```swift
socket?.on(clientEvent: .error) { [weak self] data, ack in
    DispatchQueue.main.async {
        self?.connectionStatus = .failed
        if let errorData = data.first {
            GameLogger.shared.logError("Socket 오류: \(errorData)", category: .socket)
        }
        self?.startReconnection()
    }
}
```

### Network Timeout

```swift
struct NetworkConfiguration {
    static let timeout: TimeInterval = 30.0
}
```

### Graceful Degradation

**Offline Mode**:
```swift
// DataManager.swift
class OfflineDataGenerator {
    func generateOfflineData() -> (merchants: [Merchant], items: [TradeItem]) {
        // Provide static offline data when server unavailable
        let merchants: [Merchant] = [/* ... */]
        let items: [TradeItem] = [/* ... */]
        return (merchants: merchants, items: items)
    }
}
```

## 🔍 Debugging & Logging

### GameLogger Integration

```swift
// GameLogger.swift (referenced)
enum LogCategory {
    case socket, network, game, player
}

class GameLogger {
    static let shared = GameLogger()

    func logInfo(_ message: String, category: LogCategory)
    func logError(_ message: String, category: LogCategory)
}

// Usage
GameLogger.shared.logInfo("Socket 연결 성공", category: .socket)
GameLogger.shared.logError("Socket 오류: \(error)", category: .socket)
```

## 📱 Lifecycle Management

### App Lifecycle Integration

```swift
// ContentView.swift
.onChange(of: scenePhase) { phase in
    switch phase {
    case .active:
        socketManager.connect()
    case .background:
        socketManager.disconnect()
    default:
        break
    }
}
```

### Cleanup

```swift
deinit {
    stopReconnectionTimer()
    socket?.disconnect()
    socket?.removeAllHandlers()
}
```

---

**Next**: [05_UI_DESIGN_SYSTEM.md](05_UI_DESIGN_SYSTEM.md) - Cyberpunk UI components and styling
