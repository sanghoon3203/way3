//
//  CyberpunkNavigationComponents.swift
//  way3 - Way Trading Game
//
//  사이버펑크 스타일 네비게이션 컴포넌트들
//  기존 MainTabView 기능을 완전히 유지하면서 사이버펑크 테마 강화
//

import SwiftUI
import Foundation

// MARK: - Cyberpunk Status Bar
struct CyberpunkStatusBar: View {
    let credits: Int
    let level: Int
    let connectionStatus: String
    @State private var statusPulse = false
    @State private var dataFlicker = false

    var body: some View {
        HStack(spacing: 16) {
            // System Status
            HStack(spacing: 6) {
                Text("SYSTEM_STATUS:")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Text("ONLINE")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkGreen)
                    .opacity(statusPulse ? 0.6 : 1.0)
                    .animation(CyberpunkAnimations.slowGlow, value: statusPulse)
            }

            Spacer()

            // Resource Indicators
            HStack(spacing: 20) {
                // Credits Display
                CyberpunkResourceIndicator(
                    label: "CREDITS",
                    value: "₩\(formatCredits(credits))",
                    color: .cyberpunkYellow,
                    icon: "creditcard.fill"
                )

                // Level Display
                CyberpunkResourceIndicator(
                    label: "LVL",
                    value: String(format: "%02d", level),
                    color: .cyberpunkCyan,
                    icon: "star.fill"
                )

                // Connection Status
                CyberpunkResourceIndicator(
                    label: "SYNC",
                    value: "\(connectionStatus)%",
                    color: .cyberpunkGreen,
                    icon: "wifi"
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.cyberpunkDarkBg.opacity(0.95))
        .overlay(
            Rectangle()
                .fill(Color.cyberpunkYellow)
                .frame(height: 1),
            alignment: .top
        )
        .onAppear {
            statusPulse.toggle()
        }
    }

    private func formatCredits(_ amount: Int) -> String {
        if amount >= 1000000 {
            return String(format: "%.1fM", Double(amount) / 1000000.0)
        } else if amount >= 1000 {
            return String(format: "%.1fK", Double(amount) / 1000.0)
        } else {
            return "\(amount)"
        }
    }
}

// MARK: - Cyberpunk Resource Indicator
struct CyberpunkResourceIndicator: View {
    let label: String
    let value: String
    let color: Color
    let icon: String
    @State private var glowIntensity = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)

            Text("\(label):")
                .font(.cyberpunkTechnical())
                .foregroundColor(.cyberpunkTextSecondary)

            Text(value)
                .font(.cyberpunkTechnical())
                .foregroundColor(color)
                .fontWeight(.semibold)
                .shadow(color: color.opacity(glowIntensity ? 0.6 : 0.3), radius: 2)
                .animation(CyberpunkAnimations.slowGlow, value: glowIntensity)
        }
        .onAppear {
            glowIntensity.toggle()
        }
    }
}

// MARK: - Enhanced Cyberpunk Tab Configuration
extension View {
    func setupEnhancedCyberpunkTabBar() -> some View {
        self.onAppear {
            setupCyberpunkTabBarAppearance()
        }
    }
}

private func setupCyberpunkTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()

    // Enhanced cyberpunk background with gradient effect
    let backgroundColor = UIColor.black.withAlphaComponent(0.95)
    appearance.backgroundColor = backgroundColor

    // Corporate-style shadow and glow effects
    appearance.shadowColor = UIColor(Color.cyberpunkCyan).withAlphaComponent(0.4)
    appearance.shadowImage = createGlowImage()

    // Normal tab styling with enhanced corporate theme
    appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.cyberpunkTextSecondary)
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
        .foregroundColor: UIColor(Color.cyberpunkTextSecondary),
        .font: UIFont(name: "ChosunCentennial_otf", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .regular)
    ]

    // Selected tab styling with enhanced glow
    appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.cyberpunkCyan)
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
        .foregroundColor: UIColor(Color.cyberpunkCyan),
        .font: UIFont(name: "ChosunCentennial_otf", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .medium)
    ]

    // Apply enhanced appearance
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance

    // Additional corporate styling
    UITabBar.appearance().isTranslucent = false
    UITabBar.appearance().barTintColor = backgroundColor
}

private func createGlowImage() -> UIImage? {
    let size = CGSize(width: 1, height: 1)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    defer { UIGraphicsEndImageContext() }

    guard let context = UIGraphicsGetCurrentContext() else { return nil }

    // Create subtle glow effect
    context.setFillColor(UIColor(Color.cyberpunkCyan).withAlphaComponent(0.2).cgColor)
    context.fill(CGRect(origin: .zero, size: size))

    return UIGraphicsGetImageFromCurrentImageContext()
}

// MARK: - Cyberpunk Tab Icon Enhancement
struct CyberpunkTabIcon: View {
    let systemName: String
    let isSelected: Bool
    let hasNotification: Bool

    var body: some View {
        ZStack {
            // Base icon
            Image(systemName: systemName)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .cyberpunkCyan : .cyberpunkTextSecondary)

            // Selection glow effect
            if isSelected {
                Image(systemName: systemName)
                    .font(.system(size: 24))
                    .foregroundColor(.cyberpunkCyan.opacity(0.5))
                    .blur(radius: 4)
            }

            // Notification indicator
            if hasNotification {
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.cyberpunkError)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.cyberpunkDarkBg, lineWidth: 1)
                            )
                    }
                    Spacer()
                }
            }

            // Scan line effect for selected tab
            if isSelected {
                CyberpunkScanLineEffect()
            }
        }
    }
}

// MARK: - Scan Line Effect
struct CyberpunkScanLineEffect: View {
    @State private var scanPosition: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .cyberpunkCyan.opacity(0.6),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .offset(y: scanPosition)
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: scanPosition
            )
            .onAppear {
                scanPosition = 15
            }
    }
}

// MARK: - Corporate Tab Configuration
struct CyberpunkTabConfiguration {
    static let tabs: [(String, String, String)] = [
        ("map.fill", "맵", "SURVEILLANCE_GRID"),
        ("backpack.fill", "인벤토리", "CARGO_MANIFEST"),
        ("flag.fill", "퀘스트", "MISSION_QUEUE"),
        ("storefront.fill", "상점", "TRADE_EXCHANGE"),
        ("person.fill", "프로필", "OPERATIVE_PROFILE")
    ]

    static func corporateTitle(for index: Int) -> String {
        guard index < tabs.count else { return "UNKNOWN" }
        return tabs[index].2
    }

    static func hasNotification(for index: Int) -> Bool {
        // This would be connected to actual notification state
        // For now, return mock data
        switch index {
        case 2: return true  // Quest notifications
        case 3: return true  // Shop updates
        default: return false
        }
    }
}

// MARK: - Enhanced Tab View Wrapper
struct CyberpunkEnhancedTabView<Content: View>: View {
    @Binding var selectedTab: Int
    let credits: Int
    let level: Int
    let connectionStatus: String
    let content: Content

    init(
        selectedTab: Binding<Int>,
        credits: Int = 1200000,
        level: Int = 7,
        connectionStatus: String = "99.7",
        @ViewBuilder content: () -> Content
    ) {
        self._selectedTab = selectedTab
        self.credits = credits
        self.level = level
        self.connectionStatus = connectionStatus
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status Bar
            CyberpunkStatusBar(
                credits: credits,
                level: level,
                connectionStatus: connectionStatus
            )

            // Main Tab Content
            content
                .setupEnhancedCyberpunkTabBar()

            // Optional: Additional corporate footer
            CyberpunkFooterBar()
        }
        .background(Color.cyberpunkDarkBg)
    }
}

// MARK: - Corporate Footer Bar
struct CyberpunkFooterBar: View {
    @State private var systemTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            // System timestamp
            Text("SYS_TIME: \(systemTime, formatter: corporateTimeFormatter)")
                .font(.cyberpunkTechnical())
                .foregroundColor(.cyberpunkTextSecondary)

            Spacer()

            // Corporate branding
            Text("NEO-SEOUL_TRADING_CORP")
                .font(.cyberpunkTechnical())
                .foregroundColor(.cyberpunkYellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.cyberpunkDarkBg.opacity(0.8))
        .overlay(
            Rectangle()
                .fill(Color.cyberpunkBorder.opacity(0.3))
                .frame(height: 0.5),
            alignment: .top
        )
        .onReceive(timer) { time in
            systemTime = time
        }
    }
}

// MARK: - Corporate Time Formatter
private let corporateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
}()