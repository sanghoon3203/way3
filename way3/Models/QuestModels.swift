import Foundation

// MARK: - Server Quest DTOs

struct QuestListResponse: Codable {
    let success: Bool
    let data: QuestListData?
    let error: String?
}

struct QuestListData: Codable {
    let playerId: String
    let playerLevel: Int
    let playerLicense: Int
    let totalQuests: Int
    let questsByStatus: QuestsByStatus
    let summary: QuestSummary
}

struct QuestsByStatus: Codable {
    let available: [QuestData]
    let active: [QuestData]
    let completed: [QuestData]
    let claimed: [QuestData]
}

struct QuestSummary: Codable {
    let available: Int
    let active: Int
    let completed: Int
    let claimed: Int
}

struct QuestData: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let category: String
    let questType: String
    let maxProgress: Int
    let currentProgress: Int
    let rewards: QuestRewards
    let requirements: QuestRequirements?
    let isRepeatable: Bool
    let cooldownHours: Int
    let priority: Int
    let status: String
    let acceptedAt: String?
    let completedAt: String?
    let expiresAt: String?
    let rewardClaimed: Bool
}

struct QuestRewardItem: Codable, Hashable {
    let itemId: String
    let quantity: Int
}

struct QuestActionResponse: Codable {
    let success: Bool
    let data: QuestActionData?
    let message: String?
    let error: String?
}

struct QuestActionData: Codable {
    let questId: String
    let title: String
    let description: String
    let status: String
    let acceptedAt: String
    let expiresAt: String?
}

struct QuestRewardResponse: Codable {
    let success: Bool
    let data: QuestRewardData?
    let message: String?
    let error: String?
}

struct QuestRewardData: Codable {
    let questId: String
    let title: String
    let rewards: QuestRewards
}

struct QuestProgressResponse: Codable {
    let success: Bool
    let data: QuestProgressData?
    let error: String?
}

struct QuestProgressData: Codable {
    let actionType: String
    let updatedQuests: [QuestProgressUpdate]
    let questsUpdated: Int
}

struct QuestProgressUpdate: Codable {
    let questId: String
    let title: String
    let oldProgress: Int
    let newProgress: Int
    let maxProgress: Int
    let isCompleted: Bool
    let progressDelta: Int
}

struct QuestHistoryResponse: Codable {
    let success: Bool
    let data: QuestHistoryData?
    let error: String?
}

struct QuestHistoryData: Codable {
    let quests: [QuestHistoryItem]
    let pagination: PaginationInfo
}

struct QuestHistoryItem: Codable {
    let questId: String
    let title: String
    let description: String
    let category: String
    let questType: String
    let status: String
    let currentProgress: Int
    let acceptedAt: String?
    let completedAt: String?
    let rewardClaimed: Bool
    let rewards: QuestRewards
}

// MARK: - Shared Quest Data (SubQuests + Rewards)

struct SubQuest: Codable, Identifiable, Hashable {
    let quest_id: String
    let title: String
    let type: QuestType
    let verification: QuestVerification
    let requirements: QuestRequirements
    let rewards: QuestRewards

    var id: String { quest_id }

    var iconName: String {
        switch type {
        case .trading: return "creditcard.fill"
        case .delivery: return "location.fill"
        case .dialogue: return "bubble.left.and.bubble.right.fill"
        }
    }

    var typeDescription: String {
        switch type {
        case .trading: return "거래 퀘스트"
        case .delivery: return "배달 퀘스트"
        case .dialogue: return "대화 퀘스트"
        }
    }
}

struct QuestLocation: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let radius: Int
}

enum QuestType: String, Codable {
    case trading = "trading"
    case delivery = "delivery"
    case dialogue = "dialogue"
}

enum QuestVerification: String, Codable {
    case receipt_ocr = "receipt_ocr"
    case gps_location = "gps_location"
    case story_completion = "story_completion"
}

struct QuestRequirements: Codable, Hashable {
    // Server-side requirements
    let minLevel: Int?
    let requiredLicense: Int?
    let requiredItems: [String]?
    let reputationRequirement: Int?
    let requiredMoney: Int?

    // Subquest-specific fields
    let location: QuestLocation?
    let min_purchase: Int?
    let target_location: QuestLocation?
    let time_limit: Int?
    let story_node_complete: String?
    let story_node_start: String?
    let required_story_pieces: [String]
    let required_main_quests: [String]
    let required_sub_quests: [String]
    let required_level: Int?

    init(
        minLevel: Int? = nil,
        requiredLicense: Int? = nil,
        requiredItems: [String]? = nil,
        reputationRequirement: Int? = nil,
        requiredMoney: Int? = nil,
        location: QuestLocation? = nil,
        min_purchase: Int? = nil,
        target_location: QuestLocation? = nil,
        time_limit: Int? = nil,
        story_node_complete: String? = nil,
        story_node_start: String? = nil,
        required_story_pieces: [String] = [],
        required_main_quests: [String] = [],
        required_sub_quests: [String] = [],
        required_level: Int? = nil
    ) {
        self.minLevel = minLevel
        self.requiredLicense = requiredLicense
        self.requiredItems = requiredItems
        self.reputationRequirement = reputationRequirement
        self.requiredMoney = requiredMoney
        self.location = location
        self.min_purchase = min_purchase
        self.target_location = target_location
        self.time_limit = time_limit
        self.story_node_complete = story_node_complete
        self.story_node_start = story_node_start
        self.required_story_pieces = required_story_pieces
        self.required_main_quests = required_main_quests
        self.required_sub_quests = required_sub_quests
        self.required_level = required_level
    }

    private enum CodingKeys: String, CodingKey {
        case minLevel, requiredLicense, requiredItems, reputationRequirement, requiredMoney
        case location, min_purchase, target_location, time_limit
        case story_node_complete, story_node_start
        case required_story_pieces, required_main_quests, required_sub_quests, required_level
    }
}

// MARK: - Convenience Accessors
extension QuestRequirements {
    /// 스토리 조각 요구사항 (snake_case 필드 래핑)
    var requiredStoryPieces: [String] { required_story_pieces }
    /// 선행 메인 퀘스트 요구사항
    var requiredMainQuests: [String] { required_main_quests }
    /// 선행 서브 퀘스트 요구사항
    var requiredSubQuests: [String] { required_sub_quests }
}

struct QuestRewards: Codable, Hashable {
    // Server fields
    let experience: Int?
    let money: Int?
    let trustPoints: Int?
    let items: [QuestRewardItem]?

    // Subquest fields
    let exp: Int?
    let storyPieceIds: [String]
    let inventoryItems: [String]
    let keyItems: [String]
    let relationshipChange: RelationshipChange?

    init(
        experience: Int? = nil,
        money: Int? = nil,
        trustPoints: Int? = nil,
        items: [QuestRewardItem]? = nil,
        exp: Int? = nil,
        storyPieceIds: [String] = [],
        inventoryItems: [String] = [],
        keyItems: [String] = [],
        relationshipChange: RelationshipChange? = nil
    ) {
        self.experience = experience
        self.money = money
        self.trustPoints = trustPoints
        self.items = items
        self.exp = exp
        self.storyPieceIds = storyPieceIds
        self.inventoryItems = inventoryItems
        self.keyItems = keyItems
        self.relationshipChange = relationshipChange
    }

    private enum CodingKeys: String, CodingKey {
        case experience, money, trustPoints, items
        case exp
        case storyPieceIds = "story_piece_ids"
        case inventoryItems = "inventory_items"
        case keyItems = "key_items"
        case singleStoryPiece = "item_id"
        case relationshipChange = "relationship_change"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        experience = try container.decodeIfPresent(Int.self, forKey: .experience)
        money = try container.decodeIfPresent(Int.self, forKey: .money)
        trustPoints = try container.decodeIfPresent(Int.self, forKey: .trustPoints)
        items = try container.decodeIfPresent([QuestRewardItem].self, forKey: .items)
        let decodedExp = try container.decodeIfPresent(Int.self, forKey: .exp)
        exp = decodedExp ?? experience
        relationshipChange = try container.decodeIfPresent(RelationshipChange.self, forKey: .relationshipChange)

        let storyPieces = try container.decodeIfPresent([String].self, forKey: .storyPieceIds) ?? []
        if let single = try container.decodeIfPresent(String.self, forKey: .singleStoryPiece) {
            storyPieceIds = Array(Set(storyPieces + [single]))
        } else {
            storyPieceIds = storyPieces
        }

        inventoryItems = try container.decodeIfPresent([String].self, forKey: .inventoryItems) ?? []
        keyItems = try container.decodeIfPresent([String].self, forKey: .keyItems) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(exp ?? experience, forKey: .exp)
        try container.encodeIfPresent(money, forKey: .money)
        try container.encodeIfPresent(storyPieceIds, forKey: .storyPieceIds)
        try container.encodeIfPresent(inventoryItems, forKey: .inventoryItems)
        try container.encodeIfPresent(keyItems, forKey: .keyItems)
        try container.encodeIfPresent(relationshipChange, forKey: .relationshipChange)
    }
    static func == (lhs: QuestRewards, rhs: QuestRewards) -> Bool {
        lhs.experience == rhs.experience &&
        lhs.money == rhs.money &&
        lhs.trustPoints == rhs.trustPoints &&
        lhs.items == rhs.items &&
        lhs.exp == rhs.exp &&
        lhs.storyPieceIds == rhs.storyPieceIds &&
        lhs.inventoryItems == rhs.inventoryItems &&
        lhs.keyItems == rhs.keyItems &&
        lhs.relationshipChange == rhs.relationshipChange
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(experience)
        hasher.combine(money)
        hasher.combine(trustPoints)
        hasher.combine(items)
        hasher.combine(exp)
        hasher.combine(storyPieceIds)
        hasher.combine(inventoryItems)
        hasher.combine(keyItems)
        hasher.combine(relationshipChange)
    }
}

struct RelationshipChange: Codable, Hashable {
    let merchantId: String
    let trust: Int

    private enum CodingKeys: String, CodingKey {
        case merchantId = "merchant_id"
        case trust
    }
}
