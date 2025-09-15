//
//  EnhancedTradeConfirmationPopup.swift
//  way
//
//  Created by Claude on 9/9/25.
//

import SwiftUI
import CoreLocation

struct EnhancedTradeConfirmationPopup: View {
    let item: TradeItem
    let mode: TradeMode
    let merchant: Merchant
    let onConfirm: (TradeItem, Int) -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var gameManager: GameManager
    @State private var quantity: Int = 1
    @State private var currentStep: ConfirmationStep = .itemPreview
    
    // 최대 수량 계산
    private var maxQuantity: Int {
        switch mode {
        case .buy, .browse:
            // 구매 시: 플레이어의 돈으로 살 수 있는 최대 수량
            return min(10, gameManager.player.money / item.currentPrice)
        case .sell:
            // 판매 시: 플레이어가 가진 아이템 수량
            return gameManager.player.inventory.first(where: { $0.id == item.id })?.quantity ?? 1
        }
    }
    
    // 총 가격 계산
    private var totalPrice: Int {
        return item.currentPrice * quantity
    }
    
    var body: some View {
        ZStack {
            // 배경 딤
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // 메인 팝업
            VStack(spacing: 0) {
                // 진행 표시기
                ProgressIndicator(current: currentStep)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                // 스텝별 컨텐츠
                Group {
                    switch currentStep {
                    case .itemPreview:
                        ItemPreviewStep(
                            item: item,
                            mode: mode,
                            merchant: merchant
                        )
                    case .quantitySelection:
                        QuantitySelectionStep(
                            item: item,
                            mode: mode,
                            quantity: $quantity,
                            maxQuantity: maxQuantity,
                            totalPrice: totalPrice
                        )
                    case .finalConfirmation:
                        FinalConfirmationStep(
                            item: item,
                            mode: mode,
                            merchant: merchant,
                            quantity: quantity,
                            totalPrice: totalPrice,
                            playerMoney: gameManager.player.money
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                
                // 네비게이션 버튼
                NavigationButtons(
                    currentStep: currentStep,
                    canProceed: canProceedToNext,
                    onNext: moveToNextStep,
                    onPrevious: moveToPreviousStep,
                    onConfirm: {
                        onConfirm(item, quantity)
                    },
                    onCancel: onCancel
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(width: 360, height: 520)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
        .onAppear {
            quantity = 1
            currentStep = .itemPreview
        }
    }
    
    // MARK: - Navigation Logic
    private var canProceedToNext: Bool {
        switch currentStep {
        case .itemPreview:
            return true
        case .quantitySelection:
            return quantity > 0 && quantity <= maxQuantity
        case .finalConfirmation:
            if mode == .buy {
                return gameManager.player.money >= totalPrice
            } else {
                return true
            }
        }
    }
    
    private func moveToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .itemPreview:
                currentStep = .quantitySelection
            case .quantitySelection:
                currentStep = .finalConfirmation
            case .finalConfirmation:
                break
            }
        }
    }
    
    private func moveToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .itemPreview:
                break
            case .quantitySelection:
                currentStep = .itemPreview
            case .finalConfirmation:
                currentStep = .quantitySelection
            }
        }
    }
}

// MARK: - Confirmation Steps Enum
enum ConfirmationStep: CaseIterable {
    case itemPreview
    case quantitySelection
    case finalConfirmation
    
    var title: String {
        switch self {
        case .itemPreview: return "아이템 확인"
        case .quantitySelection: return "수량 선택"
        case .finalConfirmation: return "거래 확인"
        }
    }
}

// MARK: - Progress Indicator
struct ProgressIndicator: View {
    let current: ConfirmationStep
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(ConfirmationStep.allCases.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 8) {
                    // 원형 인디케이터
                    ZStack {
                        Circle()
                            .fill(stepColor(for: step))
                            .frame(width: 32, height: 32)
                        
                        if step.rawValue < current.rawValue || step == current {
                            Image(systemName: step == current ? "circle.fill" : "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.custom("ChosunCentennial", size: 12))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 제목
                    Text(step.title)
                        .font(.custom("ChosunCentennial", size: 11))
                        .foregroundColor(stepColor(for: step))
                        .fontWeight(.semibold)
                }
                
                // 연결선 (마지막 제외)
                if step != ConfirmationStep.allCases.last {
                    Rectangle()
                        .fill(stepColor(for: step).opacity(0.3))
                        .frame(width: 30, height: 2)
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func stepColor(for step: ConfirmationStep) -> Color {
        if step.rawValue < current.rawValue {
            return .green
        } else if step == current {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Item Preview Step
struct ItemPreviewStep: View {
    let item: TradeItem
    let mode: TradeMode
    let merchant: Merchant
    
    var body: some View {
        VStack(spacing: 20) {
            // 아이템 카드 (큰 사이즈)
            EnhancedItemCard(
                item: item,
                size: .detail,
                mode: mode,
                showQuickBuy: false,
                isEnabled: true,
                onQuickAction: { },
                onDetailTap: { }
            )
            
            // 아이템 상세 정보
            VStack(alignment: .leading, spacing: 12) {
                Text("아이템 정보")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.bold)
                
                InfoRow(label: "카테고리", value: item.category)
                InfoRow(label: "등급", value: item.grade.displayName)
                InfoRow(label: "필요 라이센스", value: item.requiredLicense.displayName)
                
                if mode == .buy {
                    InfoRow(label: "거래 상인", value: merchant.name)
                    InfoRow(label: "상인 유형", value: merchant.type.displayName)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.05))
            )
        }
    }
}

// MARK: - Quantity Selection Step
struct QuantitySelectionStep: View {
    let item: TradeItem
    let mode: TradeMode
    @Binding var quantity: Int
    let maxQuantity: Int
    let totalPrice: Int
    
    var body: some View {
        VStack(spacing: 24) {
            // 아이템 요약
            HStack {
                Text(item.itemIcon)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.custom("ChosunCentennial", size: 18))
                        .fontWeight(.semibold)
                    
                    Text("\(item.currentPrice.formatted())원")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            
            // 수량 선택
            VStack(spacing: 16) {
                Text("수량 선택")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.bold)
                
                HStack(spacing: 20) {
                    // 감소 버튼
                    Button(action: {
                        if quantity > 1 {
                            quantity -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(quantity > 1 ? .blue : .gray)
                    }
                    .disabled(quantity <= 1)
                    
                    // 수량 표시
                    Text("\(quantity)")
                        .font(.custom("ChosunCentennial", size: 28))
                        .fontWeight(.bold)
                        .frame(width: 60)
                    
                    // 증가 버튼
                    Button(action: {
                        if quantity < maxQuantity {
                            quantity += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(quantity < maxQuantity ? .blue : .gray)
                    }
                    .disabled(quantity >= maxQuantity)
                }
                
                Text("최대 \(maxQuantity)개")
                    .font(.custom("ChosunCentennial", size: 12))
                    .foregroundColor(.gray)
            }
            
            // 총 가격
            VStack(spacing: 8) {
                Text("총 가격")
                    .font(.custom("ChosunCentennial", size: 14))
                    .foregroundColor(.gray)
                
                Text("\(totalPrice.formatted())원")
                    .font(.custom("ChosunCentennial", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
            )
        }
    }
}

// MARK: - Final Confirmation Step
struct FinalConfirmationStep: View {
    let item: TradeItem
    let mode: TradeMode
    let merchant: Merchant
    let quantity: Int
    let totalPrice: Int
    let playerMoney: Int
    
    private var actionText: String {
        switch mode {
        case .buy: return "구매"
        case .sell: return "판매"
        case .browse: return "확인"
        }
    }
    
    private var canAfford: Bool {
        if mode == .buy {
            return playerMoney >= totalPrice
        }
        return true
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 거래 요약
            VStack(spacing: 16) {
                Text("\(actionText) 확인")
                    .font(.custom("ChosunCentennial", size: 20))
                    .fontWeight(.bold)
                
                // 아이템 정보
                HStack {
                    Text(item.itemIcon)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(.semibold)
                        
                        Text("\(quantity)개 × \(item.currentPrice.formatted())원")
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("총액")
                            .font(.custom("ChosunCentennial", size: 12))
                            .foregroundColor(.gray)
                        
                        Text("\(totalPrice.formatted())원")
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            
            // 잔액 정보 (구매 시만)
            if mode == .buy {
                HStack {
                    VStack(alignment: .leading) {
                        Text("현재 잔액")
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.gray)
                        
                        Text("\(playerMoney.formatted())원")
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(actionText) 후 잔액")
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.gray)
                        
                        Text("\((playerMoney - totalPrice).formatted())원")
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(canAfford ? .green : .red)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((canAfford ? Color.green : Color.red).opacity(0.1))
                )
                
                if !canAfford {
                    Text("잔액이 부족합니다")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    let currentStep: ConfirmationStep
    let canProceed: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 이전/취소 버튼
            Button(action: currentStep == .itemPreview ? onCancel : onPrevious) {
                Text(currentStep == .itemPreview ? "취소" : "이전")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                    )
            }
            
            // 다음/확인 버튼
            Button(action: currentStep == .finalConfirmation ? onConfirm : onNext) {
                Text(currentStep == .finalConfirmation ? "확인" : "다음")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canProceed ? Color.blue : Color.gray)
                    )
            }
            .disabled(!canProceed)
        }
    }
}

// MARK: - Helper Components
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("ChosunCentennial", size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.custom("ChosunCentennial", size: 14))
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Extensions
extension ConfirmationStep: Comparable {
    static func < (lhs: ConfirmationStep, rhs: ConfirmationStep) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension ConfirmationStep {
    var rawValue: Int {
        switch self {
        case .itemPreview: return 0
        case .quantitySelection: return 1
        case .finalConfirmation: return 2
        }
    }
}

extension TradeItem {
    var itemIcon: String {
        switch category {
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
    
    let sampleMerchant = Merchant(
        name: "테크마켓 사장",
        title: "첨단기술 상인",
        type: .tech,
        personality: .analytical,
        district: .gangnam,
        coordinate: CLLocationCoordinate2D(latitude: 37.4989, longitude: 127.0356),
        requiredLicense: .intermediate,
        inventory: [],
        priceModifier: 1.2,
        negotiationDifficulty: 4,
        preferredItems: ["전자제품"],
        dislikedItems: ["의류"]
    )
    
    EnhancedTradeConfirmationPopup(
        item: sampleItem,
        mode: .buy,
        merchant: sampleMerchant,
        onConfirm: { _, _ in },
        onCancel: { }
    )
}
