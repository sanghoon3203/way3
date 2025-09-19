//
//  CyberpunkDesignSystem.swift
//  way3 - Way Trading Game
//
//  사이버펑크 테마 디자인 시스템
//  Cyberpunk_UI.webp 참조한 사이버펑크 스타일 구현
//

import SwiftUI

// MARK: - Cyberpunk Color Palette
extension Color {
    // Primary Colors (Based on Cyberpunk_UI.webp)
    static let cyberpunkYellow = Color(red: 1.0, green: 0.85, blue: 0.0)          // 노란색 강조
    static let cyberpunkGold = Color(red: 1.0, green: 0.75, blue: 0.0)            // 금색 액센트
    static let cyberpunkCyan = Color(red: 0.0, green: 0.9, blue: 0.9)             // 사이안 강조
    static let cyberpunkGreen = Color(red: 0.0, green: 1.0, blue: 0.3)            // 네온 그린

    // Background Colors
    static let cyberpunkDarkBg = Color(red: 0.05, green: 0.05, blue: 0.08)        // 메인 다크 배경
    static let cyberpunkPanelBg = Color(red: 0.1, green: 0.12, blue: 0.15)        // 패널 배경
    static let cyberpunkCardBg = Color(red: 0.15, green: 0.18, blue: 0.22)        // 카드 배경

    // Border and Line Colors
    static let cyberpunkBorder = Color(red: 0.3, green: 0.35, blue: 0.4)          // 기본 보더
    static let cyberpunkGlowBorder = cyberpunkCyan.opacity(0.6)                   // 글로우 보더
    static let cyberpunkActiveBorder = cyberpunkYellow                            // 활성 보더

    // Text Colors
    static let cyberpunkTextPrimary = Color.white                                 // 기본 텍스트
    static let cyberpunkTextSecondary = Color(red: 0.7, green: 0.75, blue: 0.8)   // 보조 텍스트
    static let cyberpunkTextAccent = cyberpunkCyan                                // 강조 텍스트
    static let cyberpunkTextWarning = cyberpunkYellow                             // 경고 텍스트

    // Status Colors
    static let cyberpunkSuccess = cyberpunkGreen                                  // 성공
    static let cyberpunkError = Color(red: 1.0, green: 0.2, blue: 0.3)            // 에러 (빨간색)
    static let cyberpunkWarning = cyberpunkYellow                                 // 경고
    static let cyberpunkInfo = cyberpunkCyan                                      // 정보
}

// MARK: - Cyberpunk Typography
extension Font {
    // Cyberpunk Font Styles (Technical/Monospace Style)
    static func cyberpunkTitle(size: CGFloat = 24) -> Font {
        return .system(size: size, weight: .bold, design: .monospaced)
    }

    static func cyberpunkHeading(size: CGFloat = 18) -> Font {
        return .system(size: size, weight: .semibold, design: .monospaced)
    }

    static func cyberpunkBody(size: CGFloat = 14) -> Font {
        return .system(size: size, weight: .medium, design: .default)
    }

    static func cyberpunkCaption(size: CGFloat = 12) -> Font {
        return .system(size: size, weight: .regular, design: .monospaced)
    }

    static func cyberpunkTechnical(size: CGFloat = 10) -> Font {
        return .system(size: size, weight: .medium, design: .monospaced)
    }

    static func cyberpunkButton(size: CGFloat = 16) -> Font {
        return .system(size: size, weight: .semibold, design: .default)
    }
}

// MARK: - Cyberpunk Layout Constants
struct CyberpunkLayout {
    // Grid and Spacing
    static let gridSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 12
    static let screenPadding: CGFloat = 16
    static let borderWidth: CGFloat = 1.5
    static let glowBorderWidth: CGFloat = 2.0

    // Corner Radius (Angular Style)
    static let cornerRadius: CGFloat = 4  // Much sharper than traditional iOS
    static let buttonCornerRadius: CGFloat = 2
    static let cardCornerRadius: CGFloat = 6

    // Shadows and Effects
    static let shadowRadius: CGFloat = 8
    static let glowRadius: CGFloat = 12

    // Hexagonal Grid Dimensions (for inventory)
    static let hexSize: CGFloat = 50
    static let hexSpacing: CGFloat = 8

    // Technical UI Elements
    static let statusBarHeight: CGFloat = 44
    static let technicalPanelHeight: CGFloat = 60
}

// MARK: - Cyberpunk Animations
struct CyberpunkAnimations {
    static let quickFade: Animation = .easeInOut(duration: 0.2)
    static let standardTransition: Animation = .easeInOut(duration: 0.3)
    static let slowGlow: Animation = .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    static let technicalFlicker: Animation = .easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)
    static let dataTransfer: Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)
}

// MARK: - Cyberpunk Visual Effects
extension View {
    // Cyberpunk Card Style (Angular, Technical)
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

    // Cyberpunk Button Style
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

    // Cyberpunk Panel (with technical corners)
    func cyberpunkPanel() -> some View {
        self
            .background(
                ZStack {
                    Rectangle()
                        .fill(Color.cyberpunkPanelBg)

                    // Technical corner decorations
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
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .stroke(Color.cyberpunkBorder, lineWidth: CyberpunkLayout.borderWidth)
                )
            )
    }

    // Technical Status Bar
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
            .padding(.horizontal, CyberpunkLayout.screenPadding)
            .padding(.vertical, 8)
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

    // Grid slot styling (for inventory)
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
                    .clipShape(Rectangle())
            )
            .shadow(
                color: isSelected ? Color.cyberpunkGlowBorder : Color.clear,
                radius: isSelected ? CyberpunkLayout.glowRadius : 0
            )
    }
}

// MARK: - Cyberpunk Button Styles
enum CyberpunkButtonStyle {
    case primary
    case secondary
    case danger
    case success
    case disabled

    var backgroundColor: Color {
        switch self {
        case .primary: return Color.cyberpunkYellow.opacity(0.2)
        case .secondary: return Color.cyberpunkCyan.opacity(0.1)
        case .danger: return Color.cyberpunkError.opacity(0.2)
        case .success: return Color.cyberpunkGreen.opacity(0.2)
        case .disabled: return Color.cyberpunkBorder.opacity(0.1)
        }
    }

    var borderColor: Color {
        switch self {
        case .primary: return .cyberpunkYellow
        case .secondary: return .cyberpunkCyan
        case .danger: return .cyberpunkError
        case .success: return .cyberpunkGreen
        case .disabled: return .cyberpunkBorder
        }
    }

    var textColor: Color {
        switch self {
        case .primary: return .cyberpunkYellow
        case .secondary: return .cyberpunkCyan
        case .danger: return .cyberpunkError
        case .success: return .cyberpunkGreen
        case .disabled: return .cyberpunkTextSecondary
        }
    }

    var glowColor: Color {
        return borderColor.opacity(0.3)
    }
}

// MARK: - Technical Corner Decoration
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

// MARK: - Technical Data Display
struct CyberpunkDataDisplay: View {
    let label: String
    let value: String
    let valueColor: Color

    init(label: String, value: String, valueColor: Color = .cyberpunkTextAccent) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }

    var body: some View {
        HStack {
            Text(label.uppercased())
                .font(.cyberpunkTechnical())
                .foregroundColor(.cyberpunkTextSecondary)

            Spacer()

            Text(value)
                .font(.cyberpunkCaption())
                .foregroundColor(valueColor)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Rectangle()
                .fill(Color.cyberpunkDarkBg.opacity(0.6))
                .overlay(
                    Rectangle()
                        .stroke(Color.cyberpunkBorder.opacity(0.5), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Cyberpunk Progress Bar
struct CyberpunkProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    let height: CGFloat

    init(progress: Double, color: Color = .cyberpunkCyan, height: CGFloat = 4) {
        self.progress = progress
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.cyberpunkDarkBg)
                    .overlay(
                        Rectangle()
                            .stroke(Color.cyberpunkBorder, lineWidth: 0.5)
                    )

                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(progress))
                    .animation(.linear(duration: 0.5), value: progress)
            }
        }
        .frame(height: height)
        .clipShape(Rectangle())
    }
}