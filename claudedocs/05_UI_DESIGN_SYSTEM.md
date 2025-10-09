# UI Design System - Cyberpunk Theme

## 🎨 Design Philosophy

Way3 employs a **cyberpunk/technical aesthetic** inspired by futuristic interfaces with:
- Angular, sharp geometries (minimal rounded corners)
- Neon accent colors (yellow, cyan, green)
- Technical/monospace typography
- High contrast for readability
- Glow effects and visual feedback
- JRPG-style information density

## 🌈 Color Palette

### Primary Colors

```swift
// Accent Colors
Color.cyberpunkYellow  // #FFD900 - Primary accent, CTAs
Color.cyberpunkGold    // #FFC000 - Secondary accent, premium items
Color.cyberpunkCyan    // #00E5E5 - Info, links, highlights
Color.cyberpunkGreen   // #00FF4D - Success, positive states
```

### Background Colors

```swift
Color.cyberpunkDarkBg   // RGB(0.05, 0.05, 0.08) - Main dark background
Color.cyberpunkPanelBg  // RGB(0.1, 0.12, 0.15) - Panel/section backgrounds
Color.cyberpunkCardBg   // RGB(0.15, 0.18, 0.22) - Card/item backgrounds
```

### Border & Line Colors

```swift
Color.cyberpunkBorder        // RGB(0.3, 0.35, 0.4) - Default borders
Color.cyberpunkGlowBorder    // cyberpunkCyan.opacity(0.6) - Active glow
Color.cyberpunkActiveBorder  // cyberpunkYellow - Selected/active state
```

### Text Colors

```swift
Color.cyberpunkTextPrimary    // White - Primary text
Color.cyberpunkTextSecondary  // RGB(0.7, 0.75, 0.8) - Secondary text
Color.cyberpunkTextAccent     // cyberpunkCyan - Emphasized text
Color.cyberpunkTextWarning    // cyberpunkYellow - Warnings
```

### Status Colors

```swift
Color.cyberpunkSuccess  // Green - Success states
Color.cyberpunkError    // RGB(1.0, 0.2, 0.3) - Error/danger
Color.cyberpunkWarning  // Yellow - Warnings/alerts
Color.cyberpunkInfo     // Cyan - Informational
```

## ✍️ Typography

### Font System

**Primary Font**: ChosunCentennial (custom Korean font)
**System Fonts**: Monospace design for technical UI

```swift
// Heading & Display
Font.cyberpunkTitle(size: 24)      // Bold monospace
Font.cyberpunkHeading(size: 18)    // Semibold monospace

// Body & Content
Font.cyberpunkBody(size: 14)       // Medium, default
Font.cyberpunkCaption(size: 12)    // Regular monospace

// Technical UI
Font.cyberpunkTechnical(size: 10)  // Small technical data
Font.cyberpunkButton(size: 16)     // Semibold buttons
```

### Font Hierarchy

```
cyberpunkTitle (24pt)
    ↓
cyberpunkHeading (18pt)
    ↓
cyberpunkButton (16pt)
    ↓
cyberpunkBody (14pt)
    ↓
cyberpunkCaption (12pt)
    ↓
cyberpunkTechnical (10pt)
```

### ChosunCentennial Integration

```swift
// Extensions/Font+ChosunSystem.swift
extension Font {
    static func chosun(size: CGFloat) -> Font {
        return .custom("ChosunCentennial", size: size)
    }
}

extension View {
    func defaultChosunFont() -> some View {
        self.font(.chosun(size: 16))
    }
}
```

## 📏 Layout Constants

```swift
struct CyberpunkLayout {
    // Spacing
    static let gridSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 12
    static let screenPadding: CGFloat = 16

    // Borders
    static let borderWidth: CGFloat = 1.5
    static let glowBorderWidth: CGFloat = 2.0

    // Corner Radius (Sharp/Angular)
    static let cornerRadius: CGFloat = 4
    static let buttonCornerRadius: CGFloat = 2
    static let cardCornerRadius: CGFloat = 6

    // Effects
    static let shadowRadius: CGFloat = 8
    static let glowRadius: CGFloat = 12

    // UI Elements
    static let statusBarHeight: CGFloat = 44
    static let technicalPanelHeight: CGFloat = 60
    static let hexSize: CGFloat = 50
}
```

## 🎬 Animations

```swift
struct CyberpunkAnimations {
    static let quickFade: Animation = .easeInOut(duration: 0.2)
    static let standardTransition: Animation = .easeInOut(duration: 0.3)
    static let slowGlow: Animation = .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    static let technicalFlicker: Animation = .easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)
    static let dataTransfer: Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)
}
```

## 🧩 Core Components

### 1. Cyberpunk Card

**Angular card with technical styling**

```swift
extension View {
    func cyberpunkCard(isActive: Bool = false) -> some View {
        self
            .background(
                Rectangle()
                    .fill(Color.cyberpunkCardBg)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isActive ? Color.cyberpunkActiveBorder : Color.cyberpunkBorder,
                                lineWidth: CyberpunkLayout.borderWidth
                            )
                    )
                    .clipShape(Rectangle())
            )
            .shadow(
                color: isActive ? Color.cyberpunkGlowBorder : Color.black.opacity(0.3),
                radius: isActive ? CyberpunkLayout.glowRadius : CyberpunkLayout.shadowRadius
            )
    }
}
```

**Usage**:
```swift
VStack {
    Text("Card Content")
        .padding()
}
.cyberpunkCard(isActive: true)
```

### 2. Cyberpunk Button

**Technical button with glow effect**

```swift
extension View {
    func cyberpunkButton(
        style: CyberpunkButtonStyle = .primary,
        isPressed: Bool = false
    ) -> some View {
        self
            .background(
                Rectangle()
                    .fill(style.backgroundColor)
                    .overlay(
                        Rectangle()
                            .stroke(style.borderColor, lineWidth: CyberpunkLayout.borderWidth)
                    )
                    .clipShape(Rectangle())
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: style.glowColor,
                radius: isPressed ? 4 : 8
            )
    }
}

enum CyberpunkButtonStyle {
    case primary     // Yellow accent
    case secondary   // Cyan accent
    case danger      // Red
    case success     // Green
    case disabled    // Gray
}
```

**Usage**:
```swift
Button(action: {}) {
    Text("CONFIRM")
        .font(.cyberpunkButton())
        .foregroundColor(.cyberpunkYellow)
        .padding()
}
.cyberpunkButton(style: .primary)
```

### 3. Cyberpunk Panel

**Container with technical corner decorations**

```swift
extension View {
    func cyberpunkPanel() -> some View {
        self
            .background(
                ZStack {
                    Rectangle()
                        .fill(Color.cyberpunkPanelBg)

                    // Corner decorations (4 corners)
                    VStack {
                        HStack {
                            CyberpunkCornerDecoration()
                            Spacer()
                            CyberpunkCornerDecoration()
                                .rotationEffect(.degrees(90))
                        }
                        Spacer()
                        HStack {
                            CyberpunkCornerDecoration()
                                .rotationEffect(.degrees(270))
                            Spacer()
                            CyberpunkCornerDecoration()
                                .rotationEffect(.degrees(180))
                        }
                    }
                }
                .overlay(
                    Rectangle()
                        .stroke(Color.cyberpunkBorder, lineWidth: CyberpunkLayout.borderWidth)
                )
            )
    }
}

struct CyberpunkCornerDecoration: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.cyberpunkYellow)
                .frame(width: 12, height: 1)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.cyberpunkYellow)
                    .frame(width: 1, height: 12)
                Spacer()
            }
        }
        .frame(width: 12, height: 12)
    }
}
```

### 4. Status Bar

**Technical status header with online indicator**

```swift
extension View {
    func cyberpunkStatusBar(title: String, status: String = "ONLINE") -> some View {
        VStack {
            HStack {
                Text(title.uppercased())
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.cyberpunkGreen)
                        .frame(width: 6, height: 6)
                        .animation(CyberpunkAnimations.slowGlow, value: UUID())

                    Text(status)
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkGreen)
                }
            }
            .padding()
            .background(Color.cyberpunkDarkBg)
            .overlay(
                Rectangle()
                    .fill(Color.cyberpunkYellow)
                    .frame(height: 1),
                alignment: .bottom
            )

            self
        }
    }
}
```

### 5. Grid Slot (Inventory)

**Hexagonal/grid item container**

```swift
extension View {
    func cyberpunkGridSlot(isEmpty: Bool = false, isSelected: Bool = false) -> some View {
        self
            .background(
                Rectangle()
                    .fill(isEmpty ? Color.cyberpunkDarkBg : Color.cyberpunkCardBg)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isSelected ? Color.cyberpunkActiveBorder : Color.cyberpunkBorder,
                                lineWidth: isEmpty ? 0.5 : CyberpunkLayout.borderWidth
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.cyberpunkGlowBorder : Color.clear,
                radius: isSelected ? CyberpunkLayout.glowRadius : 0
            )
    }
}
```

## 🎮 Specialized Components

### Item Grade Display

```swift
extension ItemGrade {
    var cyberpunkColor: Color {
        switch self {
        case .common: return .cyberpunkTextSecondary
        case .intermediate: return .cyberpunkCyan
        case .advanced: return .cyberpunkGreen
        case .rare: return .cyberpunkYellow
        case .legendary: return .cyberpunkGold
        }
    }
}

// Usage in views
Text(item.grade.displayName)
    .foregroundColor(item.grade.cyberpunkColor)
    .font(.cyberpunkCaption())
```

### Connection Status Indicator

```swift
// Based on SocketManager.ConnectionStatus
HStack {
    Circle()
        .fill(connectionStatus.color)
        .frame(width: 8, height: 8)

    Text(connectionStatus.description)
        .font(.cyberpunkTechnical())
        .foregroundColor(connectionStatus.color)
}
```

## 📦 Component Library

### Components Directory Structure

```
Components/
├── CyberpunkDesignSystem.swift       # Core design tokens
├── CyberpunkComponents.swift         # Base UI components
├── CyberpunkInventoryComponents.swift # Inventory-specific
├── CyberpunkShopComponents.swift      # Shop/trading UI
├── CyberpunkNavigationComponents.swift # Navigation elements
├── CyberpunkQuestComponents.swift     # Quest/achievement UI
├── CyberpunkProfileComponents.swift   # Player profile UI
├── EnhancedFontSystem.swift          # Typography utilities
├── EnhancedItemCard.swift            # Item display card
├── ItemDetailCard.swift              # Detailed item view
├── FeaturedItemsGrid.swift           # Grid layout
└── LocationTrackingButton.swift      # GPS controls
```

### Example Component: EnhancedItemCard

```swift
struct EnhancedItemCard: View {
    let item: TradeItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item header
            HStack {
                Image(systemName: item.iconName)
                    .foregroundColor(item.grade.cyberpunkColor)

                Text(item.name)
                    .font(.cyberpunkHeading(size: 14))
                    .foregroundColor(.cyberpunkTextPrimary)

                Spacer()

                Text(item.grade.displayName)
                    .font(.cyberpunkTechnical())
                    .foregroundColor(item.grade.cyberpunkColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Rectangle()
                            .fill(item.grade.cyberpunkColor.opacity(0.2))
                            .overlay(
                                Rectangle()
                                    .stroke(item.grade.cyberpunkColor, lineWidth: 0.5)
                            )
                    )
            }

            // Item price
            HStack {
                Text("PRICE")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Spacer()

                Text("\(item.displayPrice.formatted())원")
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkYellow)
            }

            // Item description (if available)
            if !item.description.isEmpty {
                Text(item.description)
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkTextSecondary)
                    .lineLimit(2)
            }
        }
        .padding(CyberpunkLayout.cardPadding)
        .cyberpunkCard(isActive: isSelected)
    }
}
```

## 🎯 Usage Guidelines

### Color Usage

**DO**:
- Use yellow for primary CTAs and important actions
- Use cyan for informational elements and links
- Use green for success states and positive feedback
- Maintain high contrast (light text on dark backgrounds)

**DON'T**:
- Mix too many accent colors in one component
- Use low-contrast combinations
- Overuse bright colors (maintain dark base)

### Typography

**DO**:
- Use monospace fonts for technical data (stats, IDs, codes)
- Use ChosunCentennial for branding and Korean text
- Maintain clear hierarchy with size differentiation
- UPPERCASE for headers and labels

**DON'T**:
- Mix too many font sizes in one component
- Use decorative fonts for body text
- Sacrifice readability for aesthetics

### Layout

**DO**:
- Use angular/rectangular shapes (minimal rounding)
- Add technical corner decorations for emphasis
- Maintain consistent spacing with CyberpunkLayout constants
- Group related information with borders/panels

**DON'T**:
- Use rounded corners excessively
- Create cluttered layouts without breathing room
- Ignore alignment and grid systems

### Animation

**DO**:
- Use subtle glows for active states
- Animate state transitions smoothly
- Add pulsing effects for status indicators
- Keep animations under 0.5s for responsiveness

**DON'T**:
- Overuse flashy animations
- Create distracting constant motion
- Ignore performance with heavy animations

## 🌟 Visual Effects

### Glow Effects

```swift
.shadow(color: Color.cyberpunkGlowBorder, radius: 12)
.animation(CyberpunkAnimations.slowGlow, value: isActive)
```

### Technical Scan Lines (Optional Enhancement)

```swift
struct ScanLineOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<Int(geometry.size.height / 4), id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.02))
                    .frame(height: 1)
            }
        }
    }
}
```

### Data Transfer Animation

```swift
HStack {
    ForEach(0..<3) { index in
        Rectangle()
            .fill(Color.cyberpunkCyan)
            .frame(width: 20, height: 2)
            .offset(x: animating ? 100 : -100)
            .animation(
                CyberpunkAnimations.dataTransfer.delay(Double(index) * 0.2),
                value: animating
            )
    }
}
```

## 📱 Responsive Design

### Screen Adaptation

```swift
// Adapt layout based on device
var columns: [GridItem] {
    let count = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
    return Array(repeating: GridItem(.flexible()), count: count)
}
```

### Safe Area Handling

```swift
VStack {
    // Content
}
.padding(.horizontal, CyberpunkLayout.screenPadding)
.ignoresSafeArea(edges: .bottom)  // For full-bleed designs
```

## 🎨 Theme Customization

### Future Theme System

```swift
protocol CyberpunkTheme {
    var primaryAccent: Color { get }
    var secondaryAccent: Color { get }
    var backgroundColor: Color { get }
}

struct YellowCyberpunkTheme: CyberpunkTheme {
    let primaryAccent = Color.cyberpunkYellow
    let secondaryAccent = Color.cyberpunkCyan
    let backgroundColor = Color.cyberpunkDarkBg
}

// Apply theme
@Environment(\.cyberpunkTheme) var theme
```

---

**Next**: [06_DATA_MODELS.md](06_DATA_MODELS.md) - Complete data model reference
