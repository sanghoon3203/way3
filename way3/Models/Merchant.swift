// 📁 Models/Merchant.swift - 오류 수정된 버전
import Foundation
import CoreLocation
import SwiftUI

struct Merchant: Identifiable {
    let id: String
    
    // 기본 정보
    let name: String
    let title: String?
    let type: MerchantType
    let personality: MerchantPersonality
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    
    // 거래 관련
    let requiredLicense: LicenseLevel
    var inventory: [TradeItem]
    let priceModifier: Double
    let negotiationDifficulty: Int // 1-5 (1이 쉬움)
    
    // 선호도 시스템
    let preferredItems: [String] // 카테고리 배열
    let dislikedItems: [String]  // 카테고리 배열
    let reputationRequirement: Int
    
    // 상태 시스템
    var isActive: Bool
    var lastRestocked: Date

    // 이미지 정보
    var imageFileName: String?

    // 거리 (계산된 값, 옵셔널)
    var distance: Double = 0.0
    
    // MARK: - 초기화
    init(
        id: String = UUID().uuidString,
        name: String,
        title: String? = nil,
        type: MerchantType,
        personality: MerchantPersonality = .calm,
        district: SeoulDistrict,
        coordinate: CLLocationCoordinate2D,
        requiredLicense: LicenseLevel,
        inventory: [TradeItem] = [],
        priceModifier: Double = 1.0,
        negotiationDifficulty: Int = 3,
        preferredItems: [String] = [],
        dislikedItems: [String] = [],
        reputationRequirement: Int = 0,
        isActive: Bool = true,
        imageFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.type = type
        self.personality = personality
        self.district = district
        self.coordinate = coordinate
        self.requiredLicense = requiredLicense
        self.inventory = inventory
        self.priceModifier = priceModifier
        self.negotiationDifficulty = negotiationDifficulty
        self.preferredItems = preferredItems
        self.dislikedItems = dislikedItems
        self.reputationRequirement = reputationRequirement
        self.isActive = isActive
        self.imageFileName = imageFileName
        self.lastRestocked = Date()
    }
    
    // MARK: - 서버 응답용 초기화
    init(from serverMerchant: ServerMerchantResponse) {
        self.id = serverMerchant.id
        self.name = serverMerchant.name
        self.title = serverMerchant.title
        self.type = MerchantType(rawValue: serverMerchant.type) ?? .retail
        self.personality = MerchantPersonality(rawValue: serverMerchant.personality) ?? .calm
        self.district = SeoulDistrict(rawValue: serverMerchant.district) ?? .gangnam
        self.coordinate = CLLocationCoordinate2D(
            latitude: serverMerchant.location.lat,
            longitude: serverMerchant.location.lng
        )
        self.requiredLicense = LicenseLevel(rawValue: serverMerchant.requiredLicense) ?? .beginner
        self.inventory = serverMerchant.inventory.map { TradeItem(from: $0) }
        self.priceModifier = serverMerchant.priceModifier
        self.negotiationDifficulty = serverMerchant.negotiationDifficulty
        self.preferredItems = serverMerchant.preferredItems ?? []
        self.dislikedItems = serverMerchant.dislikedItems ?? []
        self.reputationRequirement = serverMerchant.reputationRequirement
        self.isActive = serverMerchant.isActive
        self.imageFileName = serverMerchant.imageFileName
        self.lastRestocked = Date(timeIntervalSince1970: serverMerchant.lastRestocked)
    }
    
    // MARK: - 계산된 속성들 (호환성을 위해)
    var latitude: Double {
        return coordinate.latitude
    }
    
    var longitude: Double {
        return coordinate.longitude
    }
    
    var pinColor: Color {
        switch type {
        case .retail, .convenience: return .blue
        case .wholesale, .industrial: return .green
        case .premium, .luxury: return .purple
        case .artisan, .craftsman: return .orange
        case .mystic, .collector, .antique: return .red
        case .tech, .electronics: return .cyan
        case .fashion, .artist: return .pink
        case .herbalist, .natural, .forager: return .mint
        case .foodMerchant: return .yellow
        case .scholar: return .indigo
        case .student: return .teal
        case .tourist: return .brown
        }
    }
    
    var iconName: String {
        switch type {
        case .retail: return "cart.fill"
        case .wholesale: return "building.2.fill"
        case .premium: return "crown.fill"
        case .artisan: return "hammer.fill"
        case .mystic: return "sparkles"
        case .collector: return "archivebox.fill"
        case .tech: return "laptopcomputer"
        case .fashion: return "tshirt.fill"
        case .artist: return "paintbrush.fill"
        case .antique: return "scroll.fill"
        case .herbalist: return "leaf.fill"
        case .foodMerchant: return "fork.knife"
        case .industrial: return "gearshape.fill"
        case .luxury: return "gem.fill"
        case .scholar: return "book.fill"
        case .student: return "pencil"
        case .tourist: return "camera.fill"
        case .craftsman: return "wrench.fill"
        case .electronics: return "bolt.fill"
        case .natural: return "tree.fill"
        case .forager: return "basket.fill"
        case .convenience: return "bag.fill"
        }
    }
    
    
    // MARK: - 메서드들
    @MainActor func canTrade(with player: Player) -> Bool {
        // 라이센스 체크
        guard player.currentLicense.rawValue >= requiredLicense.rawValue else { return false }

        // 평판 체크
        guard player.reputation >= reputationRequirement else { return false }

        // 활성 상태 체크
        guard isActive else { return false }

        return true
    }
    
    func getFinalPrice(for item: TradeItem, player: Player) -> Int {
        var finalPrice = Double(item.currentPrice)
        
        // 기본 가격 수정자 적용
        finalPrice *= priceModifier
        
        // 선호 아이템 할인
        if preferredItems.contains(item.category) {
            finalPrice *= 0.9 // 10% 할인
        }
        
        // 비선호 아이템 할증
        if dislikedItems.contains(item.category) {
            finalPrice *= 1.2 // 20% 할증
        }
        
        return max(Int(finalPrice), 1) // 최소 1원
    }
    
}

// MARK: - Codable Implementation
extension Merchant: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, title, type, personality, district
        case coordinateLatitude, coordinateLongitude
        case requiredLicense, inventory, priceModifier, negotiationDifficulty
        case preferredItems, dislikedItems, reputationRequirement
        case isActive, lastRestocked, imageFileName, distance
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        type = try container.decode(MerchantType.self, forKey: .type)
        personality = try container.decode(MerchantPersonality.self, forKey: .personality)
        district = try container.decode(SeoulDistrict.self, forKey: .district)
        
        let latitude = try container.decode(Double.self, forKey: .coordinateLatitude)
        let longitude = try container.decode(Double.self, forKey: .coordinateLongitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        requiredLicense = try container.decode(LicenseLevel.self, forKey: .requiredLicense)
        inventory = try container.decode([TradeItem].self, forKey: .inventory)
        priceModifier = try container.decode(Double.self, forKey: .priceModifier)
        negotiationDifficulty = try container.decode(Int.self, forKey: .negotiationDifficulty)
        preferredItems = try container.decode([String].self, forKey: .preferredItems)
        dislikedItems = try container.decode([String].self, forKey: .dislikedItems)
        reputationRequirement = try container.decode(Int.self, forKey: .reputationRequirement)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        lastRestocked = try container.decode(Date.self, forKey: .lastRestocked)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance) ?? 0.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(personality, forKey: .personality)
        try container.encode(district, forKey: .district)
        try container.encode(coordinate.latitude, forKey: .coordinateLatitude)
        try container.encode(coordinate.longitude, forKey: .coordinateLongitude)
        try container.encode(requiredLicense, forKey: .requiredLicense)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(priceModifier, forKey: .priceModifier)
        try container.encode(negotiationDifficulty, forKey: .negotiationDifficulty)
        try container.encode(preferredItems, forKey: .preferredItems)
        try container.encode(dislikedItems, forKey: .dislikedItems)
        try container.encode(reputationRequirement, forKey: .reputationRequirement)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(lastRestocked, forKey: .lastRestocked)
        try container.encodeIfPresent(imageFileName, forKey: .imageFileName)
        try container.encode(distance, forKey: .distance)
    }
}

// MARK: - Enums and Supporting Types

// ✅ 수정된 MerchantType
enum MerchantType: String, CaseIterable, Codable {
    case retail = "retail"           // 말단상인
    case wholesale = "wholesale"     // 중간상인
    case premium = "premium"         // 중요대상인
    case artisan = "artisan"         // 장인
    case mystic = "mystic"          // 신비상인
    case collector = "collector"     // 수집가
    // 새로 추가된 상인 타입들
    case tech = "tech"               // 기술상인
    case fashion = "fashion"         // 패션상인
    case artist = "artist"           // 예술가
    case antique = "antique"         // 골동품상
    case herbalist = "herbalist"     // 약초상
    case foodMerchant = "food"       // 식품상인
    case industrial = "industrial"   // 공업용품상
    case luxury = "luxury"           // 명품상인
    case scholar = "scholar"         // 서적상인
    case student = "student"         // 학용품상
    case tourist = "tourist"         // 관광상품상
    case craftsman = "craftsman"     // 수공예가
    case electronics = "electronics" // 전자제품상
    case natural = "natural"         // 천연제품상
    case forager = "forager"         // 채집가
    case convenience = "convenience" // 일용품상
    
    var displayName: String {
        switch self {
        case .retail: return "말단상인"
        case .wholesale: return "중간상인"
        case .premium: return "중요상인"
        case .artisan: return "장인"
        case .mystic: return "신비상인"
        case .collector: return "수집가"
        case .tech: return "기술상인"
        case .fashion: return "패션상인"
        case .artist: return "예술가"
        case .antique: return "골동품상"
        case .herbalist: return "약초상"
        case .foodMerchant: return "식품상인"
        case .industrial: return "공업용품상"
        case .luxury: return "명품상인"
        case .scholar: return "서적상인"
        case .student: return "학용품상"
        case .tourist: return "관광상품상"
        case .craftsman: return "수공예가"
        case .electronics: return "전자제품상"
        case .natural: return "천연제품상"
        case .forager: return "채집가"
        case .convenience: return "일용품상"
        }
    }
    
    var maxItemGrade: ItemGrade {
        switch self {
        case .retail: return .intermediate
        case .wholesale: return .rare
        case .premium, .artisan: return .legendary
        case .mystic, .collector: return .legendary
        case .tech, .electronics: return .rare
        case .fashion, .luxury: return .legendary
        case .artist, .antique: return .legendary
        case .herbalist, .natural, .forager: return .rare
        case .foodMerchant: return .intermediate
        case .industrial, .craftsman: return .rare
        case .scholar: return .rare
        case .student, .convenience: return .common
        case .tourist: return .intermediate
        }
    }
}

// ✅ 단순화된 MerchantPersonality (만리 무역상에 맞게)
enum MerchantPersonality: String, CaseIterable, Codable {
    case calm = "calm"           // 침착한
    case shrewd = "shrewd"       // 약삭빠른
    case generous = "generous"   // 관대한
    case strict = "strict"       // 까다로운
    // 새로 추가된 성격 타입들
    case analytical = "analytical"     // 분석적인
    case elegant = "elegant"           // 우아한
    case creative = "creative"         // 창의적인
    case wise = "wise"                 // 현명한
    case scholarly = "scholarly"       // 학자적인
    case motherly = "motherly"         // 모성적인
    case practical = "practical"       // 실용적인
    case cosmopolitan = "cosmopolitan" // 국제적인
    case intellectual = "intellectual" // 지적인
    case energetic = "energetic"       // 활기찬
    case sophisticated = "sophisticated" // 세련된
    case friendly = "friendly"         // 친근한
    case meticulous = "meticulous"     // 꼼꼼한
    case techSavvy = "techSavvy"       // 기술에 밝은
    case peaceful = "peaceful"         // 평화로운
    case rustic = "rustic"             // 소박한
    
    var personalityDisplayName: String {
        switch self {
        case .calm: return "침착한"
        case .shrewd: return "약삭빠른"
        case .generous: return "관대한"
        case .strict: return "까다로운"
        case .analytical: return "분석적인"
        case .elegant: return "우아한"
        case .creative: return "창의적인"
        case .wise: return "현명한"
        case .scholarly: return "학자적인"
        case .motherly: return "모성적인"
        case .practical: return "실용적인"
        case .cosmopolitan: return "국제적인"
        case .intellectual: return "지적인"
        case .energetic: return "활기찬"
        case .sophisticated: return "세련된"
        case .friendly: return "친근한"
        case .meticulous: return "꼼꼼한"
        case .techSavvy: return "기술에 밝은"
        case .peaceful: return "평화로운"
        case .rustic: return "소박한"
        }
    }
}

// MARK: - 서버 응답 모델들 (LocationData 중복 제거)
struct MerchantLocationData: Codable {
    let lat: Double
    let lng: Double
}

struct ServerMerchantResponse: Codable {
    let id: String
    let name: String
    let title: String?
    let type: String
    let personality: String
    let district: String
    let location: MerchantLocationData
    let requiredLicense: Int
    let inventory: [ServerItemResponse]
    let priceModifier: Double
    let negotiationDifficulty: Int
    let preferredItems: [String]?
    let dislikedItems: [String]?
    let reputationRequirement: Int
    let isActive: Bool
    let lastRestocked: TimeInterval
    let imageFileName: String?
}

// 기존 GameEnums.swift에 정의된 enum들을 사용

// Player 모델은 기존 Models/Player.swift에 정의됨

// TradeItem과 ServerItemResponse는 기존 파일에 정의됨