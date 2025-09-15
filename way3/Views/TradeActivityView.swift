//
//  TradeActivityView.swift
//  way3 - Real-time Trade Activity Feed
//
//  실시간 거래 활동 피드 및 시장 동향 분석
//

import SwiftUI

struct TradeActivityView: View {
    @EnvironmentObject var socketManager: SocketManager
    @StateObject private var districtManager = DistrictManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var selectedDistrict: DistrictManager.GameDistrict = .gangnam
    
    var body: some View {
        NavigationView {
            VStack {
                // 탭 선택기
                Picker("활동 유형", selection: $selectedTab) {
                    Text("실시간").tag(0)
                    Text("지역별").tag(1)
                    Text("가격 동향").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 탭 컨텐츠
                TabView(selection: $selectedTab) {
                    // 실시간 활동
                    realTimeActivityView
                        .tag(0)
                    
                    // 지역별 활동
                    districtActivityView
                        .tag(1)
                    
                    // 가격 동향
                    priceActivityView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("거래 활동")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
    
    // MARK: - Real-time Activity View
    private var realTimeActivityView: some View {
        Group {
            if socketManager.recentTradeActivity.isEmpty {
                emptyActivityState
            } else {
                List {
                    ForEach(socketManager.recentTradeActivity) { activity in
                        TradeActivityRow(activity: activity)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - District Activity View
    private var districtActivityView: some View {
        VStack {
            // 지역 선택기
            Picker("지역 선택", selection: $selectedDistrict) {
                ForEach(DistrictManager.GameDistrict.allCases.filter { $0 != .other }, id: \\.self) { district in
                    Text(district.displayName).tag(district)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            // 선택된 지역의 활동
            if districtManager.districtActivity.filter({ $0.district == selectedDistrict }).isEmpty {
                emptyDistrictState
            } else {
                List {
                    Section(header: districtInfoHeader) {
                        ForEach(districtManager.districtActivity.filter { $0.district == selectedDistrict }) { activity in
                            DistrictActivityRow(activity: activity)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    // MARK: - Price Activity View
    private var priceActivityView: some View {
        Group {
            if socketManager.marketPriceUpdates.isEmpty {
                emptyPriceState
            } else {
                List {
                    Section(header: Text("시장 가격 변동")
                        .font(.chosunHeadline)
                        .foregroundColor(.primary)
                    ) {
                        ForEach(socketManager.marketPriceUpdates) { update in
                            PriceUpdateRow(update: update)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    // MARK: - Empty States
    private var emptyActivityState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("최근 거래 활동이 없습니다")
                .font(.chosunHeadline)
                .fontWeight(.semibold)
            
            Text("다른 플레이어들의 거래가 시작되면\\n실시간으로 표시됩니다")
                .font(.chosunBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var emptyDistrictState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text(selectedDistrict.emoji)
                .font(.system(size: 60))
            
            Text("\\(selectedDistrict.displayName)에서 활동이 없습니다")
                .font(.chosunHeadline)
                .fontWeight(.semibold)
            
            Text("이 지역에서 거래가 발생하면\\n활동이 표시됩니다")
                .font(.chosunBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("다른 지역 보기") {
                // 다음 지역으로 순환
                let districts = DistrictManager.GameDistrict.allCases.filter { $0 != .other }
                if let currentIndex = districts.firstIndex(of: selectedDistrict) {
                    let nextIndex = (currentIndex + 1) % districts.count
                    selectedDistrict = districts[nextIndex]
                }
            }
            .buttonStyle(.bordered)
            .tint(selectedDistrict.color)
            
            Spacer()
        }
        .padding()
    }
    
    private var emptyPriceState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("가격 변동 정보가 없습니다")
                .font(.chosunHeadline)
                .fontWeight(.semibold)
            
            Text("시장에서 큰 가격 변동이 발생하면\\n여기에 표시됩니다")
                .font(.chosunBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - District Info Header
    private var districtInfoHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(selectedDistrict.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDistrict.displayName)
                        .font(.chosunHeadline)
                        .fontWeight(.bold)
                    
                    Text(selectedDistrict.description)
                        .font(.chosunCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 지역 통계
            HStack(spacing: 20) {
                VStack {
                    Text("\\(districtManager.districtActivity.filter { $0.district == selectedDistrict }.count)")
                        .font(.chosunHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(selectedDistrict.color)
                    
                    Text("총 활동")
                        .font(.chosunCaption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    let recentCount = districtManager.districtActivity.filter { 
                        $0.district == selectedDistrict && 
                        $0.timestamp.timeIntervalSinceNow > -3600 
                    }.count
                    
                    Text("\\(recentCount)")
                        .font(.chosunHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(.gameGreen)
                    
                    Text("최근 1시간")
                        .font(.chosunCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Methods
    private func refreshData() {
        // 실제 구현에서는 서버에서 최신 데이터를 가져옴
        print("거래 활동 데이터 새로고침")
    }
}

// MARK: - Trade Activity Row
struct TradeActivityRow: View {
    let activity: SocketManager.TradeActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // 거래 유형 아이콘
            ZStack {
                Circle()
                    .fill(activity.isProfit ? Color.gameGreen.opacity(0.2) : Color.gameBlue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: activity.tradeType == "buy" ? "cart.fill" : "dollarsign.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(activity.isProfit ? .gameGreen : .gameBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 플레이어 이름과 행동
                HStack {
                    Text(activity.playerName)
                        .font(.chosunBody)
                        .fontWeight(.semibold)
                    
                    Text(activity.tradeType == "buy" ? "구매" : "판매")
                        .font(.chosunCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(activity.tradeType == "buy" ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        )
                        .foregroundColor(activity.tradeType == "buy" ? .blue : .orange)
                    
                    Spacer()
                    
                    Text(activity.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // 아이템과 상인 정보
                Text("\\(activity.itemName) • \\(activity.merchantName)")
                    .font(.chosunCaption)
                    .foregroundColor(.secondary)
                
                // 지역 정보
                Text("📍 \\(activity.district)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 수익 표시
            VStack {
                Text(activity.isProfit ? "💰" : "📈")
                    .font(.title3)
                
                Text(activity.isProfit ? "수익" : "투자")
                    .font(.caption2)
                    .foregroundColor(activity.isProfit ? .gameGreen : .gameBlue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - District Activity Row
struct DistrictActivityRow: View {
    let activity: DistrictManager.DistrictActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // 시간 표시
            VStack {
                Text(activity.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.playerName)
                        .font(.chosunBody)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(activity.isProfit ? "💰" : "📈")
                        .font(.caption)
                }
                
                Text("\\(activity.itemName) \\(activity.tradeType == "buy" ? "구매" : "판매")")
                    .font(.chosunCaption)
                    .foregroundColor(.primary)
                
                Text("🏪 \\(activity.merchantName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Price Update Row
struct PriceUpdateRow: View {
    let update: SocketManager.PriceUpdate
    
    var body: some View {
        HStack(spacing: 12) {
            // 트렌드 아이콘
            ZStack {
                Circle()
                    .fill(trendColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: trendIcon)
                    .font(.system(size: 16))
                    .foregroundColor(trendColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(update.itemName)
                    .font(.chosunBody)
                    .fontWeight(.semibold)
                
                HStack {
                    Text(update.changeText)
                        .font(.chosunCaption)
                        .fontWeight(.medium)
                        .foregroundColor(trendColor)
                    
                    Spacer()
                    
                    Text("📍 \\(update.district)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(update.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var trendColor: Color {
        switch update.trend {
        case "rising": return .gameGreen
        case "falling": return .red
        default: return .gameBlue
        }
    }
    
    private var trendIcon: String {
        switch update.trend {
        case "rising": return "arrow.up.circle.fill"
        case "falling": return "arrow.down.circle.fill"
        default: return "minus.circle.fill"
        }
    }
}

#Preview {
    TradeActivityView()
        .environmentObject(SocketManager.shared)
}