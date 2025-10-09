// 📁 Core/DataManager.swift - 데이터 관리 전담
import Foundation
import SwiftUI
import CoreLocation
import Combine

// MARK: - Supporting Types
struct GameEvent: Identifiable, Codable {
    let id = UUID()
    let type: EventType
    let title: String
    let description: String
    let timestamp: Date
    
    enum EventType: String, Codable {
        case priceChange, merchantUpdate, tradeCompleted, playerJoined
    }
}

class DataManager: ObservableObject {
    // MARK: - Published Properties
    @Published var merchants: [Merchant] = []
    @Published var availableItems: [TradeItem] = []
    @Published var priceBoard: [String: (district: SeoulDistrict, price: Int)] = [:]
    @Published var realTimeEvents: [GameEvent] = []
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var itemResetTimer: Timer?
    
    // MARK: - Delegates
    weak var delegate: DataManagerDelegate?
    
    // MARK: - Initialization
    init() {
        setupNetworkBindings()
        setupItemResetTimer()
    }
    
    deinit {
        itemResetTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func loadOnlineGameData() async {
        async let playerData = loadPlayerData()
        async let marketData = loadMarketData()
        async let merchantData = loadMerchantData()
        
        let (_, _, _) = await (playerData, marketData, merchantData)
    }
    
    func updateMerchants(_ merchantData: [MerchantData]) {
        merchants = merchantData.compactMap { data in
            // 정확한 enum 변환 확인
            guard let merchantType = MerchantType(rawValue: data.type),
                  let district = SeoulDistrict(rawValue: data.district),
                  let license = LicenseLevel(rawValue: data.requiredLicense) else {
                return nil
            }
            
            // 단순화된 Merchant 생성자
            return Merchant(
                name: data.name,
                type: merchantType,
                district: district,
                coordinate: CLLocationCoordinate2D(
                    latitude: data.location.lat,
                    longitude: data.location.lng
                ),
                requiredLicense: license,
                inventory: data.inventory
            )
        }
    }
    
    func updateNearbyMerchants(_ nearbyMerchants: [Merchant]) {
        var updatedMerchants = merchants
        
        for nearbyMerchant in nearbyMerchants {
            if let index = updatedMerchants.firstIndex(where: { $0.id == nearbyMerchant.id }) {
                updatedMerchants[index] = nearbyMerchant
            } else {
                updatedMerchants.append(nearbyMerchant)
            }
        }
        
        merchants = updatedMerchants
    }
    
    func updateMarketPrices(_ prices: [MarketPrice]) {
        var newPriceBoard: [String: (district: SeoulDistrict, price: Int)] = [:]
        
        for price in prices {
            let randomDistrict = SeoulDistrict.allCases.randomElement() ?? .gangnam
            newPriceBoard[price.itemName] = (district: randomDistrict, price: price.currentPrice)
        }
        
        priceBoard = newPriceBoard
    }
    
    func applyPriceUpdates(_ updates: [String: Int]) {
        for (itemName, newPrice) in updates {
            if let existingItem = priceBoard[itemName] {
                priceBoard[itemName] = (district: existingItem.district, price: newPrice)
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupNetworkBindings() {
        // 가격 업데이트 구독 (추후 구현)
        // socketManager.$marketPriceUpdates
        
        // 근처 플레이어 구독 (추후 구현)
        // socketManager.$nearbyPlayers
        
        // 실시간 거래 활동 구독 (추후 구현)
        // socketManager.$recentTradeActivity
    }
    
    private func loadPlayerData() async {
        do {
            let response = try await networkManager.getPlayerData()
            if let data = response.data {
                await delegate?.onPlayerDataReceived(data)
            }
        } catch {
            print("플레이어 데이터 로드 실패: \(error)")
        }
    }
    
    private func loadMarketData() async {
        do {
            let response = try await networkManager.getMarketPrices()
            if let prices = response.data {
                await MainActor.run {
                    self.updateMarketPrices(prices)
                }
            }
        } catch {
            print("시장 데이터 로드 실패: \(error)")
        }
    }
    
    private func loadMerchantData() async {
        do {
            let response = try await networkManager.getMerchants()
            if let merchants = response.data {
                await MainActor.run {
                    self.updateMerchants(merchants)
                }
            }
        } catch {
            print("상인 데이터 로드 실패: \(error)")
        }
    }
    
    private func setupItemResetTimer() {
        itemResetTimer?.invalidate()
        itemResetTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.refreshData()
        }
    }
    
    private func refreshData() {
        updatePriceBoard()
        delegate?.onDataRefresh()
    }
    
    private func updatePriceBoard() {
        for (item, info) in priceBoard {
            let variation = Double.random(in: 0.8...1.2)
            let newPrice = Int(Double(info.price) * variation)
            priceBoard[item] = (district: info.district, price: newPrice)
        }
    }
}

// MARK: - OfflineDataGenerator
class OfflineDataGenerator {
    func generateOfflineData() -> (merchants: [Merchant], items: [TradeItem]) {
        let merchants: [Merchant] = [
            Merchant(
                name: "전통시장 할머니",
                type: .retail,
                district: .jongno,
                coordinate: CLLocationCoordinate2D(latitude: 37.5735, longitude: 126.9788),
                requiredLicense: .beginner,
                inventory: []
            ),
            Merchant(
                name: "청과물상",
                type: .wholesale,
                district: .gangnam,
                coordinate: CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276),
                requiredLicense: .beginner,
                inventory: []
            )
        ]
        
        let items: [TradeItem] = [
            TradeItem(
                itemId: "apple_001",
                name: "사과",
                category: "food",
                grade: .common,
                requiredLicense: .beginner,
                basePrice: 800,
                currentPrice: 800,
                weight: 0.2,
                description: "신선한 사과",
                iconId: 1
            )
        ]
        
        return (merchants: merchants, items: items)
    }
}

// MARK: - DataManagerDelegate
protocol DataManagerDelegate: AnyObject {
    func onPlayerDataReceived(_ data: PlayerDetail) async
    func onDataRefresh()
}
