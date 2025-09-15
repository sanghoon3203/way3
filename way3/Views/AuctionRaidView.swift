//
//  AuctionRaidView.swift
//  way3 - Collective Auction System
//
//  Pokemon GO 레이드 스타일의 집단 경매 시스템
//

import SwiftUI
import Combine

struct AuctionRaidView: View {
    let auction: CollectiveAuction
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var player: Player
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var auctionManager = AuctionManager()
    @State private var currentBid: Int = 0
    @State private var playerBid: Int = 0
    @State private var showBidConfirmation = false
    @State private var participants: [AuctionParticipant] = []
    @State private var timeRemaining: TimeInterval = 0
    @State private var auctionPhase: AuctionPhase = .preparation
    @State private var showResults = false
    
    enum AuctionPhase {
        case preparation    // 준비 단계
        case active        // 활성 경매
        case finalCall     // 마지막 입찰 기회
        case ended         // 경매 종료
        
        var displayName: String {
            switch self {
            case .preparation: return "경매 준비"
            case .active: return "경매 진행 중"
            case .finalCall: return "마지막 기회!"
            case .ended: return "경매 종료"
            }
        }
        
        var color: Color {
            switch self {
            case .preparation: return .gameBlue
            case .active: return .gameGreen
            case .finalCall: return .orange
            case .ended: return .gray
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 배경 그라데이션 (Pokemon GO 레이드 스타일)
            LinearGradient(
                colors: [auctionPhase.color.opacity(0.8), auctionPhase.color.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 경매 헤더
                    auctionHeader
                    
                    // 타이머 및 상태
                    auctionTimer
                    
                    // 경매 아이템 정보
                    auctionItemInfo
                    
                    // 현재 최고 입찰
                    currentBidDisplay
                    
                    // 참가자 목록
                    participantsList
                    
                    // 입찰 인터페이스
                    if auctionPhase == .active || auctionPhase == .finalCall {
                        biddingInterface
                    }
                    
                    // 경매 결과 (종료 시)
                    if auctionPhase == .ended {
                        auctionResults
                    }
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupAuction()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateTimer()
        }
        .sheet(isPresented: $showBidConfirmation) {
            BidConfirmationView(
                auction: auction,
                bidAmount: playerBid,
                onConfirm: { confirmBid() },
                onCancel: { showBidConfirmation = false }
            )
        }
        .sheet(isPresented: $showResults) {
            AuctionResultsView(auction: auction, participants: participants)
        }
    }
    
    // MARK: - 경매 헤더
    private var auctionHeader: some View {
        VStack(spacing: 16) {
            // 닫기 버튼과 경매 타입
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.chosunHeadline)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("집단 경매")
                        .font(.chosunBody)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(auction.type.displayName)
                        .font(.chosunCaption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // 경매 제목
            Text(auction.title)
                .font(.chosunHeadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // 경매 상태 배지
            HStack {
                Image(systemName: auctionPhase.icon)
                    .foregroundColor(.white)
                
                Text(auctionPhase.displayName)
                    .font(.chosunBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
            )
        }
    }
    
    // MARK: - 타이머
    private var auctionTimer: some View {
        VStack(spacing: 8) {
            Text("남은 시간")
                .font(.chosunCaption)
                .foregroundColor(.white.opacity(0.8))
            
            Text(formatTime(timeRemaining))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(radius: 2)
            
            // 시간 진행 바
            ProgressView(value: 1.0 - (timeRemaining / auction.duration))
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(y: 3)
                .frame(height: 6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - 경매 아이템 정보
    private var auctionItemInfo: some View {
        VStack(spacing: 16) {
            // 아이템 이미지 또는 아이콘
            ZStack {
                Circle()
                    .fill(auction.item.rarity.color.opacity(0.3))
                    .frame(width: 120, height: 120)
                
                Image(systemName: auction.item.iconName)
                    .font(.system(size: 50))
                    .foregroundColor(auction.item.rarity.color)
            }
            
            // 아이템 정보
            VStack(spacing: 8) {
                Text(auction.item.name)
                    .font(.chosunHeadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(auction.item.description)
                    .font(.chosunBody)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                // 희귀도 표시
                HStack {
                    ForEach(0..<auction.item.rarity.starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Text(auction.item.rarity.displayName)
                        .font(.chosunCaption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - 현재 최고 입찰
    private var currentBidDisplay: some View {
        VStack(spacing: 12) {
            Text("현재 최고 입찰")
                .font(.chosunBody)
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(formatMoney(currentBid))원")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(radius: 2)
            
            if let leader = participants.first(where: { $0.currentBid == currentBid }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    
                    Text(leader.playerName)
                        .font(.chosunBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 참가자 목록
    private var participantsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("참가자")
                    .font(.chosunHeadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(participants.count)명")
                    .font(.chosunBody)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(participants.sorted { $0.currentBid > $1.currentBid }) { participant in
                        ParticipantCard(participant: participant, rank: participants.firstIndex(of: participant)! + 1)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - 입찰 인터페이스
    private var biddingInterface: some View {
        VStack(spacing: 16) {
            Text("입찰하기")
                .font(.chosunHeadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // 빠른 입찰 버튼들
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    QuickBidButton(title: "+1만", amount: currentBid + 10000, bidAmount: $playerBid)
                    QuickBidButton(title: "+5만", amount: currentBid + 50000, bidAmount: $playerBid)
                    QuickBidButton(title: "+10만", amount: currentBid + 100000, bidAmount: $playerBid)
                }
                
                HStack(spacing: 12) {
                    QuickBidButton(title: "+50만", amount: currentBid + 500000, bidAmount: $playerBid)
                    QuickBidButton(title: "+100만", amount: currentBid + 1000000, bidAmount: $playerBid)
                }
            }
            
            // 사용자 정의 입찰
            VStack(spacing: 8) {
                Text("직접 입력")
                    .font(.chosunCaption)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    TextField("입찰 금액", value: $playerBid, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.chosunBody)
                    
                    Text("원")
                        .font(.chosunBody)
                        .foregroundColor(.white)
                }
            }
            
            // 입찰 버튼
            Button(action: submitBid) {
                Text("입찰하기 (\(formatMoney(playerBid))원)")
                    .font(.chosunBody)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(playerBid > currentBid ? Color.gameGreen : Color.gray)
                    )
            }
            .disabled(playerBid <= currentBid || playerBid > player.money)
            
            // 플레이어 자금 정보
            Text("보유 금액: \(formatMoney(player.money))원")
                .font(.chosunCaption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - 경매 결과
    private var auctionResults: some View {
        VStack(spacing: 16) {
            Text("경매 종료")
                .font(.chosunHeadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let winner = participants.max(by: { $0.currentBid < $1.currentBid }) {
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    
                    Text("낙찰자")
                        .font(.chosunCaption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(winner.playerName)
                        .font(.chosunHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("낙찰가: \(formatMoney(winner.currentBid))원")
                        .font(.chosunBody)
                        .foregroundColor(.gameGreen)
                        .fontWeight(.semibold)
                }
            }
            
            Button(action: { showResults = true }) {
                Text("상세 결과 보기")
                    .font(.chosunBody)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gameBlue)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Methods
    private func setupAuction() {
        timeRemaining = auction.duration
        currentBid = auction.startingPrice
        auctionPhase = .preparation
        
        // 소켓으로 경매 참가
        socketManager.joinAuction(auctionId: auction.id)
        
        // 참가자 목록 초기화
        participants = [
            AuctionParticipant(
                id: player.id,
                playerName: player.name,
                currentBid: 0,
                totalBids: 0,
                isOnline: true
            )
        ]
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            
            // 페이즈 업데이트
            if timeRemaining <= 0 {
                auctionPhase = .ended
            } else if timeRemaining <= 30 {
                auctionPhase = .finalCall
            } else if timeRemaining <= auction.duration * 0.8 {
                auctionPhase = .active
            }
        }
    }
    
    private func setQuickBid(amount: Int) {
        playerBid = amount
    }
    
    private func submitBid() {
        guard playerBid > currentBid && playerBid <= player.money else { return }
        showBidConfirmation = true
    }
    
    private func confirmBid() {
        // 서버로 입찰 전송
        socketManager.submitAuctionBid(
            auctionId: auction.id,
            playerId: player.id,
            bidAmount: playerBid
        )
        
        // 로컬 UI 업데이트 (실제로는 서버 응답으로 처리해야 함)
        DispatchQueue.main.async {
            self.currentBid = self.playerBid
            self.showBidConfirmation = false
            
            // 참가자 목록 업데이트
            if let index = self.participants.firstIndex(where: { $0.id == self.player.id }) {
                self.participants[index].currentBid = self.playerBid
                self.participants[index].totalBids += 1
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatMoney(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - 참가자 카드
struct ParticipantCard: View {
    let participant: AuctionParticipant
    let rank: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // 순위 표시
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 30, height: 30)
                
                Text("\(rank)")
                    .font(.chosunCaption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // 플레이어 정보
            VStack(spacing: 4) {
                Text(participant.playerName)
                    .font(.chosunCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(formatMoney(participant.currentBid))원")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                
                // 온라인 상태
                Circle()
                    .fill(participant.isOnline ? .green : .gray)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .frame(width: 80)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.brown
        default: return .gameBlue
        }
    }
    
    private func formatMoney(_ amount: Int) -> String {
        if amount >= 1000000 {
            return String(format: "%.1f백만", Double(amount) / 1000000)
        } else if amount >= 10000 {
            return String(format: "%.0f만", Double(amount) / 10000)
        } else {
            return "\(amount)"
        }
    }
}

// MARK: - 빠른 입찰 버튼

// MARK: - 입찰 확인 뷰
struct BidConfirmationView: View {
    let auction: CollectiveAuction
    let bidAmount: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("입찰 확인")
                .font(.chosunHeadline)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Text(auction.item.name)
                    .font(.chosunBody)
                    .fontWeight(.semibold)
                
                Text("입찰 금액")
                    .font(.chosunCaption)
                    .foregroundColor(.secondary)
                
                Text("\(formatMoney(bidAmount))원")
                    .font(.chosunHeadline)
                    .fontWeight(.bold)
                    .foregroundColor(.gameGreen)
                
                Text("이 금액으로 입찰하시겠습니까?")
                    .font(.chosunBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGroupedBackground))
            )
            
            HStack(spacing: 16) {
                Button("취소", action: onCancel)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                
                Button("확인", action: onConfirm)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gameGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private func formatMoney(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - 경매 결과 뷰
struct AuctionResultsView: View {
    let auction: CollectiveAuction
    let participants: [AuctionParticipant]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("경매 정보").font(.chosunBody)) {
                    HStack {
                        Text("아이템")
                        Spacer()
                        Text(auction.item.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("낙찰가")
                        Spacer()
                        Text("\(formatMoney(participants.max(by: { $0.currentBid < $1.currentBid })?.currentBid ?? 0))원")
                            .foregroundColor(.gameGreen)
                            .fontWeight(.semibold)
                    }
                }
                
                Section(header: Text("순위").font(.chosunBody)) {
                    ForEach(participants.sorted { $0.currentBid > $1.currentBid }.enumerated().map { $0 }, id: \.element.id) { index, participant in
                        HStack {
                            Text("\(index + 1)")
                                .font(.chosunBody)
                                .fontWeight(.bold)
                                .foregroundColor(index < 3 ? .gameGreen : .primary)
                                .frame(width: 30)
                            
                            Text(participant.playerName)
                                .font(.chosunBody)
                            
                            Spacer()
                            
                            Text("\(formatMoney(participant.currentBid))원")
                                .font(.chosunCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("경매 결과")
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
    
    private func formatMoney(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - 모델 정의
struct CollectiveAuction: Identifiable {
    let id: String
    let title: String
    let item: AuctionItem
    let startingPrice: Int
    let duration: TimeInterval
    let type: AuctionType
    let location: String
    let maxParticipants: Int
    
    enum AuctionType {
        case standard, premium, legendary, community
        
        var displayName: String {
            switch self {
            case .standard: return "일반 경매"
            case .premium: return "프리미엄 경매"
            case .legendary: return "전설 경매"
            case .community: return "커뮤니티 경매"
            }
        }
    }
}

struct AuctionItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let rarity: Rarity
    
    enum Rarity {
        case common, rare, epic, legendary
        
        var displayName: String {
            switch self {
            case .common: return "일반"
            case .rare: return "희귀"
            case .epic: return "영웅"
            case .legendary: return "전설"
            }
        }
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .orange
            }
        }
        
        var starCount: Int {
            switch self {
            case .common: return 1
            case .rare: return 3
            case .epic: return 4
            case .legendary: return 5
            }
        }
    }
}

struct AuctionParticipant: Identifiable, Equatable {
    let id: String
    let playerName: String
    var currentBid: Int
    var totalBids: Int
    let isOnline: Bool
    
    static func == (lhs: AuctionParticipant, rhs: AuctionParticipant) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: - Extension for AuctionPhase
extension AuctionRaidView.AuctionPhase {
    var icon: String {
        switch self {
        case .preparation: return "clock"
        case .active: return "hammer.fill"
        case .finalCall: return "exclamationmark.triangle.fill"
        case .ended: return "checkmark.circle.fill"
        }
    }
}

#Preview {
    AuctionRaidView(
        auction: CollectiveAuction(
            id: "1",
            title: "한정판 전통 공예품 경매",
            item: AuctionItem(
                id: "item1",
                name: "조선 백자 달항아리",
                description: "조선 후기의 전통 백자 달항아리로, 완벽한 형태를 자랑합니다.",
                iconName: "circle.grid.cross.fill",
                rarity: .legendary
            ),
            startingPrice: 1000000,
            duration: 300,
            type: .legendary,
            location: "종로구",
            maxParticipants: 20
        )
    )
    .environmentObject(SocketManager.shared)
    .environmentObject(NetworkManager.shared)
    .environmentObject(Player())
}