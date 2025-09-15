//
//  ColorExtension.swift
//  way3 - Enhanced Color System
//
//  한국 전통 색상과 게임 UI 색상 시스템
//

import SwiftUI

extension Color {
    // MARK: - 게임 특화 색상 (Achievement, Skills 등에서 사용)
    static let treasureGold = Color(red: 1.0, green: 0.84, blue: 0.0)      // 보물 금색
    static let expGreen = Color(red: 0.2, green: 0.8, blue: 0.2)           // 경험치 녹색
    static let compass = Color(red: 0.8, green: 0.4, blue: 0.0)            // 나침반 색상
    static let oceanTeal = Color(red: 0.0, green: 0.5, blue: 0.5)          // 바다 청록색
    static let goldYellow = Color(red: 1.0, green: 0.9, blue: 0.0)         // 황금색
    
    // MARK: - 한국 전통 색상 (단청, 한복 등에서 영감)
    
    // 단청 색상
    static let dancheong빨강 = Color(red: 0.8, green: 0.2, blue: 0.2)    // 주홍색
    static let dancheong파랑 = Color(red: 0.1, green: 0.3, blue: 0.7)    // 청색
    static let dancheong노랑 = Color(red: 0.9, green: 0.8, blue: 0.1)    // 황색
    static let dancheong초록 = Color(red: 0.2, green: 0.6, blue: 0.3)    // 녹색
    static let dancheong백색 = Color(red: 0.98, green: 0.97, blue: 0.94) // 백색
    
    // 한복 색상
    static let hanbok진홍 = Color(red: 0.7, green: 0.1, blue: 0.3)      // 진홍색
    static let hanbok연두 = Color(red: 0.6, green: 0.8, blue: 0.4)      // 연두색
    static let hanbok자주 = Color(red: 0.5, green: 0.2, blue: 0.6)      // 자주색
    static let hanbok하늘 = Color(red: 0.4, green: 0.7, blue: 0.9)      // 하늘색
    static let hanbok살구 = Color(red: 0.9, green: 0.7, blue: 0.5)      // 살구색
    
    // 자연 색상 (계절별)
    static let 봄벚꽃 = Color(red: 1.0, green: 0.8, blue: 0.9)          // 연분홍
    static let 여름새잎 = Color(red: 0.4, green: 0.8, blue: 0.3)        // 새잎색
    static let 가을단풍 = Color(red: 0.9, green: 0.5, blue: 0.1)        // 단풍색
    static let 겨울눈빛 = Color(red: 0.9, green: 0.95, blue: 1.0)       // 눈빛색
    
    // 전통 문방구 색상
    static let 먹색 = Color(red: 0.1, green: 0.1, blue: 0.1)           // 먹색
    static let 한지색 = Color(red: 0.98, green: 0.96, blue: 0.92)      // 한지색
    static let 주홍인주 = Color(red: 0.8, green: 0.3, blue: 0.2)       // 주홍 인주
    static let 청자색 = Color(red: 0.4, green: 0.6, blue: 0.5)         // 청자색
    
    // MARK: - 게임 상황별 색상
    
    // 거래 상태별 (using DistrictManager colors)
    static let tradeSuccess = Color.gameGreen                           // 거래 성공
    static let tradePending = Color.orange                              // 거래 대기
    static let tradeFailed = Color.red                                  // 거래 실패
    static let tradeNegotiation = Color.gameBlue                        // 협상 중
    
    // 희귀도별 색상
    static let rarityCommon = Color.gray                                // 일반
    static let rarityUncommon = Color.green                             // 고급
    static let rarityRare = Color.gameBlue                              // 희귀
    static let rarityEpic = Color.gamePurple                            // 영웅
    static let rarityLegendary = Color.orange                           // 전설
    static let rarityMythic = Color.red                                 // 신화
    
    // 지역별 색상 (기존 DistrictManager와 연동)
    static let districtGangnam = Color.gameBlue                         // 강남
    static let districtJung = Color.dancheong빨강                       // 중구
    static let districtMapo = Color.hanbok연두                          // 마포
    static let districtJongno = Color.dancheong노랑                     // 종로
    static let districtYongsan = Color.gamePurple                       // 용산
    
    // 시간대별 색상
    static let timeMorning = Color.봄벚꽃                                // 아침
    static let timeAfternoon = Color.여름새잎                            // 오후
    static let timeEvening = Color.가을단풍                             // 저녁
    static let timeNight = Color.dancheong파랑                          // 밤
    
    // AR 관련 색상
    static let arDetected = Color.cyan                                  // AR 감지됨
    static let arCollectable = Color.yellow                             // AR 수집 가능
    static let arInteractive = Color.gameGreen                          // AR 상호작용 가능
    static let arDistance = Color.white.opacity(0.8)                    // AR 거리 표시
    
    // 경매 관련 색상
    static let auctionActive = Color.gameGreen                          // 활성 경매
    static let auctionEnding = Color.orange                             // 마감 임박
    static let auctionEnded = Color.gray                                // 종료된 경매
    static let biddingWinning = Color.yellow                            // 최고가 입찰
    static let biddingLosing = Color.red.opacity(0.7)                   // 경쟁에서 밀림
    
    // 알림/피드백 색상
    static let alertSuccess = Color.gameGreen                           // 성공 알림
    static let alertWarning = Color.orange                              // 경고 알림
    static let alertError = Color.red                                   // 오류 알림
    static let alertInfo = Color.gameBlue                               // 정보 알림
    
    // 사용자 인터페이스 색상
    static let uiPrimary = Color.dancheong파랑                          // 주요 UI
    static let uiSecondary = Color.hanbok하늘                           // 보조 UI
    static let uiAccent = Color.dancheong빨강                           // 강조 색상
    static let uiNeutral = Color.한지색                                 // 중립 색상
    static let uiDanger = Color.hanbok진홍                              // 위험 색상
    
    // MARK: - 접근성을 고려한 색상 함수
    
    // 대비를 높인 색상 (시각적 접근성)
    static func highContrast(_ baseColor: Color) -> Color {
        // 기본 색상의 명도를 조정하여 대비를 높임
        return baseColor.opacity(0.9)
    }
    
    // 색맹을 고려한 색상 (색각 이상자 배려)
    static func colorBlindFriendly(for type: ColorBlindType) -> [Color] {
        switch type {
        case .protanopia:
            return [.gameBlue, .orange, .gray, .white, .black]
        case .deuteranopia:
            return [.gameBlue, .orange, .yellow, .white, .black]
        case .tritanopia:
            return [.red, .green, .purple, .white, .black]
        }
    }
    
    enum ColorBlindType {
        case protanopia     // 적색맹
        case deuteranopia   // 녹색맹
        case tritanopia     // 청색맹
    }
    
    // MARK: - 동적 색상 (다크모드 지원)
    
    static let dynamicBackground = Color(.systemBackground)
    static let dynamicSecondaryBackground = Color(.secondarySystemBackground)
    static let dynamicTertiaryBackground = Color(.tertiarySystemBackground)
    static let dynamicLabel = Color(.label)
    static let dynamicSecondaryLabel = Color(.secondaryLabel)
    static let dynamicTertiaryLabel = Color(.tertiaryLabel)
    
    // MARK: - 그라데이션 프리셋
    
    static let gameGradient = LinearGradient(
        colors: [.gameBlue, .gamePurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let traditionalGradient = LinearGradient(
        colors: [.dancheong빨강, .dancheong노랑],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let seasonalGradient = LinearGradient(
        colors: [.봄벚꽃, .여름새잎, .가을단풍],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let auctionGradient = LinearGradient(
        colors: [.auctionActive.opacity(0.8), .auctionActive.opacity(0.3)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let arGradient = LinearGradient(
        colors: [.arDetected.opacity(0.6), .arCollectable.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 색상 유틸리티 함수
    
    // 색상의 밝기 조절
    func brightness(_ amount: Double) -> Color {
        return self.opacity(1.0 + amount)
    }
    
    // 색상의 채도 조절
    func saturation(_ amount: Double) -> Color {
        // SwiftUI에서는 직접적인 채도 조절 함수가 없으므로 근사치 구현
        return self.opacity(min(1.0, max(0.0, amount)))
    }
    
    // 색상 혼합
    func blend(with color: Color, ratio: Double) -> Color {
        // 두 색상을 지정된 비율로 혼합
        return Color(
            red: self.components.red * (1 - ratio) + color.components.red * ratio,
            green: self.components.green * (1 - ratio) + color.components.green * ratio,
            blue: self.components.blue * (1 - ratio) + color.components.blue * ratio
        )
    }
    
    // 색상 구성 요소 추출
    var components: (red: Double, green: Double, blue: Double, alpha: Double) {
        #if canImport(UIKit)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
        #else
        return (0, 0, 0, 1) // macOS에서는 기본값 반환
        #endif
    }
}

// MARK: - 색상 테마 관리자
class ColorThemeManager: ObservableObject {
    @Published var currentTheme: ColorTheme = .traditional
    
    enum ColorTheme {
        case traditional    // 전통 한국 색상
        case modern        // 현대적 게임 색상
        case seasonal      // 계절별 색상
        case accessibility // 접근성 고려 색상
        
        var primaryColor: Color {
            switch self {
            case .traditional: return .dancheong빨강
            case .modern: return .gameBlue
            case .seasonal: return .봄벚꽃 // 계절에 따라 동적으로 변경 가능
            case .accessibility: return .black
            }
        }
        
        var secondaryColor: Color {
            switch self {
            case .traditional: return .dancheong파랑
            case .modern: return .gameGreen
            case .seasonal: return .여름새잎
            case .accessibility: return .gray
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .traditional: return .한지색
            case .modern: return .dynamicBackground
            case .seasonal: return .겨울눈빛
            case .accessibility: return .white
            }
        }
        
        var textColor: Color {
            switch self {
            case .traditional: return .먹색
            case .modern: return .dynamicLabel
            case .seasonal: return .먹색
            case .accessibility: return .black
            }
        }
    }
    
    func setTheme(_ theme: ColorTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }
    
    // 계절에 따른 자동 테마 전환
    func updateSeasonalTheme() {
        let month = Calendar.current.component(.month, from: Date())
        
        switch month {
        case 3...5:  // 봄
            setTheme(.seasonal)
        case 6...8:  // 여름
            setTheme(.seasonal)
        case 9...11: // 가을
            setTheme(.seasonal)
        default:     // 겨울
            setTheme(.seasonal)
        }
    }
    
    // 시간대에 따른 색상 조절
    func getTimeBasedColor() -> Color {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5...11:   return .timeMorning   // 아침
        case 12...17:  return .timeAfternoon // 오후
        case 18...21:  return .timeEvening   // 저녁
        default:       return .timeNight     // 밤
        }
    }
}

// MARK: - 색상 적용 View Modifier
struct ThemedColorModifier: ViewModifier {
    @ObservedObject var themeManager: ColorThemeManager
    let colorType: ColorType
    
    enum ColorType {
        case primary, secondary, background, text
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(getColor())
    }
    
    private func getColor() -> Color {
        switch colorType {
        case .primary: return themeManager.currentTheme.primaryColor
        case .secondary: return themeManager.currentTheme.secondaryColor
        case .background: return themeManager.currentTheme.backgroundColor
        case .text: return themeManager.currentTheme.textColor
        }
    }
}

extension View {
    func themedColor(_ colorType: ThemedColorModifier.ColorType, themeManager: ColorThemeManager) -> some View {
        self.modifier(ThemedColorModifier(themeManager: themeManager, colorType: colorType))
    }
}

// MARK: - 미리보기
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // 전통 색상 팔레트
            Group {
                Text("한국 전통 색상")
                    .font(.headline)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                    ColorSwatch(color: .dancheong빨강, name: "단청 빨강")
                    ColorSwatch(color: .dancheong파랑, name: "단청 파랑")
                    ColorSwatch(color: .dancheong노랑, name: "단청 노랑")
                    ColorSwatch(color: .dancheong초록, name: "단청 초록")
                    ColorSwatch(color: .dancheong백색, name: "단청 백색")
                }
            }
            
            Divider()
            
            // 한복 색상 팔레트
            Group {
                Text("한복 색상")
                    .font(.headline)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                    ColorSwatch(color: .hanbok진홍, name: "진홍")
                    ColorSwatch(color: .hanbok연두, name: "연두")
                    ColorSwatch(color: .hanbok자주, name: "자주")
                    ColorSwatch(color: .hanbok하늘, name: "하늘")
                    ColorSwatch(color: .hanbok살구, name: "살구")
                }
            }
            
            Divider()
            
            // 계절 색상 팔레트
            Group {
                Text("계절 색상")
                    .font(.headline)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ColorSwatch(color: .봄벚꽃, name: "봄 벚꽃")
                    ColorSwatch(color: .여름새잎, name: "여름 새잎")
                    ColorSwatch(color: .가을단풍, name: "가을 단풍")
                    ColorSwatch(color: .겨울눈빛, name: "겨울 눈빛")
                }
            }
            
            Divider()
            
            // 그라데이션 미리보기
            Group {
                Text("그라데이션")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gameGradient)
                        .frame(height: 50)
                        .overlay(Text("게임 그라데이션").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.traditionalGradient)
                        .frame(height: 50)
                        .overlay(Text("전통 그라데이션").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.seasonalGradient)
                        .frame(height: 50)
                        .overlay(Text("계절 그라데이션").foregroundColor(.white))
                }
            }
        }
        .padding()
    }
}

// 색상 견본 컴포넌트
struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
            
            Text(name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}