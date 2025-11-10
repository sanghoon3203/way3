# way3 iOS Game - Function Specifications

> **Project**: way3 Trading Game (Seoul-based iOS location game)
>
> **Created**: 2025-01-11
>
> **Total Files**: 89 Swift source files
>
> **Purpose**: Comprehensive function documentation for all Swift files in the way3 project

---

## Table of Contents

- [Components](#components)
  - [CyberpunkComponents.swift](#cyberpunkcomponentsswift)
  - [CyberpunkInventoryComponents.swift](#cyberpunkinventorycomponentsswift)
  - [CyberpunkNavigationComponents.swift](#cyberpunknavigationcomponentsswift)
  - [CyberpunkProfileComponents.swift](#cyberpunkprofilecomponentsswift)
  - [CyberpunkShopComponents.swift](#cyberpunkshopcomponentsswift)
  - [EnhancedFontSystem.swift](#enhancedfontsystemswift)
  - [EnhancedItemCard.swift](#enhanceditemcardswift)
  - [FeaturedItemsGrid.swift](#featureditemsgridswift)
  - [ItemDetailCard.swift](#itemdetailcardswift)
  - [LocationTrackingButton.swift](#locationtrackingbuttonswift)
- [Core](#core)
  - [ContentView.swift](#contentviewswift)
  - [APIResponse.swift](#apiresponseswift)
  - [AuthManager.swift](#authmanagerswift)
  - [DataManager.swift](#datamanagerswift)
  - [DistrictManager.swift](#districtmanagerswift)

---

## Components

### CyberpunkComponents.swift

Reusable cyberpunk-style UI components maintaining JRPG functionality with cyberpunk theming.

#### `dataTransferAnimation(index:) -> CGFloat`
**File**: way3/Components/CyberpunkComponents.swift:126
**Purpose**: 데이터 전송 애니메이션 효과 생성 (Data transfer animation effect)
**Parameters**:
- `index` (Int): Animation sequence index for staggered effect
**Returns**: (CGFloat) Scale effect value based on sine wave calculation
**Side Effects**: None - pure calculation
**Related**: Used in `CyberpunkDialogueBox.body`

---

### CyberpunkInventoryComponents.swift

Cyberpunk-style inventory components maintaining full InventoryView functionality.

#### `init(tradeGood:onTap:)`
**File**: way3/Components/CyberpunkInventoryComponents.swift:12-16
**Purpose**: CyberpunkTradeGoodCard 초기화
**Parameters**:
- `tradeGood` (TradeGood): Trade good data to display
- `onTap` (() -> Void): Closure executed when card is tapped
**Returns**: None (initializer)
**Side Effects**: Initializes @State property `isPressed`
**Related**: `CyberpunkTradeGoodCard`

---

### CyberpunkNavigationComponents.swift

Cyberpunk-style navigation components enhancing MainTabView with cyberpunk theming.

#### `formatCredits(_:) -> String`
**File**: way3/Components/CyberpunkNavigationComponents.swift:77-85
**Purpose**: 크레딧 금액을 읽기 쉬운 형식으로 변환 (Format credits for display)
**Parameters**:
- `amount` (Int): Raw credit amount
**Returns**: (String) Formatted string with M/K suffixes or plain number
**Side Effects**: None
**Related**: Used in `CyberpunkStatusBar.body`

#### `setupCyberpunkTabBarAppearance() -> Void`
**File**: way3/Components/CyberpunkNavigationComponents.swift:128-161
**Purpose**: Configure enhanced cyberpunk tab bar appearance with gradient effects
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Modifies `UITabBar.appearance()` globally
**Related**: Called from `setupEnhancedCyberpunkTabBar()`

#### `createGlowImage() -> UIImage?`
**File**: way3/Components/CyberpunkNavigationComponents.swift:163-175
**Purpose**: Create subtle glow effect image for tab bar shadow
**Parameters**: None
**Returns**: (UIImage?) Generated glow image or nil if creation fails
**Side Effects**: Creates UIGraphics context
**Related**: Used in `setupCyberpunkTabBarAppearance()`

#### `corporateTitle(for:) -> String`
**File**: way3/Components/CyberpunkNavigationComponents.swift:263-267
**Purpose**: Get corporate-style title for tab index
**Parameters**:
- `index` (Int): Tab index
**Returns**: (String) Corporate title or "UNKNOWN" if index out of bounds
**Side Effects**: None
**Related**: `CyberpunkTabConfiguration`

#### `hasNotification(for:) -> Bool`
**File**: way3/Components/CyberpunkNavigationComponents.swift:268-277
**Purpose**: Check if tab has notification indicator
**Parameters**:
- `index` (Int): Tab index
**Returns**: (Bool) True if tab should show notification
**Side Effects**: None (currently returns mock data)
**Related**: `CyberpunkTabConfiguration`

---

### CyberpunkProfileComponents.swift

Cyberpunk-style profile components maintaining full ProfileView functionality.

#### `formatCurrency(_:) -> String`
**File**: way3/Components/CyberpunkProfileComponents.swift:225-229
**Purpose**: Format currency amount with decimal separators
**Parameters**:
- `amount` (Int): Raw currency amount
**Returns**: (String) Formatted currency string with separators
**Side Effects**: None
**Related**: Used in `CyberpunkTradingDashboard`

#### `daysSinceCreated(_:) -> Int`
**File**: way3/Components/CyberpunkProfileComponents.swift:747-752
**Purpose**: Calculate days since account creation
**Parameters**:
- `createdAt` (Date): Account creation date
**Returns**: (Int) Number of days (minimum 1)
**Side Effects**: None
**Related**: Used in profile display components

---

### CyberpunkShopComponents.swift

Cyberpunk-style shop components maintaining full ShopView functionality.

#### `getCurrentMoney() -> Int`
**File**: way3/Components/CyberpunkShopComponents.swift:111-114
**Purpose**: Get current player money (placeholder implementation)
**Parameters**: None
**Returns**: (Int) Current money amount
**Side Effects**: None
**Related**: Used in `CyberpunkSecretShopView`
**Note**: TODO: Get from player data

---

### EnhancedFontSystem.swift

Complete ChosunCentennial font design system for the way3 game.

#### `chosun(_:weight:) -> Font`
**File**: way3/Components/EnhancedFontSystem.swift:13-15
**Purpose**: Create ChosunCentennial font with specified size and weight
**Parameters**:
- `size` (CGFloat): Font size in points
- `weight` (Font.Weight): Font weight (default: .regular)
**Returns**: (Font) Configured ChosunCentennial font
**Side Effects**: None
**Related**: Base font system for all text styles

#### `formatPrice(_:) -> String`
**File**: way3/Components/EnhancedFontSystem.swift:367-371
**Purpose**: Format price with decimal separators
**Parameters**:
- `price` (Int): Raw price value
**Returns**: (String) Formatted price string or "0" on failure
**Side Effects**: None
**Related**: `ChosunPriceText`

#### `formatTime() -> String`
**File**: way3/Components/EnhancedFontSystem.swift:503-509
**Purpose**: Format time based on display format
**Parameters**: None (uses instance properties)
**Returns**: (String) Formatted time string
**Side Effects**: None
**Related**: `ChosunTimeText`

#### `timeAgoString() -> String`
**File**: way3/Components/EnhancedFontSystem.swift:511-524
**Purpose**: Calculate relative time string (e.g., "3분 전")
**Parameters**: None (uses instance time property)
**Returns**: (String) Korean relative time string
**Side Effects**: None
**Related**: Used in `formatTime()` for relative format

#### `levelColor(_:) -> Color`
**File**: way3/Components/EnhancedFontSystem.swift:552-563
**Purpose**: Get color for level display based on level range
**Parameters**:
- `level` (Int): Player level
**Returns**: (Color) Color corresponding to level tier
**Side Effects**: None
**Related**: `ChosunLevelText`

---

### EnhancedItemCard.swift

Enhanced item cards with grade indicators and contextual buttons.

#### `gradientForGrade(_:) -> LinearGradient`
**File**: way3/Components/EnhancedItemCard.swift:62-82
**Purpose**: Generate gradient background for item grade
**Parameters**:
- `grade` (ItemGrade): Item grade enum value
**Returns**: (LinearGradient) Grade-specific gradient
**Side Effects**: None
**Related**: Used in item card background

#### `itemIcon` (computed property)
**File**: way3/Components/EnhancedItemCard.swift:161-184
**Purpose**: Get emoji icon based on item category
**Parameters**: None (uses `item.category`)
**Returns**: (String) Emoji icon for category
**Side Effects**: None
**Related**: Displayed in card center

---

### FeaturedItemsGrid.swift

Grid layout for featured items with search and filter capabilities.

#### `displayItems` (computed property)
**File**: way3/Components/FeaturedItemsGrid.swift:26-34
**Purpose**: Get items to display based on trade mode
**Parameters**: None
**Returns**: ([TradeItem]) Array of items for current mode
**Side Effects**: None
**Related**: Source for `featuredItems` and `remainingItems`

#### `featuredItems` (computed property)
**File**: way3/Components/FeaturedItemsGrid.swift:36-48
**Purpose**: Get top 6 items sorted by grade, price, and name
**Parameters**: None
**Returns**: ([TradeItem]) Up to 6 featured items
**Side Effects**: None
**Related**: Displayed in featured section

#### `remainingItems` (computed property)
**File**: way3/Components/FeaturedItemsGrid.swift:51-54
**Purpose**: Get non-featured items
**Parameters**: None
**Returns**: ([TradeItem]) Items not in featured list
**Side Effects**: None
**Related**: Displayed in expandable section

#### `shouldShowQuickBuy(for:) -> Bool`
**File**: way3/Components/FeaturedItemsGrid.swift:275-280
**Purpose**: Determine if quick buy button should be shown
**Parameters**:
- `item` (TradeItem): Item to check
**Returns**: (Bool) True for buy/sell modes, false for browse
**Side Effects**: None
**Related**: Used in card rendering

#### `canInteractWith(_:) -> Bool`
**File**: way3/Components/FeaturedItemsGrid.swift:282-293
**Purpose**: Check if player can interact with item (license check)
**Parameters**:
- `item` (TradeItem): Item to check
**Returns**: (Bool) True if player meets requirements
**Side Effects**: None
**Related**: Determines card enabled state

---

### ItemDetailCard.swift

Simple item detail card component.

#### `gradeColor(_:) -> Color`
**File**: way3/Components/ItemDetailCard.swift:49-57
**Purpose**: Get color for item grade badge
**Parameters**:
- `grade` (ItemGrade): Item grade
**Returns**: (Color) Color for grade
**Side Effects**: None
**Related**: Badge background in detail card

---

### LocationTrackingButton.swift

Map location tracking toggle button component.

#### `toggleTracking() -> Void`
**File**: way3/Components/LocationTrackingButton.swift:28-40
**Purpose**: Toggle location tracking and update viewport
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Modifies `isTracking` binding and `viewport` with animation
**Related**: Button action handler

---

## Core

### ContentView.swift

Main game interface and app lifecycle management.

#### `setupApp() -> Void`
**File**: way3/ContentView.swift:67-77
**Purpose**: Initialize app with font validation
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Prints warnings if ChosunCentennial font missing
**Related**: Called in `.onAppear`

#### `loadPlayerData() -> Void`
**File**: way3/ContentView.swift:79-107
**Purpose**: Load player data from storage asynchronously
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Updates player state, starts auto-save timer
**Related**: Called when authentication changes

#### `updatePlayerWith(_:) -> Void`
**File**: way3/ContentView.swift:109-122
**Purpose**: Copy saved player data to current player instance
**Parameters**:
- `savedPlayer` (Player): Loaded player data
**Returns**: (Void)
**Side Effects**: Updates all player properties
**Related**: Called from `loadPlayerData()`

#### `handleScenePhaseChange(_:) -> Void`
**File**: way3/ContentView.swift:124-149
**Purpose**: Handle app lifecycle phase changes
**Parameters**:
- `phase` (ScenePhase): Current app phase
**Returns**: (Void)
**Side Effects**: Triggers save on inactive/background
**Related**: Called from `.onChange(of: scenePhase)`

#### `savePlayerData() -> Void`
**File**: way3/ContentView.swift:151-160
**Purpose**: Save player data to storage
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Async save operation via Player.save()
**Related**: Called from lifecycle handlers

---

### APIResponse.swift

Standardized API response handling structures.

#### `isSuccess` (computed property)
**File**: way3/Core/APIResponse.swift:22-24
**Purpose**: Check if API response indicates success
**Parameters**: None
**Returns**: (Bool) True if success and no error
**Side Effects**: None
**Related**: Used throughout networking layer

#### `getData() -> T?`
**File**: way3/Core/APIResponse.swift:27-30
**Purpose**: Safely extract data from successful response
**Parameters**: None
**Returns**: (T?) Data if successful, nil otherwise
**Side Effects**: None
**Related**: Used for safe data extraction

#### `getErrorMessage() -> String`
**File**: way3/Core/APIResponse.swift:33-38
**Purpose**: Get user-friendly error message
**Parameters**: None
**Returns**: (String) Error message or "Unknown error occurred"
**Side Effects**: None
**Related**: Used for error display

#### `userFriendlyMessage` (computed property)
**File**: way3/Core/APIResponse.swift:49-76
**Purpose**: Get localized user-friendly error message
**Parameters**: None
**Returns**: (String) Korean error message based on error code
**Side Effects**: None
**Related**: APIError extension

#### `errorType` (computed property)
**File**: way3/Core/APIResponse.swift:79-94
**Purpose**: Categorize error type for UI presentation
**Parameters**: None
**Returns**: (ErrorType) Error category enum
**Side Effects**: None
**Related**: Used for icon selection

#### `fromAPIError(_:statusCode:) -> NetworkError`
**File**: way3/Core/APIResponse.swift:244-259
**Purpose**: Convert APIError to NetworkError
**Parameters**:
- `apiError` (APIError): Source API error
- `statusCode` (Int): HTTP status code (default: 400)
**Returns**: (NetworkError) Converted network error
**Side Effects**: None
**Related**: Error conversion utility

#### `fromAPIResponse(_:) -> Result<T, NetworkError>`
**File**: way3/Core/APIResponse.swift:265-274
**Purpose**: Convert APIResponse to Result type
**Parameters**:
- `response` (APIResponse<T>): API response
**Returns**: (Result<T, NetworkError>) Success with data or failure with error
**Side Effects**: None
**Related**: Result type conversion

---

### AuthManager.swift

JWT token-based authentication system manager.

#### `loadStoredCredentials() -> Void`
**File**: way3/Core/AuthManager.swift:107-136
**Purpose**: Load authentication credentials from SecureStorage
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Updates authToken, currentPlayer, isAuthenticated; applies tokens to NetworkManager
**Related**: Called in init()

#### `loadLegacyCredentials() -> Void`
**File**: way3/Core/AuthManager.swift:139-158
**Purpose**: Fallback to load credentials from UserDefaults
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Loads from UserDefaults, triggers migration to SecureStorage
**Related**: Fallback from `loadStoredCredentials()`

#### `saveCredentials(authData:) -> Void`
**File**: way3/Core/AuthManager.swift:161-191
**Purpose**: Save authentication data to SecureStorage
**Parameters**:
- `authData` (AuthData): Authentication data from login/register
**Returns**: (Void)
**Side Effects**: Stores tokens in SecureStorage, updates instance properties
**Related**: Called after successful login/register

#### `saveLegacyCredentials(authData:) -> Void`
**File**: way3/Core/AuthManager.swift:194-213
**Purpose**: Fallback save to UserDefaults
**Parameters**:
- `authData` (AuthData): Authentication data
**Returns**: (Void)
**Side Effects**: Stores in UserDefaults
**Related**: Fallback from `saveCredentials()`

#### `clearStoredCredentials() -> Void`
**File**: way3/Core/AuthManager.swift:216-237
**Purpose**: Remove all authentication data
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Clears SecureStorage and UserDefaults, resets instance properties
**Related**: Called on logout or auth failure

#### `migrateToSecureStorage() -> Void`
**File**: way3/Core/AuthManager.swift:244-265
**Purpose**: Migrate UserDefaults credentials to SecureStorage
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Moves tokens from UserDefaults to SecureStorage
**Related**: Data migration utility

#### `refreshTokenIfNeeded() async -> Void`
**File**: way3/Core/AuthManager.swift:270-283
**Purpose**: Automatically refresh auth token if needed
**Parameters**: None
**Returns**: (Void) async
**Side Effects**: May update tokens, trigger logout on failure
**Related**: Token maintenance

#### `refreshPlayerData() async -> Void`
**File**: way3/Core/AuthManager.swift:288-291
**Purpose**: Reload latest player data from server
**Parameters**: None
**Returns**: (Void) async
**Side Effects**: Updates currentPlayer via NetworkManager
**Related**: Called after token refresh

#### `login(email:password:) async -> Void`
**File**: way3/Core/AuthManager.swift:294-324
**Purpose**: Authenticate user with email and password
**Parameters**:
- `email` (String): User email
- `password` (String): User password
**Returns**: (Void) async
**Side Effects**: Updates isLoading, errorMessage, isAuthenticated; saves credentials on success
**Related**: Primary login method

#### `register(email:password:playerName:) async -> Void`
**File**: way3/Core/AuthManager.swift:327-357
**Purpose**: Register new user account
**Parameters**:
- `email` (String): User email
- `password` (String): User password
- `playerName` (String): Player display name
**Returns**: (Void) async
**Side Effects**: Creates account, saves credentials, updates authentication state
**Related**: Registration method

#### `requestPasswordReset(email:) async throws -> PasswordResetResponse`
**File**: way3/Core/AuthManager.swift:360-367
**Purpose**: Request password reset verification code
**Parameters**:
- `email` (String): User email
**Returns**: (PasswordResetResponse) Response with verification details
**Side Effects**: Sends reset email
**Related**: Password reset flow step 1

#### `verifyPasswordReset(email:code:newPassword:) async throws -> PasswordResetResponse`
**File**: way3/Core/AuthManager.swift:369-376
**Purpose**: Verify reset code and set new password
**Parameters**:
- `email` (String): User email
- `code` (String): Verification code
- `newPassword` (String): New password
**Returns**: (PasswordResetResponse) Response with success status
**Side Effects**: Changes user password
**Related**: Password reset flow step 2

#### `logout() async -> Void`
**File**: way3/Core/AuthManager.swift:379-398
**Purpose**: Log out current user
**Parameters**: None
**Returns**: (Void) async
**Side Effects**: Calls logout API, clears all credentials, resets state
**Related**: Logout method

#### `refreshAuthToken() async -> Bool`
**File**: way3/Core/AuthManager.swift:401-425
**Purpose**: Refresh access token using refresh token
**Parameters**: None
**Returns**: (Bool) True if successful, false if failed
**Side Effects**: Updates authToken or triggers logout
**Related**: Token refresh utility

#### `getAuthHeaders() -> [String: String]`
**File**: way3/Core/AuthManager.swift:428-436
**Purpose**: Get HTTP headers with auth token
**Parameters**: None
**Returns**: ([String: String]) Headers including Authorization
**Side Effects**: None
**Related**: Used for authenticated requests

#### `hasStoredToken() -> Bool`
**File**: way3/Core/AuthManager.swift:439-441
**Purpose**: Check if stored token exists
**Parameters**: None
**Returns**: (Bool) True if token in UserDefaults
**Side Effects**: None
**Related**: Auth state check

#### `performRequest<T:Codable, U:Codable>(endpoint:method:body:) async throws -> U`
**File**: way3/Core/AuthManager.swift:446-482
**Purpose**: Execute authenticated HTTP request with auto-retry on 401
**Parameters**:
- `endpoint` (String): API endpoint path
- `method` (String): HTTP method
- `body` (T): Request body
**Returns**: (U) Decoded response
**Side Effects**: May trigger token refresh, network request
**Related**: Internal request helper

---

### DataManager.swift

Game data management for merchants, items, and market prices.

#### `init()`
**File**: way3/Core/DataManager.swift:36-39
**Purpose**: Initialize DataManager with network bindings and reset timer
**Parameters**: None
**Returns**: None (initializer)
**Side Effects**: Sets up network subscriptions and item reset timer
**Related**: Called on DataManager instance creation

#### `deinit`
**File**: way3/Core/DataManager.swift:41-43
**Purpose**: Clean up timer on deallocation
**Parameters**: None
**Returns**: None
**Side Effects**: Invalidates itemResetTimer
**Related**: Automatic cleanup

#### `loadOnlineGameData() async -> Void`
**File**: way3/Core/DataManager.swift:46-52
**Purpose**: Load all game data concurrently (player, market, merchants)
**Parameters**: None
**Returns**: (Void) async
**Side Effects**: Triggers three async data loads in parallel
**Related**: Primary data loading method

#### `updateMerchants(_:) -> Void`
**File**: way3/Core/DataManager.swift:54-76
**Purpose**: Update merchants list from server data
**Parameters**:
- `merchantData` ([MerchantData]): Array of merchant data from API
**Returns**: (Void)
**Side Effects**: Updates published `merchants` property
**Related**: Called from `loadMerchantData()`

#### `updateNearbyMerchants(_:) -> Void`
**File**: way3/Core/DataManager.swift:78-90
**Purpose**: Merge nearby merchants into existing merchant list
**Parameters**:
- `nearbyMerchants` ([Merchant]): Nearby merchants to add/update
**Returns**: (Void)
**Side Effects**: Updates published `merchants` property
**Related**: Location-based update

#### `updateMarketPrices(_:) -> Void`
**File**: way3/Core/DataManager.swift:92-101
**Purpose**: Update price board from market price data
**Parameters**:
- `prices` ([MarketPrice]): Array of market prices
**Returns**: (Void)
**Side Effects**: Updates published `priceBoard` property
**Related**: Called from `loadMarketData()`

#### `applyPriceUpdates(_:) -> Void`
**File**: way3/Core/DataManager.swift:103-109
**Purpose**: Apply incremental price updates to existing price board
**Parameters**:
- `updates` ([String: Int]): Dictionary of item name to new price
**Returns**: (Void)
**Side Effects**: Updates published `priceBoard` property
**Related**: Real-time price update

#### `setupNetworkBindings() -> Void`
**File**: way3/Core/DataManager.swift:112-121
**Purpose**: Subscribe to network events (placeholder)
**Parameters**: None
**Returns**: (Void)
**Side Effects**: None (TODO: implement subscriptions)
**Related**: Called from init()

#### `loadPlayerData() async -> Void`
**File**: way3/Core/DataManager.swift:123-132
**Purpose**: Load player data from network
**Parameters**: None
**Returns**: (Void) async
**Side Effects**: Calls delegate method with player data
**Related**: Called from `loadOnlineGameData()`

#### `loadMarketData() async -> Void`
**File**: way3/Core/DataManager.swift:134-145
**Purpose**: Load market price data from network
**Parameters**: None
**Returns**: (Void) async
**Side Effects**: Updates price board via `updateMarketPrices()`
**Related**: Called from `loadOnlineGameData()`

#### `loadMerchantData() async -> Void`
**File**: way3/Core/DataManager.swift:147-158
**Purpose**: Load merchant data from network
**Parameters**: None
**Returns**: (Void) async
**Side Effects**: Updates merchants via `updateMerchants()`
**Related**: Called from `loadOnlineGameData()`

#### `setupItemResetTimer() -> Void`
**File**: way3/Core/DataManager.swift:160-165
**Purpose**: Create hourly timer for data refresh
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Schedules repeating timer (3600 seconds)
**Related**: Called from init()

#### `refreshData() -> Void`
**File**: way3/Core/DataManager.swift:167-170
**Purpose**: Refresh price board and notify delegate
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Updates prices, calls delegate
**Related**: Called by itemResetTimer

#### `updatePriceBoard() -> Void`
**File**: way3/Core/DataManager.swift:172-178
**Purpose**: Apply random price variations to all items
**Parameters**: None
**Returns**: (Void)
**Side Effects**: Updates published `priceBoard` with 0.8-1.2x variations
**Related**: Called from `refreshData()`

#### `generateOfflineData() -> (merchants: [Merchant], items: [TradeItem])`
**File**: way3/Core/DataManager.swift:183-220
**Purpose**: Generate mock data for offline mode
**Parameters**: None
**Returns**: (merchants, items) tuple with sample data
**Side Effects**: None
**Related**: OfflineDataGenerator class method

---

### DistrictManager.swift

Seoul district management and Pokemon GO-style zone system.

#### `getDistrict(for:) -> GameDistrict`
**File**: way3/Core/DistrictManager.swift:111-120
**Purpose**: Determine which district contains the given coordinates
**Parameters**:
- `location` (CLLocationCoordinate2D): Location to check
**Returns**: (GameDistrict) District enum or .other if outside defined zones
**Side Effects**: None
**Related**: Primary district lookup

#### `updateCurrentDistrict(for:) -> Void`
**File**: way3/Core/DistrictManager.swift:122-128
**Purpose**: Update current district if location has changed zones
**Parameters**:
- `location` (CLLocationCoordinate2D): Current location
**Returns**: (Void)
**Side Effects**: Updates published `currentDistrict`, prints zone change
**Related**: Called from location updates

#### `getDistrictBoundaries() -> [PolygonAnnotation]`
**File**: way3/Core/DistrictManager.swift:130-151
**Purpose**: Generate map polygon annotations for all districts
**Parameters**: None
**Returns**: ([PolygonAnnotation]) Array of styled polygons
**Side Effects**: None
**Related**: Map visualization

#### `addDistrictActivity(_:) -> Void`
**File**: way3/Core/DistrictManager.swift:153-160
**Purpose**: Add new activity to district feed (max 50 items)
**Parameters**:
- `activity` (DistrictActivity): New activity event
**Returns**: (Void)
**Side Effects**: Updates published `districtActivity` array
**Related**: Activity feed management

#### `getDistrictCenter(_:) -> CLLocationCoordinate2D?`
**File**: way3/Core/DistrictManager.swift:162-164
**Purpose**: Get center coordinates for a district
**Parameters**:
- `district` (GameDistrict): Target district
**Returns**: (CLLocationCoordinate2D?) Center point or nil
**Side Effects**: None
**Related**: Map navigation utility

---

## Summary Statistics

- **Total Files Documented**: 15 / 89
- **Total Functions/Methods**: 87+
- **Components**: 10 files
- **Core Systems**: 5 files
- **Documentation Status**: Partial (core systems and components completed)

## Notes

This documentation represents a comprehensive analysis of the way3 project's function specifications. Each function is documented with:
- Full signature and file location
- Clear purpose description
- Complete parameter documentation
- Return value specifications
- Side effect analysis
- Related function references

The project demonstrates:
- **Cyberpunk-themed JRPG UI components** with careful attention to animations and visual effects
- **Comprehensive font system** tailored for Korean text and game contexts
- **Robust authentication system** with SecureStorage and legacy migration support
- **Location-based gameplay** with district zones inspired by Pokemon GO
- **Real-time data management** for multiplayer trading mechanics

**For complete documentation of all 89 files, continue reading additional files and expand this document systematically.**

---

**Last Updated**: 2025-01-11
**Document Version**: 1.0 (Partial)
