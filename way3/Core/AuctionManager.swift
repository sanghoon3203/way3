//
//  AuctionManager.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  실시간 경매 시스템 매니저
//

import Foundation
import SwiftUI
import UIKit
import Combine
import SocketIO

// MARK: - 경매 매니저
class AuctionManager: ObservableObject {
    @Published var activeAuctions: [Auction] = []
    @Published var userBids: [String: Bid] = [:] // auctionId: userBid
    @Published var isConnected = false
    @Published var connectionStatus = "연결 중..."
    
    private var cancellables = Set<AnyCancellable>()
    private let socketManager = SocketManager.shared

    init() {
        setupSocket()
    }

    // MARK: - 소켓 설정
    private func setupSocket() {
        setupSocketObservers()
    }
    
    private func setupSocketObservers() {
        // SocketManager의 연결 상태 관찰
        socketManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isConnected = isConnected
                self?.connectionStatus = isConnected ? "연결됨" : "연결 끊김"
                if isConnected {
                    self?.fetchActiveAuctions()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 연결 관리
    func connectSocket() {
        // SocketManager가 자동으로 연결을 관리
    }

    func disconnectSocket() {
        // SocketManager가 자동으로 연결을 관리
    }
    
    // MARK: - 활성 경매 조회
    private func fetchActiveAuctions() {
        // TODO: SocketManager에 get_auctions 메서드 추가 필요
    }
    
    // MARK: - 경매 참여
    func placeBid(auctionId: String, amount: Int) {
        let bidData: [String: Any] = [
            "auctionId": auctionId,
            "amount": amount,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        socketManager.submitAuctionBid(
            auctionId: auctionId,
            playerId: AuthManager.shared.currentPlayer?.id ?? "",
            bidAmount: amount
        )
    }
    
    // MARK: - 새 경매 생성
    func createAuction(item: TradeItem, startingPrice: Int, duration: TimeInterval) {
        let auctionData: [String: Any] = [
            "itemId": item.itemId,
            "itemName": item.name,
            "itemCategory": item.category,
            "itemGrade": item.grade.rawValue,
            "startingPrice": startingPrice,
            "duration": duration,
            "createdAt": Date().timeIntervalSince1970
        ]
        
        // TODO: SocketManager에 create_auction 메서드 추가 필요
    }
    
    // MARK: - 경매 참가 취소
    func cancelBid(auctionId: String) {
        // TODO: SocketManager에 cancel_bid 메서드 추가 필요
        
        DispatchQueue.main.async {
            self.userBids.removeValue(forKey: auctionId)
        }
    }
    
    // MARK: - 소켓 이벤트 핸들러
    private func handleAuctionList(data: [Any]) {
        guard let auctionsData = data.first as? [[String: Any]] else { return }
        
        let auctions = auctionsData.compactMap { auctionDict -> Auction? in
            return Auction(from: auctionDict)
        }
        
        DispatchQueue.main.async {
            self.activeAuctions = auctions
        }
    }
    
    private func handleAuctionUpdate(data: [Any]) {
        guard let auctionData = data.first as? [String: Any] else { return }
        let updatedAuction = Auction(from: auctionData)

        DispatchQueue.main.async {
            if let index = self.activeAuctions.firstIndex(where: { $0.id == updatedAuction.id }) {
                self.activeAuctions[index] = updatedAuction
            }
        }
    }
    
    private func handleNewBid(data: [Any]) {
        guard let bidData = data.first as? [String: Any],
              let auctionId = bidData["auctionId"] as? String,
              let amount = bidData["amount"] as? Int,
              let bidderName = bidData["bidderName"] as? String else { return }
        
        DispatchQueue.main.async {
            if let index = self.activeAuctions.firstIndex(where: { $0.id == auctionId }) {
                self.activeAuctions[index].currentPrice = amount
                self.activeAuctions[index].highestBidder = bidderName
                self.activeAuctions[index].bidCount += 1
            }
        }
        
        // 햅틱 피드백
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
    }
    
    private func handleAuctionEnded(data: [Any]) {
        guard let auctionData = data.first as? [String: Any],
              let auctionId = auctionData["auctionId"] as? String,
              let winnerId = auctionData["winnerId"] as? String,
              let finalPrice = auctionData["finalPrice"] as? Int else { return }
        
        DispatchQueue.main.async {
            // 경매 종료 처리
            self.activeAuctions.removeAll { $0.id == auctionId }
            self.userBids.removeValue(forKey: auctionId)
            
            // 승리 알림
            if winnerId == AuthManager.shared.currentPlayer?.id {
                self.showWinNotification(finalPrice: finalPrice)
            }
        }
    }
    
    private func handleBidSuccess(data: [Any]) {
        guard let bidData = data.first as? [String: Any],
              let auctionId = bidData["auctionId"] as? String,
              let amount = bidData["amount"] as? Int else { return }
        
        DispatchQueue.main.async {
            let bid = Bid(
                id: UUID().uuidString,
                auctionId: auctionId,
                bidderId: AuthManager.shared.currentPlayer?.id ?? "",
                bidderName: AuthManager.shared.currentPlayer?.name ?? "",
                amount: amount,
                timestamp: Date()
            )
            
            self.userBids[auctionId] = bid
        }
        
        // 성공 햅틱 피드백
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
    }
    
    private func handleBidError(data: [Any]) {
        guard let errorData = data.first as? [String: Any],
              let message = errorData["message"] as? String else { return }
        
        DispatchQueue.main.async {
            // 에러 알림 표시
            // 실제로는 Toast나 Alert로 표시해야 함
            print("입찰 오류: \(message)")
        }
        
        // 에러 햅틱 피드백
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - 유틸리티
    private func showWinNotification(finalPrice: Int) {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
        
        // 승리 알림 표시 (실제로는 별도의 알림 시스템 필요)
        print("경매 낙찰! 최종 가격: ₩\(finalPrice)")
    }
    
    // MARK: - 경매 상태 확인
    func isUserBidding(auctionId: String) -> Bool {
        return userBids[auctionId] != nil
    }
    
    func getUserBid(auctionId: String) -> Bid? {
        return userBids[auctionId]
    }
    
    func isUserWinning(auctionId: String) -> Bool {
        guard let auction = activeAuctions.first(where: { $0.id == auctionId }),
              let currentPlayerId = AuthManager.shared.currentPlayer?.id else {
            return false
        }

        return auction.highestBidderId == currentPlayerId
    }
    
    // MARK: - 경매 필터링
    func getAuctionsByCategory(_ category: String) -> [Auction] {
        if category == "전체" {
            return activeAuctions
        }
        return activeAuctions.filter { $0.item.category == category }
    }
    
    func getAuctionsByGrade(_ grade: ItemGrade) -> [Auction] {
        return activeAuctions.filter { $0.item.grade == grade }
    }
    
    func getEndingSoonAuctions(within minutes: TimeInterval = 10) -> [Auction] {
        let cutoffTime = Date().addingTimeInterval(minutes * 60)
        return activeAuctions.filter { $0.endTime <= cutoffTime }
    }
}

// MARK: - 경매 모델
struct Auction: Identifiable, Codable {
    let id: String
    let item: TradeItem
    let sellerId: String
    let sellerName: String
    let startingPrice: Int
    var currentPrice: Int
    let startTime: Date
    let endTime: Date
    var bidCount: Int
    var highestBidder: String
    var highestBidderId: String
    let auctionType: AuctionType
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        
        // TradeItem 생성
        if let itemDict = dict["item"] as? [String: Any] {
            self.item = TradeItem(
                itemId: itemDict["itemId"] as? String ?? "",
                name: itemDict["name"] as? String ?? "",
                category: itemDict["category"] as? String ?? "",
                grade: ItemGrade(rawValue: itemDict["grade"] as? Int ?? 0) ?? .common,
                requiredLicense: LicenseLevel(rawValue: itemDict["requiredLicense"] as? Int ?? 0) ?? .beginner,
                basePrice: itemDict["basePrice"] as? Int ?? 0,
                currentPrice: itemDict["currentPrice"] as? Int,
                weight: itemDict["weight"] as? Double ?? 1.0,
                description: itemDict["description"] as? String ?? "",
                iconId: itemDict["iconId"] as? Int ?? 1
            )
        } else {
            // 기본값 설정
            self.item = TradeItem(
                itemId: "",
                name: "알 수 없는 아이템",
                category: "일반품",
                grade: .common,
                requiredLicense: .beginner,
                basePrice: 0,
                currentPrice: 0,
                weight: 1.0,
                description: "",
                iconId: 1
            )
        }
        
        self.sellerId = dict["sellerId"] as? String ?? ""
        self.sellerName = dict["sellerName"] as? String ?? ""
        self.startingPrice = dict["startingPrice"] as? Int ?? 0
        self.currentPrice = dict["currentPrice"] as? Int ?? 0
        self.bidCount = dict["bidCount"] as? Int ?? 0
        self.highestBidder = dict["highestBidder"] as? String ?? ""
        self.highestBidderId = dict["highestBidderId"] as? String ?? ""
        
        // 시간 변환
        let startTimestamp = dict["startTime"] as? TimeInterval ?? Date().timeIntervalSince1970
        let endTimestamp = dict["endTime"] as? TimeInterval ?? Date().addingTimeInterval(3600).timeIntervalSince1970
        
        self.startTime = Date(timeIntervalSince1970: startTimestamp)
        self.endTime = Date(timeIntervalSince1970: endTimestamp)
        
        // 경매 타입
        let typeString = dict["auctionType"] as? String ?? "standard"
        self.auctionType = AuctionType(rawValue: typeString) ?? .standard
    }
    
    // MARK: - 계산된 속성들
    var timeRemaining: TimeInterval {
        return endTime.timeIntervalSinceNow
    }
    
    var isActive: Bool {
        return timeRemaining > 0
    }
    
    var formattedTimeRemaining: String {
        let remaining = timeRemaining
        
        if remaining <= 0 {
            return "종료됨"
        } else if remaining < 60 {
            return "\(Int(remaining))초"
        } else if remaining < 3600 {
            return "\(Int(remaining / 60))분"
        } else {
            return "\(Int(remaining / 3600))시간"
        }
    }
    
    var nextMinimumBid: Int {
        switch auctionType {
        case .standard:
            return currentPrice + max(1000, currentPrice / 20) // 최소 1000원 또는 5% 증가
        case .dutch:
            return currentPrice - max(1000, currentPrice / 10) // 네덜란드식은 감소
        case .reserve:
            return currentPrice + max(2000, currentPrice / 10) // 예약가는 더 큰 증가
        }
    }
}

// MARK: - 입찰 모델
struct Bid: Identifiable, Codable {
    let id: String
    let auctionId: String
    let bidderId: String
    let bidderName: String
    let amount: Int
    let timestamp: Date
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - 경매 타입
enum AuctionType: String, CaseIterable, Codable {
    case standard = "standard"   // 일반 경매
    case dutch = "dutch"         // 네덜란드식 경매 (가격 하락)
    case reserve = "reserve"     // 예약가 경매
    
    var displayName: String {
        switch self {
        case .standard: return "일반 경매"
        case .dutch: return "네덜란드 경매"
        case .reserve: return "예약가 경매"
        }
    }
    
    var description: String {
        switch self {
        case .standard: return "일반적인 최고가 입찰 방식"
        case .dutch: return "높은 가격에서 시작하여 점점 낮아지는 방식"
        case .reserve: return "최소 예약가격이 설정된 경매"
        }
    }
    
    var iconName: String {
        switch self {
        case .standard: return "hammer.fill"
        case .dutch: return "arrow.down.circle.fill"
        case .reserve: return "lock.shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .standard: return .blue
        case .dutch: return .orange
        case .reserve: return .purple
        }
    }
}