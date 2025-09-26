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

    func addItem(_ item: TradeItem, quantity: Int, type: TradeType = .buy) {
        if let existingIndex = items.firstIndex(where: { $0.item.id == item.id && $0.type == type }) {
            items[existingIndex].quantity += quantity
        } else {
            items.append(CartItem(item: item, quantity: quantity, type: type))
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

    func clearCart() {
        items.removeAll()
    }

    // TradeManager 호환성을 위한 메서드
    func clear() {
        clearCart()
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let item: TradeItem
    var quantity: Int
    var type: TradeType = .buy  // 구매/판매 타입 추가
}

// MARK: - MerchantDetailView 로직 확장
extension MerchantDetailView {
    func startDialogue() {
        viewModel.startDialogue()
    }

    func continueDialogue() {
        viewModel.continueDialogue()
    }

    func exitMerchant() {
        isPresented = false
    }

    func selectItem(_ item: TradeItem) {
        selectedItem = item
        showQuantityPopup = true
    }

    func showThankYouDialogue() {
        currentMode = .dialogue
        viewModel.showThankYouDialogue()
    }
}

// MARK: - 아이템 그리드 뷰들
extension MerchantDetailView {
    var MerchantInventoryGridView: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: 120, maximum: 200)),
                    GridItem(.flexible(minimum: 120, maximum: 200))
                ], spacing: 15) {
                    ForEach(viewModel.inventory) { item in
                        SimpleTradeItemCard(item: item) {
                            selectItem(item)
                        }
                    }
                }
                .padding(.horizontal, max(16, geometry.size.width * 0.05))
                .padding(.vertical, 16)
            }
        }
    }

    var PlayerInventoryGridView: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: 120, maximum: 200)),
                    GridItem(.flexible(minimum: 120, maximum: 200))
                ], spacing: 15) {
                    ForEach(viewModel.playerInventory) { item in
                        SimpleTradeItemCard(item: item) {
                            selectItem(item)
                        }
                    }
                }
                .padding(.horizontal, max(16, geometry.size.width * 0.05))
                .padding(.vertical, 16)
            }
        }
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

// MARK: - 사이버펑크 트레이드 아이템 카드 (기존 기능 유지)
struct SimpleTradeItemCard: View {
    let item: TradeItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // 아이템 헤더
                HStack {
                    Text("ID: \(String(item.id.prefix(4)))")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)

                    Spacer()

                    Text(item.grade.displayName.uppercased())
                        .font(.cyberpunkTechnical())
                        .foregroundColor(item.grade.cyberpunkColor)
                }

                // 아이템 이미지
                ZStack {
                    Rectangle()
                        .fill(item.grade.cyberpunkColor.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Rectangle()
                                .stroke(item.grade.cyberpunkColor.opacity(0.6), lineWidth: 1)
                        )

                    Image(systemName: item.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(item.grade.cyberpunkColor)
                }
                .frame(maxHeight: 50)

                VStack(spacing: 2) {
                    Text(item.name.uppercased())
                        .font(.cyberpunkCaption())
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.cyberpunkTextPrimary)
                        .minimumScaleFactor(0.8)

                    CyberpunkDataDisplay(
                        label: "PRICE",
                        value: "₩\(item.currentPrice)",
                        valueColor: .cyberpunkGreen
                    )

                    CyberpunkDataDisplay(
                        label: "STOCK",
                        value: "\(item.quantity)",
                        valueColor: .cyberpunkCyan
                    )
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 120)
            .cyberpunkGridSlot()
        }
        .buttonStyle(PlainButtonStyle())
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
}
