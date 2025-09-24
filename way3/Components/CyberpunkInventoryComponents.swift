//
//  CyberpunkInventoryComponents.swift
//  way3 - Way Trading Game
//
//  사이버펑크 스타일 인벤토리 컴포넌트들
//  기존 InventoryView 기능을 완전히 유지하면서 사이버펑크 테마 적용
//

import SwiftUI

// MARK: - Cyberpunk Trade Good Card
struct CyberpunkTradeGoodCard: View {
    let tradeGood: TradeGood
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Header with ID and Grade
                HStack {
                    Text("TG_\(String(tradeGood.id.uuidString.prefix(4)))")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)

                    Spacer()

                    Text(tradeGood.grade.displayName.uppercased())
                        .font(.cyberpunkTechnical())
                        .foregroundColor(tradeGood.grade.cyberpunkColor)
                }

                // Item Image
                ZStack {
                    Rectangle()
                        .fill(tradeGood.grade.cyberpunkColor.opacity(0.1))
                        .frame(height: 60)
                        .overlay(
                            Rectangle()
                                .stroke(tradeGood.grade.cyberpunkColor.opacity(0.6), lineWidth: 1)
                        )

                    Image(systemName: tradeGood.imageName)
                        .font(.system(size: 28))
                        .foregroundColor(tradeGood.grade.cyberpunkColor)
                }

                // Item Info
                VStack(spacing: 4) {
                    Text(tradeGood.name.uppercased())
                        .font(.cyberpunkCaption())
                        .fontWeight(.semibold)
                        .foregroundColor(.cyberpunkTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(tradeGood.category.uppercased())
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkTextSecondary)

                    // Data displays
                    VStack(spacing: 2) {
                        CyberpunkDataDisplay(
                            label: "PRICE",
                            value: "₩\(tradeGood.basePrice)",
                            valueColor: .cyberpunkGreen
                        )

                        CyberpunkDataDisplay(
                            label: "QTY",
                            value: "\(tradeGood.quantity)",
                            valueColor: .cyberpunkCyan
                        )

                        CyberpunkDataDisplay(
                            label: "TOTAL",
                            value: "₩\(tradeGood.basePrice * tradeGood.quantity)",
                            valueColor: .cyberpunkYellow
                        )
                    }
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


// MARK: - Cyberpunk Trade Good Detail Sheet
struct CyberpunkTradeGoodDetailSheet: View {
    let tradeGood: TradeGood
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color.cyberpunkDarkBg
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Item Image and Header
                        VStack(spacing: 16) {
                            ZStack {
                                Rectangle()
                                    .fill(tradeGood.grade.cyberpunkColor.opacity(0.1))
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        Rectangle()
                                            .stroke(tradeGood.grade.cyberpunkColor, lineWidth: 2)
                                    )

                                Image(systemName: tradeGood.imageName)
                                    .font(.system(size: 60))
                                    .foregroundColor(tradeGood.grade.cyberpunkColor)
                            }

                            Text(tradeGood.name.uppercased())
                                .font(.cyberpunkTitle())
                                .foregroundColor(.cyberpunkTextPrimary)
                                .fontWeight(.bold)
                        }

                        // Technical Info Panel
                        CyberpunkStatusPanel(
                            title: "ITEM_SPECIFICATIONS",
                            statusItems: [
                                ("CATEGORY", tradeGood.category.uppercased(), .cyberpunkCyan),
                                ("GRADE", tradeGood.grade.displayName.uppercased(), tradeGood.grade.cyberpunkColor),
                                ("UNIT_PRICE", "₩\(tradeGood.basePrice)", .cyberpunkGreen),
                                ("QUANTITY", "\(tradeGood.quantity) UNITS", .cyberpunkYellow),
                                ("TOTAL_VALUE", "₩\(tradeGood.basePrice * tradeGood.quantity)", .cyberpunkGreen),
                                ("ITEM_ID", "TG_\(String(tradeGood.id.uuidString.prefix(8)))", .cyberpunkTextSecondary)
                            ]
                        )

                        Spacer(minLength: 20)

                        // Action Buttons
                        VStack(spacing: 12) {
                            CyberpunkButton(
                                title: "SELL_ALL",
                                style: .success
                            ) {
                                // Sell all action - 기존 기능 유지
                                presentationMode.wrappedValue.dismiss()
                            }

                            CyberpunkButton(
                                title: "PARTIAL_SELL",
                                style: .secondary
                            ) {
                                // Partial sell action - 기존 기능 유지
                                presentationMode.wrappedValue.dismiss()
                            }

                            CyberpunkButton(
                                title: "CANCEL",
                                style: .disabled
                            ) {
                                presentationMode.wrappedValue.dismiss()
                            }
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

// MARK: - Extensions for TradeGood
extension TradeGood {
    // 기존 TradeGood에 사이버펑크 색상 지원 추가
    var cyberpunkColor: Color {
        return grade.cyberpunkColor
    }
}