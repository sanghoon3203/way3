//
//  FeaturedItemsGrid.swift
//  way
//
//  Created by Claude on 9/9/25.
//

import SwiftUI
import CoreLocation

struct FeaturedItemsGrid: View {
    let merchant: Merchant
    let playerInventory: [TradeItem]
    let mode: TradeMode
    let isEnabled: Bool
    let onItemSelected: (TradeItem) -> Void
    let onQuickAction: (TradeItem) -> Void
    
    @EnvironmentObject var gameManager: GameManager
    
    // 그리드 레이아웃
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    private let compactGridColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    // 표시할 아이템들
    private var displayItems: [TradeItem] {
        switch mode {
        case .buy, .browse:
            return merchant.inventory
        case .sell:
            return playerInventory
        }
    }
    
    // 추천 아이템 (최대 6개)
    private var featuredItems: [TradeItem] {
        let sortedItems = displayItems.sorted { item1, item2 in
            // 정렬 우선순위: 등급 > 가격 > 이름
            if item1.grade.rawValue != item2.grade.rawValue {
                return item1.grade.rawValue > item2.grade.rawValue
            } else if item1.currentPrice != item2.currentPrice {
                return item1.currentPrice > item2.currentPrice
            } else {
                return item1.name < item2.name
            }
        }
        return Array(sortedItems.prefix(6))
    }
    
    // 나머지 아이템들
    private var remainingItems: [TradeItem] {
        let featuredIds = Set(featuredItems.map { $0.id })
        return displayItems.filter { !featuredIds.contains($0.id) }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 추천 아이템 섹션
            if !featuredItems.isEmpty {
                featuredItemsSection
            }
            
            // 전체 아이템 목록 (확장 가능)
            if !remainingItems.isEmpty {
                expandableItemsList
            }
            
            // 빈 상태
            if displayItems.isEmpty {
                emptyStateView
            }
        }
    }
    
    // MARK: - Featured Items Section
    private var featuredItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sectionTitle)
                        .font(.custom("ChosunCentennial", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text(sectionSubtitle)
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                Spacer()
                
                // 아이템 개수 표시
                Text("\(featuredItems.count)개")
                    .font(.custom("ChosunCentennial", size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.1))
                    )
            }
            .padding(.horizontal, 20)
            
            // 그리드 아이템들
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(featuredItems, id: \.id) { item in
                    EnhancedItemCard(
                        item: item,
                        size: .featured,
                        mode: mode,
                        showQuickBuy: shouldShowQuickBuy(for: item),
                        isEnabled: isEnabled && canInteractWith(item),
                        onQuickAction: {
                            onQuickAction(item)
                        },
                        onDetailTap: {
                            onItemSelected(item)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Expandable Items List
    @State private var isExpanded = false
    
    private var expandableItemsList: some View {
        VStack(spacing: 16) {
            // 확장/축소 헤더
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("전체 아이템 목록")
                        .font(.custom("ChosunCentennial", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text("(\(remainingItems.count)개)")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.black.opacity(0.6))
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 확장된 아이템 리스트
            if isExpanded {
                LazyVGrid(columns: compactGridColumns, spacing: 12) {
                    ForEach(remainingItems, id: \.id) { item in
                        EnhancedItemCard(
                            item: item,
                            size: .compact,
                            mode: mode,
                            showQuickBuy: shouldShowQuickBuy(for: item),
                            isEnabled: isEnabled && canInteractWith(item),
                            onQuickAction: {
                                onQuickAction(item)
                            },
                            onDetailTap: {
                                onItemSelected(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.black.opacity(0.3))
            
            Text(emptyStateTitle)
                .font(.custom("ChosunCentennial", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.black.opacity(0.6))
            
            Text(emptyStateMessage)
                .font(.custom("ChosunCentennial", size: 14))
                .foregroundColor(.black.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Helper Properties
    private var sectionTitle: String {
        switch mode {
        case .buy: return "추천 상품"
        case .sell: return "판매 가능 아이템"
        case .browse: return "인기 상품"
        }
    }
    
    private var sectionSubtitle: String {
        switch mode {
        case .buy: return "이 상인이 추천하는 상품들입니다"
        case .sell: return "높은 가격으로 판매할 수 있는 아이템들입니다"
        case .browse: return "많은 사람들이 관심을 가지는 상품들입니다"
        }
    }
    
    private var emptyStateIcon: String {
        switch mode {
        case .buy, .browse: return "storefront"
        case .sell: return "bag"
        }
    }
    
    private var emptyStateTitle: String {
        switch mode {
        case .buy, .browse: return "판매 중인 상품이 없습니다"
        case .sell: return "판매할 아이템이 없습니다"
        }
    }
    
    private var emptyStateMessage: String {
        switch mode {
        case .buy: return "이 상인은 현재 판매할 상품이 없습니다.\n나중에 다시 방문해보세요."
        case .sell: return "인벤토리에 판매할 아이템이 없습니다.\n먼저 아이템을 구입하거나 획득하세요."
        case .browse: return "둘러볼 상품이 없습니다."
        }
    }
    
    // MARK: - Helper Methods
    private func shouldShowQuickBuy(for item: TradeItem) -> Bool {
        switch mode {
        case .buy, .sell: return true
        case .browse: return false
        }
    }
    
    private func canInteractWith(_ item: TradeItem) -> Bool {
        // 라이센스 체크
        let licenseCheck = gameManager.player.currentLicense.rawValue >= item.requiredLicense.rawValue
        
        switch mode {
        case .buy, .browse:
            return licenseCheck
        case .sell:
            return true // 판매는 라이센스 체크 없음
        }
    }
}

// MARK: - Search and Filter Bar
struct ItemSearchAndFilter: View {
    @Binding var searchText: String
    @Binding var selectedCategory: String?
    let categories: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            // 검색 바
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.black.opacity(0.6))
                
                TextField("아이템 검색...", text: $searchText)
                    .font(.custom("ChosunCentennial", size: 16))
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.black.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // 카테고리 필터
            if !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // 전체 버튼
                        ItemCategoryFilterButton(
                            title: "전체",
                            isSelected: selectedCategory == nil,
                            action: {
                                selectedCategory = nil
                            }
                        )
                        
                        // 카테고리 버튼들
                        ForEach(categories, id: \.self) { category in
                            ItemCategoryFilterButton(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ItemCategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("ChosunCentennial", size: 14))
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .black.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.clear : Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Color.blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    let sampleMerchant = Merchant(
        name: "테크마켓 사장",
        title: "첨단기술 상인",
        type: .tech,
        personality: .analytical,
        district: .gangnam,
        coordinate: CLLocationCoordinate2D(latitude: 37.4989, longitude: 127.0356),
        requiredLicense: .intermediate,
        inventory: [
            TradeItem(itemId: "1", name: "정련된 철검", category: "금속공예", grade: .rare, requiredLicense: LicenseLevel.intermediate, basePrice: 120000, currentPrice: 135000),
            TradeItem(itemId: "2", name: "비취 목걸이", category: "보석", grade: .legendary, requiredLicense: LicenseLevel.advanced, basePrice: 300000, currentPrice: 315000),
            TradeItem(itemId: "3", name: "비단 한복", category: "직물", grade: .rare, requiredLicense: LicenseLevel.intermediate, basePrice: 240000, currentPrice: 255000)
        ],
        priceModifier: 1.2,
        negotiationDifficulty: 4,
        preferredItems: ["전자제품"],
        dislikedItems: ["의류"]
    )
    
    FeaturedItemsGrid(
        merchant: sampleMerchant,
        playerInventory: [],
        mode: .buy,
        isEnabled: true,
        onItemSelected: { _ in },
        onQuickAction: { _ in }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}