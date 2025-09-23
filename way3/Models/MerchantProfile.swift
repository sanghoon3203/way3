// 📁 Models/MerchantProfile.swift - 상인 프로필 모델
import Foundation
import CoreLocation

/// 상인의 기본 프로필 정보
struct MerchantProfile: Identifiable, Codable {
    let id: String
    let name: String
    let title: String?
    let type: MerchantType
    let personality: PersonalityType
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    let requiredLicense: LicenseLevel
    let reputationRequirement: Int
    let priceModifier: Double
    let negotiationDifficulty: Int
    let preferredCategories: [String]
    let dislikedCategories: [String]

    // MARK: - Computed Properties
    var displayTitle: String {
        return title ?? type.displayName
    }

    var accessibilityDescription: String {
        let licenseText = requiredLicense == .beginner ? "누구나" : "\(requiredLicense.displayName) 이상"
        return "\(name), \(displayTitle), \(district.name)구, \(licenseText) 거래 가능"
    }

    // MARK: - CLLocationCoordinate2D Codable 지원
    enum CodingKeys: String, CodingKey {
        case id, name, title, type, personality, district
        case latitude, longitude
        case requiredLicense, reputationRequirement, priceModifier
        case negotiationDifficulty, preferredCategories, dislikedCategories
    }

    init(
        id: String,
        name: String,
        title: String? = nil,
        type: MerchantType,
        personality: PersonalityType,
        district: SeoulDistrict,
        coordinate: CLLocationCoordinate2D,
        requiredLicense: LicenseLevel = .beginner,
        reputationRequirement: Int = 0,
        priceModifier: Double = 1.0,
        negotiationDifficulty: Int = 3,
        preferredCategories: [String] = [],
        dislikedCategories: [String] = []
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.type = type
        self.personality = personality
        self.district = district
        self.coordinate = coordinate
        self.requiredLicense = requiredLicense
        self.reputationRequirement = reputationRequirement
        self.priceModifier = priceModifier
        self.negotiationDifficulty = negotiationDifficulty
        self.preferredCategories = preferredCategories
        self.dislikedCategories = dislikedCategories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        type = try container.decode(MerchantType.self, forKey: .type)
        personality = try container.decode(PersonalityType.self, forKey: .personality)
        district = try container.decode(SeoulDistrict.self, forKey: .district)

        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        requiredLicense = try container.decode(LicenseLevel.self, forKey: .requiredLicense)
        reputationRequirement = try container.decode(Int.self, forKey: .reputationRequirement)
        priceModifier = try container.decode(Double.self, forKey: .priceModifier)
        negotiationDifficulty = try container.decode(Int.self, forKey: .negotiationDifficulty)
        preferredCategories = try container.decode([String].self, forKey: .preferredCategories)
        dislikedCategories = try container.decode([String].self, forKey: .dislikedCategories)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(personality, forKey: .personality)
        try container.encode(district, forKey: .district)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(requiredLicense, forKey: .requiredLicense)
        try container.encode(reputationRequirement, forKey: .reputationRequirement)
        try container.encode(priceModifier, forKey: .priceModifier)
        try container.encode(negotiationDifficulty, forKey: .negotiationDifficulty)
        try container.encode(preferredCategories, forKey: .preferredCategories)
        try container.encode(dislikedCategories, forKey: .dislikedCategories)
    }
}

/// 상인 관계 정보
struct MerchantRelationship: Codable {
    let friendshipPoints: Int
    let trustLevel: Int
    let totalTrades: Int
    let totalSpent: Int
    let lastInteraction: String?
    let notes: String?

    // MARK: - Computed Properties
    var friendshipLevel: FriendshipLevel {
        switch friendshipPoints {
        case 0..<25: return .stranger
        case 25..<75: return .acquaintance
        case 75..<150: return .friend
        case 150..<300: return .closeFriend
        default: return .bestFriend
        }
    }

    var trustDescription: String {
        switch trustLevel {
        case 0..<20: return "신뢰하지 않음"
        case 20..<50: return "조금 신뢰함"
        case 50..<80: return "신뢰함"
        case 80..<95: return "매우 신뢰함"
        default: return "완전히 신뢰함"
        }
    }

    var canGetDiscount: Bool {
        return friendshipPoints >= 50 || trustLevel >= 60
    }

    var discountPercentage: Double {
        let friendshipBonus = min(Double(friendshipPoints) / 500.0, 0.15) // 최대 15%
        let trustBonus = min(Double(trustLevel) / 500.0, 0.10) // 최대 10%
        return friendshipBonus + trustBonus
    }
}

enum FriendshipLevel: String, CaseIterable {
    case stranger = "stranger"
    case acquaintance = "acquaintance"
    case friend = "friend"
    case closeFriend = "close_friend"
    case bestFriend = "best_friend"

    var displayName: String {
        switch self {
        case .stranger: return "모르는 사이"
        case .acquaintance: return "아는 사이"
        case .friend: return "친구"
        case .closeFriend: return "가까운 친구"
        case .bestFriend: return "절친"
        }
    }

    var emoji: String {
        switch self {
        case .stranger: return "👤"
        case .acquaintance: return "🙋"
        case .friend: return "😊"
        case .closeFriend: return "😄"
        case .bestFriend: return "🥰"
        }
    }
}

/// 근처 상인 미리보기 정보 (지도용)
struct MerchantPreview: Identifiable {
    let id: String
    let name: String
    let title: String?
    let type: MerchantType
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    let distance: Double
    let canTrade: Bool
    let inventoryCount: Int

    var distanceText: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }

    var statusEmoji: String {
        if !canTrade {
            return "🔒"
        } else if inventoryCount == 0 {
            return "📦"
        } else {
            return "💼"
        }
    }
}