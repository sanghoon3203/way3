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

    var buyItems: [CartItem] {
        items.filter { $0.type == .buy }
    }

    var sellItems: [CartItem] {
        items.filter { $0.type == .sell }
    }

    var totalBuyCost: Int {
        buyItems.reduce(0) { $0 + ($1.item.currentPrice * $1.quantity) }
    }

    var totalSellRevenue: Int {
        sellItems.reduce(0) { $0 + ($1.item.currentPrice * $1.quantity) }
    }

    var netAmount: Int {
        totalBuyCost - totalSellRevenue
    }

    // Backward compatibility for existing usage
    var totalAmount: Int {
        totalBuyCost
    }

    func addItem(_ item: TradeItem, quantity: Int, type: TradeType = .buy) {
        let maxQuantity = max(1, item.quantity)
        if let existingIndex = items.firstIndex(where: { $0.item.id == item.id && $0.type == type }) {
            items[existingIndex].quantity = min(items[existingIndex].quantity + quantity, maxQuantity)
        } else {
            let clampedQuantity = min(quantity, maxQuantity)
            items.append(CartItem(item: item, quantity: clampedQuantity, type: type))
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

    // Legacy compatibility helper for older TradeManager-based flows
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
    func exitMerchant() {
        isPresented = false
    }

    private func validateCartForTrade() -> MerchantDataError? {
        guard let player = gameManager.currentPlayer else {
            return .merchantNotFound
        }

        let netCost = max(0, cartManager.netAmount)
        if netCost > player.core.money {
            return .insufficientFunds
        }

        if !cartManager.sellItems.isEmpty {
            let inventory = player.inventory.inventory
            let inventoryCounts = Dictionary(grouping: inventory, by: { $0.id }).mapValues { items in
                items.reduce(0) { $0 + $1.quantity }
            }

            for cartItem in cartManager.sellItems {
                let available = inventoryCounts[cartItem.item.id] ?? cartItem.item.quantity
                if cartItem.quantity > available {
                    return .insufficientItems
                }
            }
        }

        return nil
    }

    private func proposedPrice(for cartItem: CartItem) -> Int {
        let base = cartItem.item.currentPrice * cartItem.quantity
        switch cartItem.type {
        case .buy:
            return base
        case .sell:
            if let purchasePrice = cartItem.item.purchasePrice {
                let desired = Int(Double(purchasePrice) * Double(cartItem.quantity) * 1.1)
                return max(base, desired)
            }
            return base
        case .exchange:
            return base
        }
    }

    private func executeTradeForCart() async {
        if let requirementMessage = TradeManager.shared.requirementFailureMessage(for: merchant) {
            await MainActor.run {
                viewModel.error = MerchantDataError.tradeValidationFailed(requirementMessage)
            }
            return
        }

        let merchantId = merchant.id

        let totalBuy = cartManager.totalBuyCost
        let totalSell = cartManager.totalSellRevenue
        let net = cartManager.netAmount

        await MainActor.run { viewModel.isLoading = true }

        do {
            for cartItem in cartManager.items {
                let request = TradeExecuteRequest(
                    merchantId: merchantId,
                    itemTemplateId: cartItem.item.itemId,
                    tradeType: cartItem.type.rawValue,
                    quantity: cartItem.quantity,
                    proposedPrice: proposedPrice(for: cartItem)
                )

                let response = try await NetworkManager.shared.executeTrade(request: request)
                if !response.success {
                    throw TradeExecutionError(message: response.error ?? response.message ?? "거래에 실패했습니다")
                }
            }

            await gameManager.refreshPlayerData()
            await viewModel.refreshMerchantData()

            await MainActor.run {
                cartManager.clearCart()
                showPurchaseConfirmation = false
                isCartPresented = false
                viewModel.isLoading = false
                selectTab(.dialogue)

                let summary: String
                if totalSell > 0 {
                    summary = "구매 ₩\(totalBuy.formatted()) · 판매 ₩\(totalSell.formatted())"
                } else {
                    summary = "총 ₩\(totalBuy.formatted()) 지출"
                }
                gameManager.addNotification(title: "거래 완료", message: summary, type: .success)
            }

        } catch let tradeError as TradeExecutionError {
            await MainActor.run {
                viewModel.error = MerchantDataError.tradeExecutionFailed(tradeError.message)
                viewModel.isLoading = false
            }
        } catch let networkError as NetworkManager.NetworkError {
            if case .clientError(let statusCode, _) = networkError, statusCode == 403 {
                let message = TradeManager.shared.requirementFailureMessage(for: merchant) ?? "거래 조건을 충족하지 못했습니다."
                await MainActor.run {
                    viewModel.error = MerchantDataError.tradeExecutionFailed(message)
                    viewModel.isLoading = false
                }
            } else {
                await MainActor.run {
                    viewModel.error = MerchantDataError.networkError(networkError)
                    viewModel.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                viewModel.error = MerchantDataError.networkError(error)
                viewModel.isLoading = false
            }
        }
    }

    private struct TradeExecutionError: Error {
        let message: String
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
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    isCartPresented = false
                }

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

                // 요약 및 진행 버튼
                VStack(spacing: 16) {
                    let totalBuy = cartManager.totalBuyCost
                    let totalSell = cartManager.totalSellRevenue
                    let net = cartManager.netAmount

                    VStack(alignment: .leading, spacing: 6) {
                        if totalBuy > 0 {
                            Text("구매 금액: ₩\(totalBuy)")
                                .font(Font.chosunOrFallback(size: 18, weight: .bold))
                                .foregroundColor(.cyberpunkYellow)
                        }
                        if totalSell > 0 {
                            Text("판매 수익: ₩\(totalSell)")
                                .font(Font.chosunOrFallback(size: 18, weight: .bold))
                                .foregroundColor(.cyberpunkGreen)
                        }
                        if totalBuy > 0 && totalSell > 0 {
                            Text(net >= 0 ? "순 지출: ₩\(net)" : "순 수익: ₩\(-net)")
                                .font(Font.chosunOrFallback(size: 16, weight: .semibold))
                                .foregroundColor(net >= 0 ? .cyberpunkTextPrimary : .cyberpunkGreen)
                        }
                    }

                    Button("거래 진행") {
                        if let validationError = validateCartForTrade() {
                            viewModel.error = validationError
                        } else {
                            showPurchaseConfirmation = true
                        }
                    }
                    .font(Font.chosunOrFallback(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .fill(Color.cyberpunkYellow)
                    )
                }
                .padding()
                .background(Color.black.opacity(0.9))
            }
            .frame(maxWidth: 420)
            .background(Color.black.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cyberpunkBorder.opacity(0.6), lineWidth: 1)
            )
        }
    }

    var CartHeaderView: some View {
        HStack {
            Button(action: { isCartPresented = false }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("거래로 돌아가기")
                }
                .font(Font.chosunOrFallback(size: 16))
                .foregroundColor(.cyan)
            }

            Spacer()

            Text("장바구니")
                .font(Font.chosunOrFallback(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // 투명한 버튼 (대칭을 위해)
            HStack {
                Image(systemName: "arrow.left")
                Text("거래로 돌아가기")
            }
            .font(Font.chosunOrFallback(size: 16))
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
                    .font(Font.chosunOrFallback(size: 20, weight: .bold))
                    .foregroundColor(.cyan)

                Text("정말 구매하시겠습니까?")
                    .font(Font.chosunOrFallback(size: 16))
                    .foregroundColor(.white)

                VStack(alignment: .trailing, spacing: 6) {
                    if cartManager.totalBuyCost > 0 {
                        Text("구매 금액: ₩\(cartManager.totalBuyCost)")
                            .font(Font.chosunOrFallback(size: 16, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    if cartManager.totalSellRevenue > 0 {
                        Text("판매 수익: ₩\(cartManager.totalSellRevenue)")
                            .font(Font.chosunOrFallback(size: 16, weight: .bold))
                            .foregroundColor(.cyberpunkGreen)
                    }
                    if cartManager.totalBuyCost > 0 && cartManager.totalSellRevenue > 0 {
                        let net = cartManager.netAmount
                        Text(net >= 0 ? "순 지출: ₩\(net)" : "순 수익: ₩\(-net)")
                            .font(Font.chosunOrFallback(size: 16, weight: .semibold))
                            .foregroundColor(net >= 0 ? .cyberpunkYellow : .cyberpunkGreen)
                    }
                }

                HStack(spacing: 20) {
                    Button("취소") {
                        showPurchaseConfirmation = false
                    }
                    .font(Font.chosunOrFallback(size: 16))
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
                    .font(Font.chosunOrFallback(size: 16))
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
        QuantityPopupContentView(
            item: item,
            tradeType: viewModel.selectedTradeType,
            cartManager: cartManager,
            showQuantityPopup: $showQuantityPopup
        )
    }
}

struct QuantityPopupContentView: View {
    let item: TradeItem
    let tradeType: TradeType
    let cartManager: CartManager
    @Binding var showQuantityPopup: Bool
    let maxQuantity: Int
    @State private var quantity = 1

    init(item: TradeItem, tradeType: TradeType, cartManager: CartManager, showQuantityPopup: Binding<Bool>) {
        self.item = item
        self.tradeType = tradeType
        self.cartManager = cartManager
        self._showQuantityPopup = showQuantityPopup
        if item.quantity > 0 {
            self.maxQuantity = item.quantity
        } else {
            self.maxQuantity = tradeType == .buy ? 99 : 1
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("수량 선택")
                .font(Font.chosunOrFallback(size: 18, weight: .bold))
                .foregroundColor(.cyan)

            VStack(spacing: 12) {
                Text(item.name)
                    .font(Font.chosunOrFallback(size: 16))
                    .foregroundColor(.white)

                Text("₩\(item.currentPrice) 각")
                    .font(Font.chosunOrFallback(size: 14))
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
                    .font(Font.chosunOrFallback(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60)

                Button("+") {
                    if quantity < maxQuantity { quantity += 1 }
                }
                .font(.title2)
                .foregroundColor(.cyan)
                .frame(width: 40, height: 40)
                .background(Circle().stroke(Color.cyan, lineWidth: 1))
            }

            Text(tradeType == .buy ? "총액: ₩\(item.currentPrice * quantity)" : "판매 금액: ₩\(item.currentPrice * quantity)")
                .font(Font.chosunOrFallback(size: 16, weight: .bold))
                .foregroundColor(.cyan)

            HStack(spacing: 20) {
                Button("아니요") {
                    showQuantityPopup = false
                }
                .font(Font.chosunOrFallback(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )

                Button("예") {
                    cartManager.addItem(item, quantity: quantity, type: tradeType)
                    showQuantityPopup = false
                }
                .font(Font.chosunOrFallback(size: 16))
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
        guard !cartManager.items.isEmpty else {
            isCartPresented = false
            showPurchaseConfirmation = false
            return
        }

        if let validationError = validateCartForTrade() {
            viewModel.error = validationError
            showPurchaseConfirmation = false
            return
        }

        Task { await executeTradeForCart() }
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
                    .font(Font.chosunOrFallback(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text("₩\(cartItem.item.currentPrice) x \(cartItem.quantity)개")
                    .font(Font.chosunOrFallback(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // 총 가격
            Text("₩\(cartItem.item.currentPrice * cartItem.quantity)")
                .font(Font.chosunOrFallback(size: 16, weight: .bold))
                .foregroundColor(.cyan)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}
