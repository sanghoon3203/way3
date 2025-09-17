//
//  ShopView.swift
//  way3
//
//  Created by Claude on 17/09/2025.
//  네오-서울 비밀상점 - 특수 아이템 및 경매장 통합 뷰
//

import SwiftUI

// MARK: - Special Item Model
struct SpecialItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let price: Int
    let grade: TradeGood.ItemGrade
    let specialEffect: String
    let imageName: String
    let isLimited: Bool
    let stock: Int?

    var displayPrice: String {
        return "₩\(price)"
    }
}

// MARK: - Advertisement Banner Model
struct AdBanner: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    let backgroundColor: Color
}

struct ShopView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0 // 0: 상점, 1: 경매장
    @State private var showingItemDetail = false
    @State private var selectedItem: SpecialItem?

    // Sample Special Items
    @State private var specialItems: [SpecialItem] = [
        SpecialItem(
            name: "시간 가속기",
            description: "거래 시간을 단축시켜주는 신비한 장치",
            price: 150000,
            grade: .legendary,
            specialEffect: "거래 시간 -50%",
            imageName: "timer",
            isLimited: true,
            stock: 3
        ),
        SpecialItem(
            name: "행운의 목걸이",
            description: "착용하면 모든 거래에서 행운이 따르는 목걸이",
            price: 80000,
            grade: .epic,
            specialEffect: "거래 성공률 +25%",
            imageName: "gift.circle.fill",
            isLimited: false,
            stock: nil
        ),
        SpecialItem(
            name: "상인의 지혜서",
            description: "고대 상인들의 지혜가 담긴 비밀 서적",
            price: 120000,
            grade: .rare,
            specialEffect: "가격 협상력 +30%",
            imageName: "book.fill",
            isLimited: true,
            stock: 5
        ),
        SpecialItem(
            name: "텔레포트 스크롤",
            description: "원하는 상인에게 즉시 이동할 수 있는 마법 스크롤",
            price: 50000,
            grade: .uncommon,
            specialEffect: "즉시 이동",
            imageName: "location.fill",
            isLimited: false,
            stock: nil
        )
    ]

    // Sample Advertisement Banners
    private let adBanners: [AdBanner] = [
        AdBanner(
            title: "신규 상인 오픈!",
            subtitle: "강남역 럭셔리 상점가",
            imageName: "building.2.fill",
            backgroundColor: .purple
        ),
        AdBanner(
            title: "한정판 아이템",
            subtitle: "오늘만 50% 할인",
            imageName: "star.fill",
            backgroundColor: .orange
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Selector
                HStack(spacing: 0) {
                    Button(action: { selectedTab = 0 }) {
                        VStack(spacing: 8) {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 20))
                            Text("비밀상점")
                                .font(.chosunSmall)
                        }
                        .foregroundColor(selectedTab == 0 ? .blue : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(selectedTab == 0 ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }

                    Button(action: { selectedTab = 1 }) {
                        VStack(spacing: 8) {
                            Image(systemName: "hammer.fill")
                                .font(.system(size: 20))
                            Text("경매장")
                                .font(.chosunSmall)
                        }
                        .foregroundColor(selectedTab == 1 ? .blue : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(selectedTab == 1 ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                }
                .background(Color(.systemGray6))

                // Content based on selected tab
                if selectedTab == 0 {
                    SecretShopView(
                        specialItems: specialItems,
                        adBanners: adBanners,
                        onItemTap: { item in
                            selectedItem = item
                            showingItemDetail = true
                        }
                    )
                } else {
                    AuctionPlaceholderView()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingItemDetail) {
            if let item = selectedItem {
                SpecialItemDetailSheet(specialItem: item)
            }
        }
    }
}

// MARK: - Secret Shop Content View
struct SecretShopView: View {
    let specialItems: [SpecialItem]
    let adBanners: [AdBanner]
    let onItemTap: (SpecialItem) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("네오-서울 비밀상점")
                        .font(.chosunH1)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    // Shop Status Indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("영업중")
                            .font(.chosunSmall)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Advertisement Content
                TabView {
                    ForEach(adBanners) { banner in
                        AdBannerView(banner: banner)
                    }
                }
                .frame(height: 160)
                .tabViewStyle(PageTabViewStyle())

                // Special Items Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("특수 아이템")
                            .font(.chosunH2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("현재 보유: ₩\(getCurrentMoney())")
                            .font(.chosunCaption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 20)

                    Text("특이한 효과를 가진 아이템들을 만나보세요")
                        .font(.chosunBody)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)

                    // Items Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(specialItems) { item in
                            SpecialItemCard(specialItem: item) {
                                onItemTap(item)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 100) // Tab bar spacing
            }
        }
    }

    private func getCurrentMoney() -> Int {
        // TODO: Get from player data
        return 500000
    }
}

// MARK: - Advertisement Banner View
struct AdBannerView: View {
    let banner: AdBanner

    var body: some View {
        HStack(spacing: 20) {
            // Banner Content
            VStack(alignment: .leading, spacing: 8) {
                Text(banner.title)
                    .font(.chosunH2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(banner.subtitle)
                    .font(.chosunBody)
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            // Banner Icon
            Image(systemName: banner.imageName)
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .frame(width: 400, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [banner.backgroundColor, banner.backgroundColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Special Item Card
struct SpecialItemCard: View {
    let specialItem: SpecialItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Item Image and Limited Badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: specialItem.imageName)
                        .font(.system(size: 40))
                        .foregroundColor(specialItem.grade.color)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(specialItem.grade.color.opacity(0.1))
                        )

                    if specialItem.isLimited {
                        Text("한정")
                            .font(.chosunSmall)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                            )
                            .offset(x: 8, y: -8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Item Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(specialItem.name)
                        .font(.chosunSubhead)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // Grade Badge
                    Text(specialItem.grade.rawValue)
                        .font(.chosunSmall)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(specialItem.grade.color)
                        )

                    // Special Effect
                    Text(specialItem.specialEffect)
                        .font(.chosunSmall)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    // Stock Info
                    if let stock = specialItem.stock {
                        Text("재고: \(stock)개")
                            .font(.chosunSmall)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }

                // Price
                Text(specialItem.displayPrice)
                    .font(.chosunSubhead)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Auction Placeholder View (Frontend Only)
struct AuctionPlaceholderView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("경매장")
                .font(.chosunH1)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 40)

            // Auction House Image
            Image(systemName: "hammer.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            VStack(spacing: 12) {
                Text("프론트엔드 전용 구현")
                    .font(.chosunH2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("실제 경매 기능은 추후 서버 연동과 함께 구현됩니다.")
                    .font(.chosunBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Sample Auction Items (UI Only)
            VStack(alignment: .leading, spacing: 16) {
                Text("진행중인 경매 (시뮬레이션)")
                    .font(.chosunH3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                LazyVStack(spacing: 12) {
                    AuctionItemPreview(
                        name: "희귀한 도자기",
                        currentBid: 450000,
                        timeLeft: "2시간 15분",
                        bidders: 12
                    )
                    AuctionItemPreview(
                        name: "고급 차잎 세트",
                        currentBid: 180000,
                        timeLeft: "45분",
                        bidders: 8
                    )
                    AuctionItemPreview(
                        name: "빈티지 시계",
                        currentBid: 1200000,
                        timeLeft: "1일 3시간",
                        bidders: 24
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// MARK: - Auction Item Preview (UI Only)
struct AuctionItemPreview: View {
    let name: String
    let currentBid: Int
    let timeLeft: String
    let bidders: Int

    var body: some View {
        HStack(spacing: 16) {
            // Item Icon
            Image(systemName: "photo.artframe")
                .font(.system(size: 30))
                .foregroundColor(.purple)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.1))
                )

            // Item Info
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.chosunSubhead)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("현재 입찰가: ₩\(currentBid)")
                    .font(.chosunCaption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)

                Text("남은 시간: \(timeLeft)")
                    .font(.chosunSmall)
                    .foregroundColor(.orange)
            }

            Spacer()

            // Bidders Count
            VStack {
                Text("\(bidders)")
                    .font(.chosunSubhead)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("입찰자")
                    .font(.chosunSmall)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Special Item Detail Sheet
struct SpecialItemDetailSheet: View {
    let specialItem: SpecialItem
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Item Image
                    Image(systemName: specialItem.imageName)
                        .font(.system(size: 100))
                        .foregroundColor(specialItem.grade.color)
                        .frame(width: 150, height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(specialItem.grade.color.opacity(0.1))
                        )

                    // Item Info
                    VStack(spacing: 16) {
                        Text(specialItem.name)
                            .font(.chosunTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(specialItem.description)
                            .font(.chosunBody)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        // Grade and Effect
                        VStack(spacing: 12) {
                            HStack {
                                Text("등급:")
                                    .font(.chosunSubhead)
                                Spacer()
                                Text(specialItem.grade.rawValue)
                                    .font(.chosunSubhead)
                                    .fontWeight(.semibold)
                                    .foregroundColor(specialItem.grade.color)
                            }

                            HStack {
                                Text("특수 효과:")
                                    .font(.chosunSubhead)
                                Spacer()
                                Text(specialItem.specialEffect)
                                    .font(.chosunSubhead)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }

                            if let stock = specialItem.stock {
                                HStack {
                                    Text("재고:")
                                        .font(.chosunSubhead)
                                    Spacer()
                                    Text("\(stock)개")
                                        .font(.chosunSubhead)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                            }

                            Divider()

                            HStack {
                                Text("가격:")
                                    .font(.chosunH2)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(specialItem.displayPrice)
                                    .font(.chosunH2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    // Purchase Button
                    Button(action: {
                        // Purchase action
                    }) {
                        Text("구매하기")
                            .font(.chosunButton)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("아이템 상세")
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