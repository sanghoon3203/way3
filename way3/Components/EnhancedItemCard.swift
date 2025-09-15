//
//  EnhancedItemCard.swift
//  way
//
//  Created by Claude on 9/9/25.
//

import SwiftUI

// MARK: - Card Size Enum
enum ItemCardSize {
    case featured    // 큰 카드 (그리드용)
    case compact     // 작은 카드 (리스트용)
    case detail      // 상세 카드 (팝업용)
    
    var imageSize: CGFloat {
        switch self {
        case .featured: return 80
        case .compact: return 50
        case .detail: return 100
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .featured: return 32
        case .compact: return 20
        case .detail: return 40
        }
    }
    
    var titleSize: CGFloat {
        switch self {
        case .featured: return 16
        case .compact: return 14
        case .detail: return 18
        }
    }
    
    var padding: CGFloat {
        switch self {
        case .featured: return 16
        case .compact: return 12
        case .detail: return 20
        }
    }
}

struct EnhancedItemCard: View {
    let item: TradeItem
    let size: ItemCardSize
    let mode: TradeMode
    let showQuickBuy: Bool
    let isEnabled: Bool
    let onQuickAction: () -> Void
    let onDetailTap: () -> Void
    
    @State private var isPressed = false
    
    // 아이템 등급별 그라디언트
    private func gradientForGrade(_ grade: ItemGrade) -> LinearGradient {
        let colors: [Color]
        switch grade {
        case .common:
            colors = [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
        case .intermediate:
            colors = [Color.blue.opacity(0.3), Color.blue.opacity(0.2)]
        case .advanced:
            colors = [Color.green.opacity(0.3), Color.green.opacity(0.2)]
        case .rare:
            colors = [Color.purple.opacity(0.3), Color.purple.opacity(0.2)]
        case .legendary:
            colors = [Color.orange.opacity(0.4), Color.yellow.opacity(0.3)]
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        Button(action: onDetailTap) {
            VStack(spacing: 12) {
                // Enhanced Item Image with Grade Indicator
                ZStack(alignment: .topTrailing) {
                    // 그림자 효과
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .frame(width: size.imageSize + 3, height: size.imageSize + 3)
                        .cornerRadius(12)
                        .offset(x: 2, y: 2)
                    
                    // 메인 이미지 배경
                    Rectangle()
                        .fill(gradientForGrade(item.grade))
                        .frame(width: size.imageSize, height: size.imageSize)
                        .cornerRadius(12)
                        .overlay(
                            // 아이템 아이콘
                            Text(itemIcon)
                                .font(.system(size: size.iconSize))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )
                    
                    // Grade badge
                    GradeBadge(grade: item.grade, size: size)
                        .offset(x: 6, y: -6)
                }
                
                // Item Information
                VStack(spacing: 6) {
                    Text(item.name)
                        .font(.custom("ChosunCentennial", size: size.titleSize))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // 카테고리 표시 (featured 사이즈일 때만)
                    if size == .featured {
                        Text(item.category)
                            .font(.custom("ChosunCentennial", size: 12))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    // Price with better formatting
                    PriceDisplay(price: item.displayPrice, size: size, mode: mode)
                }
                
                // Quick action button (if enabled)
                if showQuickBuy && isEnabled {
                    QuickActionButton(mode: mode, size: size, action: onQuickAction)
                }
            }
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    // 아이템별 아이콘 (카테고리 기반)
    private var itemIcon: String {
        switch item.category {
        case "금속공예": return "⚔️"
        case "보석": return "💎"
        case "직물": return "🧵"
        case "예술품": return "🎨"
        case "골동품": return "🏺"
        case "한약재": return "🌿"
        case "식품": return "🥘"
        case "공구류": return "⚙️"
        case "수입품": return "✈️"
        case "서적": return "📚"
        case "문구류": return "✏️"
        case "명품": return "👑"
        case "기념품": return "🎪"
        case "가죽제품": return "👞"
        case "전자제품": return "📱"
        case "천연제품": return "🌱"
        case "약초": return "🍄"
        case "생활용품": return "🏪"
        default: return "📦"
        }
    }
}

// MARK: - Grade Badge Component
struct GradeBadge: View {
    let grade: ItemGrade
    let size: ItemCardSize
    
    private var badgeSize: CGFloat {
        switch size {
        case .featured: return 20
        case .compact: return 16
        case .detail: return 24
        }
    }
    
    private var fontSize: CGFloat {
        switch size {
        case .featured: return 10
        case .compact: return 8
        case .detail: return 12
        }
    }
    
    var body: some View {
        Text(grade.shortDisplayName)
            .font(.custom("ChosunCentennial", size: fontSize))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: badgeSize, height: badgeSize)
            .background(
                Circle()
                    .fill(grade.color)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            )
    }
}

// MARK: - Price Display Component
struct PriceDisplay: View {
    let price: Int
    let size: ItemCardSize
    let mode: TradeMode
    
    private var fontSize: CGFloat {
        switch size {
        case .featured: return 16
        case .compact: return 14
        case .detail: return 18
        }
    }
    
    private var priceColor: Color {
        switch mode {
        case .buy: return .blue
        case .sell: return .green
        case .browse: return .black
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if mode == .buy {
                Image(systemName: "cart.fill")
                    .font(.system(size: fontSize - 2))
            } else if mode == .sell {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: fontSize - 2))
            }
            
            Text("\(price.formatted())원")
                .font(.custom("ChosunCentennial", size: fontSize))
                .fontWeight(.semibold)
        }
        .foregroundColor(priceColor)
    }
}

// MARK: - Quick Action Button Component
struct QuickActionButton: View {
    let mode: TradeMode
    let size: ItemCardSize
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var buttonText: String {
        switch mode {
        case .buy: return "구매"
        case .sell: return "판매"
        case .browse: return "보기"
        }
    }
    
    private var buttonHeight: CGFloat {
        switch size {
        case .featured: return 32
        case .compact: return 26
        case .detail: return 36
        }
    }
    
    private var fontSize: CGFloat {
        switch size {
        case .featured: return 12
        case .compact: return 10
        case .detail: return 14
        }
    }
    
    var body: some View {
        Button(action: {
            action()
            // 햅틱 피드백
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 4) {
                Image(systemName: mode.iconName)
                    .font(.system(size: fontSize - 2, weight: .semibold))
                
                Text(buttonText)
                    .font(.custom("ChosunCentennial", size: fontSize))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [mode.color.opacity(0.9), mode.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: mode.color.opacity(0.3), radius: 2, x: 0, y: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action
        }
    }
}

// ItemGrade extensions는 GameEnums.swift에 정의됨

// MARK: - Preview
#Preview {
    let sampleItem = TradeItem(
        itemId: "iron_sword",
        name: "정련된 철검",
        category: "금속공예",
        grade: .rare,
        requiredLicense: .intermediate,
        basePrice: 120000,
        currentPrice: 135000
    )
    
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            // Featured size
            EnhancedItemCard(
                item: sampleItem,
                size: .featured,
                mode: .buy,
                showQuickBuy: true,
                isEnabled: true,
                onQuickAction: { },
                onDetailTap: { }
            )
            
            // Compact size
            EnhancedItemCard(
                item: sampleItem,
                size: .compact,
                mode: .sell,
                showQuickBuy: true,
                isEnabled: true,
                onQuickAction: { },
                onDetailTap: { }
            )
        }
        
        // Detail size
        EnhancedItemCard(
            item: sampleItem,
            size: .detail,
            mode: .browse,
            showQuickBuy: false,
            isEnabled: true,
            onQuickAction: { },
            onDetailTap: { }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}