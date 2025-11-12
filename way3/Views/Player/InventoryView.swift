//
//  InventoryView.swift
//  way3
//
//  Created by Claude on 17/09/2025.
//  새로운 인벤토리 뷰 - 무역품과 인벤토리 섹션 분리
//

import SwiftUI

// MARK: - Trade Goods Model
struct TradeGood: Identifiable, Codable {
    var id = UUID()
    let serverItemId: String?
    let name: String
    let category: String
    let grade: ItemGrade
    let basePrice: Int
    let quantity: Int
    let imageName: String
    let purchasePrice: Int?

    // 기존 생성자 (샘플 데이터용)
    init(name: String, category: String, grade: ItemGrade, basePrice: Int, quantity: Int, imageName: String) {
        self.serverItemId = nil
        self.name = name
        self.category = category
        self.grade = grade
        self.basePrice = basePrice
        self.quantity = quantity
        self.imageName = imageName
        self.purchasePrice = nil
    }

    // 서버 데이터 생성자
    init(serverItemId: String, name: String, category: String, grade: ItemGrade, basePrice: Int, quantity: Int, purchasePrice: Int?) {
        self.serverItemId = serverItemId
        self.name = name
        self.category = category
        self.grade = grade
        self.basePrice = basePrice
        self.quantity = quantity
        self.imageName = Self.categoryToImageName(category)
        self.purchasePrice = purchasePrice
    }

    // 서버 API 응답에서 TradeGood 생성
    static func from(inventoryItem: InventoryItem) -> TradeGood {
        return TradeGood(
            serverItemId: inventoryItem.id,
            name: inventoryItem.name,
            category: inventoryItem.category,
            grade: ItemGrade.fromServerGrade(Int(inventoryItem.grade) ?? 1),
            basePrice: inventoryItem.basePrice,
            quantity: 1, // 기본값 설정 (개별 아이템)
            purchasePrice: inventoryItem.currentPrice // 현재 가격을 구매가로 사용
        )
    }

    // 카테고리별 아이콘 매핑
    private static func categoryToImageName(_ category: String) -> String {
        switch category.lowercased() {
        case "ceramic", "pottery": return "cup.and.saucer.fill"
        case "electronics", "electronic": return "iphone"
        case "agricultural", "agriculture": return "leaf.fill"
        case "luxury": return "sparkles"
        case "textile", "clothes": return "tshirt.fill"
        case "food", "meat": return "heart.fill"
        case "jewelry": return "diamond.fill"
        case "books": return "book.fill"
        default: return "cube.box.fill"
        }
    }
}


// MARK: - Personal Items Views

struct PersonalItemsLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkCyan))
                .scaleEffect(0.8)

            Text("개인 아이템 로딩 중...")
                .font(.cyberpunkCaption())
                .foregroundColor(.cyberpunkTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct EmptyPersonalItemsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.box")
                .font(.largeTitle)
                .foregroundColor(.cyberpunkTextSecondary)

            Text("보유한 개인 아이템이 없습니다")
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct PersonalItemsErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("개인 아이템 로딩 실패")
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextPrimary)

            Text(message)
                .font(.cyberpunkCaption())
                .foregroundColor(.cyberpunkTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct PersonalItemsGridView: View {
    let items: [PersonalItem]
    let onItemTap: (PersonalItem) -> Void
    let isRefreshing: Bool
    let usingItem: PersonalItem?
    let equippingItem: PersonalItem?

    init(
        items: [PersonalItem],
        onItemTap: @escaping (PersonalItem) -> Void,
        isRefreshing: Bool = false,
        usingItem: PersonalItem? = nil,
        equippingItem: PersonalItem? = nil
    ) {
        self.items = items
        self.onItemTap = onItemTap
        self.isRefreshing = isRefreshing
        self.usingItem = usingItem
        self.equippingItem = equippingItem
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(items) { item in
                PersonalItemCard(
                    item: item,
                    isLoading: (usingItem?.id == item.id) || (equippingItem?.id == item.id),
                    onTap: { onItemTap(item) }
                )
            }
        }
        .padding(.horizontal, CyberpunkLayout.screenPadding)
    }
}

struct PersonalItemCard: View {
    let item: PersonalItem
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 아이템 아이콘
                ZStack {
                    Circle()
                        .fill(item.grade.cyberpunkColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    if let firstEffect = item.effects.first {
                        Image(systemName: firstEffect.type.icon)
                            .font(.title2)
                            .foregroundColor(firstEffect.type.color)
                    } else {
                        Image(systemName: "cube.box.fill")
                            .font(.title2)
                            .foregroundColor(.cyberpunkTextSecondary)
                    }

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkCyan))
                            .scaleEffect(0.6)
                    }
                }

                // 아이템 정보
                VStack(spacing: 4) {
                    Text(item.name)
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkTextPrimary)
                        .lineLimit(1)

                    Text(item.type.displayName)
                        .font(.system(size: 10))
                        .foregroundColor(item.type.color)

                    // 수량 또는 장착 상태
                    Group {
                        if item.type == .consumable {
                            Text("x\(item.quantity)")
                                .font(.system(size: 10))
                                .foregroundColor(.cyberpunkTextSecondary)
                        } else if item.isEquipped {
                            Text("장착됨")
                                .font(.system(size: 10))
                                .foregroundColor(.cyberpunkGreen)
                        } else {
                            Text("미장착")
                                .font(.system(size: 10))
                                .foregroundColor(.cyberpunkTextSecondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cyberpunkCardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(item.grade.cyberpunkColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

struct InventoryView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var gameManager: GameManager
    @State private var showingSellSheet = false
    @State private var selectedItem: TradeGood?

    // 서버 데이터를 기반으로 한 인벤토리 데이터
    private var tradeGoods: [TradeGood] {
        guard let player = gameManager.currentPlayer else { return [] }

        return player.inventory.inventory.map { tradeItem in
            TradeGood(
                serverItemId: tradeItem.id,
                name: tradeItem.name,
                category: tradeItem.category,
                grade: tradeItem.grade,
                basePrice: tradeItem.basePrice,
                quantity: tradeItem.quantity,
                purchasePrice: nil
            )
        }
    }

    // 서버 데이터 기반 개인 아이템
    private var personalItems: [PersonalItem] {
        return gameManager.personalItems
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 사이버펑크 배경
                Color.cyberpunkDarkBg
                    .ignoresSafeArea()

                // 상태 기반 콘텐츠 렌더링
                switch gameManager.inventoryViewState {
                case .loading:
                    InventoryLoadingView()
                case .loaded:
                    InventoryContentView(
                        tradeGoods: tradeGoods,
                        personalItems: personalItems,
                        personalItemsState: gameManager.personalItemsViewState,
                        onTradeItemTap: { item in
                            selectedItem = item
                            showingSellSheet = true
                        },
                        onPersonalItemTap: { item in
                            // 개인 아이템 액션 메뉴 표시
                            handlePersonalItemTap(item)
                        }
                    )
                case .error(let message):
                    InventoryErrorView(
                        message: message,
                        onRetry: {
                            Task {
                                await gameManager.loadInventoryData()
                            }
                        }
                    )
                case .refreshing:
                    InventoryContentView(
                        tradeGoods: tradeGoods,
                        personalItems: personalItems,
                        personalItemsState: gameManager.personalItemsViewState,
                        onTradeItemTap: { item in
                            selectedItem = item
                            showingSellSheet = true
                        },
                        onPersonalItemTap: { item in
                            handlePersonalItemTap(item)
                        },
                        isRefreshing: true
                    )
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await gameManager.smartLoadInventory()
                    await gameManager.loadPersonalItemsData()
                }
            }
            .refreshable {
                await gameManager.refreshInventoryData()
                await gameManager.refreshPersonalItemsData()
            }
        }
        .sheet(isPresented: $showingSellSheet) {
            if let item = selectedItem {
                CyberpunkTradeGoodDetailSheet(tradeGood: item)
            }
        }
    }

    // MARK: - Helper Functions
    private func calculateTradeGoodsValue() -> Int {
        return tradeGoods.reduce(0) { total, good in
            total + (good.basePrice * good.quantity)
        }
    }

    private func handlePersonalItemTap(_ item: PersonalItem) {
        // 개인 아이템 액션 시트 또는 상세 뷰 표시
        // 현재는 사용 또는 장착 액션만 수행
        Task {
            if item.type == .consumable {
                let success = await gameManager.usePersonalItem(item)
                if success {
                    // 성공 시 UI 업데이트는 GameManager에서 처리
                }
            } else if item.type == .equipment {
                let success = await gameManager.toggleEquipPersonalItem(item)
                if success {
                    // 성공 시 UI 업데이트는 GameManager에서 처리
                }
            }
        }
    }
}

// MARK: - Inventory Content View
struct InventoryContentView: View {
    let tradeGoods: [TradeGood]
    let personalItems: [PersonalItem]
    let personalItemsState: PersonalItemsViewState
    let onTradeItemTap: (TradeGood) -> Void
    let onPersonalItemTap: (PersonalItem) -> Void
    let isRefreshing: Bool

    init(
        tradeGoods: [TradeGood],
        personalItems: [PersonalItem],
        personalItemsState: PersonalItemsViewState,
        onTradeItemTap: @escaping (TradeGood) -> Void,
        onPersonalItemTap: @escaping (PersonalItem) -> Void,
        isRefreshing: Bool = false
    ) {
        self.tradeGoods = tradeGoods
        self.personalItems = personalItems
        self.personalItemsState = personalItemsState
        self.onTradeItemTap = onTradeItemTap
        self.onPersonalItemTap = onPersonalItemTap
        self.isRefreshing = isRefreshing
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - 무역품 섹션
                VStack(alignment: .leading, spacing: 16) {
                    // Section Header - 사이버펑크 스타일
                    CyberpunkSectionHeader(
                        title: "TRADE_GOODS",
                        subtitle: isRefreshing ? "UPDATING..." : "INVENTORY_SYSTEM_V2.1",
                        rightContent: "VALUE: ₩\(calculateTradeGoodsValue())"
                    )

                    if tradeGoods.isEmpty {
                        EmptyInventoryView(message: "보유 중인 무역품이 없습니다")
                    } else {
                        // Trade Goods List - 사이버펑크 그리드
                        CyberpunkInventoryGrid(
                            items: tradeGoods,
                            columns: 2,
                            emptySlots: 2
                        ) { good in
                            CyberpunkTradeGoodCard(tradeGood: good) {
                                onTradeItemTap(good)
                            }
                        }
                        .padding(.horizontal, CyberpunkLayout.screenPadding)
                    }
                }

                // Section Divider - 사이버펑크 스타일
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyberpunkYellow, .cyberpunkCyan, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, CyberpunkLayout.screenPadding)

                // MARK: - 개인 아이템 섹션
                VStack(alignment: .leading, spacing: 16) {
                    // Section Header - 사이버펑크 스타일
                    CyberpunkSectionHeader(
                        title: "PERSONAL_ITEMS",
                        subtitle: personalItemsState.isLoading ? "LOADING..." : "ENHANCEMENT_ITEMS",
                        rightContent: "ITEMS: \(personalItems.count)/50"
                    )

                    // 개인 아이템 상태별 렌더링
                    switch personalItemsState {
                    case .loading:
                        PersonalItemsLoadingView()
                    case .loaded:
                        if personalItems.isEmpty {
                            EmptyPersonalItemsView()
                        } else {
                            PersonalItemsGridView(
                                items: personalItems,
                                onItemTap: onPersonalItemTap
                            )
                        }
                    case .error(let message):
                        PersonalItemsErrorView(message: message)
                    case .refreshing:
                        PersonalItemsGridView(
                            items: personalItems,
                            onItemTap: onPersonalItemTap,
                            isRefreshing: true
                        )
                    case .using(let item):
                        PersonalItemsGridView(
                            items: personalItems,
                            onItemTap: onPersonalItemTap,
                            usingItem: item
                        )
                    case .equipping(let item):
                        PersonalItemsGridView(
                            items: personalItems,
                            onItemTap: onPersonalItemTap,
                            equippingItem: item
                        )
                    }
                }

                Spacer(minLength: 100) // Tab bar spacing
            }
            .padding(.vertical, 20)
        }
    }

    private func calculateTradeGoodsValue() -> Int {
        return tradeGoods.reduce(0) { total, good in
            total + (good.basePrice * good.quantity)
        }
    }
}

// MARK: - Inventory Loading View
struct InventoryLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkCyan))
                .scaleEffect(1.5)

            Text("LOADING_INVENTORY...")
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextSecondary)
                .tracking(2)

            Text("서버에서 인벤토리 데이터를 불러오는 중입니다")
                .font(.cyberpunkCaption())
                .foregroundColor(.cyberpunkTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cyberpunkDarkBg)
    }
}

// MARK: - Inventory Error View
struct InventoryErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.cyberpunkYellow)

            VStack(spacing: 12) {
                Text("INVENTORY_ERROR")
                    .font(.cyberpunkTitle())
                    .foregroundColor(.cyberpunkTextPrimary)
                    .tracking(2)

                Text(message)
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Retry Button
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("다시 시도")
                }
                .font(.cyberpunkButton())
                .foregroundColor(.cyberpunkDarkBg)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyberpunkCyan)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cyberpunkDarkBg)
    }
}

// MARK: - Empty Inventory View
struct EmptyInventoryView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 40))
                .foregroundColor(.cyberpunkTextSecondary)

            Text(message)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}



