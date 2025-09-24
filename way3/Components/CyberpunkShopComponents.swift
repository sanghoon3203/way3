//
//  CyberpunkShopComponents.swift
//  way3 - Way Trading Game
//
//  사이버펑크 스타일 상점 컴포넌트들
//  기존 ShopView 기능을 완전히 유지하면서 사이버펑크 테마 적용
//

import SwiftUI

// MARK: - Cyberpunk Tab Button
struct CyberpunkTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .cyberpunkYellow : .cyberpunkTextSecondary)

                Text(title)
                    .font(.cyberpunkTechnical())
                    .foregroundColor(isSelected ? .cyberpunkYellow : .cyberpunkTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.cyberpunkYellow.opacity(0.1) : Color.clear)
                    .overlay(
                        Rectangle()
                            .fill(Color.cyberpunkYellow)
                            .frame(height: isSelected ? 2 : 0),
                        alignment: .bottom
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Cyberpunk Secret Shop View
struct CyberpunkSecretShopView: View {
    let specialItems: [SpecialItem]
    let adBanners: [AdBanner]
    let onItemTap: (SpecialItem) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                CyberpunkSectionHeader(
                    title: "NEO-SEOUL_BLACK_MARKET",
                    subtitle: "RESTRICTED_ACCESS_TERMINAL",
                    rightContent: "STATUS: ONLINE"
                )
                .padding(.top, 20)

                // Status Panel
                CyberpunkStatusPanel(
                    title: "MARKET_STATUS",
                    statusItems: [
                        ("CONNECTION", "SECURE", .cyberpunkGreen),
                        ("ENCRYPTION", "MILITARY_GRADE", .cyberpunkCyan),
                        ("BALANCE", "₩\(getCurrentMoney())", .cyberpunkGreen),
                        ("ACCESS_LEVEL", "PREMIUM", .cyberpunkYellow)
                    ]
                )
                .padding(.horizontal, CyberpunkLayout.screenPadding)

                // Advertisement Banner - 사이버펑크 스타일
                if !adBanners.isEmpty {
                    TabView {
                        ForEach(adBanners) { banner in
                            CyberpunkAdBanner(banner: banner)
                        }
                    }
                    .frame(height: 120)
                    .tabViewStyle(PageTabViewStyle())
                }

                // Special Items Section
                VStack(alignment: .leading, spacing: 16) {
                    CyberpunkSectionHeader(
                        title: "SPECIAL_ITEMS",
                        subtitle: "ENHANCED_EQUIPMENT_CATALOG"
                    )

                    // Items Grid
                    CyberpunkInventoryGrid(
                        items: specialItems,
                        columns: 2,
                        emptySlots: 2
                    ) { item in
                        CyberpunkSpecialItemCard(specialItem: item) {
                            onItemTap(item)
                        }
                    }
                    .padding(.horizontal, CyberpunkLayout.screenPadding)
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

// MARK: - Cyberpunk Advertisement Banner
struct CyberpunkAdBanner: View {
    let banner: AdBanner

    var body: some View {
        HStack(spacing: 16) {
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(banner.title.uppercased())
                    .font(.cyberpunkHeading())
                    .foregroundColor(.cyberpunkTextPrimary)
                    .fontWeight(.bold)

                Text(banner.subtitle.uppercased())
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkTextSecondary)

                Rectangle()
                    .fill(Color.cyberpunkYellow)
                    .frame(width: 40, height: 2)
            }

            Spacer()

            // Icon
            Image(systemName: banner.imageName)
                .font(.system(size: 32))
                .foregroundColor(.cyberpunkCyan)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            LinearGradient(
                colors: [
                    banner.backgroundColor.opacity(0.3),
                    Color.cyberpunkDarkBg
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cyberpunkCard()
        .padding(.horizontal, CyberpunkLayout.screenPadding)
    }
}

// MARK: - Cyberpunk Special Item Card
struct CyberpunkSpecialItemCard: View {
    let specialItem: SpecialItem
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Header
                HStack {
                    Text("SI_\(String(specialItem.id.uuidString.prefix(4)))")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)

                    Spacer()

                    if specialItem.isLimited {
                        Text("LIMITED")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkError)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Rectangle()
                                    .fill(Color.cyberpunkError.opacity(0.2))
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.cyberpunkError, lineWidth: 0.5)
                                    )
                            )
                    }
                }

                // Item Image
                ZStack {
                    Rectangle()
                        .fill(specialItem.grade.cyberpunkColor.opacity(0.1))
                        .frame(height: 60)
                        .overlay(
                            Rectangle()
                                .stroke(specialItem.grade.cyberpunkColor.opacity(0.6), lineWidth: 1)
                        )

                    Image(systemName: specialItem.imageName)
                        .font(.system(size: 28))
                        .foregroundColor(specialItem.grade.cyberpunkColor)
                }

                // Item Info
                VStack(spacing: 4) {
                    Text(specialItem.name.uppercased())
                        .font(.cyberpunkCaption())
                        .fontWeight(.semibold)
                        .foregroundColor(.cyberpunkTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    // Grade
                    Text(specialItem.grade.displayName.uppercased())
                        .font(.cyberpunkTechnical())
                        .foregroundColor(specialItem.grade.cyberpunkColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Rectangle()
                                .fill(specialItem.grade.cyberpunkColor.opacity(0.2))
                                .overlay(
                                    Rectangle()
                                        .stroke(specialItem.grade.cyberpunkColor.opacity(0.6), lineWidth: 0.5)
                                )
                        )

                    // Effect
                    Text(specialItem.specialEffect.uppercased())
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkCyan)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)

                    // Stock
                    if let stock = specialItem.stock {
                        Text("STOCK: \(stock)")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkYellow)
                    }

                    // Price
                    Text(specialItem.displayPrice)
                        .font(.cyberpunkCaption())
                        .fontWeight(.bold)
                        .foregroundColor(.cyberpunkGreen)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 180)
            .cyberpunkGridSlot(isSelected: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: CGFloat.infinity, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        }, perform: {})
    }
}

// MARK: - Cyberpunk Auction View
struct CyberpunkAuctionView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                CyberpunkSectionHeader(
                    title: "AUCTION_TERMINAL",
                    subtitle: "DECENTRALIZED_TRADING_PLATFORM",
                    rightContent: "STATUS: BETA"
                )
                .padding(.top, 40)

                // Status Icon
                Image(systemName: "hammer.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.cyberpunkYellow)

                // Status Panel
                CyberpunkStatusPanel(
                    title: "SYSTEM_STATUS",
                    statusItems: [
                        ("IMPLEMENTATION", "FRONTEND_ONLY", .cyberpunkYellow),
                        ("BACKEND", "IN_DEVELOPMENT", .cyberpunkError),
                        ("ETA", "Q2_2024", .cyberpunkCyan)
                    ]
                )
                .padding(.horizontal, CyberpunkLayout.screenPadding)

                // Sample Auction Items
                VStack(alignment: .leading, spacing: 16) {
                    Text("ACTIVE_AUCTIONS_[SIMULATION]")
                        .font(.cyberpunkHeading())
                        .foregroundColor(.cyberpunkTextPrimary)
                        .padding(.horizontal, CyberpunkLayout.screenPadding)

                    LazyVStack(spacing: 12) {
                        CyberpunkAuctionItemPreview(
                            name: "RARE_CERAMIC_SET",
                            currentBid: 450000,
                            timeLeft: "02:15:00",
                            bidders: 12
                        )

                        CyberpunkAuctionItemPreview(
                            name: "PREMIUM_TEA_COLLECTION",
                            currentBid: 180000,
                            timeLeft: "00:45:00",
                            bidders: 8
                        )

                        CyberpunkAuctionItemPreview(
                            name: "VINTAGE_TIMEPIECE",
                            currentBid: 1200000,
                            timeLeft: "1D:03:00",
                            bidders: 24
                        )
                    }
                    .padding(.horizontal, CyberpunkLayout.screenPadding)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Cyberpunk Auction Item Preview
struct CyberpunkAuctionItemPreview: View {
    let name: String
    let currentBid: Int
    let timeLeft: String
    let bidders: Int

    var body: some View {
        HStack(spacing: 12) {
            // Item Icon
            ZStack {
                Rectangle()
                    .fill(Color.cyberpunkYellow.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(Color.cyberpunkYellow.opacity(0.6), lineWidth: 1)
                    )

                Image(systemName: "photo.artframe")
                    .font(.system(size: 24))
                    .foregroundColor(.cyberpunkYellow)
            }

            // Item Info
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.cyberpunkCaption())
                    .fontWeight(.semibold)
                    .foregroundColor(.cyberpunkTextPrimary)

                CyberpunkDataDisplay(
                    label: "BID",
                    value: "₩\(currentBid)",
                    valueColor: .cyberpunkGreen
                )

                CyberpunkDataDisplay(
                    label: "TIME",
                    value: timeLeft,
                    valueColor: .cyberpunkYellow
                )
            }

            Spacer()

            // Bidders Count
            VStack(alignment: .center, spacing: 2) {
                Text("\(bidders)")
                    .font(.cyberpunkHeading())
                    .fontWeight(.bold)
                    .foregroundColor(.cyberpunkCyan)

                Text("BIDDERS")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)
            }
        }
        .padding(12)
        .cyberpunkCard()
    }
}

// MARK: - Cyberpunk Special Item Detail Sheet
struct CyberpunkSpecialItemDetailSheet: View {
    let specialItem: SpecialItem
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color.cyberpunkDarkBg
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Item Display
                        VStack(spacing: 16) {
                            ZStack {
                                Rectangle()
                                    .fill(specialItem.grade.cyberpunkColor.opacity(0.1))
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        Rectangle()
                                            .stroke(specialItem.grade.cyberpunkColor, lineWidth: 2)
                                    )

                                Image(systemName: specialItem.imageName)
                                    .font(.system(size: 60))
                                    .foregroundColor(specialItem.grade.cyberpunkColor)
                            }

                            Text(specialItem.name.uppercased())
                                .font(.cyberpunkTitle())
                                .foregroundColor(.cyberpunkTextPrimary)
                                .fontWeight(.bold)

                            Text(specialItem.description)
                                .font(.cyberpunkBody())
                                .foregroundColor(.cyberpunkTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        // Item Specifications
                        CyberpunkStatusPanel(
                            title: "ITEM_SPECIFICATIONS",
                            statusItems: [
                                ("GRADE", specialItem.grade.displayName.uppercased(), specialItem.grade.cyberpunkColor),
                                ("EFFECT", specialItem.specialEffect.uppercased(), .cyberpunkCyan),
                                ("PRICE", specialItem.displayPrice, .cyberpunkGreen),
                                ("STOCK", specialItem.stock != nil ? "\(specialItem.stock!) UNITS" : "UNLIMITED", .cyberpunkYellow),
                                ("LIMITED", specialItem.isLimited ? "YES" : "NO", specialItem.isLimited ? .cyberpunkError : .cyberpunkGreen),
                                ("ID", "SI_\(String(specialItem.id.uuidString.prefix(8)))", .cyberpunkTextSecondary)
                            ]
                        )

                        Spacer(minLength: 20)

                        // Purchase Button
                        CyberpunkButton(
                            title: "PURCHASE_ITEM",
                            style: .primary
                        ) {
                            // Purchase action - 기존 기능 유지
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.horizontal, CyberpunkLayout.screenPadding)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("ITEM_ANALYSIS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("CLOSE") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.cyberpunkYellow)
                    .font(.cyberpunkCaption())
                }
            }
        }
        .accentColor(.cyberpunkYellow)
    }
}

// MARK: - Extensions for SpecialItem
extension SpecialItem {
    var cyberpunkColor: Color {
        return grade.cyberpunkColor
    }
}