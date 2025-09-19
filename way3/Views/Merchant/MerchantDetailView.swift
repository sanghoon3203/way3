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
    @State var currentMode: MerchantInteractionMode = .dialogue
    @State var displayedText = ""
    @State var isTypingComplete = false
    @State var showNextArrow = false
    @State var currentDialogueIndex = 0

    // 거래 상태
    @StateObject var cartManager = CartManager()
    @State var selectedTradeType: TradeType = .buy
    @State var showQuantityPopup = false
    @State var selectedItem: TradeItem?
    @State var showCartDetail = false
    @State var showPurchaseConfirmation = false

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

// MARK: - JRPG 스타일 대화 화면
extension MerchantDetailView {
    var DialogueView: some View {
        VStack(spacing: 0) {
            // 상단: 상인 캐릭터 영역 (65%)
            JRPGCharacterArea
                .frame(height: JRPGScreenManager.characterAreaHeight)

            // 하단: 대화창 영역 (35%)
            ZStack(alignment: .topTrailing) {
                // 메인 대화창
                JRPGDialogueArea

                // 우상단 선택지 메뉴 (JRPG 전통 스타일)
                if isTypingComplete {
                    JRPGChoiceMenu
                        .offset(
                            x: JRPGScreenManager.JRPGLayout.choiceMenuOffset.x,
                            y: JRPGScreenManager.JRPGLayout.choiceMenuOffset.y
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.easeOut(duration: JRPGScreenManager.JRPGAnimations.choiceMenuAppearDuration), value: isTypingComplete)
                }
            }
            .frame(height: JRPGScreenManager.dialogueAreaHeight)
        }
        .background(JRPGScreenManager.JRPGColors.characterAreaBackground)
    }

    // MARK: - JRPG 캐릭터 영역
    var JRPGCharacterArea: some View {
        ZStack {
            // 배경 효과
            JRPGCharacterBackground

            // 상인 캐릭터 (중앙 배치)
            VStack {
                Spacer()

                JRPGMerchantCharacter
                    .scaleEffect(JRPGScreenManager.isCompactHeight ? 0.8 : 1.0)

                Spacer()

                // 상인 이름 표시
                Text(merchant.name)
                    .font(.jrpgTitle())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                Capsule()
                                    .stroke(Color.gold, lineWidth: 1.5)
                            )
                    )
                    .jrpgGlowPulse()

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - JRPG 캐릭터 배경 효과
    var JRPGCharacterBackground: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.purple.opacity(0.2),
                        Color.blue.opacity(0.1),
                        Color.black.opacity(0.3)
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 200
                )
            )
            .overlay(
                // 미묘한 파티클 효과 (향후 추가)
                Rectangle()
                    .fill(Color.clear)
            )
    }

    // MARK: - JRPG 상인 캐릭터
    var JRPGMerchantCharacter: some View {
        ZStack {
            // 캐릭터 배경 원
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.gold.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(JRPGScreenManager.isLargeScreen ? 1.2 : 1.0)

            // 동적 상인 이미지 (Asset 폴더 자동 매칭)
            MerchantImageView(
                merchantName: merchant.name,
                width: JRPGScreenManager.isLargeScreen ? 140 : 120,
                height: JRPGScreenManager.isLargeScreen ? 140 : 120
            )
            // 캐릭터 살랑살랑 애니메이션
            .offset(y: sin(Date().timeIntervalSince1970) * 3)
            .animation(
                Animation.easeInOut(duration: JRPGScreenManager.JRPGAnimations.characterBounceDuration)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )
        }
    }

    // MARK: - JRPG 대화창 영역
    var JRPGDialogueArea: some View {
        VStack(spacing: 0) {
            Spacer()

            // 메인 대화창 (하단 고정)
            JRPGDialogueBox
                .padding(.horizontal, JRPGScreenManager.JRPGLayout.screenPadding)
                .padding(.bottom, JRPGScreenManager.JRPGLayout.screenPadding)
        }
    }

    // MARK: - JRPG 스타일 대화창
    var JRPGDialogueBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 대화창 헤더 (상인 이름)
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gold)
                    .font(.system(size: 20))

                Text(merchant.name)
                    .font(.jrpgTitle())
                    .foregroundColor(.white)

                Spacer()

                // 대화 진행 상태 표시
                if !isTypingComplete {
                    HStack(spacing: 3) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.gold)
                                .frame(width: 4, height: 4)
                                .opacity(0.6)
                                .scaleEffect(typingDotAnimation(index: index))
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: UUID()
                                )
                        }
                    }
                }
            }
            .padding(.bottom, 8)

            // 대화 텍스트
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayedText)
                        .font(.jrpgDialogue())
                        .foregroundColor(JRPGScreenManager.JRPGColors.dialogueText)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
            .frame(height: 80)

            // 하단 액션 영역
            HStack {
                Spacer()

                // 다음 화살표 (타이핑 완료 시)
                if showNextArrow {
                    HStack(spacing: 4) {
                        Text("계속")
                            .font(.jrpgUI())
                            .foregroundColor(.gold)

                        Image(systemName: "arrowtriangle.right.fill")
                            .foregroundColor(.gold)
                            .font(.system(size: 12))
                            .offset(x: sin(Date().timeIntervalSince1970 * 3) * 2)
                            .animation(
                                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: UUID()
                            )
                    }
                    .onTapGesture {
                        continueDialogue()
                    }
                }
            }
        }
        .padding(JRPGScreenManager.JRPGLayout.dialoguePadding)
        .frame(height: JRPGScreenManager.JRPGLayout.dialogueBoxHeight)
        .jrpgDialogueBox()
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .animation(.easeOut(duration: JRPGScreenManager.JRPGAnimations.dialogueAppearDuration), value: displayedText)
    }

    // MARK: - 타이핑 도트 애니메이션
    func typingDotAnimation(index: Int) -> CGFloat {
        let time = Date().timeIntervalSince1970
        return 1.0 + sin(time * 2 + Double(index) * 0.5) * 0.3
    }

    // MARK: - JRPG 스타일 선택지 메뉴
    var JRPGChoiceMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 선택지 헤더
            HStack {
                Image(systemName: "list.bullet.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 16))

                Text("선택하세요")
                    .font(.jrpgChoice())
                    .foregroundColor(.white)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(Color.blue.opacity(0.8))
                    .overlay(
                        Rectangle()
                            .stroke(Color.cyan, lineWidth: 1)
                    )
            )

            // 선택지 리스트
            VStack(alignment: .leading, spacing: 2) {
                JRPGChoiceButton(
                    text: "💰 거래하기",
                    action: { startTrading() },
                    isSelected: false
                )

                JRPGChoiceButton(
                    text: "💬 대화하기",
                    action: { continueDialogue() },
                    isSelected: false
                )

                JRPGChoiceButton(
                    text: "🚪 떠나기",
                    action: { closeDialogue() },
                    isSelected: false
                )
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .frame(width: JRPGScreenManager.JRPGLayout.choiceMenuWidth)
        .jrpgChoiceMenu()
    }

    // MARK: - JRPG 선택지 버튼
    func JRPGChoiceButton(text: String, action: @escaping () -> Void, isSelected: Bool) -> some View {
        Button(action: action) {
            HStack {
                // 선택 표시 화살표
                Image(systemName: "arrowtriangle.right.fill")
                    .foregroundColor(.gold)
                    .font(.system(size: 10))
                    .opacity(isSelected ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)

                Text(text)
                    .font(.jrpgChoice())
                    .foregroundColor(isSelected ? .gold : .white)
                    .fontWeight(isSelected ? .bold : .medium)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.gold.opacity(0.2) : Color.clear)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isSelected ? Color.gold.opacity(0.8) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 선택지 액션들
    func startTrading() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentMode = .trading
        }
    }

    func continueDialogue() {
        // Extensions에서 정의된 기존 대화 시스템 사용
        proceedToNextDialogue()
    }

    // Extensions에 정의된 함수들과 연결하기 위한 래퍼
    func getDialogues() -> [String] {
        return merchantDialogues
    }

    func closeDialogue() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isPresented = false
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
