//
//  MerchantDetailView.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  상인 상세 정보 및 거래 화면
//

import SwiftUI

struct MerchantDetailView: View {
    let merchant: Merchant
    @Binding var isPresented: Bool
    @State private var selectedTab = 0
    @State private var showTradeView = false
    @StateObject private var tradeManager = TradeManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상인 헤더
                MerchantHeaderView(merchant: merchant)
                
                // 탭 선택
                TabSelectionView(selectedTab: $selectedTab)
                
                // 탭 컨텐츠
                TabView(selection: $selectedTab) {
                    // 구매 탭
                    MerchantInventoryView(merchant: merchant, tradeManager: tradeManager, tradeType: .buy)
                        .tag(0)
                    
                    // 판매 탭
                    PlayerInventoryView(merchant: merchant, tradeManager: tradeManager, tradeType: .sell)
                        .tag(1)
                    
                    // 정보 탭
                    MerchantInfoView(merchant: merchant)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // 거래 요약 및 버튼
                if !tradeManager.selectedItems.isEmpty {
                    TradeFooterView(tradeManager: tradeManager) {
                        showTradeView = true
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        isPresented = false
                    }
                    .font(.custom("ChosunCentennial", size: 16))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 즐겨찾기 토글
                    }) {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showTradeView) {
            TradeConfirmationView(
                merchant: merchant,
                tradeManager: tradeManager,
                isPresented: $showTradeView
            )
        }
    }
}

// MARK: - 상인 헤더
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