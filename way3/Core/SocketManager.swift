//
//  SocketManager.swift
//  way3 - Real-time Socket.IO Integration
//
//  실시간 서버 통신 및 Pokemon GO 스타일 실시간 기능
//

import SwiftUI
import SocketIO
import CoreLocation

class SocketManager: ObservableObject {
    static let shared = SocketManager()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var nearbyPlayers: [NearbyPlayer] = []
    @Published var recentTradeActivity: [TradeActivity] = []
    @Published var marketPriceUpdates: [PriceUpdate] = []
    @Published var tradeOffers: [TradeOffer] = []
    
    // MARK: - Private Properties
    private var manager: SocketIO.SocketManager?
    private var socket: SocketIOClient?
    
    // MARK: - Data Models
    struct NearbyPlayer: Identifiable {
        let id: String
        let name: String
        let level: Int
        let location: CLLocationCoordinate2D
        let distance: Double
        
        var distanceText: String {
            if distance < 1000 {
                return "\(Int(distance))m"
            } else {
                return String(format: "%.1fkm", distance / 1000)
            }
        }
    }
    
    struct TradeActivity: Identifiable {
        let id = UUID()
        let playerId: String
        let playerName: String
        let merchantName: String
        let itemName: String
        let tradeType: String
        let isProfit: Bool
        let timestamp: Date
        
        var timeText: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        }

        var timeAgo: String {
            let interval = Date().timeIntervalSince(timestamp)
            if interval < 60 {
                return "방금 전"
            } else if interval < 3600 {
                return "\(Int(interval / 60))분 전"
            } else if interval < 86400 {
                return "\(Int(interval / 3600))시간 전"
            } else {
                return "\(Int(interval / 86400))일 전"
            }
        }
    }
    
    struct PriceUpdate: Identifiable {
        let id = UUID()
        let itemName: String
        let oldPrice: Int
        let newPrice: Int
        let district: String
        let changePercent: Double
        let timestamp: Date
        
        var changeDirection: PriceDirection {
            if newPrice > oldPrice {
                return .up
            } else if newPrice < oldPrice {
                return .down
            } else {
                return .stable
            }
        }
        
        enum PriceDirection {
            case up, down, stable
            
            var color: Color {
                switch self {
                case .up: return .green
                case .down: return .red
                case .stable: return .gray
                }
            }
            
            var icon: String {
                switch self {
                case .up: return "arrow.up"
                case .down: return "arrow.down"
                case .stable: return "minus"
                }
            }
        }
    }
    
    struct TradeOffer: Identifiable {
        let id: String
        let fromPlayerId: String
        let fromPlayerName: String
        let toPlayerId: String
        let toPlayerName: String
        let itemsOffered: [String]
        let itemsRequested: [String]
        let message: String?
        let timestamp: Date
        let status: OfferStatus
        
        enum OfferStatus {
            case pending, accepted, rejected, expired
            
            var color: Color {
                switch self {
                case .pending: return .orange
                case .accepted: return .green
                case .rejected: return .red
                case .expired: return .gray
                }
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        setupSocket()
    }
    
    private func setupSocket() {
        guard let url = URL(string: NetworkConfiguration.baseURL) else {
            print("Invalid socket URL")
            return
        }
        
        // Updated Socket.IO configuration for current version
        let config: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .connectParams(["platform": "ios"])
        ]
        
        manager = SocketIO.SocketManager(socketURL: url, config: config)
        socket = manager?.defaultSocket
        
        setupEventHandlers()
    }
    
    // MARK: - Event Handlers
    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.isConnected = true
                print("Socket connected")
            }
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.isConnected = false
                print("Socket disconnected")
            }
        }
        
        // Custom events
        socket?.on("nearbyPlayersUpdate") { [weak self] data, ack in
            self?.handleNearbyPlayersUpdate(data: data)
        }
        
        socket?.on("tradeActivity") { [weak self] data, ack in
            self?.handleTradeActivity(data: data)
        }
        
        socket?.on("priceUpdate") { [weak self] data, ack in
            self?.handlePriceUpdate(data: data)
        }
        
        socket?.on("tradeOffer") { [weak self] data, ack in
            self?.handleTradeOffer(data: data)
        }
    }
    
    // MARK: - Data Handlers
    private func handleNearbyPlayersUpdate(data: [Any]) {
        guard let playersData = data[0] as? [[String: Any]] else { return }
        
        let players = playersData.compactMap { playerData -> NearbyPlayer? in
            guard let id = playerData["id"] as? String,
                  let name = playerData["name"] as? String,
                  let level = playerData["level"] as? Int,
                  let lat = playerData["lat"] as? Double,
                  let lng = playerData["lng"] as? Double,
                  let distance = playerData["distance"] as? Double else {
                return nil
            }
            
            return NearbyPlayer(
                id: id,
                name: name,
                level: level,
                location: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                distance: distance
            )
        }
        
        DispatchQueue.main.async {
            self.nearbyPlayers = players
        }
    }
    
    private func handleTradeActivity(data: [Any]) {
        guard let activityData = data[0] as? [String: Any],
              let playerId = activityData["playerId"] as? String,
              let playerName = activityData["playerName"] as? String,
              let merchantName = activityData["merchantName"] as? String,
              let itemName = activityData["itemName"] as? String,
              let tradeType = activityData["tradeType"] as? String,
              let isProfit = activityData["isProfit"] as? Bool else {
            return
        }
        
        let activity = TradeActivity(
            playerId: playerId,
            playerName: playerName,
            merchantName: merchantName,
            itemName: itemName,
            tradeType: tradeType,
            isProfit: isProfit,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.recentTradeActivity.insert(activity, at: 0)
            if self.recentTradeActivity.count > 50 {
                self.recentTradeActivity = Array(self.recentTradeActivity.prefix(50))
            }
        }
    }
    
    private func handlePriceUpdate(data: [Any]) {
        guard let priceData = data[0] as? [String: Any],
              let itemName = priceData["itemName"] as? String,
              let oldPrice = priceData["oldPrice"] as? Int,
              let newPrice = priceData["newPrice"] as? Int,
              let district = priceData["district"] as? String else {
            return
        }
        
        let changePercent = Double(newPrice - oldPrice) / Double(oldPrice) * 100.0
        
        let update = PriceUpdate(
            itemName: itemName,
            oldPrice: oldPrice,
            newPrice: newPrice,
            district: district,
            changePercent: changePercent,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.marketPriceUpdates.insert(update, at: 0)
            if self.marketPriceUpdates.count > 30 {
                self.marketPriceUpdates = Array(self.marketPriceUpdates.prefix(30))
            }
        }
    }
    
    private func handleTradeOffer(data: [Any]) {
        guard let offerData = data[0] as? [String: Any],
              let id = offerData["id"] as? String,
              let fromPlayerId = offerData["fromPlayerId"] as? String,
              let fromPlayerName = offerData["fromPlayerName"] as? String,
              let toPlayerId = offerData["toPlayerId"] as? String,
              let toPlayerName = offerData["toPlayerName"] as? String,
              let itemsOffered = offerData["itemsOffered"] as? [String],
              let itemsRequested = offerData["itemsRequested"] as? [String],
              let statusString = offerData["status"] as? String else {
            return
        }
        
        let status: TradeOffer.OfferStatus = {
            switch statusString {
            case "accepted": return .accepted
            case "rejected": return .rejected
            case "expired": return .expired
            default: return .pending
            }
        }()
        
        let offer = TradeOffer(
            id: id,
            fromPlayerId: fromPlayerId,
            fromPlayerName: fromPlayerName,
            toPlayerId: toPlayerId,
            toPlayerName: toPlayerName,
            itemsOffered: itemsOffered,
            itemsRequested: itemsRequested,
            message: offerData["message"] as? String,
            timestamp: Date(),
            status: status
        )
        
        DispatchQueue.main.async {
            if let index = self.tradeOffers.firstIndex(where: { $0.id == offer.id }) {
                self.tradeOffers[index] = offer
            } else {
                self.tradeOffers.append(offer)
            }
        }
    }
    
    // MARK: - Public Methods
    func connect(with token: String? = nil) {
        if let token = token {
            socket?.connect(withPayload: ["token": token])
        } else {
            socket?.connect()
        }
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    func updatePlayerLocation(coordinate: CLLocationCoordinate2D, playerId: String) {
        socket?.emit("updateLocation", [
            "playerId": playerId,
            "lat": coordinate.latitude,
            "lng": coordinate.longitude
        ])
    }
    
    func sendTradeOffer(to playerId: String, playerName: String, offeredItems: [String], requestedItems: [String], message: String?) {
        socket?.emit("sendTradeOffer", [
            "toPlayerId": playerId,
            "toPlayerName": playerName,
            "itemsOffered": offeredItems,
            "itemsRequested": requestedItems,
            "message": message ?? ""
        ])
    }
    
    func respondToTradeOffer(offerId: String, accept: Bool) {
        socket?.emit("respondToTradeOffer", [
            "offerId": offerId,
            "accept": accept
        ])
    }
    
    func joinLocationGroup(district: String) {
        socket?.emit("joinLocationGroup", district)
    }
    
    func leaveLocationGroup(district: String) {
        socket?.emit("leaveLocationGroup", district)
    }
    
    // MARK: - Auction Methods
    func joinAuction(auctionId: String) {
        socket?.emit("joinAuction", [
            "auctionId": auctionId
        ])
    }
    
    func leaveAuction(auctionId: String) {
        socket?.emit("leaveAuction", [
            "auctionId": auctionId
        ])
    }
    
    func submitAuctionBid(auctionId: String, playerId: String, bidAmount: Int) {
        socket?.emit("submitAuctionBid", [
            "auctionId": auctionId,
            "playerId": playerId,
            "bidAmount": bidAmount
        ])
    }

    // MARK: - Trade Broadcasting
    func broadcastTradeCompletion(
        playerId: String,
        merchantId: String,
        itemName: String,
        tradeType: String,
        amount: Int,
        isProfit: Bool
    ) {
        socket?.emit("tradeCompleted", [
            "playerId": playerId,
            "merchantId": merchantId,
            "itemName": itemName,
            "tradeType": tradeType,
            "amount": amount,
            "isProfit": isProfit,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}