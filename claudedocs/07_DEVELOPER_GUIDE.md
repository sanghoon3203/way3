# Developer Guide

## 🚀 Getting Started

### Prerequisites

**Required**:
- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+
- iOS 16.0+ deployment target
- CocoaPods or Swift Package Manager

**Recommended**:
- Git for version control
- Mapbox account (for maps API key)
- Backend server (Socket.IO + REST API)

### Project Setup

**1. Clone Repository**
```bash
git clone <repository-url>
cd way3
```

**2. Open in Xcode**
```bash
open way3.xcodeproj
```

**3. Install Dependencies**

Dependencies are managed via Swift Package Manager:
- MapboxMaps (~> 11.0)
- SocketIO (~> 16.0)

Xcode will automatically resolve packages on first build.

**4. Configure API Keys**

Create `NetworkConfiguration.swift` (if not exists):
```swift
struct NetworkConfiguration {
    static let baseURL = "https://your-server.com"
    static let mapboxAccessToken = "your-mapbox-token"
    static let timeout: TimeInterval = 30.0
}
```

**5. Add Font Files**

Ensure `ChosunCentennial_otf.otf` is in `Resources/` and added to `Info.plist`:
```xml
<key>UIAppFonts</key>
<array>
    <string>ChosunCentennial_otf.otf</string>
</array>
```

**6. Configure Entitlements**

`way3.entitlements` should include:
```xml
<key>com.apple.security.location</key>
<true/>
<key>com.apple.developer.networking.wifi-info</key>
<true/>
```

**7. Build & Run**
```
Product → Build (⌘B)
Product → Run (⌘R)
```

## 📁 Project Structure

```
way3/
├── way3.xcodeproj              # Xcode project file
├── way3/                       # Main app target
│   ├── Core/                   # Managers and core logic
│   ├── Models/                 # Data models
│   ├── Views/                  # SwiftUI views
│   ├── Components/             # Reusable UI components
│   ├── Utils/                  # Utilities and helpers
│   ├── Security/               # Security features
│   ├── Extensions/             # Swift extensions
│   ├── Resources/              # Assets, fonts, media
│   ├── Assets.xcassets/        # Image assets
│   ├── ContentView.swift       # Main entry point
│   └── way3App.swift           # App lifecycle
│
├── way3Tests/                  # Unit tests
│   ├── Core/
│   └── Security/
│
├── way3UITests/                # UI tests
│
├── claudedocs/                 # Documentation
│
└── start_server.sh             # Dev server script
```

## 🔧 Development Workflow

### Running the App

**Development Build**:
```bash
# Select iPhone simulator
Product → Destination → iPhone 15 Pro
# Run
⌘R
```

**Device Testing**:
1. Connect iPhone via USB
2. Select device in Xcode
3. Trust computer on device
4. Run (⌘R)

### Running Tests

**Unit Tests**:
```bash
Product → Test (⌘U)
```

**Specific Test Suite**:
```bash
⌘6 (Test Navigator)
Right-click test suite → Run
```

**UI Tests**:
```bash
Select way3UITests scheme
⌘U
```

### Debugging

**Breakpoints**:
- Click line number gutter to set breakpoint
- ⌘Y to toggle all breakpoints
- Breakpoint navigator (⌘7)

**Console Logging**:
```swift
#if DEBUG
print("📱 Debug message: \(variable)")
#endif

// Or use GameLogger
GameLogger.shared.logInfo("Message", category: .game)
```

**View Hierarchy**:
- Debug → View Debugging → Capture View Hierarchy
- Inspect SwiftUI view structure

## 🏗️ Architecture Patterns

### Adding a New Feature

**1. Define Data Model** (`Models/`)
```swift
struct NewFeature: Codable {
    let id: String
    var property: String
}
```

**2. Create Manager** (`Core/`)
```swift
class NewFeatureManager: ObservableObject {
    static let shared = NewFeatureManager()

    @Published var data: [NewFeature] = []

    private init() {}

    func loadData() async { /* ... */ }
}
```

**3. Create View** (`Views/`)
```swift
struct NewFeatureView: View {
    @EnvironmentObject var manager: NewFeatureManager

    var body: some View {
        List(manager.data) { item in
            Text(item.property)
        }
        .task {
            await manager.loadData()
        }
    }
}
```

**4. Integrate in App**
```swift
// ContentView.swift
@StateObject private var newFeatureManager = NewFeatureManager.shared

MainTabView()
    .environmentObject(newFeatureManager)
```

### Adding a New Player Component

**1. Create Component Model** (`Models/Player/`)
```swift
class PlayerNewComponent: Codable {
    var property: Int = 0

    func performAction() { /* ... */ }
}
```

**2. Add to Player** (`Models/Player.swift`)
```swift
@MainActor
class Player: ObservableObject {
    @Published var newComponent: PlayerNewComponent

    init() {
        self.newComponent = PlayerNewComponent()
        // ...
    }
}
```

**3. Update Codable**
```swift
enum CodingKeys: String, CodingKey {
    case core, stats, inventory, relationships, achievements, newComponent
}

required init(from decoder: Decoder) throws {
    // ... decode newComponent
}

func encode(to encoder: Encoder) throws {
    // ... encode newComponent
}
```

## 🎨 UI Development

### Creating Cyberpunk Components

```swift
// 1. Create base component
struct NewCyberpunkComponent: View {
    var body: some View {
        VStack {
            // Content
        }
        .padding(CyberpunkLayout.cardPadding)
        .cyberpunkCard()  // Apply design system
    }
}

// 2. Add to Components/
// 3. Use in views
NewCyberpunkComponent()
```

### Custom Modifiers

```swift
extension View {
    func customModifier(enabled: Bool) -> some View {
        self
            .foregroundColor(enabled ? .cyberpunkYellow : .gray)
            .font(.cyberpunkBody())
    }
}
```

## 🌐 Backend Integration

### REST API Calls

```swift
// NetworkManager.swift
func fetchData<T: Codable>(endpoint: String) async throws -> T {
    let url = URL(string: "\(baseURL)/\(endpoint)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(T.self, from: data)
}

// Usage
let items: [TradeItem] = try await networkManager.fetchData(endpoint: "api/items")
```

### Socket.IO Events

**Adding New Event Handler**:
```swift
// SocketManager.swift
func setupEventHandlers() {
    // ...
    socket?.on("newEventName") { [weak self] data, ack in
        self?.handleNewEvent(data: data)
    }
}

private func handleNewEvent(data: [Any]) {
    guard let eventData = data[0] as? [String: Any],
          let property = eventData["property"] as? String else {
        return
    }

    // Process data
    DispatchQueue.main.async {
        self.eventProperty = property
    }
}
```

**Emitting Events**:
```swift
func emitNewEvent(data: String) {
    socket?.emit("eventName", [
        "property": data,
        "timestamp": Date().timeIntervalSince1970
    ])
}
```

## 🧪 Testing

### Unit Test Example

```swift
// way3Tests/Core/NewManagerTests.swift
import XCTest
@testable import way3

final class NewManagerTests: XCTestCase {
    var manager: NewManager!

    override func setUp() {
        super.setUp()
        manager = NewManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testDataLoading() async throws {
        await manager.loadData()
        XCTAssertFalse(manager.data.isEmpty)
    }
}
```

### UI Test Example

```swift
// way3UITests/NewFeatureUITests.swift
import XCTest

final class NewFeatureUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }

    func testNewFeatureFlow() {
        let button = app.buttons["FeatureButton"]
        XCTAssertTrue(button.exists)
        button.tap()

        let view = app.otherElements["FeatureView"]
        XCTAssertTrue(view.waitForExistence(timeout: 2))
    }
}
```

## 🔐 Security Best Practices

### Secure Data Storage

```swift
// Store sensitive data in Keychain
let storage = SecureStorage()
_ = storage.save(key: "authToken", value: token)

// Retrieve
if let token = storage.retrieve(key: "authToken") {
    // Use token
}

// Delete when done
_ = storage.delete(key: "authToken")
```

### Network Security

```swift
// Always use HTTPS
let url = URL(string: "https://secure-server.com/api")!

// Validate responses
guard response.success else {
    throw APIError.invalidResponse
}
```

## 📱 Performance Optimization

### Async/Await Best Practices

```swift
// Load data in parallel
func loadGameData() async {
    async let items = loadItems()
    async let merchants = loadMerchants()
    async let prices = loadPrices()

    let (itemsData, merchantsData, pricesData) = await (items, merchants, prices)
    // All loaded in parallel
}
```

### Main Thread Safety

```swift
// Ensure UI updates on main thread
Task { @MainActor in
    player.money = newValue
}

// Or
DispatchQueue.main.async {
    self.isLoading = false
}
```

### Memory Management

```swift
// Use weak self in closures
socket?.on("event") { [weak self] data, ack in
    guard let self = self else { return }
    self.handleEvent(data)
}

// Cleanup in deinit
deinit {
    timer?.invalidate()
    socket?.removeAllHandlers()
}
```

## 🐛 Common Issues & Solutions

### Issue: Build Fails with Font Error

**Solution**:
1. Verify font file in Resources/
2. Check Info.plist for UIAppFonts
3. Clean build folder (⌘⇧K)
4. Rebuild (⌘B)

### Issue: Socket Won't Connect

**Solution**:
1. Check server URL in NetworkConfiguration
2. Verify server is running
3. Check console for error messages
4. Try forceReconnect()

### Issue: Location Updates Not Working

**Solution**:
1. Check Info.plist for location permissions:
   - NSLocationWhenInUseUsageDescription
   - NSLocationAlwaysAndWhenInUseUsageDescription
2. Request permissions in code
3. Enable location in simulator (Features → Location)

### Issue: Data Not Persisting

**Solution**:
1. Check PlayerDataManager save path
2. Verify Codable implementation
3. Check for encode/decode errors in console
4. Test with smaller data subset

## 📦 Building for Release

### Release Checklist

- [ ] Update version number (CFBundleShortVersionString)
- [ ] Update build number (CFBundleVersion)
- [ ] Remove debug logging
- [ ] Test on physical device
- [ ] Verify all assets are optimized
- [ ] Check entitlements
- [ ] Archive build (Product → Archive)

### App Store Preparation

**1. Configure Signing**:
- Xcode → Signing & Capabilities
- Select team
- Automatic signing

**2. Create Archive**:
```
Product → Archive
```

**3. Validate Archive**:
- Window → Organizer → Archives
- Select archive → Validate App

**4. Distribute**:
- Distribute App → App Store Connect
- Upload

## 🔄 Version Control

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "Add new feature"

# Push to remote
git push origin feature/new-feature

# Create pull request on GitHub/GitLab
```

### Commit Message Format

```
[Type] Brief description

Detailed explanation if needed

- Bullet points for changes
- Multiple lines OK
```

Types: Feature, Fix, Refactor, Docs, Test, Style

## 📊 Monitoring & Analytics

### Logging

```swift
// Use GameLogger for structured logging
GameLogger.shared.logInfo("User logged in", category: .player)
GameLogger.shared.logError("API failed: \(error)", category: .network)
```

### Performance Monitoring

```swift
// Measure execution time
let start = Date()
await expensiveOperation()
let duration = Date().timeIntervalSince(start)
print("⏱️ Operation took \(duration)s")
```

## 🎓 Learning Resources

### Apple Documentation
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Combine](https://developer.apple.com/documentation/combine)
- [CoreLocation](https://developer.apple.com/documentation/corelocation)

### Third-Party Libraries
- [MapboxMaps for iOS](https://docs.mapbox.com/ios/maps/guides/)
- [Socket.IO Swift Client](https://github.com/socketio/socket.io-client-swift)

### Design Resources
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## 🤝 Contributing

### Code Style

- Follow Swift style guide
- Use meaningful variable names
- Comment complex logic
- Maintain consistent formatting
- Group related code with // MARK:

### Pull Request Process

1. Create feature branch
2. Implement feature with tests
3. Update documentation
4. Submit PR with description
5. Address review feedback
6. Merge after approval

## 📞 Support

### Getting Help

- Check documentation (this guide)
- Review code comments
- Search issues on GitHub
- Ask in team channels

### Reporting Bugs

Include:
- iOS version
- Device model
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/logs

---

**Project**: Way3 - Location-Based Trading Game
**Platform**: iOS 16.0+
**Language**: Swift 5+
**Last Updated**: 2025-10-05
