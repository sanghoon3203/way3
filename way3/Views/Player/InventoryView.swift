
// 📁 Views/Inventory/InventoryView.swift - 수묵화 스타일 인벤토리 화면
import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSellSheet = false
    @State private var selectedItem: TradeItem?
    @State private var sampleItems: [TradeItem] = [
        TradeItem(itemId: "i1", name: "스마트폰", category: "전자제품", grade: .rare, requiredLicense: .intermediate, basePrice: 800000, description: "최신 스마트폰"),
        TradeItem(itemId: "i2", name: "노트북", category: "전자제품", grade: .legendary, requiredLicense: .advanced, basePrice: 1500000, description: "게이밍 노트북"),
        TradeItem(itemId: "i3", name: "한우", category: "식품", grade: .rare, requiredLicense: .intermediate, basePrice: 50000, description: "1등급 한우")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 기본 배경
                LinearGradient(colors: [Color.gray.opacity(0.1), Color.white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 상단 정보
                    VStack {
                        Text("인벤토리 (\(sampleItems.count)/50)")
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.semibold)
                        Text("총 가치: ₩\(calculateTotalValue())")
                            .font(.custom("ChosunCentennial", size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    if sampleItems.isEmpty {
                        // 빈 상태
                        VStack(spacing: 20) {
                            Image(systemName: "backpack")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("인벤토리가 비어있습니다")
                                .font(.custom("ChosunCentennial", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                    } else {
                        // 아이템 그리드
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150))
                        ], spacing: 16) {
                            ForEach(sampleItems) { item in
                                VStack(spacing: 8) {
                                    // 아이템 아이콘
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(item.grade.color.opacity(0.2))
                                            .frame(height: 80)

                                        Image(systemName: getItemIcon(for: item.category))
                                            .font(.system(size: 30))
                                            .foregroundColor(item.grade.color)
                                    }

                                    Text(item.name)
                                        .font(.custom("ChosunCentennial", size: 16))
                                        .fontWeight(.semibold)
                                        .lineLimit(1)

                                    Text("₩\(item.currentPrice)")
                                        .font(.custom("ChosunCentennial", size: 14))
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)

                                    Text(item.grade.displayName)
                                        .font(.custom("ChosunCentennial", size: 12))
                                        .foregroundColor(item.grade.color)
                                        .fontWeight(.medium)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(radius: 2)
                                )
                                .onTapGesture {
                                    selectedItem = item
                                    showingSellSheet = true
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("무역품")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedItem) { item in
            NavigationView {
                VStack(spacing: 20) {
                    // 아이템 이미지
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(item.grade.color.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: getItemIcon(for: item.category))
                            .font(.system(size: 50))
                            .foregroundColor(item.grade.color)
                    }

                    VStack(spacing: 12) {
                        Text(item.name)
                            .font(.custom("ChosunCentennial", size: 24))
                            .fontWeight(.bold)

                        Text(item.grade.displayName)
                            .font(.custom("ChosunCentennial", size: 16))
                            .foregroundColor(item.grade.color)
                            .fontWeight(.semibold)

                        Text("₩\(item.currentPrice)")
                            .font(.custom("ChosunCentennial", size: 20))
                            .foregroundColor(.blue)
                            .fontWeight(.bold)

                        Text(item.description)
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    Button("판매하기") {
                        // 판매 로직
                        selectedItem = nil
                    }
                    .font(.custom("ChosunCentennial", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding()
                .navigationTitle("아이템 정보")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("닫기") {
                            selectedItem = nil
                        }
                        .font(.custom("ChosunCentennial", size: 16))
                    }
                }
            }
        }
    }

    private func calculateTotalValue() -> Int {
        sampleItems.reduce(0) { $0 + $1.currentPrice }
    }

    private func getItemIcon(for category: String) -> String {
        switch category.lowercased() {
        case "전자제품": return "laptopcomputer"
        case "식품": return "leaf.fill"
        case "의류": return "tshirt.fill"
        case "보석": return "gem"
        case "도구": return "wrench.fill"
        case "차량": return "car.fill"
        default: return "cube.fill"
        }
    }
}

// MARK: - 수묵화 스타일 인벤토리 헤더 카드
/*
// 커스텀 UI 컴포넌트들은 임시로 주석 처리
struct InkInventoryHeaderCard: View {
    let itemCount: Int
    let maxItems: Int
    let totalValue: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                Text("무역품 현황")
                    .font(.brushStroke)
                    .foregroundColor(.brushText)
                
                Spacer()
                
                Text("\(itemCount) / \(maxItems)")
                    .font(.inkText)
                    .foregroundColor(.fadeText)
            }
            
            // 용량 표시 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.inkMist.opacity(0.3))
                        .frame(height: 12)
                    
                    // 진행률
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: itemCount >= maxItems ? 
                                [Color.compass.opacity(0.7), Color.compass] : 
                                [Color.brushText.opacity(0.6), Color.brushText],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * min(Double(itemCount) / Double(maxItems), 1.0),
                            height: 12
                        )
                        .animation(.easeInOut(duration: 0.3), value: itemCount)
                }
            }
            .frame(height: 12)
            
            // 총 가치
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.brushText.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text("총 가치")
                        .font(.inkText)
                        .foregroundColor(.brushText)
                }
                
                Spacer()
                
                Text("\(totalValue) 전")
                    .font(.brushStroke)
                    .fontWeight(.medium)
                    .foregroundColor(.brushText)
            }
        }
        .inkCard()
    }
}

// MARK: - 수묵화 스타일 빈 인벤토리 뷰
struct InkEmptyInventoryView: View {
    var body: some View {
        VStack(spacing: 24) {
            // 빈 상태 아이콘
            ZStack {
                Circle()
                    .fill(Color.softWhite)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.inkBlack.opacity(0.2), lineWidth: 2)
                    )
                
                Image(systemName: "bag")
                    .font(.system(size: 60))
                    .foregroundColor(.brushText.opacity(0.5))
            }
            .shadow(color: Color.inkMist.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 12) {
                Text("무역품이 없습니다")
                    .font(.brushStroke)
                    .foregroundColor(.brushText)
                
                Text("상인들과 거래하여 무역품을 수집해보세요")
                    .font(.inkText)
                    .foregroundColor(.fadeText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inkCard()
    }
}

// MARK: - 수묵화 스타일 인벤토리 그리드 뷰
struct InkInventoryGridView: View {
    let items: [TradeItem]
    let onItemTap: (TradeItem) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items, id: \.id) { item in
                    InkInventoryItemCard(
                        item: item,
                        onTap: { onItemTap(item) }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - 수묵화 스타일 인벤토리 아이템 카드
struct InkInventoryItemCard: View {
    let item: TradeItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 아이템 아이콘 영역
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.softWhite)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.inkBlack.opacity(0.1), lineWidth: 1)
                        )
                    
                    // 임시 아이콘 (실제로는 아이템 이미지)
                    Image(systemName: itemIcon(for: item.category))
                        .font(.system(size: 32))
                        .foregroundColor(.brushText.opacity(0.7))
                }
                
                // 아이템 정보
                VStack(spacing: 4) {
                    Text(item.name)
                        .font(.inkText)
                        .fontWeight(.medium)
                        .foregroundColor(.brushText)
                        .lineLimit(1)
                    
                    Text("\(item.currentPrice) 전")
                        .font(.whisperText)
                        .foregroundColor(.fadeText)
                    
                    // 수량 (여러 개인 경우)
                    if item.quantity > 1 {
                        Text("x\(item.quantity)")
                            .font(.whisperText)
                            .foregroundColor(.brushText.opacity(0.6))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.softWhite.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.inkBlack.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.inkMist.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func itemIcon(for category: String) -> String {
        switch category.lowercased() {
        case "it부품", "전자제품": return "laptopcomputer"
        case "명품", "luxury": return "crown.fill"
        case "의류", "clothing": return "tshirt.fill"
        case "음식", "food": return "leaf.fill"
        case "도구", "tools": return "wrench.fill"
        case "의약품", "medicine": return "pills.fill"
        case "차량", "vehicle": return "car.fill"
        case "부동산", "property": return "house.fill"
        default: return "shippingbox.fill"
        }
    }
}

// =====================================
*/
