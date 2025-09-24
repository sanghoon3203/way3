//
//  CyberpunkProfileComponents.swift
//  way3 - Way Trading Game
//
//  사이버펑크 스타일 프로필 컴포넌트들
//  기존 ProfileView 기능을 완전히 유지하면서 사이버펑크 테마 적용
//

import SwiftUI

// MARK: - Cyberpunk Profile Header
struct CyberpunkProfileHeader: View {
    let profile: Player
    let onEditProfile: () -> Void
    @State private var scanLineOffset: CGFloat = 0
    @State private var statusPulse = false

    var body: some View {
        VStack(spacing: 16) {
            // Biometric Scanner Header
            CyberpunkSectionHeader(
                title: "OPERATIVE_PROFILE",
                subtitle: "BIOMETRIC_ACCESS_GRANTED"
            )

            HStack(spacing: 20) {
                // Hexagonal Avatar Frame
                ZStack {
                    // Background hexagon
                    HexagonShape()
                        .fill(Color.cyberpunkDarkBg)
                        .frame(width: 120, height: 120)

                    // Border hexagon with glow
                    HexagonShape()
                        .stroke(Color.cyberpunkCyan, lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.cyberpunkCyan.opacity(0.5), radius: 8)

                    // Profile image placeholder
                    ZStack {
                        Circle()
                            .fill(Color.cyberpunkCardBg)
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.cyberpunkTextSecondary)
                    }

                    // Scan line animation
                    Rectangle()
                        .fill(Color.cyberpunkCyan.opacity(0.3))
                        .frame(width: 120, height: 2)
                        .offset(y: scanLineOffset)
                        .animation(
                            Animation.linear(duration: 2.0)
                                .repeatForever(autoreverses: false),
                            value: scanLineOffset
                        )
                        .mask(
                            HexagonShape()
                                .frame(width: 120, height: 120)
                        )
                }
                .onAppear {
                    scanLineOffset = 60
                }

                // Operative Data Panel
                VStack(alignment: .leading, spacing: 8) {
                    // Operative Handle
                    HStack {
                        Text("TRADER_ID:")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkTextSecondary)

                        Text("KR-2025-\(String(profile.core.name.prefix(4)).uppercased())")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkYellow)
                    }

                    // Name Display
                    Text(profile.core.name.uppercased())
                        .font(.cyberpunkHeading())
                        .foregroundColor(.cyberpunkTextPrimary)
                        .fontWeight(.bold)

                    // Status Indicators
                    HStack(spacing: 12) {
                        CyberpunkDataDisplay(
                            label: "AGE",
                            value: "\(profile.core.age)",
                            valueColor: .cyberpunkCyan
                        )

                        CyberpunkDataDisplay(
                            label: "LVL",
                            value: String(format: "%02d", profile.core.level),
                            valueColor: .cyberpunkGreen
                        )
                    }

                    // Online Status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.cyberpunkGreen)
                            .frame(width: 8, height: 8)
                            .scaleEffect(statusPulse ? 1.2 : 1.0)
                            .animation(CyberpunkAnimations.slowGlow, value: statusPulse)

                        Text("ONLINE_STATUS: ACTIVE")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkGreen)
                    }
                    .onAppear {
                        statusPulse.toggle()
                    }
                }

                Spacer()
            }

            // Edit Profile Button
            CyberpunkButton(
                title: "EDIT_PROFILE",
                style: .secondary,
                action: onEditProfile
            )
        }
        .padding(16)
        .cyberpunkCard()
    }
}

// MARK: - Cyberpunk Trading Dashboard
struct CyberpunkTradingDashboard: View {
    let profile: Player
    @State private var dataRefreshAnimation = false

    var body: some View {
        VStack(spacing: 16) {
            // Dashboard Header
            CyberpunkSectionHeader(
                title: "TRADING_TERMINAL_v3.7",
                subtitle: "REAL_TIME_METRICS"
            )

            VStack(spacing: 12) {
                // Profit Metrics Row
                HStack(spacing: 16) {
                    CyberpunkMetricCard(
                        label: "TOTAL_PROFIT",
                        value: "₩\(formatCurrency(profile.core.money))",
                        trend: "+2.3%",
                        trendPositive: true,
                        icon: "chart.line.uptrend.xyaxis"
                    )

                    CyberpunkMetricCard(
                        label: "OPERATION_DAYS",
                        value: String(format: "%03d", daysSinceCreated(profile.core.createdAt)),
                        trend: "ACTIVE",
                        trendPositive: true,
                        icon: "calendar.badge.clock"
                    )
                }

                // Performance Metrics Row
                HStack(spacing: 16) {
                    CyberpunkMetricCard(
                        label: "SUCCESS_RATE",
                        value: "87.3%",
                        trend: "ABOVE_AVG",
                        trendPositive: true,
                        icon: "target"
                    )

                    CyberpunkMetricCard(
                        label: "MARKET_RANK",
                        value: "LVL_\(String(format: "%02d", profile.core.level))",
                        trend: "ASCENDING",
                        trendPositive: true,
                        icon: "star.fill"
                    )
                }

                // System Performance Bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("SYSTEM_PERFORMANCE")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkTextSecondary)

                        Spacer()

                        Text("98.7%")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkGreen)
                    }

                    CyberpunkProgressBar(
                        progress: 0.987,
                        color: .cyberpunkGreen,
                        height: 6
                    )
                }
            }
            .scaleEffect(dataRefreshAnimation ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: dataRefreshAnimation)
            .onAppear {
                // Simulate data refresh animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dataRefreshAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dataRefreshAnimation = false
                    }
                }
            }
        }
        .padding(16)
        .cyberpunkCard()
    }

    private func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Cyberpunk Biography Panel
struct CyberpunkBiographyPanel: View {
    let backgroundStory: String
    @State private var revealAnimation = false
    @State private var classifiedEffect = true

    var body: some View {
        VStack(spacing: 16) {
            // Classified Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkYellow)

                    Text("CORPORATE_LINEAGE_FILE")
                        .font(.cyberpunkHeading())
                        .foregroundColor(.cyberpunkYellow)
                        .fontWeight(.bold)
                }

                Spacer()

                // Classification Level
                Text("[CLASSIFIED_LEVEL_3]")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkError)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Rectangle()
                            .fill(Color.cyberpunkError.opacity(0.2))
                            .overlay(
                                Rectangle()
                                    .stroke(Color.cyberpunkError, lineWidth: 1)
                            )
                    )
            }

            // Corporate Timeline
            VStack(alignment: .leading, spacing: 12) {
                CyberpunkTimelineEntry(
                    era: "FOUNDING_ERA",
                    period: "Late Joseon Period (1800s)",
                    description: "조선 후기 대상인 가문 창립",
                    icon: "building.columns",
                    isRevealed: revealAnimation
                )

                CyberpunkTimelineEntry(
                    era: "MODERNIZATION",
                    period: "Meiji Integration Protocol",
                    description: "개화기 해외 진출 및 근대화",
                    icon: "globe.asia.australia",
                    isRevealed: revealAnimation
                )

                CyberpunkTimelineEntry(
                    era: "DIGITAL_TRANSITION",
                    period: "2020s Corporate Uprising",
                    description: "디지털 무역 제국 구축",
                    icon: "network",
                    isRevealed: revealAnimation
                )

                CyberpunkTimelineEntry(
                    era: "CURRENT_OPERATIVE",
                    period: "[USER_DESIGNATION]",
                    description: "Neo-Seoul 무역 패권 도전",
                    icon: "person.badge.key",
                    isRevealed: revealAnimation
                )
            }

            // Access Control
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.cyberpunkGreen)
                    .font(.cyberpunkTechnical())

                Text("BIOMETRIC_ACCESS_VERIFIED")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkGreen)

                Spacer()

                Text("CLEARANCE: ALPHA")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)
            }
        }
        .padding(16)
        .cyberpunkCard()
        .onAppear {
            // Staggered reveal animation
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                revealAnimation = true
            }
        }
    }
}

// MARK: - Supporting Components

// Hexagon Shape for Avatar
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var path = Path()

        for i in 0..<6 {
            let angle = Double(i) * Double.pi / 3
            let point = CGPoint(
                x: center.x + radius * Darwin.cos(angle),
                y: center.y + radius * Darwin.sin(angle)
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

// Metric Card Component
struct CyberpunkMetricCard: View {
    let label: String
    let value: String
    let trend: String
    let trendPositive: Bool
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            // Icon and Trend
            HStack {
                Image(systemName: icon)
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkCyan)

                Spacer()

                Text(trend)
                    .font(.cyberpunkTechnical())
                    .foregroundColor(trendPositive ? .cyberpunkGreen : .cyberpunkError)
            }

            // Value
            Text(value)
                .font(.cyberpunkHeading())
                .foregroundColor(.cyberpunkTextPrimary)
                .fontWeight(.bold)

            // Label
            Text(label)
                .font(.cyberpunkTechnical())
                .foregroundColor(.cyberpunkTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.cyberpunkPanelBg)
        .overlay(
            Rectangle()
                .stroke(Color.cyberpunkBorder, lineWidth: 1)
        )
        .clipShape(Rectangle())
    }
}

// Timeline Entry Component
struct CyberpunkTimelineEntry: View {
    let era: String
    let period: String
    let description: String
    let icon: String
    let isRevealed: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Timeline Icon
            ZStack {
                Circle()
                    .fill(Color.cyberpunkDarkBg)
                    .frame(width: 32, height: 32)

                Circle()
                    .stroke(Color.cyberpunkCyan, lineWidth: 1)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkCyan)
            }

            // Timeline Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("├─ \(era):")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkYellow)

                    Text(period)
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)
                }

                Text(description)
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkTextPrimary)
            }

            Spacer()
        }
        .opacity(isRevealed ? 1.0 : 0.3)
        .scaleEffect(isRevealed ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.5), value: isRevealed)
    }
}

// MARK: - Cyberpunk Control Panel
struct CyberpunkControlPanel: View {
    @State private var notificationsEnabled = true
    @State private var autoSaveEnabled = true
    @State private var securityLevel = 2
    @State private var systemDiagnostics = false

    var body: some View {
        VStack(spacing: 16) {
            // Control Panel Header
            CyberpunkSectionHeader(
                title: "SYSTEM_CONTROL_PANEL",
                subtitle: "SECURITY_CLEARANCE: ALPHA"
            )

            VStack(spacing: 12) {
                // Notification Protocols
                CyberpunkControlRow(
                    icon: "bell.badge",
                    label: "NOTIFICATION_PROTOCOLS",
                    description: "Push alerts and system updates",
                    isEnabled: $notificationsEnabled,
                    securityLevel: "STANDARD"
                )

                // Auto-Save Configuration
                CyberpunkControlRow(
                    icon: "arrow.clockwise.icloud",
                    label: "AUTO_SAVE_PROTOCOL",
                    description: "Automatic data synchronization",
                    isEnabled: $autoSaveEnabled,
                    securityLevel: "ENHANCED"
                )

                // System Diagnostics
                CyberpunkControlRow(
                    icon: "checklist",
                    label: "SYSTEM_DIAGNOSTICS",
                    description: "Performance monitoring and logs",
                    isEnabled: $systemDiagnostics,
                    securityLevel: "CLASSIFIED"
                )

                // Security Level Selector
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkYellow)

                        Text("SECURITY_LEVEL")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkTextPrimary)

                        Spacer()

                        Text("LEVEL_\(securityLevel)")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkCyan)
                    }

                    CyberpunkSecurityLevelPicker(selectedLevel: $securityLevel)
                }
                .padding(12)
                .background(Color.cyberpunkPanelBg)
                .overlay(
                    Rectangle()
                        .stroke(Color.cyberpunkBorder, lineWidth: 1)
                )

                // Emergency Protocols
                CyberpunkEmergencyButton()
            }
        }
        .padding(16)
        .cyberpunkCard()
    }
}

// MARK: - Cyberpunk Control Row
struct CyberpunkControlRow: View {
    let icon: String
    let label: String
    let description: String
    @Binding var isEnabled: Bool
    let securityLevel: String
    @State private var switchGlow = false

    var body: some View {
        HStack(spacing: 12) {
            // Control Icon
            ZStack {
                Circle()
                    .fill(Color.cyberpunkDarkBg)
                    .frame(width: 36, height: 36)

                Circle()
                    .stroke(isEnabled ? Color.cyberpunkGreen : Color.cyberpunkTextSecondary, lineWidth: 1)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.cyberpunkTechnical())
                    .foregroundColor(isEnabled ? .cyberpunkGreen : .cyberpunkTextSecondary)
            }

            // Control Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkTextPrimary)

                    Spacer()

                    // Security Badge
                    Text(securityLevel)
                        .font(.system(size: 8))
                        .foregroundColor(.cyberpunkYellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Rectangle()
                                .fill(Color.cyberpunkYellow.opacity(0.2))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.cyberpunkYellow, lineWidth: 0.5)
                                )
                        )
                }

                Text(description)
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)
            }

            // Cyberpunk Toggle Switch
            CyberpunkToggleSwitch(isOn: $isEnabled)
        }
        .padding(12)
        .background(Color.cyberpunkPanelBg)
        .overlay(
            Rectangle()
                .stroke(isEnabled ? Color.cyberpunkGreen.opacity(0.5) : Color.cyberpunkBorder, lineWidth: 1)
        )
    }
}

// MARK: - Cyberpunk Toggle Switch
struct CyberpunkToggleSwitch: View {
    @Binding var isOn: Bool
    @State private var glowEffect = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        }) {
            ZStack {
                // Background track
                Rectangle()
                    .fill(isOn ? Color.cyberpunkGreen : Color.cyberpunkTextSecondary)
                    .frame(width: 40, height: 20)
                    .overlay(
                        Rectangle()
                            .stroke(Color.cyberpunkBorder, lineWidth: 1)
                    )

                // Switch handle
                Rectangle()
                    .fill(Color.cyberpunkDarkBg)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Rectangle()
                            .stroke(isOn ? Color.cyberpunkGreen : Color.cyberpunkTextSecondary, lineWidth: 1)
                    )
                    .offset(x: isOn ? 10 : -10)
                    .shadow(color: isOn ? Color.cyberpunkGreen.opacity(0.6) : Color.clear, radius: 4)

                // Status indicator
                if isOn {
                    Rectangle()
                        .fill(Color.cyberpunkGreen)
                        .frame(width: 4, height: 4)
                        .offset(x: isOn ? 10 : -10)
                        .opacity(glowEffect ? 0.4 : 1.0)
                        .animation(CyberpunkAnimations.slowGlow, value: glowEffect)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isOn {
                glowEffect.toggle()
            }
        }
        .onChange(of: isOn) { newValue in
            if newValue {
                glowEffect.toggle()
            }
        }
    }
}

// MARK: - Security Level Picker
struct CyberpunkSecurityLevelPicker: View {
    @Binding var selectedLevel: Int
    private let levels = ["BASIC", "STANDARD", "ENHANCED", "CLASSIFIED"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { level in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedLevel = level
                    }
                }) {
                    Text(levels[level])
                        .font(.cyberpunkTechnical())
                        .foregroundColor(selectedLevel >= level ? .cyberpunkYellow : .cyberpunkTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Rectangle()
                                .fill(selectedLevel >= level ? Color.cyberpunkYellow.opacity(0.2) : Color.cyberpunkDarkBg)
                                .overlay(
                                    Rectangle()
                                        .stroke(selectedLevel >= level ? Color.cyberpunkYellow : Color.cyberpunkBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Emergency Button
struct CyberpunkEmergencyButton: View {
    @State private var isPressed = false
    @State private var pulseEffect = false

    var body: some View {
        Button(action: {
            // Emergency logout or reset action
        }) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkError)

                Text("EMERGENCY_LOGOUT")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkError)
                    .fontWeight(.semibold)

                Spacer()

                Text("█ AUTHORIZED ONLY █")
                    .font(.system(size: 8))
                    .foregroundColor(.cyberpunkError)
            }
            .padding(12)
            .background(Color.cyberpunkError.opacity(0.1))
            .overlay(
                Rectangle()
                    .stroke(Color.cyberpunkError, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(pulseEffect ? 0.8 : 1.0)
            .animation(CyberpunkAnimations.technicalFlicker, value: pulseEffect)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: CGFloat.infinity, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        }, perform: {})
        .onAppear {
            // Subtle pulse effect for emergency button
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                pulseEffect.toggle()
            }
        }
    }
}

// MARK: - Helper Functions
private func daysSinceCreated(_ createdAt: Date) -> Int {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.day], from: createdAt, to: now)
    return max(1, components.day ?? 1) // 최소 1일로 표시
}