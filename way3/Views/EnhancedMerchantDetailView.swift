//
//  EnhancedMerchantDetailView.swift
//  way3 - Enhanced Merchant Interaction Interface
//
//  Pokemon GO 스타일의 상인 상호작용 인터페이스
//

import SwiftUI
import CoreLocation

struct EnhancedMerchantDetailView: View {
    let merchant: EnhancedMerchant
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var socketManager: SocketManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var inventory: [MerchantItem] = []
    @State private var selectedItem: MerchantItem?
    @State private var showTradeConfirmation = false
    @State private var negotiationInProgress = false
    @State private var currentOffer: Int = 0
    @State private var maxNegotiationRounds = 3
    @State private var negotiationRound = 0
    
    // 임시 인벤토리 데이터
    private let sampleInventory: [MerchantItem] = [
        MerchantItem(id: "1", name: "스마트폰", category: "electronics", grade: 2, basePrice: 800000, currentPrice: 850000, quantity: 3, description: "최신 스마트폰"),
        MerchantItem(id: "2", name: "노트북", category: "electronics", grade: 3, basePrice: 1500000, currentPrice: 1680000, quantity: 1, description: "고성능 노트북"),
        MerchantItem(id: "3", name: "이어폰", category: "electronics", grade: 1, basePrice: 150000, currentPrice: 140000, quantity: 5, description: "무선 이어폰")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상인 헤더
                merchantHeader
                
                // 탭 선택기
                tabSelector
                
                // 탭 컨텐츠
                TabView(selection: $selectedTab) {
                    // 인벤토리
                    inventoryView
                        .tag(0)
                    
                    // 상인 정보
                    merchantInfoView
                        .tag(1)
                    
                    // 거래 기록
                    tradeHistoryView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showTradeConfirmation) {
            if let item = selectedItem {
                TradeNegotiationView(
                    merchant: merchant,
                    item: item,
                    onTradeComplete: handleTradeComplete
                )
            }
        }
        .onAppear {
            loadMerchantData()
        }
    }
    
    // MARK: - Merchant Header
    private var merchantHeader: some View {
        VStack(spacing: 0) {
            // 상단 컨트롤
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                
                Spacer()
                
                Button(action: shareMerchant) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
            }
            .padding()
            .zIndex(1)
            
            // 상인 정보 카드
            VStack(spacing: 16) {
                // 상인 아바타
                ZStack {
                    Circle()
                        .fill(merchant.type.color.opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .fill(merchant.type.color)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: merchant.type.icon)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // 상인 정보
                VStack(spacing: 8) {
                    Text(merchant.name)
                        .font(.chosunTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(merchant.title)
                        .font(.chosunBody)
                        .foregroundColor(.white.opacity(0.9))
                    
                    // 거리 및 상태
                    HStack(spacing: 16) {
                        if let distance = merchant.distanceFromPlayer {
                            Label("\(Int(distance))m", systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Label(merchant.district.displayName, systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // 협상 난이도
                    HStack {
                        Text("협상 난이도:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < merchant.negotiationDifficulty ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [merchant.district.color, merchant.district.color.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 4) {
                        Text(tabTitle(for: index))
                            .font(.chosunBody)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                        
                        Rectangle()
                            .fill(selectedTab == index ? merchant.type.color : Color.clear)
                            .frame(height: 2)
                    }
                }
                .foregroundColor(selectedTab == index ? .primary : .secondary)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Inventory View
    private var inventoryView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(inventory) { item in
                    MerchantItemCard(item: item) {
                        selectedItem = item
                        showTradeConfirmation = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Merchant Info View
    private var merchantInfoView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 기본 정보
                merchantInfoSection
                
                // 특화 정보
                merchantSpecialtySection
                
                // 거래 조건
                tradingConditionsSection
                
                // 평판 정보
                reputationSection
            }
            .padding()
        }
    }
    
    // MARK: - Trade History View
    private var tradeHistoryView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 최근 거래 통계
                tradeStatsSection
                
                // 거래 기록 목록
                if socketManager.recentTradeActivity.isEmpty {
                    emptyTradeHistoryView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(socketManager.recentTradeActivity.prefix(10)) { activity in
                            TradeHistoryRow(activity: activity)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Supporting Views
    private var merchantInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상인 정보")
                .font(.chosunHeadline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                infoRow("전문 분야", value: merchant.type.description)
                infoRow("가격 조정률", value: String(format: "%.0f%%", (merchant.priceModifier - 1) * 100))
                infoRow("필요 평판", value: "\(merchant.reputationRequirement)점")
                infoRow("운영 시간", value: "24시간")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var merchantSpecialtySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("전문 영역")
                .font(.chosunHeadline)
                .fontWeight(.bold)
            
            Text(merchant.type.specialtyDescription)
                .font(.chosunBody)
                .foregroundColor(.secondary)
            
            // 취급 카테고리
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(merchant.type.categories, id: \.self) { category in
                    Text(category)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(merchant.type.color.opacity(0.2))
                        )
                        .foregroundColor(merchant.type.color)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var tradingConditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("거래 조건")
                .font(.chosunHeadline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                conditionRow("최대 협상 횟수", value: "\(maxNegotiationRounds)회")
                conditionRow("거래 가능 거리", value: "400m 이내")
                conditionRow("결제 방식", value: "즉시 결제")
                conditionRow("교환/환불", value: "불가")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var reputationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("평판 정보")
                .font(.chosunHeadline)
                .fontWeight(.bold)
            
            // 평판 점수 (임시 데이터)
            VStack(spacing: 8) {
                HStack {
                    Text("신뢰도")
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < 4 ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                HStack {
                    Text("거래 성사율")
                    Spacer()
                    Text("87%")
                        .fontWeight(.semibold)
                        .foregroundColor(.gameGreen)
                }
                
                HStack {
                    Text("총 거래 횟수")
                    Spacer()
                    Text("1,234회")
                        .fontWeight(.semibold)
                }
            }
            .font(.chosunBody)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var tradeStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("거래 통계")
                .font(.chosunHeadline)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                VStack {
                    Text("24")
                        .font(.chosunTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.gameBlue)
                    
                    Text("오늘 거래")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("156")
                        .font(.chosunTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.gameGreen)
                    
                    Text("이번 주")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("89%")
                        .font(.chosunTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.gamePurple)
                    
                    Text("성공률")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var emptyTradeHistoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("최근 거래 내역이 없습니다")
                .font(.chosunHeadline)
                .fontWeight(.semibold)
            
            Text("이 상인과의 거래가 시작되면\\n여기에 표시됩니다")
                .font(.chosunBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Helper Views
    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.chosunBody)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.chosunBody)
                .fontWeight(.medium)
        }
    }
    
    private func conditionRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.chosunBody)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.chosunBody)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Methods
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "상품 (\(inventory.count))"
        case 1: return "정보"
        case 2: return "거래내역"
        default: return ""
        }
    }
    
    private func loadMerchantData() {
        // 실제로는 서버에서 데이터를 가져옴
        inventory = sampleInventory
        maxNegotiationRounds = 5 - merchant.negotiationDifficulty
    }
    
    private func shareMerchant() {
        // 상인 정보 공유 기능
        print("상인 정보 공유: \(merchant.name)")
    }
    
    private func handleTradeComplete(_ item: MerchantItem, finalPrice: Int) {
        // 거래 완료 처리
        socketManager.broadcastTradeCompletion(
            playerId: gameManager.player.id,
            merchantId: merchant.id,
            itemName: item.name,
            tradeType: "buy",
            amount: finalPrice,
            isProfit: finalPrice < item.basePrice
        )
        
        // 인벤토리에서 해당 아이템 수량 감소
        if let index = inventory.firstIndex(where: { $0.id == item.id }) {
            inventory[index].quantity -= 1
            if inventory[index].quantity <= 0 {
                inventory.remove(at: index)
            }
        }
        
        dismiss()
    }
}

// MARK: - Merchant Item Card
struct MerchantItemCard: View {
    let item: MerchantItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 아이템 이미지 (임시)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.gradeColor.opacity(0.3))
                        .frame(height: 80)
                    
                    Image(systemName: item.categoryIcon)
                        .font(.system(size: 24))
                        .foregroundColor(item.gradeColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.chosunBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(formatMoney(item.currentPrice))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gameGreen)
                        
                        Spacer()
                        
                        Text("×\(item.quantity)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // 등급 표시
                    Text("등급 \(item.grade)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(item.gradeColor.opacity(0.2))
                        )
                        .foregroundColor(item.gradeColor)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(item.quantity <= 0)
        .opacity(item.quantity <= 0 ? 0.5 : 1.0)
    }
    
    private func formatMoney(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "0")원"
    }
}

// MARK: - Data Models
struct MerchantItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let grade: Int
    let basePrice: Int
    let currentPrice: Int
    var quantity: Int
    let description: String
    
    var gradeColor: Color {
        switch grade {
        case 0: return .gray
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
    
    var categoryIcon: String {
        switch category {
        case "electronics": return "laptopcomputer"
        case "clothing": return "tshirt"
        case "food": return "leaf"
        case "arts": return "paintbrush"
        case "antiques": return "crown"
        default: return "cube"
        }
    }
}

// MARK: - Trade History Row
struct TradeHistoryRow: View {
    let activity: SocketManager.TradeActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.isProfit ? Color.gameGreen : Color.gameBlue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(activity.playerName)님이 \(activity.itemName) \(activity.tradeType == "buy" ? "구매" : "판매")")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(activity.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.isProfit ? "💰" : "📈")
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Merchant Type Extensions
extension EnhancedMerchant.MerchantType {
    var description: String {
        switch self {
        case .electronics: return "전자제품 전문"
        case .cultural: return "문화재 감정"
        case .antique: return "골동품 거래"
        case .artist: return "예술 작품"
        case .craftsman: return "전통 공예"
        case .scholar: return "고서 및 문헌"
        case .foodMaster: return "전통 음식"
        case .trader: return "국제 무역"
        case .importer: return "수입품 전문"
        }
    }
    
    var specialtyDescription: String {
        switch self {
        case .electronics:
            return "최신 기술 제품부터 구형 전자기기까지 폭넓은 전자제품을 취급합니다. 기술적 지식이 풍부하여 제품의 성능과 가치를 정확히 평가할 수 있습니다."
        case .cultural:
            return "한국 전통 문화재와 공예품 전문가입니다. 오랜 경험을 바탕으로 문화재의 진위와 가치를 감정하며, 전통의 가치를 소중히 여깁니다."
        case .antique:
            return "희귀한 골동품과 고미술품을 전문으로 합니다. 까다로운 안목으로 진품을 선별하며, 높은 수준의 컬렉션을 보유하고 있습니다."
        default:
            return "다양한 분야의 전문 지식을 보유한 상인입니다."
        }
    }
    
    var categories: [String] {
        switch self {
        case .electronics:
            return ["스마트폰", "컴퓨터", "게임기", "오디오"]
        case .cultural:
            return ["도자기", "서예", "한지", "민화"]
        case .antique:
            return ["고서", "청자", "백자", "고가구"]
        case .artist:
            return ["회화", "조각", "현대미술", "설치미술"]
        case .craftsman:
            return ["목공예", "금속공예", "섬유공예", "도예"]
        case .scholar:
            return ["고서", "문헌", "필사본", "학술서"]
        case .foodMaster:
            return ["전통주", "발효식품", "건어물", "약재"]
        case .trader:
            return ["수입품", "원자재", "가공품", "공산품"]
        case .importer:
            return ["해외명품", "수입식품", "공예품", "잡화"]
        }
    }
}

#Preview {
    EnhancedMerchantDetailView(
        merchant: EnhancedMerchant(
            id: "1",
            name: "김테크",
            title: "전자제품 전문가",
            type: .electronics,
            location: CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276),
            district: .gangnam,
            priceModifier: 1.2,
            negotiationDifficulty: 4,
            reputationRequirement: 50,
            distanceFromPlayer: 250
        )
    )
    .environmentObject(NetworkManager.shared)
    .environmentObject(SocketManager.shared)
}