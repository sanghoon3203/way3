// 📁 Models/TradeItem.swift - 순수 무역품 전용
import Foundation
import CoreLocation

struct TradeItem: Identifiable, Codable, Equatable {
    let id: String
    let itemId: String
    let name: String
    let category: String
    
    // 등급 및 거래 조건
    let grade: ItemGrade
    let requiredLicense: LicenseLevel
    
    // 가격 시스템 (100원 단위로 단순화)
    let basePrice: Int
    var currentPrice: Int
    var marketValue: Int?
    
    // 가격을 100원 단위로 반올림하는 computed property
    var displayPrice: Int {
        return ((currentPrice + 50) / 100) * 100
    }
    
    var displayBasePrice: Int {
        return ((basePrice + 50) / 100) * 100
    }
    
    // 구매 기록 추가 (수익 계산용)
    var purchasePrice: Int?
    var purchaseDate: Date?
    
    // 수익 계산
    func calculateProfit(sellPrice: Int) -> ProfitInfo {
        guard let buyPrice = purchasePrice else {
            return ProfitInfo(profit: 0, profitPercentage: 0, isProfitable: false)
        }
        
        let profit = sellPrice - buyPrice
        let profitPercentage = Double(profit) / Double(buyPrice) * 100
        
        return ProfitInfo(
            profit: profit,
            profitPercentage: profitPercentage,
            isProfitable: profit > 0
        )
    }
    
    // 거래 속성
    let weight: Double
    var quantity: Int = 1
    let description: String
    let iconId: Int
    
    // 호환성을 위한 iconName 계산 프로퍼티
    var iconName: String {
        switch category {
        case "food", "식품": return "leaf.fill"
        case "craft", "수공예": return "hammer.fill"
        case "luxury", "명품": return "gem.fill"
        case "electronics", "전자": return "bolt.fill"
        case "fashion", "패션": return "tshirt.fill"
        case "antique", "골동품": return "archivebox.fill"
        case "medicine", "의약품": return "cross.fill"
        case "books", "서적": return "book.fill"
        case "industrial", "공업": return "gearshape.fill"
        case "natural", "천연": return "tree.fill"
        default: return "cube.fill"
        }
    }
    
    // MARK: - 초기화
    init(
        itemId: String,
        name: String,
        category: String,
        grade: ItemGrade,
        requiredLicense: LicenseLevel,
        basePrice: Int,
        currentPrice: Int? = nil,
        weight: Double = 1.0,
        description: String = "",
        iconId: Int = 1
    ) {
        self.id = UUID().uuidString
        self.itemId = itemId
        self.name = name
        self.category = category
        self.grade = grade
        self.requiredLicense = requiredLicense
        self.basePrice = basePrice
        self.currentPrice = currentPrice ?? basePrice
        self.weight = weight
        self.description = description
        self.iconId = iconId
    }
    
    // MARK: - 서버 응답용 초기화
    init(from serverItem: ServerItemResponse) {
        self.id = UUID().uuidString
        self.itemId = serverItem.id
        self.name = serverItem.name
        self.category = serverItem.category
        // String을 Int로 변환하여 ItemGrade 생성
        let gradeInt: Int
        switch serverItem.grade {
        case "common": gradeInt = 0
        case "intermediate": gradeInt = 1  
        case "advanced": gradeInt = 2
        case "rare": gradeInt = 3
        case "legendary": gradeInt = 4
        default: gradeInt = 0
        }
        self.grade = ItemGrade(rawValue: gradeInt) ?? .common
        self.requiredLicense = LicenseLevel(rawValue: serverItem.requiredLicense) ?? .beginner
        self.basePrice = serverItem.basePrice
        self.currentPrice = serverItem.currentPrice ?? serverItem.basePrice
        self.weight = 1.0
        self.description = serverItem.description ?? ""
        self.iconId = serverItem.iconId ?? 1
    }
    
    // MARK: - 메서드
    func canUse(by player: Player) -> Bool {
        return player.currentLicense.rawValue >= requiredLicense.rawValue
    }
    
    // 시장 가격 업데이트 (100원 단위로 반올림)
    mutating func updatePrice(for region: SeoulDistrict) {
        let regionMultiplier = region.priceMultiplier(for: category)
        let rawPrice = Int(Double(basePrice) * regionMultiplier)
        currentPrice = ((rawPrice + 50) / 100) * 100  // 100원 단위로 반올림
    }
    
    // 거리 기반 가격 업데이트 (새로운 기능)
    mutating func updatePriceWithDistance(
        for region: SeoulDistrict, 
        playerLocation: CLLocationCoordinate2D, 
        merchantLocation: CLLocationCoordinate2D
    ) {
        let regionMultiplier = region.priceMultiplier(for: category)
        let distance = playerLocation.distance(to: merchantLocation)
        
        // 거리 기반 배수 계산 (1km당 2% 할증, 최대 50% 할증)
        let distanceMultiplier = min(1.0 + (distance / 1000.0) * 0.02, 1.5)
        
        let rawPrice = Int(Double(basePrice) * regionMultiplier * distanceMultiplier)
        currentPrice = ((rawPrice + 50) / 100) * 100  // 100원 단위로 반올림
    }
    
    // 구매 기록 설정 (GameManager에서 호출)
    mutating func setPurchaseInfo(price: Int, date: Date = Date()) {
        self.purchasePrice = price
        self.purchaseDate = date
    }
}

// MARK: - 간소화된 서버 응답 모델
struct ServerItemResponse: Codable {
    let id: String
    let name: String
    let category: String
    let grade: String
    let requiredLicense: Int
    let basePrice: Int
    let currentPrice: Int?
    let description: String?
    let iconId: Int?
}

// MARK: - 수익 계산 구조체
struct ProfitInfo {
    let profit: Int
    let profitPercentage: Double
    let isProfitable: Bool
    
    var displayProfit: Int {
        return ((profit + 50) / 100) * 100  // 100원 단위로 표시
    }
    
    var formattedProfitPercentage: String {
        return String(format: "%.1f%%", profitPercentage)
    }
    
    var profitDescription: String {
        if isProfitable {
            return "이익 +\(displayProfit.formatted())원 (\(formattedProfitPercentage))"
        } else {
            return "손실 \(displayProfit.formatted())원 (\(formattedProfitPercentage))"
        }
    }
}

// MARK: - CLLocationCoordinate2D Extension (거리 계산)
extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)  // 미터 단위
    }
}
