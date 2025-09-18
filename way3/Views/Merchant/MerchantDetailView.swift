//
//  MerchantDetailView.swift
//  way3 - Way Trading Game
//
//  JRPG 스타일 상인 대화 시스템 및 거래 화면
//  ProfileInputView와 동일한 대화창 구조 사용
//

import SwiftUI

struct MerchantDetailView: View {
    let merchant: Merchant
    @Binding var isPresented: Bool
    @EnvironmentObject var gameManager: GameManager

    // 대화 상태
    @State private var currentMode: MerchantInteractionMode = .dialogue
    @State private var displayedText = ""
    @State private var isTypingComplete = false
    @State private var showNextArrow = false
    @State private var currentDialogueIndex = 0

    // 거래 상태
    @StateObject private var cartManager = CartManager()
    @State private var selectedTradeType: TradeType = .buy
    @State private var showQuantityPopup = false
    @State private var selectedItem: TradeItem?
    @State private var showCartDetail = false
    @State private var showPurchaseConfirmation = false

    // 상인 이미지 이름
    private var merchantImageName: String {
        return merchant.name.replacingOccurrences(of: " ", with: "")
    }

    var body: some View {
        ZStack {
            // 1. 검정보라색 울렁거리는 애니메이션 배경 (ProfileInputView와 동일)
            AnimatedPurpleBackground()

            // 2. 메인 레이아웃
            if currentMode == .dialogue {
                DialogueView
            } else if currentMode == .trading {
                TradingView
            } else if currentMode == .cart {
                CartDetailView
            }

            // 3. 팝업들
            if showQuantityPopup {
                QuantitySelectionPopup
            }

            if showPurchaseConfirmation {
                PurchaseConfirmationPopup
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startDialogue()
        }
    }
}

// MARK: - 상호작용 모드
enum MerchantInteractionMode {
    case dialogue    // 대화 모드
    case trading     // 거래 모드
    case cart        // 장바구니 상세
}

// MARK: - 대화 화면
extension MerchantDetailView {
    var DialogueView: some View {
        HStack(spacing: 0) {
            // 좌측: 상인 캐릭터
            VStack {
                Spacer()
                MerchantCharacterView
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width * 0.4)

            // 우측: 대화창 + 선택지
            VStack {
                Spacer()

                // 대화창
                DialogueBoxView

                // 선택지 (JRPG 스타일)
                if isTypingComplete {
                    DialogueChoicesView
                }

                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width * 0.6)
        }
    }

    var MerchantCharacterView: some View {
        VStack(spacing: 12) {
            // 상인 캐릭터 이미지
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                merchant.type.color.opacity(0.3),
                                merchant.type.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 180)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(merchant.type.color.opacity(0.6), lineWidth: 2)
                    )

                // 실제 상인 이미지 또는 fallback
                Group {
                    if let _ = UIImage(named: merchantImageName) {
                        Image(merchantImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    } else {
                        // fallback 캐릭터
                        VStack(spacing: 8) {
                            Image(systemName: merchant.type.iconName)
                                .font(.system(size: 50))
                                .foregroundColor(merchant.type.color)

                            Text(merchant.name)
                                .font(.chosunOrFallback(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
        }
    }

    var DialogueBoxView: some View {
        ZStack {
            // 대화창 배경
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(merchant.type.color.opacity(0.6), lineWidth: 2)
                )

            VStack(spacing: 16) {
                // 상인 이름과 대화 텍스트
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(merchant.name)
                            .font(.chosunOrFallback(size: 16, weight: .bold))
                            .foregroundColor(merchant.type.color)

                        Text(displayedText)
                            .font(.chosunOrFallback(size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }

                // 다음 화살표
                HStack {
                    Spacer()
                    if showNextArrow && !merchantDialogues.isEmpty {
                        Button(action: proceedToNextDialogue) {
                            HStack(spacing: 8) {
                                Text("다음")
                                    .font(.chosunOrFallback(size: 14))
                                    .foregroundColor(merchant.type.color)

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(merchant.type.color)
                            }
                        }
                        .opacity(isTypingComplete ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: isTypingComplete)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 200)
        .padding(.horizontal, 20)
    }

    var DialogueChoicesView: some View {
        VStack(spacing: 12) {
            DialogueChoiceButton(
                title: "대화하기",
                icon: "bubble.left.fill",
                action: { continueDialogue() }
            )

            DialogueChoiceButton(
                title: "거래하기",
                icon: "bag.fill",
                action: { startTrading() }
            )

            DialogueChoiceButton(
                title: "나가기",
                icon: "xmark.circle.fill",
                action: { exitMerchant() }
            )
        }
        .padding(.top, 16)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - 거래 화면
extension MerchantDetailView {
    var TradingView: some View {
        VStack(spacing: 0) {
            // 상인 헤더
            TradingHeaderView

            // 탭 선택 (구매/판매)
            TradeTabSelectionView

            // 아이템 그리드
            if selectedTradeType == .buy {
                MerchantInventoryGridView
            } else {
                PlayerInventoryGridView
            }

            // 장바구니 푸터
            if !cartManager.items.isEmpty {
                CartFooterView
            }
        }
        .background(Color.black.opacity(0.9))
    }

    var TradingHeaderView: some View {
        HStack {
            // 뒤로가기 버튼
            Button(action: { currentMode = .dialogue }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("대화로 돌아가기")
                }
                .font(.chosunOrFallback(size: 16))
                .foregroundColor(.cyan)
            }

            Spacer()

            // 상인 정보
            HStack {
                // 상인 이미지 (작게)
                Group {
                    if let _ = UIImage(named: merchantImageName) {
                        Image(merchantImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(merchant.type.color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: merchant.type.iconName)
                                    .foregroundColor(.white)
                            )
                    }
                }

                Text(merchant.name)
                    .font(.chosunOrFallback(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }

    var TradeTabSelectionView: some View {
        HStack {
            TradeTabButton(
                title: "구매",
                isSelected: selectedTradeType == .buy,
                action: { selectedTradeType = .buy }
            )

            TradeTabButton(
                title: "판매",
                isSelected: selectedTradeType == .sell,
                action: { selectedTradeType = .sell }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    var CartFooterView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("장바구니: \(cartManager.items.count)개")
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)

                Spacer()

                Text("총액: ₩\(cartManager.totalAmount)")
                    .font(.chosunOrFallback(size: 18, weight: .bold))
                    .foregroundColor(.cyan)
            }

            Button("장바구니 보기") {
                currentMode = .cart
            }
            .font(.chosunOrFallback(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.cyan)
            )
        }
        .padding()
        .background(Color.black.opacity(0.9))
    }
}

// MARK: - 헬퍼 컴포넌트들
struct DialogueChoiceButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.cyan)

                Text(title)
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct TradeTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.chosunOrFallback(size: 16))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .cyan : .white.opacity(0.7))

                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? .cyan : .clear)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 상인 헤더 (기존 코드 유지)
struct MerchantHeaderView: View {
    let merchant: Merchant
    
    var body: some View {
        VStack(spacing: 15) {
            // 상인 아바타
            ZStack {
                Circle()
                    .fill(merchant.pinColor)
                    .frame(width: 80, height: 80)
                    .shadow(radius: 10)
                
                Image(systemName: merchant.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(merchant.name)
                    .font(.custom("ChosunCentennial", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(merchant.type.displayName) 상인 • \(merchant.district.displayName)")
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 20) {
                    // 거리
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("\(Int(merchant.distance))m")
                            .font(.custom("ChosunCentennial", size: 14))
                    }
                    
                    // 평점
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("4.5")
                            .font(.custom("ChosunCentennial", size: 14))
                    }
                    
                    // 카테고리
                    Text(merchant.type.displayName)
                        .font(.custom("ChosunCentennial", size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(merchant.pinColor.opacity(0.2))
                        )
                        .foregroundColor(merchant.pinColor)
                }
            }
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
    }
}

// MARK: - 탭 선택
struct TabSelectionView: View {
    @Binding var selectedTab: Int
    
    private let tabs = ["구매", "판매", "정보"]
    
    var body: some View {
        HStack {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == index ? .blue : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
    }
}

// MARK: - 상인 인벤토리 (구매 탭)
struct MerchantInventoryView: View {
    let merchant: Merchant
    @ObservedObject var tradeManager: TradeManager
    let tradeType: TradeType
    
    private let sampleItems = [
        TradeItem(itemId: "1", name: "고급 쌀", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 2500, description: "고품질 쌀"),
        TradeItem(itemId: "2", name: "한우", category: "food", grade: .rare, requiredLicense: .intermediate, basePrice: 15000, description: "최고급 한우"),
        TradeItem(itemId: "3", name: "인삼", category: "food", grade: .intermediate, requiredLicense: .intermediate, basePrice: 8000, description: "6년근 인삼"),
        TradeItem(itemId: "4", name: "전통차", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 4500, description: "전통 한국차")
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(sampleItems) { item in
                    TradeItemCard(
                        item: item,
                        tradeType: tradeType,
                        isSelected: tradeManager.selectedItems.contains { $0.id == item.id },
                        onTap: {
                            tradeManager.toggleItem(item, type: tradeType)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 플레이어 인벤토리 (판매 탭)
struct PlayerInventoryView: View {
    let merchant: Merchant
    @ObservedObject var tradeManager: TradeManager
    let tradeType: TradeType
    
    private let sampleItems = [
        TradeItem(itemId: "p1", name: "사과", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 800, description: "신선한 사과"),
        TradeItem(itemId: "p2", name: "배", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 1200, description: "달콤한 배"),
        TradeItem(itemId: "p3", name: "고구마", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 600, description: "고구마")
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(sampleItems) { item in
                    TradeItemCard(
                        item: item,
                        tradeType: tradeType,
                        isSelected: tradeManager.selectedItems.contains { $0.id == item.id },
                        onTap: {
                            tradeManager.toggleItem(item, type: tradeType)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 상인 정보 탭
struct MerchantInfoView: View {
    let merchant: Merchant
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 영업 시간
                InfoSection(title: "영업 시간") {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text("오전 9시 - 오후 6시")
                            .font(.custom("ChosunCentennial", size: 16))
                    }
                }
                
                // 전문 분야
                InfoSection(title: "전문 분야") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        SpecialtyTag(text: "유기농 식품")
                        SpecialtyTag(text: "전통 발효식품")
                        SpecialtyTag(text: "지역 특산품")
                        SpecialtyTag(text: "건강식품")
                    }
                }
                
                // 상인 스토리
                InfoSection(title: "상인 이야기") {
                    Text("30년간 이 자리에서 신선한 식료품을 판매해온 김씨 상점입니다. 지역 농가와 직접 계약하여 신선하고 품질 좋은 식품만을 엄선하여 제공합니다.")
                        .font(.custom("ChosunCentennial", size: 16))
                        .lineSpacing(4)
                }
                
                // 거래 통계
                InfoSection(title: "거래 통계") {
                    VStack(spacing: 12) {
                        StatRow(label: "총 거래 횟수", value: "1,234회")
                        StatRow(label: "평균 거래 만족도", value: "4.5/5.0")
                        StatRow(label: "주요 고객층", value: "일반 가정")
                        StatRow(label: "추천 상품", value: "한우, 인삼")
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 정보 섹션
struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("ChosunCentennial", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - 전문분야 태그
struct SpecialtyTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.custom("ChosunCentennial", size: 14))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.1))
            )
            .foregroundColor(.blue)
    }
}

// MARK: - 통계 행
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("ChosunCentennial", size: 16))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.custom("ChosunCentennial", size: 16))
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 거래 아이템 카드
struct TradeItemCard: View {
    let item: TradeItem
    let tradeType: TradeType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 아이템 이미지
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.grade.color.opacity(0.2))
                        .frame(height: 80)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(item.grade.color)
                }
                
                VStack(spacing: 4) {
                    Text(item.name)
                        .font(.custom("ChosunCentennial", size: 16))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("₩\(item.currentPrice)")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    Text("재고: \(item.quantity)개")
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .strokeBorder(
                        isSelected ? Color.blue : Color.clear,
                        lineWidth: 2
                    )
                    .shadow(radius: isSelected ? 8 : 4)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 거래 푸터
struct TradeFooterView: View {
    @ObservedObject var tradeManager: TradeManager
    let onTradeButtonTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("선택된 아이템: \(tradeManager.selectedItems.count)개")
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("총액: ₩\(tradeManager.totalAmount)")
                    .font(.custom("ChosunCentennial", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Button(action: onTradeButtonTap) {
                Text("거래하기")
                    .font(.custom("ChosunCentennial", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.blue)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 10)
    }
}
