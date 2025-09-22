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
    let id = UUID()
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
            grade: ItemGrade.fromServerGrade(inventoryItem.grade),
            basePrice: inventoryItem.basePrice,
            quantity: inventoryItem.quantity,
            purchasePrice: inventoryItem.purchasePrice
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

// 서버 API 응답 모델
struct InventoryItem: Codable {
    let id: String
    let itemTemplateId: String
    let name: String
    let category: String
    let grade: Int
    let basePrice: Int
    let quantity: Int
    let purchasePrice: Int?
}

// MARK: - Player Inventory Item Model
struct PlayerInventoryItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let grade: ItemGrade
    let effect: String
    let imageName: String
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

    // Sample Inventory Items
    @State private var inventoryItems: [PlayerInventoryItem] = [
        PlayerInventoryItem(name: "체력 물약", grade: .common, effect: "체력 +50", imageName: "heart.circle.fill"),
        PlayerInventoryItem(name: "행운의 부적", grade: .rare, effect: "거래 성공률 +10%", imageName: "sparkles"),
        PlayerInventoryItem(name: "상인의 인장", grade: .legendary, effect: "가격 협상 +15%", imageName: "seal.fill")
    ]

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
                        inventoryItems: inventoryItems,
                        onItemTap: { item in
                            selectedItem = item
                            showingSellSheet = true
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
                        inventoryItems: inventoryItems,
                        onItemTap: { item in
                            selectedItem = item
                            showingSellSheet = true
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
                }
            }
            .refreshable {
                await gameManager.refreshInventoryData()
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
}

// MARK: - Inventory Content View
struct InventoryContentView: View {
    let tradeGoods: [TradeGood]
    let inventoryItems: [PlayerInventoryItem]
    let onItemTap: (TradeGood) -> Void
    let isRefreshing: Bool

    init(tradeGoods: [TradeGood], inventoryItems: [PlayerInventoryItem], onItemTap: @escaping (TradeGood) -> Void, isRefreshing: Bool = false) {
        self.tradeGoods = tradeGoods
        self.inventoryItems = inventoryItems
        self.onItemTap = onItemTap
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
                                onItemTap(good)
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

                // MARK: - 인벤토리 섹션
                VStack(alignment: .leading, spacing: 16) {
                    // Section Header - 사이버펑크 스타일
                    CyberpunkSectionHeader(
                        title: "PLAYER_INVENTORY",
                        subtitle: "PERSONAL_ITEMS",
                        rightContent: "ITEMS: \(inventoryItems.count)/20"
                    )

                    // Inventory Items List - 사이버펑크 그리드
                    CyberpunkInventoryGrid(
                        items: inventoryItems,
                        columns: 1,
                        emptySlots: 3
                    ) { item in
                        CyberpunkPlayerInventoryCard(inventoryItem: item)
                    }
                    .padding(.horizontal, CyberpunkLayout.screenPadding)
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
                .font(.cyberpunkBody)
                .foregroundColor(.cyberpunkTextSecondary)
                .tracking(2)

            Text("서버에서 인벤토리 데이터를 불러오는 중입니다")
                .font(.cyberpunkCaption)
                .foregroundColor(.cyberpunkTextTertiary)
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
                    .font(.cyberpunkTitle)
                    .foregroundColor(.cyberpunkTextPrimary)
                    .tracking(2)

                Text(message)
                    .font(.cyberpunkBody)
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
                .font(.cyberpunkButton)
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
                .font(.cyberpunkBody)
                .foregroundColor(.cyberpunkTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Trade Good Box Component (320x160)
struct TradeGoodBoxView: View {
    let tradeGood: TradeGood
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Top Row: Image, Name, Price
                HStack(spacing: 30) {
                    // Image
                    Image(systemName: tradeGood.imageName)
                        .font(.system(size: 40))
                        .foregroundColor(tradeGood.grade.color)
                        .frame(width: 50, height: 50)

                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tradeGood.name)
                            .font(.chosunH3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text(tradeGood.category)
                            .font(.chosunCaption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Price
                    Text("₩\(tradeGood.basePrice)")
                        .font(.chosunSubhead)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()
                    .frame(height: 50)

                // Bottom Row: Grade, Quantity
                HStack(spacing: 110) {
                    // Grade Badge
                    Text(tradeGood.grade.displayName)
                        .font(.chosunSmall)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(tradeGood.grade.color)
                        )

                    Spacer()

                    // Quantity
                    Text("\(tradeGood.quantity)개")
                        .font(.chosunSubhead)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 320, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Inventory Item Box Component
struct PlayerInventoryItemBoxView: View {
    let inventoryItem: PlayerInventoryItem

    var body: some View {
        HStack(spacing: 0) {
            // Image
            Image(systemName: inventoryItem.imageName)
                .font(.system(size: 30))
                .foregroundColor(inventoryItem.grade.color)
                .frame(width: 60, height: 60)

            Spacer()
                .frame(width: 110)

            // Name and Details
            VStack(alignment: .leading, spacing: 8) {
                Text(inventoryItem.name)
                    .font(.chosunH3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // Grade Badge
                Text(inventoryItem.grade.displayName)
                    .font(.chosunSmall)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(inventoryItem.grade.color)
                    )

                // Effect
                Text(inventoryItem.effect)
                    .font(.chosunCaption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Trade Good Detail Sheet
struct TradeGoodDetailSheet: View {
    let tradeGood: TradeGood
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Item Image
                Image(systemName: tradeGood.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(tradeGood.grade.color)
                    .frame(width: 120, height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(tradeGood.grade.color.opacity(0.1))
                    )

                // Item Details
                VStack(spacing: 16) {
                    Text(tradeGood.name)
                        .font(.chosunTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    HStack(spacing: 40) {
                        VStack {
                            Text("등급")
                                .font(.chosunCaption)
                                .foregroundColor(.secondary)
                            Text(tradeGood.grade.displayName)
                                .font(.chosunSubhead)
                                .fontWeight(.semibold)
                                .foregroundColor(tradeGood.grade.color)
                        }

                        VStack {
                            Text("수량")
                                .font(.chosunCaption)
                                .foregroundColor(.secondary)
                            Text("\(tradeGood.quantity)개")
                                .font(.chosunSubhead)
                                .fontWeight(.semibold)
                        }

                        VStack {
                            Text("가격")
                                .font(.chosunCaption)
                                .foregroundColor(.secondary)
                            Text("₩\(tradeGood.basePrice)")
                                .font(.chosunSubhead)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }

                    Divider()

                    HStack {
                        Text("총 가치:")
                            .font(.chosunBody)
                        Spacer()
                        Text("₩\(tradeGood.basePrice * tradeGood.quantity)")
                            .font(.chosunH2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Sell action
                    }) {
                        Text("전체 판매")
                            .font(.chosunButton)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green)
                            )
                    }

                    Button(action: {
                        // Partial sell action
                    }) {
                        Text("부분 판매")
                            .font(.chosunButton)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                    }
                }
            }
            .padding(20)
            .navigationTitle("상품 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}