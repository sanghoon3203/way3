// 📁 Extensions/Color+GameColors.swift - 게임 전용 색상 정의
import SwiftUI

/**
 * 게임에서 사용하는 커스텀 색상들
 *
 * 일관성 있는 UI/UX를 위해 게임 전체에서 사용할 색상들을 정의합니다.
 * 각 색상은 게임의 특정 요소나 등급을 나타냅니다.
 */
extension Color {

    // MARK: - 게임 테마 색상

    /// 보물/골드 관련 색상 (황금색)
    static let treasureGold = Color(red: 1.0, green: 0.84, blue: 0.0) // #FFD700

    /// 경험치/성장 관련 색상 (녹색)
    static let expGreen = Color(red: 0.0, green: 0.8, blue: 0.0) // #00CC00

    /// 희귀 아이템 색상 (보라색)
    static let rarePurple = Color(red: 0.64, green: 0.21, blue: 0.93) // #A335EE

    /// 전설 아이템 색상 (주황색)
    static let legendaryOrange = Color(red: 1.0, green: 0.5, blue: 0.0) // #FF8000

    /// 신화 아이템 색상 (빨간색)
    static let mythicRed = Color(red: 0.9, green: 0.1, blue: 0.1) // #E61919

    /// 에픽 아이템 색상 (자주색)
    static let epicPurple = Color(red: 0.58, green: 0.44, blue: 0.86) // #9370DB

    /// 언커먼 아이템 색상 (초록색)
    static let uncommonGreen = Color(red: 0.12, green: 0.56, blue: 0.1) // #1E8F1A

    /// 커먼 아이템 색상 (회색)
    static let commonGray = Color(red: 0.62, green: 0.62, blue: 0.62) // #9D9D9D

    // MARK: - 아이템 등급별 색상

    /**
     * 아이템 등급에 따른 색상 반환
     */
    static func itemGradeColor(for grade: String) -> Color {
        switch grade.lowercased() {
        case "common", "일반":
            return .commonGray
        case "uncommon", "고급":
            return .uncommonGreen
        case "rare", "희귀":
            return .rarePurple
        case "epic", "영웅":
            return .epicPurple
        case "legendary", "전설":
            return .legendaryOrange
        case "mythic", "신화":
            return .mythicRed
        default:
            return .commonGray
        }
    }

    // MARK: - 상태별 색상

    /// 성공/긍정 상태 색상
    static let successGreen = Color(red: 0.0, green: 0.7, blue: 0.0) // #00B300

    /// 경고 상태 색상
    static let warningYellow = Color(red: 1.0, green: 0.8, blue: 0.0) // #FFCC00

    /// 위험/오류 상태 색상
    static let dangerRed = Color(red: 0.9, green: 0.2, blue: 0.2) // #E63333

    /// 정보 상태 색상
    static let infoBlue = Color(red: 0.2, green: 0.6, blue: 1.0) // #3399FF

    // MARK: - 게임 UI 색상

    /// 배경 색상 (다크 모드 대응)
    static let gameBackground = Color(.systemBackground)

    /// 카드 배경 색상
    static let cardBackground = Color(.secondarySystemBackground)

    /// 텍스트 주요 색상
    static let primaryText = Color(.label)

    /// 텍스트 보조 색상
    static let secondaryText = Color(.secondaryLabel)

    /// 구분선 색상
    static let separatorColor = Color(.separator)

    // MARK: - 상인/거래 관련 색상

    /// 상인 핀 색상 (기본)
    static let merchantPin = Color(red: 0.2, green: 0.5, blue: 0.9) // #3380E6

    /// 상인 핀 색상 (프리미엄)
    static let premiumMerchantPin = Color(red: 0.8, green: 0.4, blue: 0.9) // #CC66E6

    /// 거래 가능 색상
    static let tradeAvailable = Color(red: 0.0, green: 0.8, blue: 0.4) // #00CC66

    /// 거래 불가 색상
    static let tradeUnavailable = Color(red: 0.8, green: 0.3, blue: 0.3) // #CC4D4D

    // MARK: - 진행도/레벨 색상

    /// 레벨업 색상
    static let levelUpGold = Color(red: 1.0, green: 0.9, blue: 0.0) // #FFE600

    /// 경험치 바 색상
    static let experienceBlue = Color(red: 0.1, green: 0.4, blue: 0.8) // #1A66CC

    /// 진행도 바 배경
    static let progressBackground = Color(red: 0.9, green: 0.9, blue: 0.9) // #E6E6E6

    // MARK: - 특수 효과 색상

    /// 반짝임 효과 색상
    static let sparkleGold = Color(red: 1.0, green: 0.96, blue: 0.4) // #FFF566

    /// 마법 효과 색상
    static let magicPurple = Color(red: 0.5, green: 0.0, blue: 0.8) // #8000CC

    /// 버프 효과 색상
    static let buffGreen = Color(red: 0.4, green: 0.9, blue: 0.4) // #66E666

    /// 디버프 효과 색상
    static let debuffRed = Color(red: 0.9, green: 0.4, blue: 0.4) // #E66666

    // MARK: - 지역별 색상

    /// 강남 지역 색상
    static let gangnamPink = Color(red: 1.0, green: 0.4, blue: 0.7) // #FF66B3

    /// 홍대 지역 색상
    static let hongdaeOrange = Color(red: 1.0, green: 0.6, blue: 0.2) // #FF9933

    /// 명동 지역 색상
    static let myeongdongBlue = Color(red: 0.3, green: 0.6, blue: 1.0) // #4D99FF

    /// 이태원 지역 색상
    static let itaewonGreen = Color(red: 0.2, green: 0.8, blue: 0.5) // #33CC80

    // MARK: - 나침반/방향 관련 색상

    /// 나침반 색상 (북쪽을 가리키는 빨간색)
    static let compass = Color(red: 0.9, green: 0.2, blue: 0.2) // #E63333

    // MARK: - Achievement 관련 색상

    /// 바다 청록색 (성취 색상)
    static let oceanTeal = Color(red: 0.0, green: 0.5, blue: 0.5) // #008080

    /// 황금색 (성취 색상)
    static let goldYellow = Color(red: 1.0, green: 0.84, blue: 0.0) // #FFD700

    // MARK: - 헬퍼 메서드들

    /**
     * 색상에 투명도 적용
     */
    func withGameOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }

    /**
     * 다크모드/라이트모드에 따른 적응형 색상
     */
    static func adaptiveColor(light: Color, dark: Color) -> Color {
        return Color(.systemBackground) == Color.black ? dark : light
    }

    /**
     * 색상을 밝게 만들기
     */
    func lighter(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }

    /**
     * 색상을 어둡게 만들기
     */
    func darker(by percentage: Double = 0.2) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return Color(
            red: Double(max(red - CGFloat(percentage), 0.0)),
            green: Double(max(green - CGFloat(percentage), 0.0)),
            blue: Double(max(blue - CGFloat(percentage), 0.0)),
            opacity: Double(alpha)
        )
    }
}

// MARK: - 색상 팔레트 구조체
struct GameColorPalette {
    // 아이템 등급 색상 배열
    static let itemGrades: [Color] = [
        .commonGray,
        .uncommonGreen,
        .rarePurple,
        .epicPurple,
        .legendaryOrange,
        .mythicRed
    ]

    // 상태 색상 배열
    static let statusColors: [Color] = [
        .successGreen,
        .warningYellow,
        .dangerRed,
        .infoBlue
    ]

    // 지역 색상 배열
    static let districtColors: [Color] = [
        .gangnamPink,
        .hongdaeOrange,
        .myeongdongBlue,
        .itaewonGreen
    ]

    // 랜덤 게임 색상 반환
    static func randomGameColor() -> Color {
        let allColors = itemGrades + statusColors + districtColors
        return allColors.randomElement() ?? .blue
    }
}

// MARK: - 색상 유틸리티 확장
extension Color {
    /// 16진수 문자열로부터 색상 생성
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// 색상을 16진수 문자열로 변환
    var hexString: String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}