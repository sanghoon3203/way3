//
//  JRPGScreenManager.swift
//  way3 - Way Trading Game
//
//  JRPG 스타일 화면 크기 및 레이아웃 관리
//  전통적인 JRPG 비율과 현대적 반응형 디자인 결합
//

import SwiftUI
import UIKit

// MARK: - JRPG 화면 관리 시스템
struct JRPGScreenManager {

    // MARK: - 기본 화면 정보
    static let screenBounds = UIScreen.main.bounds
    static let screenWidth = screenBounds.width
    static let screenHeight = screenBounds.height
    static let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero

    // MARK: - JRPG 전통 비율 (16:9 기준 최적화)
    struct JRPGLayout {
        // 상인 대화 화면 비율
        static let characterAreaRatio: CGFloat = 0.65    // 상단 65% - 캐릭터 영역
        static let dialogueAreaRatio: CGFloat = 0.35     // 하단 35% - 대화창 영역

        // 대화창 내부 비율
        static let dialogueBoxHeight: CGFloat = 120      // 고정 높이 (전통적)
        static let choiceMenuWidth: CGFloat = 200        // 선택지 메뉴 너비
        static let choiceMenuHeight: CGFloat = 160       // 선택지 메뉴 높이

        // 여백 및 패딩
        static let screenPadding: CGFloat = 20           // 화면 가장자리 여백
        static let dialoguePadding: CGFloat = 16         // 대화창 내부 여백
        static let choiceMenuOffset: CGPoint = CGPoint(x: -30, y: 20) // 선택지 메뉴 오프셋
    }

    // MARK: - 계산된 크기들
    static var characterAreaHeight: CGFloat {
        let availableHeight = screenHeight - safeAreaInsets.top - safeAreaInsets.bottom
        return availableHeight * JRPGLayout.characterAreaRatio
    }

    static var dialogueAreaHeight: CGFloat {
        let availableHeight = screenHeight - safeAreaInsets.top - safeAreaInsets.bottom
        return availableHeight * JRPGLayout.dialogueAreaRatio
    }

    static var safeDialogueWidth: CGFloat {
        return screenWidth - (JRPGLayout.screenPadding * 2)
    }

    static var choiceMenuPosition: CGPoint {
        return CGPoint(
            x: safeDialogueWidth - JRPGLayout.choiceMenuWidth + JRPGLayout.choiceMenuOffset.x,
            y: JRPGLayout.choiceMenuOffset.y
        )
    }

    // MARK: - 기기별 최적화
    static var isCompactHeight: Bool {
        return screenHeight < 700 // iPhone SE 등 작은 화면
    }

    static var isLargeScreen: Bool {
        return screenWidth > 400 // iPhone Pro Max 등 큰 화면
    }

    // MARK: - 적응형 크기 계산
    static func adaptiveSize(base: CGFloat, compact: CGFloat? = nil, large: CGFloat? = nil) -> CGFloat {
        if isCompactHeight, let compactSize = compact {
            return compactSize
        } else if isLargeScreen, let largeSize = large {
            return largeSize
        }
        return base
    }

    // MARK: - JRPG 전용 색상 팔레트
    struct JRPGColors {
        static let dialogueBackground = Color.black.opacity(0.85)
        static let dialogueBorder = Color.gold
        static let dialogueText = Color.white
        static let choiceBackground = Color.blue.opacity(0.9)
        static let choiceBorder = Color.cyan
        static let choiceHighlight = Color.yellow
        static let characterAreaBackground = Color.clear

        // 그라데이션
        static let dialogueGradient = LinearGradient(
            colors: [Color.black.opacity(0.9), Color.blue.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )

        static let choiceGradient = LinearGradient(
            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - JRPG 애니메이션 상수
    struct JRPGAnimations {
        static let textTypingSpeed: Double = 0.03        // 텍스트 타이핑 속도
        static let dialogueAppearDuration: Double = 0.5  // 대화창 등장 시간
        static let choiceMenuAppearDuration: Double = 0.3 // 선택지 등장 시간
        static let characterBounceDuration: Double = 2.0  // 캐릭터 살랑살랑 애니메이션
        static let glowPulseDuration: Double = 1.5       // 테두리 글로우 애니메이션
    }

    // MARK: - 디버그 정보
    static var debugInfo: String {
        return """
        📱 Screen: \(Int(screenWidth))x\(Int(screenHeight))
        👤 Character Area: \(Int(characterAreaHeight))px
        💬 Dialogue Area: \(Int(dialogueAreaHeight))px
        📱 Safe Width: \(Int(safeDialogueWidth))px
        🎮 Layout: \(isCompactHeight ? "Compact" : "Normal")
        """
    }
}

// MARK: - JRPG 스타일 Modifier들
extension View {
    func jrpgDialogueBox() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(JRPGScreenManager.JRPGColors.dialogueGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(JRPGScreenManager.JRPGColors.dialogueBorder, lineWidth: 2)
                            .shadow(color: JRPGScreenManager.JRPGColors.dialogueBorder.opacity(0.5), radius: 8)
                    )
            )
    }

    func jrpgChoiceMenu() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(JRPGScreenManager.JRPGColors.choiceGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(JRPGScreenManager.JRPGColors.choiceBorder, lineWidth: 1.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 2, y: 2)
    }

    func jrpgGlowPulse() -> some View {
        self
            .shadow(color: JRPGScreenManager.JRPGColors.dialogueBorder.opacity(0.6), radius: 4)
            .animation(
                Animation.easeInOut(duration: JRPGScreenManager.JRPGAnimations.glowPulseDuration)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )
    }
}

// MARK: - JRPG 폰트 시스템
extension Font {
    static func jrpgTitle() -> Font {
        return .chosunOrFallback(size: 22, weight: .bold)
    }

    static func jrpgDialogue() -> Font {
        return .chosunOrFallback(size: 16, weight: .medium)
    }

    static func jrpgChoice() -> Font {
        return .chosunOrFallback(size: 14, weight: .semibold)
    }

    static func jrpgUI() -> Font {
        return .chosunOrFallback(size: 12, weight: .regular)
    }
}