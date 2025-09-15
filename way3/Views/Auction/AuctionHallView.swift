//
//  AuctionHallView.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  실시간 경매장 메인 화면
//

import SwiftUI

struct AuctionHallView: View {
    @StateObject private var auctionManager = AuctionManager()
    @State private var selectedCategory = "전체"
    @State private var selectedSort = SortOption.timeRemaining
    @State private var showingCreateAuction = false
    @State private var searchText = ""
    
    let categories = ["전체", "식료품", "공예품", "명품", "보석", "직물", "금속공예"]
    
    enum SortOption: String, CaseIterable {
        case timeRemaining = "남은 시간"
        case currentPrice = "현재 가격"
        case bidCount = "입찰 수"
        case grade = "등급"
        
        var iconName: String {
            switch self {
            case .timeRemaining: return "clock.fill"
            case .currentPrice: return "wonsign.circle.fill"
            case .bidCount: return "person.3.fill"
            case .grade: return "star.fill"
            }
        }
    }
    
    var filteredAndSortedAuctions: [Auction] {
        var auctions = auctionManager.getAuctionsByCategory(selectedCategory)
        
        // 검색 필터
        if !searchText.isEmpty {
            auctions = auctions.filter { 
                $0.item.name.localizedCaseInsensitiveContains(searchText) ||
                $0.sellerName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 정렬
        switch selectedSort {
        case .timeRemaining:
            auctions.sort { $0.timeRemaining < $1.timeRemaining }
        case .currentPrice:
            auctions.sort { $0.currentPrice > $1.currentPrice }
        case .bidCount:
            auctions.sort { $0.bidCount > $1.bidCount }
        case .grade:
            auctions.sort { $0.item.grade.rawValue > $1.item.grade.rawValue }
        }
        
        return auctions
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 상태 바
                AuctionStatusBar(auctionManager: auctionManager)
                
                // 검색 및 필터 바
                VStack(spacing: 12) {
                    // 검색바
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("아이템 또는 판매자 검색", text: $searchText)
                            .font(.custom("ChosunCentennial", size: 16))
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // 카테고리 필터
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                CategoryFilterChip(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 정렬 옵션
                    HStack {
                        Text("정렬:")
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { selectedSort = option }) {
                                    HStack {
                                        Image(systemName: option.iconName)
                                        Text(option.rawValue)
                                        if selectedSort == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: selectedSort.iconName)
                                Text(selectedSort.rawValue)
                                Image(systemName: "chevron.down")
                            }
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        // 경매 생성 버튼
                        Button(action: { showingCreateAuction = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("경매 등록")
                            }
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange)
                            .cornerRadius(15)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // 경매 목록
                if filteredAndSortedAuctions.isEmpty {
                    AuctionEmptyState(
                        isLoading: !auctionManager.isConnected,
                        hasFilter: selectedCategory != "전체" || !searchText.isEmpty
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // 마감 임박 경매 섹션
                            let endingSoon = auctionManager.getEndingSoonAuctions()
                            if !endingSoon.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("마감 임박")
                                            .font(.custom("ChosunCentennial", size: 18))
                                            .fontWeight(.bold)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(endingSoon.prefix(5)) { auction in
                                                CompactAuctionCard(
                                                    auction: auction,
                                                    auctionManager: auctionManager
                                                )
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                
                                Divider()
                                    .padding()
                            }
                            
                            // 메인 경매 목록
                            ForEach(filteredAndSortedAuctions) { auction in
                                NavigationLink(destination: AuctionDetailView(
                                    auction: auction,
                                    auctionManager: auctionManager
                                )) {
                                    AuctionCard(
                                        auction: auction,
                                        auctionManager: auctionManager
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        auctionManager.connectSocket()
                    }
                }
            }
            .navigationTitle("경매장")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCreateAuction) {
            CreateAuctionView(auctionManager: auctionManager)
        }
        .onAppear {
            if !auctionManager.isConnected {
                auctionManager.connectSocket()
            }
        }
    }
}

// MARK: - 경매 상태 바
struct AuctionStatusBar: View {
    @ObservedObject var auctionManager: AuctionManager
    
    var body: some View {
        HStack(spacing: 16) {
            // 연결 상태
            HStack(spacing: 6) {
                Circle()
                    .fill(auctionManager.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(auctionManager.connectionStatus)
                    .font(.custom("ChosunCentennial", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 활성 경매 수
            HStack(spacing: 4) {
                Image(systemName: "hammer.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 12))
                
                Text("활성 경매 \(auctionManager.activeAuctions.count)개")
                    .font(.custom("ChosunCentennial", size: 12))
                    .foregroundColor(.secondary)
            }
            
            // 참여 중인 경매 수
            HStack(spacing: 4) {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 12))
                
                Text("참여 중 \(auctionManager.userBids.count)개")
                    .font(.custom("ChosunCentennial", size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
}

// MARK: - 카테고리 필터 칩
struct CategoryFilterChip: View {
    let category: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(category)
                .font(.custom("ChosunCentennial", size: 14))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? .blue : Color(.tertiarySystemBackground))
                .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 경매 카드
struct AuctionCard: View {
    let auction: Auction
    @ObservedObject var auctionManager: AuctionManager
    
    var body: some View {
        VStack(spacing: 12) {
            // 상단 - 아이템 정보
            HStack(spacing: 12) {
                // 아이템 이미지
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(auction.item.grade.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 24))
                            .foregroundColor(auction.item.grade.color)
                        
                        Text(auction.item.grade.shortDisplayName)
                            .font(.custom("ChosunCentennial", size: 8))
                            .foregroundColor(auction.item.grade.color)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(auction.item.name)
                        .font(.custom("ChosunCentennial", size: 18))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("판매자: \(auction.sellerName)")
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        // 경매 타입 배지
                        HStack(spacing: 4) {
                            Image(systemName: auction.auctionType.iconName)
                            Text(auction.auctionType.displayName)
                        }
                        .font(.custom("ChosunCentennial", size: 10))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(auction.auctionType.color)
                        .cornerRadius(8)
                        
                        // 카테고리
                        Text(auction.item.category)
                            .font(.custom("ChosunCentennial", size: 10))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
                
                // 시간 및 상태
                VStack(alignment: .trailing, spacing: 4) {
                    Text(auction.formattedTimeRemaining)
                        .font(.custom("ChosunCentennial", size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(auction.timeRemaining < 300 ? .red : .primary)
                    
                    if auctionManager.isUserBidding(auctionId: auction.id) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 10))
                            Text("참여 중")
                                .font(.custom("ChosunCentennial", size: 10))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    if auctionManager.isUserWinning(auctionId: auction.id) {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 10))
                            Text("최고가")
                                .font(.custom("ChosunCentennial", size: 10))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            Divider()
            
            // 하단 - 가격 정보
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 가격")
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("₩\(auction.currentPrice.formatted())")
                        .font(.custom("ChosunCentennial", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("입찰 수: \(auction.bidCount)")
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.secondary)
                    
                    if !auction.highestBidder.isEmpty {
                        Text("최고 입찰자: \(auction.highestBidder)")
                            .font(.custom("ChosunCentennial", size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 컴팩트 경매 카드
struct CompactAuctionCard: View {
    let auction: Auction
    @ObservedObject var auctionManager: AuctionManager
    
    var body: some View {
        NavigationLink(destination: AuctionDetailView(
            auction: auction,
            auctionManager: auctionManager
        )) {
            VStack(spacing: 8) {
                // 아이템 아이콘
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(auction.item.grade.color.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "cube.fill")
                        .font(.system(size: 20))
                        .foregroundColor(auction.item.grade.color)
                }
                
                VStack(spacing: 2) {
                    Text(auction.item.name)
                        .font(.custom("ChosunCentennial", size: 12))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("₩\(auction.currentPrice.formatted())")
                        .font(.custom("ChosunCentennial", size: 10))
                        .foregroundColor(.green)
                    
                    Text(auction.formattedTimeRemaining)
                        .font(.custom("ChosunCentennial", size: 10))
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                .frame(width: 80)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 빈 상태 뷰
struct AuctionEmptyState: View {
    let isLoading: Bool
    let hasFilter: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("경매 정보를 불러오는 중...")
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: hasFilter ? "magnifyingglass" : "hammer.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text(hasFilter ? "검색 결과가 없습니다" : "현재 진행 중인 경매가 없습니다")
                    .font(.custom("ChosunCentennial", size: 18))
                    .fontWeight(.bold)
                
                Text(hasFilter ? 
                     "다른 검색어나 필터를 시도해보세요" : 
                     "첫 번째 경매를 등록해보세요!")
                    .font(.custom("ChosunCentennial", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AuctionHallView()
}