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
    let name: String
    let category: String
    let grade: ItemGrade
    let basePrice: Int
    let quantity: Int
    let imageName: String

    enum ItemGrade: String, CaseIterable, Codable {
        case common = "일반"
        case uncommon = "고급"
        case rare = "희귀"
        case epic = "영웅"
        case legendary = "전설"

        var color: Color {
            switch self {
            case .common: return .gray
            case .uncommon: return .green
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .orange
            }
        }
    }
}

// MARK: - Inventory Item Model
struct InventoryItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let grade: TradeGood.ItemGrade
    let effect: String
    let imageName: String
}

struct InventoryView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSellSheet = false
    @State private var selectedItem: TradeGood?

    // Sample Trade Goods
    @State private var tradeGoods: [TradeGood] = [
        TradeGood(name: "고급 차잎", category: "농산물", grade: .rare, basePrice: 45000, quantity: 5, imageName: "leaf.fill"),
        TradeGood(name: "스마트폰", category: "전자제품", grade: .epic, basePrice: 800000, quantity: 2, imageName: "iphone"),
        TradeGood(name: "한우", category: "축산물", grade: .legendary, basePrice: 120000, quantity: 3, imageName: "heart.fill"),
        TradeGood(name: "전통 도자기", category: "공예품", grade: .rare, basePrice: 200000, quantity: 1, imageName: "cup.and.saucer.fill")
    ]

    // Sample Inventory Items
    @State private var inventoryItems: [InventoryItem] = [
        InventoryItem(name: "체력 물약", grade: .common, effect: "체력 +50", imageName: "heart.circle.fill"),
        InventoryItem(name: "행운의 부적", grade: .rare, effect: "거래 성공률 +10%", imageName: "sparkles"),
        InventoryItem(name: "상인의 인장", grade: .epic, effect: "가격 협상 +15%", imageName: "seal.fill")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // MARK: - 무역품 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack {
                            Text("무역품")
                                .font(.chosunH1)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Spacer()

                            Text("₩\(calculateTradeGoodsValue())")
                                .font(.chosunSubhead)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 20)

                        // Trade Goods List
                        LazyVStack(spacing: 12) {
                            ForEach(tradeGoods) { good in
                                TradeGoodBoxView(tradeGood: good) {
                                    selectedItem = good
                                    showingSellSheet = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Section Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    // MARK: - 인벤토리 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack {
                            Text("인벤토리")
                                .font(.chosunH1)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(inventoryItems.count)개 아이템")
                                .font(.chosunSubhead)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)

                        // Inventory Items List
                        LazyVStack(spacing: 12) {
                            ForEach(inventoryItems) { item in
                                InventoryItemBoxView(inventoryItem: item)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 100) // Tab bar spacing
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSellSheet) {
            if let item = selectedItem {
                TradeGoodDetailSheet(tradeGood: item)
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
                    Text(tradeGood.grade.rawValue)
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
struct InventoryItemBoxView: View {
    let inventoryItem: InventoryItem

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
                Text(inventoryItem.grade.rawValue)
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
                            Text(tradeGood.grade.rawValue)
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