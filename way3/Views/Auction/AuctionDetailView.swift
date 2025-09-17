//
//  AuctionDetailView.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  경매 상세 및 입찰 화면
//

import SwiftUI

struct AuctionDetailView: View {
    let auction: Auction
    @ObservedObject var auctionManager: AuctionManager
    
    @State private var bidAmount = 0
    @State private var showingBidConfirmation = false
    @State private var showingBidHistory = false
    @State private var isPlacingBid = false
    @State private var bidErrorMessage = ""
    @State private var showBidError = false
    
    // 실시간 업데이트를 위한 타이머
    @State private var timeUpdateTimer: Timer?
    @State private var currentTimeRemaining: TimeInterval
    
    init(auction: Auction, auctionManager: AuctionManager) {
        self.auction = auction
        self.auctionManager = auctionManager
        _currentTimeRemaining = State(initialValue: auction.timeRemaining)
        _bidAmount = State(initialValue: auction.nextMinimumBid)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 헤더 - 아이템 정보
                AuctionItemHeader(auction: auction)
                
                // 실시간 정보 패널
                AuctionLivePanel(
                    auction: auction,
                    timeRemaining: currentTimeRemaining,
                    auctionManager: auctionManager
                )
                
                // 입찰 섹션
                if auction.isActive {
                    AuctionBiddingSection(
                        auction: auction,
                        bidAmount: $bidAmount,
                        isPlacingBid: $isPlacingBid,
                        onBidTapped: {
                            if validateBid() {
                                showingBidConfirmation = true
                            }
                        }
                    )
                } else {
                    AuctionEndedSection(auction: auction)
                }
                
                // 입찰 내역
                AuctionHistorySection(
                    auction: auction,
                    showingBidHistory: $showingBidHistory
                )
                
                // 아이템 상세 정보
                AuctionItemDetails(auction: auction)
                
                // 판매자 정보
                AuctionSellerInfo(auction: auction)
            }
            .padding()
        }
        .navigationTitle(auction.item.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            startTimeUpdateTimer()
            bidAmount = auction.nextMinimumBid
        }
        .onDisappear {
            stopTimeUpdateTimer()
        }
        .alert("입찰 확인", isPresented: $showingBidConfirmation) {
            Button("취소", role: .cancel) { }
            Button("입찰하기") {
                placeBid()
            }
        } message: {
            Text("₩\(bidAmount.formatted())에 입찰하시겠습니까?")
        }
        .alert("입찰 오류", isPresented: $showBidError) {
            Button("확인") { }
        } message: {
            Text(bidErrorMessage)
        }
        .sheet(isPresented: $showingBidHistory) {
            AuctionBidHistoryView(auction: auction)
        }
    }
    
    // MARK: - 입찰 검증
    private func validateBid() -> Bool {
        guard auction.isActive else {
            bidErrorMessage = "경매가 종료되었습니다."
            showBidError = true
            return false
        }
        
        guard bidAmount >= auction.nextMinimumBid else {
            bidErrorMessage = "최소 입찰 금액은 ₩\(auction.nextMinimumBid.formatted())입니다."
            showBidError = true
            return false
        }
        
        // 플레이어 잔액 확인 (실제로는 서버에서 확인해야 함)
        let playerMoney = Int(AuthManager.shared.currentPlayer?.money ?? 0)
        guard bidAmount <= playerMoney else {
            bidErrorMessage = "보유 금액이 부족합니다."
            showBidError = true
            return false
        }
        
        return true
    }
    
    // MARK: - 입찰 실행
    private func placeBid() {
        isPlacingBid = true
        auctionManager.placeBid(auctionId: auction.id, amount: bidAmount)
        
        // 1초 후 로딩 해제 (실제로는 서버 응답을 기다려야 함)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isPlacingBid = false
        }
    }
    
    // MARK: - 타이머 관리
    private func startTimeUpdateTimer() {
        timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTimeRemaining = auction.timeRemaining
        }
    }
    
    private func stopTimeUpdateTimer() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
    }
}

// MARK: - 아이템 헤더
struct AuctionItemHeader: View {
    let auction: Auction
    
    var body: some View {
        VStack(spacing: 16) {
            // 아이템 이미지
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(auction.item.grade.color.opacity(0.2))
                    .frame(height: 200)
                
                VStack(spacing: 12) {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 80))
                        .foregroundColor(auction.item.grade.color)
                    
                    Text("3D 모델")
                        .font(.custom("ChosunCentennial", size: 16))
                        .foregroundColor(auction.item.grade.color)
                        .fontWeight(.semibold)
                }
            }
            
            // 등급 및 카테고리
            HStack(spacing: 12) {
                // 등급 배지
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(auction.item.grade.color)
                    Text(auction.item.grade.displayName)
                        .font(.custom("ChosunCentennial", size: 14))
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(auction.item.grade.color.opacity(0.2))
                .cornerRadius(15)
                
                // 카테고리 배지
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.blue)
                    Text(auction.item.category)
                        .font(.custom("ChosunCentennial", size: 14))
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.1))
                .cornerRadius(15)
                
                Spacer()
            }
        }
    }
}

// MARK: - 실시간 정보 패널
struct AuctionLivePanel: View {
    let auction: Auction
    let timeRemaining: TimeInterval
    @ObservedObject var auctionManager: AuctionManager
    
    var body: some View {
        VStack(spacing: 16) {
            // 경매 타입 헤더
            HStack {
                Image(systemName: auction.auctionType.iconName)
                    .foregroundColor(auction.auctionType.color)
                Text(auction.auctionType.displayName)
                    .font(.custom("ChosunCentennial", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(auction.auctionType.color)
                
                Spacer()
                
                // 라이브 인디케이터
                if auction.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .opacity(0.8)
                            .animation(.easeInOut(duration: 1).repeatForever(), value: UUID())
                        
                        Text("LIVE")
                            .font(.custom("ChosunCentennial", size: 12))
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // 메인 정보 그리드
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // 현재 가격
                InfoCard(
                    title: "현재 가격",
                    value: "₩\(auction.currentPrice.formatted())",
                    iconName: "wonsign.circle.fill",
                    color: .green,
                    isHighlighted: true
                )
                
                // 남은 시간
                InfoCard(
                    title: "남은 시간",
                    value: formatTimeRemaining(timeRemaining),
                    iconName: "clock.fill",
                    color: timeRemaining < 300 ? .red : .blue,
                    isHighlighted: timeRemaining < 300
                )
                
                // 입찰 수
                InfoCard(
                    title: "총 입찰",
                    value: "\(auction.bidCount)회",
                    iconName: "hand.raised.fill",
                    color: .purple
                )
                
                // 최고 입찰자
                InfoCard(
                    title: "최고 입찰자",
                    value: auction.highestBidder.isEmpty ? "없음" : auction.highestBidder,
                    iconName: "crown.fill",
                    color: .orange
                )
            }
            
            // 사용자 상태
            if auctionManager.isUserBidding(auctionId: auction.id) {
                HStack(spacing: 12) {
                    Image(systemName: auctionManager.isUserWinning(auctionId: auction.id) ? 
                          "crown.fill" : "hand.raised.fill")
                        .foregroundColor(auctionManager.isUserWinning(auctionId: auction.id) ? 
                                       .orange : .blue)
                    
                    Text(auctionManager.isUserWinning(auctionId: auction.id) ? 
                         "현재 최고가 입찰자입니다!" : "경매에 참여 중입니다")
                        .font(.custom("ChosunCentennial", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(auctionManager.isUserWinning(auctionId: auction.id) ? 
                                       .orange : .blue)
                }
                .padding()
                .background((auctionManager.isUserWinning(auctionId: auction.id) ? 
                           Color.orange : Color.blue).opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "종료됨"
        } else if timeInterval < 60 {
            return "\(Int(timeInterval))초"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            return "\(minutes)분 \(seconds)초"
        } else {
            let hours = Int(timeInterval / 3600)
            let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)시간 \(minutes)분"
        }
    }
}

// MARK: - 정보 카드
struct InfoCard: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    var isHighlighted: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("ChosunCentennial", size: 12))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.custom("ChosunCentennial", size: isHighlighted ? 18 : 16))
                    .fontWeight(isHighlighted ? .bold : .semibold)
                    .foregroundColor(isHighlighted ? color : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: 2)
            }
        }
    }
}

// MARK: - 입찰 섹션
struct AuctionBiddingSection: View {
    let auction: Auction
    @Binding var bidAmount: Int
    @Binding var isPlacingBid: Bool
    let onBidTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "hammer.fill")
                    .foregroundColor(.orange)
                Text("입찰하기")
                    .font(.custom("ChosunCentennial", size: 18))
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // 입찰 금액 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("입찰 금액")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("₩")
                            .font(.custom("ChosunCentennial", size: 18))
                            .foregroundColor(.secondary)
                        
                        TextField("입찰 금액", value: $bidAmount, format: .number)
                            .font(.custom("ChosunCentennial", size: 20))
                            .fontWeight(.bold)
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                    
                    Text("최소 입찰 금액: ₩\(auction.nextMinimumBid.formatted())")
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.secondary)
                }
                
                // 빠른 입찰 버튼들
                HStack(spacing: 8) {
                    QuickBidButton(
                        title: "최소금액",
                        amount: auction.nextMinimumBid,
                        bidAmount: $bidAmount
                    )
                    
                    QuickBidButton(
                        title: "+10%",
                        amount: auction.currentPrice + (auction.currentPrice / 10),
                        bidAmount: $bidAmount
                    )
                    
                    QuickBidButton(
                        title: "+20%",
                        amount: auction.currentPrice + (auction.currentPrice / 5),
                        bidAmount: $bidAmount
                    )
                    
                    QuickBidButton(
                        title: "MAX",
                        amount: Int(AuthManager.shared.currentPlayer?.money ?? 0),
                        bidAmount: $bidAmount
                    )
                }
                
                // 입찰 버튼
                Button(action: onBidTapped) {
                    HStack {
                        if isPlacingBid {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "hammer.fill")
                        }
                        
                        Text(isPlacingBid ? "입찰 중..." : "입찰하기")
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(bidAmount >= auction.nextMinimumBid ? .orange : .gray)
                    .cornerRadius(16)
                }
                .disabled(isPlacingBid || bidAmount < auction.nextMinimumBid)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 빠른 입찰 버튼
struct QuickBidButton: View {
    let title: String
    let amount: Int
    @Binding var bidAmount: Int
    
    var body: some View {
        Button(action: {
            bidAmount = amount
        }) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.custom("ChosunCentennial", size: 10))
                    .fontWeight(.semibold)
                
                if title != "최소금액" {
                    Text("₩\(amount.formatted())")
                        .font(.custom("ChosunCentennial", size: 8))
                }
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 경매 종료 섹션
struct AuctionEndedSection: View {
    let auction: Auction
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("경매가 종료되었습니다")
                .font(.custom("ChosunCentennial", size: 20))
                .fontWeight(.bold)
            
            if !auction.highestBidder.isEmpty {
                VStack(spacing: 8) {
                    Text("낙찰자: \(auction.highestBidder)")
                        .font(.custom("ChosunCentennial", size: 16))
                    
                    Text("최종 가격: ₩\(auction.currentPrice.formatted())")
                        .font(.custom("ChosunCentennial", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            } else {
                Text("유찰되었습니다")
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 입찰 내역 섹션
struct AuctionHistorySection: View {
    let auction: Auction
    @Binding var showingBidHistory: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                Text("입찰 내역")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("전체 보기") {
                    showingBidHistory = true
                }
                .font(.custom("ChosunCentennial", size: 14))
                .foregroundColor(.blue)
            }
            
            Text("총 \(auction.bidCount)회 입찰")
                .font(.custom("ChosunCentennial", size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 아이템 상세 정보
struct AuctionItemDetails: View {
    let auction: Auction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("아이템 정보")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                DetailRow(title: "기본 가격", value: "₩\(auction.item.basePrice.formatted())")
                DetailRow(title: "필요 라이센스", value: auction.item.requiredLicense.displayName)
                DetailRow(title: "무게", value: String(format: "%.1f", auction.item.weight) + "kg")
                
                if !auction.item.description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("설명")
                            .font(.custom("ChosunCentennial", size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(auction.item.description)
                            .font(.custom("ChosunCentennial", size: 14))
                            .lineLimit(nil)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 상세 정보 행
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("ChosunCentennial", size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.custom("ChosunCentennial", size: 14))
                .fontWeight(.medium)
        }
    }
}

// MARK: - 판매자 정보
struct AuctionSellerInfo: View {
    let auction: Auction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.blue)
                Text("판매자 정보")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // 판매자 아바타
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(auction.sellerName)
                        .font(.custom("ChosunCentennial", size: 16))
                        .fontWeight(.semibold)
                    
                    Text("경매 시작: \(auction.startTime, formatter: dateFormatter)")
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - 입찰 내역 모달
struct AuctionBidHistoryView: View {
    let auction: Auction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Mock bid history - 실제로는 서버에서 가져와야 함
                List {
                    ForEach(0..<auction.bidCount, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("입찰자 \(index + 1)")
                                    .font(.custom("ChosunCentennial", size: 14))
                                    .fontWeight(.semibold)
                                
                                Text("5분 전")
                                    .font(.custom("ChosunCentennial", size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("₩\((auction.currentPrice - (auction.bidCount - index) * 1000).formatted())")
                                .font(.custom("ChosunCentennial", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("입찰 내역")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AuctionDetailView(
        auction: Auction(from: [
            "id": "sample_auction",
            "sellerId": "seller1",
            "sellerName": "테스트 판매자",
            "startingPrice": 50000,
            "currentPrice": 75000,
            "bidCount": 5,
            "highestBidder": "bidder1",
            "highestBidderId": "bidder1",
            "startTime": Date().timeIntervalSince1970 - 3600,
            "endTime": Date().timeIntervalSince1970 + 1800,
            "auctionType": "standard",
            "item": [
                "itemId": "test_item",
                "name": "테스트 아이템",
                "category": "보석",
                "grade": 4,
                "requiredLicense": 2,
                "basePrice": 50000,
                "currentPrice": 75000
            ]
        ]),
        auctionManager: AuctionManager()
    )
}