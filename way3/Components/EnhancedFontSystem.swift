//
//  EnhancedFontSystem.swift
//  way3 - Enhanced ChosunCentennial Font System
//
//  완전한 ChosunCentennial 폰트 디자인 시스템
//

import SwiftUI

// MARK: - 확장된 폰트 시스템
extension Font {
    // MARK: - 기본 크기 체계 (기존 확장)
    static func chosun(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom("ChosunCentennial", size: size).weight(weight)
    }
    
    // MARK: - 새로운 맥락별 폰트 스타일
    
    // 게임 UI 특화
    static let gameDisplay = Font.chosun(48, weight: .heavy)      // 대형 디스플레이
    static let gameTitle = Font.chosun(32, weight: .bold)         // 화면 제목
    static let gameSubtitle = Font.chosun(24, weight: .semibold)  // 부제목
    static let gameHeader = Font.chosun(20, weight: .semibold)    // 섹션 헤더
    static let gameBody = Font.chosun(16, weight: .regular)       // 본문
    static let gameDetail = Font.chosun(14, weight: .regular)     // 상세 정보
    static let gameCaption = Font.chosun(12, weight: .regular)    // 캡션
    static let gameSmall = Font.chosun(10, weight: .regular)      // 작은 텍스트
    
    // 상거래/경제 특화
    static let priceDisplay = Font.chosun(28, weight: .heavy)     // 가격 표시
    static let priceLarge = Font.chosun(24, weight: .bold)        // 큰 가격
    static let priceRegular = Font.chosun(18, weight: .semibold)  // 일반 가격
    static let priceSmall = Font.chosun(14, weight: .medium)      // 작은 가격
    static let currency = Font.chosun(16, weight: .medium)        // 통화 단위
    
    // 거래/협상 특화
    static let negotiationTitle = Font.chosun(22, weight: .bold)  // 협상 제목
    static let merchantName = Font.chosun(20, weight: .semibold)  // 상인 이름
    static let itemName = Font.chosun(18, weight: .medium)        // 아이템 이름
    static let tradeStatus = Font.chosun(16, weight: .semibold)   // 거래 상태
    static let dialogueText = Font.chosun(16, weight: .regular)   // 대화 텍스트
    
    // AR/특수 효과 특화
    static let arOverlay = Font.chosun(20, weight: .bold)         // AR 오버레이
    static let arHUD = Font.chosun(16, weight: .semibold)         // AR HUD
    static let arInfo = Font.chosun(14, weight: .medium)          // AR 정보
    static let arDistance = Font.chosun(12, weight: .regular)     // AR 거리
    
    // 경매/이벤트 특화
    static let auctionTimer = Font.chosun(36, weight: .heavy)     // 경매 타이머
    static let auctionPrice = Font.chosun(28, weight: .bold)      // 경매 가격
    static let auctionBid = Font.chosun(20, weight: .semibold)    // 입찰 금액
    static let eventTitle = Font.chosun(24, weight: .bold)        // 이벤트 제목
    static let eventInfo = Font.chosun(16, weight: .regular)      // 이벤트 정보
    
    // 알림/피드백 특화
    static let alertTitle = Font.chosun(18, weight: .bold)        // 알림 제목
    static let alertMessage = Font.chosun(16, weight: .regular)   // 알림 메시지
    static let toastMessage = Font.chosun(14, weight: .medium)    // 토스트 메시지
    static let notification = Font.chosun(12, weight: .regular)   // 알림
    
    // 버튼/액션 특화
    static let buttonPrimary = Font.chosun(16, weight: .semibold) // 주요 버튼
    static let buttonSecondary = Font.chosun(14, weight: .medium) // 보조 버튼
    static let buttonSmall = Font.chosun(12, weight: .medium)     // 작은 버튼
    static let tabBar = Font.chosun(10, weight: .medium)          // 탭바
    
    // 통계/데이터 특화
    static let statsTitle = Font.chosun(20, weight: .bold)        // 통계 제목
    static let statsValue = Font.chosun(24, weight: .heavy)       // 통계 값
    static let statsLabel = Font.chosun(14, weight: .regular)     // 통계 라벨
    static let leaderboard = Font.chosun(16, weight: .semibold)   // 리더보드
    
    // 지역/위치 특화
    static let districtName = Font.chosun(18, weight: .bold)      // 지역명
    static let locationInfo = Font.chosun(14, weight: .regular)   // 위치 정보
    static let addressText = Font.chosun(12, weight: .regular)    // 주소
    
    // 시간/날짜 특화
    static let timeDisplay = Font.chosun(20, weight: .bold)       // 시간 표시
    static let dateText = Font.chosun(16, weight: .regular)       // 날짜
    static let timestamp = Font.chosun(12, weight: .regular)      // 타임스탬프
}

// MARK: - 텍스트 스타일 프리셋
struct ChosunTextStyle {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat
    let kerning: CGFloat
    
    init(font: Font, color: Color = .primary, lineSpacing: CGFloat = 0, kerning: CGFloat = 0) {
        self.font = font
        self.color = color
        self.lineSpacing = lineSpacing
        self.kerning = kerning
    }
    
    // MARK: - 프리셋 스타일들
    
    // 제목 스타일
    static let heroTitle = ChosunTextStyle(
        font: .gameDisplay,
        color: .primary,
        lineSpacing: 4,
        kerning: 1
    )
    
    static let pageTitle = ChosunTextStyle(
        font: .gameTitle,
        color: .primary,
        lineSpacing: 2,
        kerning: 0.5
    )
    
    static let sectionTitle = ChosunTextStyle(
        font: .gameSubtitle,
        color: .primary,
        lineSpacing: 2,
        kerning: 0.3
    )
    
    // 가격 스타일
    static let priceHighlight = ChosunTextStyle(
        font: .priceDisplay,
        color: .gameGreen,
        lineSpacing: 0,
        kerning: 1
    )
    
    static let priceNormal = ChosunTextStyle(
        font: .priceRegular,
        color: .primary,
        lineSpacing: 0,
        kerning: 0.5
    )
    
    static let priceDiscount = ChosunTextStyle(
        font: .priceRegular,
        color: .orange,
        lineSpacing: 0,
        kerning: 0.5
    )
    
    // 상거래 스타일
    static let merchantTitle = ChosunTextStyle(
        font: .merchantName,
        color: .gameBlue,
        lineSpacing: 0,
        kerning: 0.3
    )
    
    static let itemNameStyle = ChosunTextStyle(
        font: .itemName,
        color: .primary,
        lineSpacing: 0,
        kerning: 0.2
    )
    
    static let tradeStatusSuccess = ChosunTextStyle(
        font: .tradeStatus,
        color: .gameGreen,
        lineSpacing: 0,
        kerning: 0.2
    )
    
    static let tradeStatusPending = ChosunTextStyle(
        font: .tradeStatus,
        color: .orange,
        lineSpacing: 0,
        kerning: 0.2
    )
    
    static let tradeStatusFailed = ChosunTextStyle(
        font: .tradeStatus,
        color: .red,
        lineSpacing: 0,
        kerning: 0.2
    )
    
    // AR 스타일
    static let arTitle = ChosunTextStyle(
        font: .arOverlay,
        color: .white,
        lineSpacing: 0,
        kerning: 0.5
    )
    
    static let arInfo = ChosunTextStyle(
        font: .arInfo,
        color: .white.opacity(0.9),
        lineSpacing: 0,
        kerning: 0.2
    )
    
    // 경매 스타일
    static let auctionTimerStyle = ChosunTextStyle(
        font: .auctionTimer,
        color: .white,
        lineSpacing: 0,
        kerning: 2
    )
    
    static let auctionPriceStyle = ChosunTextStyle(
        font: .auctionPrice,
        color: .gameGreen,
        lineSpacing: 0,
        kerning: 1
    )
    
    // 알림 스타일
    static let successAlert = ChosunTextStyle(
        font: .alertTitle,
        color: .gameGreen,
        lineSpacing: 0,
        kerning: 0.3
    )
    
    static let warningAlert = ChosunTextStyle(
        font: .alertTitle,
        color: .orange,
        lineSpacing: 0,
        kerning: 0.3
    )
    
    static let errorAlert = ChosunTextStyle(
        font: .alertTitle,
        color: .red,
        lineSpacing: 0,
        kerning: 0.3
    )
}

// MARK: - 텍스트 스타일 적용 View Modifier
struct ChosunTextStyleModifier: ViewModifier {
    let style: ChosunTextStyle
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(style.color)
            .lineSpacing(style.lineSpacing)
            .kerning(style.kerning)
    }
}

extension View {
    func chosunStyle(_ style: ChosunTextStyle) -> some View {
        self.modifier(ChosunTextStyleModifier(style: style))
    }
}

// MARK: - 특수 효과 Text Components
struct ChosunAnimatedText: View {
    let text: String
    let style: ChosunTextStyle
    let animationType: AnimationType
    @State private var isAnimating = false
    
    enum AnimationType {
        case typewriter
        case fadeIn
        case scale
        case glow
        case shake
    }
    
    var body: some View {
        switch animationType {
        case .typewriter:
            typewriterText
        case .fadeIn:
            fadeInText
        case .scale:
            scaleText
        case .glow:
            glowText
        case .shake:
            shakeText
        }
    }
    
    private var typewriterText: some View {
        Text(text)
            .chosunStyle(style)
            .onAppear {
                // 타이프라이터 효과 구현
            }
    }
    
    private var fadeInText: some View {
        Text(text)
            .chosunStyle(style)
            .opacity(isAnimating ? 1 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    isAnimating = true
                }
            }
    }
    
    private var scaleText: some View {
        Text(text)
            .chosunStyle(style)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAnimating = true
                }
            }
    }
    
    private var glowText: some View {
        Text(text)
            .chosunStyle(style)
            .shadow(color: style.color.opacity(0.8), radius: isAnimating ? 10 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
    
    private var shakeText: some View {
        Text(text)
            .chosunStyle(style)
            .offset(x: isAnimating ? 2 : 0)
            .onAppear {
                withAnimation(.linear(duration: 0.1).repeatCount(6, autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - 가격 표시 전용 컴포넌트
struct ChosunPriceText: View {
    let price: Int
    let style: PriceStyle
    let showCurrency: Bool
    
    enum PriceStyle {
        case large, normal, small, discount
        
        var textStyle: ChosunTextStyle {
            switch self {
            case .large: return .priceHighlight
            case .normal: return .priceNormal
            case .small: return ChosunTextStyle(font: .priceSmall, color: .primary)
            case .discount: return .priceDiscount
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text(formatPrice(price))
                .chosunStyle(style.textStyle)
            
            if showCurrency {
                Text("원")
                    .chosunStyle(ChosunTextStyle(font: .currency, color: style.textStyle.color))
            }
        }
    }
    
    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "0"
    }
}

// MARK: - 상거래 상태 표시 컴포넌트
struct ChosunTradeStatusText: View {
    let status: TradeStatus
    let showIcon: Bool
    
    enum TradeStatus {
        case pending, inProgress, success, failed, cancelled
        
        var text: String {
            switch self {
            case .pending: return "대기 중"
            case .inProgress: return "거래 중"
            case .success: return "완료"
            case .failed: return "실패"
            case .cancelled: return "취소됨"
            }
        }
        
        var style: ChosunTextStyle {
            switch self {
            case .pending: return ChosunTextStyle(font: .tradeStatus, color: .orange)
            case .inProgress: return ChosunTextStyle(font: .tradeStatus, color: .gameBlue)
            case .success: return .tradeStatusSuccess
            case .failed: return .tradeStatusFailed
            case .cancelled: return ChosunTextStyle(font: .tradeStatus, color: .gray)
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .inProgress: return "arrow.triangle.2.circlepath"
            case .success: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            case .cancelled: return "minus.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: status.icon)
                    .foregroundColor(status.style.color)
                    .font(.system(size: 12))
            }
            
            Text(status.text)
                .chosunStyle(status.style)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.style.color.opacity(0.1))
        )
    }
}

// MARK: - 지역별 텍스트 스타일
struct ChosunDistrictText: View {
    let district: DistrictManager.GameDistrict
    let showEmoji: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            if showEmoji {
                Text(district.emoji)
                    .font(.title2)
            }
            
            Text(district.displayName)
                .chosunStyle(ChosunTextStyle(
                    font: .districtName,
                    color: district.color,
                    kerning: 0.5
                ))
        }
    }
}

// MARK: - 시간 표시 전용 컴포넌트
struct ChosunTimeText: View {
    let time: Date
    let format: TimeFormat
    
    enum TimeFormat {
        case relative, absolute, timer
        
        var formatter: DateFormatter {
            let formatter = DateFormatter()
            switch self {
            case .relative:
                formatter.dateStyle = .none
                formatter.timeStyle = .short
            case .absolute:
                formatter.dateFormat = "yyyy.MM.dd HH:mm"
            case .timer:
                formatter.dateFormat = "mm:ss"
            }
            return formatter
        }
        
        var font: Font {
            switch self {
            case .relative: return .timestamp
            case .absolute: return .dateText
            case .timer: return .timeDisplay
            }
        }
        
        var color: Color {
            switch self {
            case .relative: return .secondary
            case .absolute: return .primary
            case .timer: return .gameBlue
            }
        }
    }
    
    var body: some View {
        Text(formatTime())
            .chosunStyle(ChosunTextStyle(
                font: format.font,
                color: format.color,
                kerning: format == .timer ? 1 : 0
            ))
    }
    
    private func formatTime() -> String {
        if format == .relative {
            return timeAgoString()
        } else {
            return format.formatter.string(from: time)
        }
    }
    
    private func timeAgoString() -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(time)
        
        if timeInterval < 60 {
            return "방금 전"
        } else if timeInterval < 3600 {
            return "\(Int(timeInterval / 60))분 전"
        } else if timeInterval < 86400 {
            return "\(Int(timeInterval / 3600))시간 전"
        } else {
            return "\(Int(timeInterval / 86400))일 전"
        }
    }
}

// MARK: - 레벨/등급 표시 컴포넌트
struct ChosunLevelText: View {
    let level: Int
    let showPrefix: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            if showPrefix {
                Text("Lv.")
                    .chosunStyle(ChosunTextStyle(
                        font: .gameDetail,
                        color: .secondary,
                        kerning: 0.2
                    ))
            }
            
            Text("\(level)")
                .chosunStyle(ChosunTextStyle(
                    font: .statsValue,
                    color: levelColor(level),
                    kerning: 0.5
                ))
        }
    }
    
    private func levelColor(_ level: Int) -> Color {
        switch level {
        case 1...10: return .gray
        case 11...25: return .green
        case 26...50: return .blue
        case 51...75: return .purple
        case 76...99: return .orange
        case 100...: return .red
        default: return .gray
        }
    }
}

// MARK: - 미리보기
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // 제목 스타일들
            VStack(spacing: 8) {
                Text("게임 타이틀")
                    .chosunStyle(.heroTitle)
                
                Text("페이지 제목")
                    .chosunStyle(.pageTitle)
                
                Text("섹션 제목")
                    .chosunStyle(.sectionTitle)
            }
            
            Divider()
            
            // 가격 스타일들
            Group {
                ChosunPriceText(price: 1500000, style: .large, showCurrency: true)
                ChosunPriceText(price: 250000, style: .normal, showCurrency: true)
                ChosunPriceText(price: 50000, style: .discount, showCurrency: true)
            }
            
            Divider()
            
            // 상태 표시들
            Group {
                ChosunTradeStatusText(status: .success, showIcon: true)
                ChosunTradeStatusText(status: .pending, showIcon: true)
                ChosunTradeStatusText(status: .failed, showIcon: true)
            }
            
            Divider()
            
            // 지역과 시간
            Group {
                ChosunDistrictText(district: .gangnam, showEmoji: true)
                ChosunTimeText(time: Date(), format: .relative)
                ChosunLevelText(level: 45, showPrefix: true)
            }
            
            Divider()
            
            // 애니메이션 텍스트
            Group {
                ChosunAnimatedText(
                    text: "페이드인 효과",
                    style: .pageTitle,
                    animationType: .fadeIn
                )
                
                ChosunAnimatedText(
                    text: "스케일 효과",
                    style: .sectionTitle,
                    animationType: .scale
                )
                
                ChosunAnimatedText(
                    text: "글로우 효과",
                    style: .merchantTitle,
                    animationType: .glow
                )
            }
        }
        .padding()
    }
}