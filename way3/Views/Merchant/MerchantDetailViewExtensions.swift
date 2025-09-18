//
//  MerchantDetailViewExtensions.swift
//  way3 - Way Trading Game
//
//  MerchantDetailView 확장 - 로직 및 추가 컴포넌트
//

import SwiftUI

// MARK: - CartManager
class CartManager: ObservableObject {
    @Published var items: [CartItem] = []

    var totalAmount: Int {
        items.reduce(0) { $0 + ($1.item.currentPrice * $1.quantity) }
    }

    func addItem(_ item: TradeItem, quantity: Int) {
        if let existingIndex = items.firstIndex(where: { $0.item.id == item.id }) {
            items[existingIndex].quantity += quantity
        } else {
            items.append(CartItem(item: item, quantity: quantity))
        }
    }

    func removeItem(_ item: TradeItem) {
        items.removeAll { $0.item.id == item.id }
    }

    func updateQuantity(for item: TradeItem, quantity: Int) {
        if let index = items.firstIndex(where: { $0.item.id == item.id }) {
            if quantity > 0 {
                items[index].quantity = quantity
            } else {
                items.remove(at: index)
            }
        }
    }

    func clear() {
        items.removeAll()
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let item: TradeItem
    var quantity: Int
}

// MARK: - MerchantDetailView 로직 확장
extension MerchantDetailView {
    // 임시 상인 대화 데이터 (나중에 merchant 폴더별로 구성)
    public var merchantDialogues: [String] {
        [
            "안녕하세요! \(merchant.name)입니다. 오늘 좋은 거래를 하러 오셨나요?",
            "저희 상점은 \(merchant.district.displayName)에서 가장 오래된 곳이에요.",
            "신선하고 좋은 상품만 골라서 준비했습니다!",
            "혹시 특별히 찾으시는 물건이 있으신가요?"
        ]
    }

    // 구매 후 감사 대화
    public var thankYouMessages: [String] {
        [
            "좋은 거래였습니다! 감사합니다!",
            "또 언제든 오세요. 항상 환영입니다!",
            "좋은 상품 잘 선택하셨어요. 만족하실 거예요!",
            "다음에도 좋은 상품으로 기다리고 있겠습니다!"
        ]
    }

    // 대화 시작
    func startDialogue() {
        if !merchantDialogues.isEmpty {
            typeDialogue(merchantDialogues[0])
        }
    }

    // 타이핑 애니메이션
    private func typeDialogue(_ text: String) {
        displayedText = ""
        isTypingComplete = false
        showNextArrow = false

        let characters = Array(text)
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedText += String(characters[currentIndex])
                currentIndex += 1

                // 타이핑 효과 햅틱
                if currentIndex % 4 == 0 {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } else {
                timer.invalidate()
                isTypingComplete = true

                // 잠시 후 화살표 표시
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showNextArrow = true
                    }
                }
            }
        }
    }

    // 다음 대화로 진행
    func proceedToNextDialogue() {
        currentDialogueIndex += 1
        if currentDialogueIndex < merchantDialogues.count {
            typeDialogue(merchantDialogues[currentDialogueIndex])
        } else {
            // 대화 끝 - 선택지만 표시
            showNextArrow = false
        }
    }

    // 대화 계속하기
    func continueDialogue() {
        if currentDialogueIndex >= merchantDialogues.count - 1 {
            // 처음부터 다시 시작
            currentDialogueIndex = 0
            typeDialogue(merchantDialogues[0])
        } else {
            proceedToNextDialogue()
        }
    }

    // 거래 시작
    func startTrading() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentMode = .trading
        }
    }

    // 나가기
    func exitMerchant() {
        isPresented = false
    }

    // 아이템 선택 시 수량 팝업 표시
    func selectItem(_ item: TradeItem) {
        selectedItem = item
        showQuantityPopup = true
    }

    // 구매 완료 후 감사 대화
    func showThankYouDialogue() {
        currentMode = .dialogue
        let randomMessage = thankYouMessages.randomElement() ?? "감사합니다!"
        typeDialogue(randomMessage)
    }
}

// MARK: - 아이템 그리드 뷰들
extension MerchantDetailView {
    var MerchantInventoryGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(sampleMerchantItems) { item in
                    SimpleTradeItemCard(item: item) {
                        selectItem(item)
                    }
                }
            }
            .padding()
        }
    }

    var PlayerInventoryGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(samplePlayerItems) { item in
                    SimpleTradeItemCard(item: item) {
                        selectItem(item)
                    }
                }
            }
            .padding()
        }
    }

    // 임시 상인 아이템들
    private var sampleMerchantItems: [TradeItem] {
        [
            TradeItem(itemId: "m1", name: "고급 쌀", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 2500, description: "고품질 쌀"),
            TradeItem(itemId: "m2", name: "한우", category: "food", grade: .rare, requiredLicense: .intermediate, basePrice: 15000, description: "최고급 한우"),
            TradeItem(itemId: "m3", name: "인삼", category: "food", grade: .intermediate, requiredLicense: .intermediate, basePrice: 8000, description: "6년근 인삼"),
            TradeItem(itemId: "m4", name: "전통차", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 4500, description: "전통 한국차")
        ]
    }

    // 임시 플레이어 아이템들
    private var samplePlayerItems: [TradeItem] {
        [
            TradeItem(itemId: "p1", name: "사과", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 800, description: "신선한 사과"),
            TradeItem(itemId: "p2", name: "배", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 1200, description: "달콤한 배"),
            TradeItem(itemId: "p3", name: "고구마", category: "food", grade: .common, requiredLicense: .beginner, basePrice: 600, description: "고구마")
        ]
    }

    // 장바구니 상세 화면
    var CartDetailView: some View {
        VStack(spacing: 0) {
            // 헤더
            CartHeaderView

            // 장바구니 아이템들
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cartManager.items) { cartItem in
                        CartItemRow(cartItem: cartItem, cartManager: cartManager)
                    }
                }
                .padding()
            }

            // 구매 버튼
            VStack(spacing: 16) {
                HStack {
                    Text("총액")
                        .font(.chosunOrFallback(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Text("₩\(cartManager.totalAmount)")
                        .font(.chosunOrFallback(size: 20, weight: .bold))
                        .foregroundColor(.cyan)
                }

                Button("구매하기") {
                    showPurchaseConfirmation = true
                }
                .font(.chosunOrFallback(size: 18, weight: .semibold))
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
        .background(Color.black.opacity(0.95))
    }

    var CartHeaderView: some View {
        HStack {
            Button(action: { currentMode = .trading }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("거래로 돌아가기")
                }
                .font(.chosunOrFallback(size: 16))
                .foregroundColor(.cyan)
            }

            Spacer()

            Text("장바구니")
                .font(.chosunOrFallback(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // 투명한 버튼 (대칭을 위해)
            HStack {
                Image(systemName: "arrow.left")
                Text("거래로 돌아가기")
            }
            .font(.chosunOrFallback(size: 16))
            .foregroundColor(.clear)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - 팝업들
extension MerchantDetailView {
    var QuantitySelectionPopup: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    showQuantityPopup = false
                }

            if let item = selectedItem {
                QuantityPopupContent(item: item)
            }
        }
    }

    var PurchaseConfirmationPopup: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("구매 확인")
                    .font(.chosunOrFallback(size: 20, weight: .bold))
                    .foregroundColor(.cyan)

                Text("정말 구매하시겠습니까?")
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)

                Text("총액: ₩\(cartManager.totalAmount)")
                    .font(.chosunOrFallback(size: 18, weight: .bold))
                    .foregroundColor(.cyan)

                HStack(spacing: 20) {
                    Button("취소") {
                        showPurchaseConfirmation = false
                    }
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )

                    Button("구매 확인") {
                        completePurchase()
                    }
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cyan)
                    )
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 40)
        }
    }

    func QuantityPopupContent(item: TradeItem) -> some View {
        QuantityPopupContentView(item: item, cartManager: cartManager, showQuantityPopup: $showQuantityPopup)
    }
}

struct QuantityPopupContentView: View {
    let item: TradeItem
    let cartManager: CartManager
    @Binding var showQuantityPopup: Bool
    @State private var quantity = 1

    var body: some View {
        VStack(spacing: 20) {
            Text("수량 선택")
                .font(.chosunOrFallback(size: 18, weight: .bold))
                .foregroundColor(.cyan)

            VStack(spacing: 12) {
                Text(item.name)
                    .font(.chosunOrFallback(size: 16))
                    .foregroundColor(.white)

                Text("₩\(item.currentPrice) 각")
                    .font(.chosunOrFallback(size: 14))
                    .foregroundColor(.cyan)
            }

            HStack {
                Button("-") {
                    if quantity > 1 { quantity -= 1 }
                }
                .font(.title2)
                .foregroundColor(.cyan)
                .frame(width: 40, height: 40)
                .background(Circle().stroke(Color.cyan, lineWidth: 1))

                Text("\(quantity)")
                    .font(.chosunOrFallback(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60)

                Button("+") {
                    if quantity < 99 { quantity += 1 }
                }
                .font(.title2)
                .foregroundColor(.cyan)
                .frame(width: 40, height: 40)
                .background(Circle().stroke(Color.cyan, lineWidth: 1))
            }

            Text("총액: ₩\(item.currentPrice * quantity)")
                .font(.chosunOrFallback(size: 16, weight: .bold))
                .foregroundColor(.cyan)

            HStack(spacing: 20) {
                Button("아니요") {
                    showQuantityPopup = false
                }
                .font(.chosunOrFallback(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )

                Button("예") {
                    cartManager.addItem(item, quantity: quantity)
                    showQuantityPopup = false
                }
                .font(.chosunOrFallback(size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyan)
                )
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                )
        )
        .padding(.horizontal, 40)
    }
}

extension MerchantDetailView {
    // 구매 완료 처리
    func completePurchase() {
        // 실제 플레이어 머니 차감
        if let player = gameManager.currentPlayer {
            let totalCost = cartManager.totalAmount
            if player.money >= totalCost {
                player.money -= totalCost

                // 구매한 아이템들을 플레이어 인벤토리에 추가
                for cartItem in cartManager.items {
                    // TODO: 실제 인벤토리 시스템에 추가
                    print("구매 완료: \(cartItem.item.name) x\(cartItem.quantity)")
                }

                // 장바구니 비우기
                cartManager.clear()

                // 팝업 닫기
                showPurchaseConfirmation = false

                // 감사 대화 표시
                showThankYouDialogue()
            } else {
                // 돈이 부족한 경우
                // TODO: 에러 처리
                print("돈이 부족합니다")
            }
        }
    }
}

// MARK: - 헬퍼 컴포넌트들
struct SimpleTradeItemCard: View {
    let item: TradeItem
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
                        .font(.chosunOrFallback(size: 16))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.white)

                    Text("₩\(item.currentPrice)")
                        .font(.chosunOrFallback(size: 14))
                        .foregroundColor(.cyan)
                        .fontWeight(.medium)

                    Text("재고: \(item.quantity)개")
                        .font(.chosunOrFallback(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct CartItemRow: View {
    let cartItem: CartItem
    @ObservedObject var cartManager: CartManager

    var body: some View {
        HStack(spacing: 12) {
            // 아이템 이미지
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cartItem.item.grade.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: cartItem.item.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(cartItem.item.grade.color)
            }

            // 아이템 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(cartItem.item.name)
                    .font(.chosunOrFallback(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text("₩\(cartItem.item.currentPrice) x \(cartItem.quantity)개")
                    .font(.chosunOrFallback(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // 총 가격
            Text("₩\(cartItem.item.currentPrice * cartItem.quantity)")
                .font(.chosunOrFallback(size: 16, weight: .bold))
                .foregroundColor(.cyan)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }

    // 장바구니 헤더
    var CartHeaderView: some View {
        HStack {
            Button(action: {
                currentMode = .trading
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("거래로 돌아가기")
                }
                .font(.chosunOrFallback(size: 16))
                .foregroundColor(.white)
            }

            Spacer()

            Text("장바구니")
                .font(.chosunOrFallback(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Text("총 \(cartManager.items.count)개")
                .font(.chosunOrFallback(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.purple.opacity(0.3))
    }
}

