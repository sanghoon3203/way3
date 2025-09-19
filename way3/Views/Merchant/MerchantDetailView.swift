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
    
    // Extensions에서 사용할 수 있도록 computed properties 추가
    var merchantInventoryGridView: some View {
        MerchantInventoryGridView
    }
    
    var playerInventoryGridView: some View {
        PlayerInventoryGridView
    }
    
    var cartDetailView: some View {
        CartDetailView
    }
    
    var quantitySelectionPopup: some View {
        QuantitySelectionPopup
    }
    
    var purchaseConfirmationPopup: some View {
        PurchaseConfirmationPopup
    }
    
    var body: some View {
        ZStack {
            // 1. 사이버펑크 다크 배경
            Color.cyberpunkDarkBg
                .ignoresSafeArea()
            
            // 2. 메인 레이아웃
            if currentMode == .dialogue {
                DialogueView
            } else if currentMode == .trading {
                tradingView
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
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
            // 상단: 상인 캐릭터 영역 (65%) - JRPG 레이아웃 유지
            CyberpunkCharacterArea
                .frame(height: JRPGScreenManager.characterAreaHeight)
                .layoutPriority(1)

            // 하단: 대화창 영역 (35%) - JRPG 레이아웃 유지
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {
                    // 메인 대화창 - JRPG 구조 유지, 사이버펑크 스타일 적용
                    CyberpunkJRPGDialogueArea

                    // 우상단 선택지 메뉴 - JRPG 위치 유지, 사이버펑크 스타일 적용
                    if isTypingComplete {
                        CyberpunkJRPGChoiceMenu
                            .offset(
                                x: min(JRPGScreenManager.JRPGLayout.choiceMenuOffset.x, -20),
                                y: max(JRPGScreenManager.JRPGLayout.choiceMenuOffset.y, 20)
                            )
                            .position(
                                x: geometry.size.width - (JRPGScreenManager.JRPGLayout.choiceMenuWidth / 2) - 20,
                                y: geometry.size.height * 0.3
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                            .animation(.easeOut(duration: JRPGScreenManager.JRPGAnimations.choiceMenuAppearDuration), value: isTypingComplete)
                    }
                }
            }
            .frame(height: JRPGScreenManager.dialogueAreaHeight)
            .layoutPriority(2)
        }
        .background(Color.cyberpunkDarkBg) // 배경만 사이버펑크로
    }

    // MARK: - 사이버펑크 스타일 캐릭터 영역 (JRPG 구조 유지)
    var CyberpunkCharacterArea: some View {
        ZStack {
            // 사이버펑크 배경 효과
            CyberpunkCharacterBackground

            // 상인 캐릭터 (중앙 배치) - JRPG 위치 유지
            VStack {
                Spacer()

                CyberpunkMerchantCharacter
                    .scaleEffect(JRPGScreenManager.isCompactHeight ? 0.8 : 1.0)

                Spacer()

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - 사이버펑크 캐릭터 배경 효과
    var CyberpunkCharacterBackground: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.cyberpunkYellow.opacity(0.1),
                        Color.cyberpunkCyan.opacity(0.05),
                        Color.cyberpunkDarkBg.opacity(0.8)
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 200
                )
            )
            .overlay(
                // 사이버펑크 스타일 스캔라인 효과
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.cyberpunkCyan.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(0.3)
            )
    }

    // MARK: - 사이버펑크 스타일 상인 캐릭터 (JRPG 애니메이션 유지)
    var CyberpunkMerchantCharacter: some View {
        ZStack {
            // 사이버펑크 캐릭터 홀로그램 배경
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyberpunkCyan.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 4)) // 각진 사이버펑크 스타일
                .scaleEffect(JRPGScreenManager.isLargeScreen ? 1.2 : 1.0)
                .overlay(
                    // 홀로그램 효과 테두리
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.cyberpunkCyan.opacity(0.6), lineWidth: 1)
                )

            // 동적 상인 이미지 (Asset 폴더 자동 매칭) - 기존 시스템 유지
            MerchantImageView(
                merchantName: merchant.name,
                width: JRPGScreenManager.isLargeScreen ? 140 : 120,
                height: JRPGScreenManager.isLargeScreen ? 140 : 120
            )
            // 캐릭터 살랑살랑 애니메이션 유지
            .offset(y: sin(Date().timeIntervalSince1970) * 3)
            .animation(
                Animation.easeInOut(duration: JRPGScreenManager.JRPGAnimations.characterBounceDuration)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )
            .overlay(
                // 홀로그램 글리치 효과
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.cyberpunkYellow.opacity(0.3), lineWidth: 0.5)
                    .opacity(sin(Date().timeIntervalSince1970 * 8) * 0.5 + 0.5)
            )
        }
    }

    // MARK: - 사이버펑크 JRPG 대화창 영역 (구조 유지)
    var CyberpunkJRPGDialogueArea: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                // 메인 대화창 (하단 고정) - JRPG 위치 유지
                CyberpunkJRPGDialogueBox
                    .padding(.horizontal, min(JRPGScreenManager.JRPGLayout.screenPadding, geometry.size.width * 0.05))
                    .padding(.bottom, JRPGScreenManager.JRPGLayout.screenPadding)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 사이버펑크 JRPG 대화창 (기존 기능 완전 유지)
    var CyberpunkJRPGDialogueBox: some View {
        VStack(alignment: .center, spacing: 12) {
            // 대화창 헤더 (상인 이름) - 사이버펑크 스타일
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.cyberpunkCyan)
                    .font(.system(size: 16))

                Text("COMM_LINK")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Rectangle()
                    .fill(Color.cyberpunkYellow)
                    .frame(width: 20, height: 1)

                Text(merchant.name.uppercased())
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkYellow)

                Spacer()

                // 대화 진행 상태 표시 - 사이버펑크 스타일
                if !isTypingComplete {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { index in
                            Rectangle()
                                .fill(Color.cyberpunkCyan)
                                .frame(width: 3, height: 3)
                                .opacity(0.6)
                                .scaleEffect(typingDotAnimation(index: index))
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: UUID()
                                )
                        }

                        Text("PROCESSING")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkCyan)
                    }
                }
            }
            .padding(.bottom, 8)

            // 대화 텍스트 - 기존 스크롤뷰 유지
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayedText)
                        .font(.cyberpunkBody()) // 사이버펑크 폰트로 변경
                        .foregroundColor(.cyberpunkTextPrimary) // 사이버펑크 텍스트 색상
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }

            // 하단 액션 영역 - 기존 기능 유지, 스타일만 변경
            HStack {
                Spacer()

                // 다음 화살표 (타이핑 완료 시)
                if showNextArrow {
                    HStack(spacing: 4) {
                        Text("CONTINUE")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkYellow)

                        Text(">")
                            .font(.cyberpunkCaption())
                            .foregroundColor(.cyberpunkYellow)
                            .offset(x: sin(Date().timeIntervalSince1970 * 3) * 2)
                            .animation(
                                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: UUID()
                            )
                    }
                    .onTapGesture {
                        continueDialogue() // 기존 함수 유지
                    }
                }
            }
        }
        .padding(JRPGScreenManager.JRPGLayout.dialoguePadding) // 기존 패딩 유지
        .frame(height: JRPGScreenManager.JRPGLayout.dialogueBoxHeight) // 기존 높이 유지
        .background(Color.cyberpunkCardBg) // 사이버펑크 배경
        .overlay(
            Rectangle()
                .stroke(Color.cyberpunkBorder, lineWidth: CyberpunkLayout.borderWidth)
        )
        .clipShape(Rectangle()) // 각진 사이버펑크 스타일
        .transition(.asymmetric( // 기존 애니메이션 유지
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

    // MARK: - 사이버펑크 JRPG 선택지 메뉴 (기존 구조 유지)
    var CyberpunkJRPGChoiceMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 선택지 헤더 - 사이버펑크 스타일
            HStack {
                Image(systemName: "command.circle.fill")
                    .foregroundColor(.cyberpunkYellow)
                    .font(.system(size: 14))

                Text("ACTION_MENU")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextPrimary)
                    .fontWeight(.semibold)

                Spacer()

                Text("[SELECT]")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkCyan)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.cyberpunkDarkBg)
            .overlay(
                Rectangle()
                    .fill(Color.cyberpunkYellow)
                    .frame(height: 1),
                alignment: .bottom
            )

            // 선택지 리스트 - 기존 액션 유지, 스타일만 변경
            VStack(alignment: .leading, spacing: 1) {
                CyberpunkJRPGChoiceButton(
                    text: "TRADE",
                    icon: "$",
                    action: { startTrading() }, // 기존 함수 유지
                    isSelected: false
                )

                CyberpunkJRPGChoiceButton(
                    text: "DIALOGUE",
                    icon: ">>",
                    action: { continueDialogue() }, // 기존 함수 유지
                    isSelected: false
                )

                CyberpunkJRPGChoiceButton(
                    text: "EXIT",
                    icon: "X",
                    action: { closeDialogue() }, // 기존 함수 유지
                    isSelected: false
                )
            }
            .padding(4)
        }
        .frame(width: JRPGScreenManager.JRPGLayout.choiceMenuWidth) // 기존 너비 유지
        .background(Color.cyberpunkPanelBg)
        .overlay(
            Rectangle()
                .stroke(Color.cyberpunkBorder, lineWidth: CyberpunkLayout.borderWidth)
        )
        .clipShape(Rectangle())
    }

    // MARK: - 사이버펑크 JRPG 선택지 버튼 (기존 기능 유지)
    func CyberpunkJRPGChoiceButton(text: String, icon: String, action: @escaping () -> Void, isSelected: Bool) -> some View {
        Button(action: action) {
            HStack {
                // 선택 표시 화살표 - 사이버펑크 스타일
                Text(">")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkYellow)
                    .opacity(isSelected ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)

                Text(icon)
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkCyan)
                    .frame(width: 16)

                Text(text)
                    .font(.cyberpunkBody())
                    .foregroundColor(isSelected ? .cyberpunkYellow : .cyberpunkTextPrimary)
                    .fontWeight(isSelected ? .semibold : .medium)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.cyberpunkYellow.opacity(0.1) : Color.clear)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isSelected ? Color.cyberpunkYellow.opacity(0.6) : Color.clear,
                                lineWidth: 0.5
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




// MARK: - 거래 화면
extension MerchantDetailView {
    var tradingView: some View {
        VStack(spacing: 0) {
            // 상인 헤더
            tradingHeaderView

            // 탭 선택 (구매/판매)
            tradeTabSelectionView

            // 아이템 그리드
            if selectedTradeType == .buy {
                merchantInventoryGridView
            } else {
                playerInventoryGridView
            }

            // 장바구니 푸터
            if !cartManager.items.isEmpty {
                cartFooterView
            }
        }
        .background(Color.black.opacity(0.9))
    }

    var tradingHeaderView: some View {
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
                            .fill(self.merchant.type.color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: self.merchant.type.iconName)
                                    .foregroundColor(.white)
                            )
                    }
                }

                Text(self.merchant.name)
                    .font(.chosunOrFallback(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }

    var tradeTabSelectionView: some View {
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

    var cartFooterView: some View {
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
