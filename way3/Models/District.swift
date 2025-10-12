//
//  District.swift
//  way3
//
//  구역/상인/퀘스트 시스템 모델
//  25개 구역, 각 구역마다 1개 상인 + 2-3개 서브퀘스트
//

import Foundation
import CoreLocation

// MARK: - District Model

struct District: Codable, Identifiable, Hashable {
    let district_id: String
    let chapter_id: String
    let name: String
    let merchant: MerchantQuest
    let unlock_condition: String

    var id: String { district_id }

    // 구역 완료 여부
    func isCompleted(progress: PlayerProgress) -> Bool {
        // 모든 서브퀘스트가 완료되어야 구역 완료
        return merchant.sub_quests.allSatisfy { progress.isQuestCompleted($0.quest_id) }
    }

    // 진행률 계산
    func progressPercentage(progress: PlayerProgress) -> Double {
        let completedCount = merchant.sub_quests.filter { progress.isQuestCompleted($0.quest_id) }.count
        return Double(completedCount) / Double(merchant.sub_quests.count) * 100
    }
}

// MARK: - Merchant Quest

struct MerchantQuest: Codable, Hashable {
    let merchant_id: String
    let name: String
    let location: QuestLocation
    let main_story_id: String
    let sub_quests: [SubQuest]

    // 상인 거리 계산
    func distance(from userLocation: CLLocationCoordinate2D) -> Double {
        let merchantLocation = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        return userLocation.distance(to: merchantLocation)
    }

    // 상인 위치 CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
    }

    // 반경 내 있는지 확인
    func isInRange(from userLocation: CLLocationCoordinate2D) -> Bool {
        return distance(from: userLocation) <= Double(location.radius)
    }
}

// MARK: - Sub Quest

struct SubQuest: Codable, Identifiable, Hashable {
    let quest_id: String
    let title: String
    let type: QuestType
    let verification: QuestVerification
    let requirements: QuestRequirements
    let rewards: QuestRewards

    var id: String { quest_id }

    // 퀘스트 타입별 아이콘
    var iconName: String {
        switch type {
        case .trading: return "creditcard.fill"
        case .delivery: return "location.fill"
        case .dialogue: return "bubble.left.and.bubble.right.fill"
        }
    }

    // 퀘스트 타입별 설명
    var typeDescription: String {
        switch type {
        case .trading: return "거래 퀘스트"
        case .delivery: return "배달 퀘스트"
        case .dialogue: return "대화 퀘스트"
        }
    }
}

// MARK: - Quest Location

struct QuestLocation: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let radius: Int
}

// MARK: - Quest Type

enum QuestType: String, Codable {
    case trading = "trading"      // 영수증 OCR
    case delivery = "delivery"    // GPS 위치
    case dialogue = "dialogue"    // 스토리 완료
}

// MARK: - Quest Verification

enum QuestVerification: String, Codable {
    case receipt_ocr = "receipt_ocr"
    case gps_location = "gps_location"
    case story_completion = "story_completion"
}

// MARK: - Quest Requirements

struct QuestRequirements: Codable, Hashable {
    // Trading 퀘스트용
    let location: QuestLocation?
    let min_purchase: Int?

    // Delivery 퀘스트용
    let target_location: QuestLocation?
    let time_limit: Int?

    // Dialogue 퀘스트용
    let story_node_complete: String?
    let story_node_start: String?

    // 공통 요구 조건
    let required_items: [String]
    let required_story_pieces: [String]
    let required_main_quests: [String]
    let required_sub_quests: [String]
    let required_level: Int?

    init(
        location: QuestLocation? = nil,
        min_purchase: Int? = nil,
        target_location: QuestLocation? = nil,
        time_limit: Int? = nil,
        story_node_complete: String? = nil,
        story_node_start: String? = nil,
        required_items: [String] = [],
        required_story_pieces: [String] = [],
        required_main_quests: [String] = [],
        required_sub_quests: [String] = [],
        required_level: Int? = nil
    ) {
        self.location = location
        self.min_purchase = min_purchase
        self.target_location = target_location
        self.time_limit = time_limit
        self.story_node_complete = story_node_complete
        self.story_node_start = story_node_start
        self.required_items = required_items
        self.required_story_pieces = required_story_pieces
        self.required_main_quests = required_main_quests
        self.required_sub_quests = required_sub_quests
        self.required_level = required_level
    }

    enum CodingKeys: String, CodingKey {
        case location
        case min_purchase
        case target_location
        case time_limit
        case story_node_complete
        case story_node_start
        case required_items
        case required_story_pieces
        case required_main_quests
        case required_sub_quests
        case required_level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        location = try container.decodeIfPresent(QuestLocation.self, forKey: .location)
        min_purchase = try container.decodeIfPresent(Int.self, forKey: .min_purchase)
        target_location = try container.decodeIfPresent(QuestLocation.self, forKey: .target_location)
        time_limit = try container.decodeIfPresent(Int.self, forKey: .time_limit)
        story_node_complete = try container.decodeIfPresent(String.self, forKey: .story_node_complete)
        story_node_start = try container.decodeIfPresent(String.self, forKey: .story_node_start)
        required_items = try container.decodeIfPresent([String].self, forKey: .required_items) ?? []
        required_story_pieces = try container.decodeIfPresent([String].self, forKey: .required_story_pieces) ?? []
        required_main_quests = try container.decodeIfPresent([String].self, forKey: .required_main_quests) ?? []
        required_sub_quests = try container.decodeIfPresent([String].self, forKey: .required_sub_quests) ?? []
        required_level = try container.decodeIfPresent(Int.self, forKey: .required_level)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(min_purchase, forKey: .min_purchase)
        try container.encodeIfPresent(target_location, forKey: .target_location)
        try container.encodeIfPresent(time_limit, forKey: .time_limit)
        try container.encodeIfPresent(story_node_complete, forKey: .story_node_complete)
        try container.encodeIfPresent(story_node_start, forKey: .story_node_start)
        if !required_items.isEmpty { try container.encode(required_items, forKey: .required_items) }
        if !required_story_pieces.isEmpty { try container.encode(required_story_pieces, forKey: .required_story_pieces) }
        if !required_main_quests.isEmpty { try container.encode(required_main_quests, forKey: .required_main_quests) }
        if !required_sub_quests.isEmpty { try container.encode(required_sub_quests, forKey: .required_sub_quests) }
        try container.encodeIfPresent(required_level, forKey: .required_level)
    }
}

// MARK: - Quest Rewards

struct QuestRewards: Codable, Hashable {
    let money: Int?
    let exp: Int?
    let storyPieceIds: [String]
    let inventoryItems: [String]
    let keyItems: [String]
    let relationshipChange: RelationshipChange?

    enum CodingKeys: String, CodingKey {
        case money
        case exp
        case item_id
        case story_piece_ids
        case inventory_items
        case key_items
        case relationship_change
    }

    init(
        money: Int? = nil,
        exp: Int? = nil,
        storyPieceIds: [String] = [],
        inventoryItems: [String] = [],
        keyItems: [String] = [],
        relationshipChange: RelationshipChange? = nil
    ) {
        self.money = money
        self.exp = exp
        self.storyPieceIds = storyPieceIds
        self.inventoryItems = inventoryItems
        self.keyItems = keyItems
        self.relationshipChange = relationshipChange
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        money = try container.decodeIfPresent(Int.self, forKey: .money)
        exp = try container.decodeIfPresent(Int.self, forKey: .exp)

        let singleStoryPiece = try container.decodeIfPresent(String.self, forKey: .item_id)
        let storyPieces = try container.decodeIfPresent([String].self, forKey: .story_piece_ids) ?? []
        if let single = singleStoryPiece {
            storyPieceIds = Array(Set(storyPieces + [single]))
        } else {
            storyPieceIds = storyPieces
        }

        inventoryItems = try container.decodeIfPresent([String].self, forKey: .inventory_items) ?? []
        keyItems = try container.decodeIfPresent([String].self, forKey: .key_items) ?? []
        relationshipChange = try container.decodeIfPresent(RelationshipChange.self, forKey: .relationship_change)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(money, forKey: .money)
        try container.encodeIfPresent(exp, forKey: .exp)
        if !storyPieceIds.isEmpty {
            try container.encode(storyPieceIds, forKey: .story_piece_ids)
            if storyPieceIds.count == 1 {
                try container.encode(storyPieceIds.first, forKey: .item_id)
            }
        }
        if !inventoryItems.isEmpty {
            try container.encode(inventoryItems, forKey: .inventory_items)
        }
        if !keyItems.isEmpty {
            try container.encode(keyItems, forKey: .key_items)
        }
        try container.encodeIfPresent(relationshipChange, forKey: .relationship_change)
    }
}

// MARK: - Relationship Change

struct RelationshipChange: Codable, Hashable {
    let merchantId: String
    let trust: Int

    enum CodingKeys: String, CodingKey {
        case merchant_id
        case trust
    }

    init(merchantId: String, trust: Int) {
        self.merchantId = merchantId
        self.trust = trust
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        merchantId = try container.decode(String.self, forKey: .merchant_id)
        trust = try container.decode(Int.self, forKey: .trust)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(merchantId, forKey: .merchant_id)
        try container.encode(trust, forKey: .trust)
    }
}

// MARK: - Districts Container

struct DistrictsData: Codable {
    let districts: [District]
}

// MARK: - District Loader

enum DistrictLoader {
    private static var cachedDistricts: [District]?
    private static var questMerchantMap: [String: String] = [:]

    static func loadDistricts() -> [District] {
        if let cached = cachedDistricts {
            return cached
        }

        guard let path = Bundle.main.path(forResource: "districts", ofType: "json", inDirectory: "GameData/Districts") ??
                         Bundle.main.path(forResource: "districts", ofType: "json") else {
            print("❌ districts.json 파일을 찾을 수 없습니다")
            return []
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let districtsData = try JSONDecoder().decode(DistrictsData.self, from: data)
            print("✅ 구역 \(districtsData.districts.count)개 로드 완료")
            cachedDistricts = districtsData.districts
            questMerchantMap = [:]
            return districtsData.districts
        } catch {
            print("❌ districts.json 파싱 실패: \(error)")
            return []
        }
    }

    // 챕터별 구역 필터링
    static func getDistricts(for chapterId: String, from districts: [District]) -> [District] {
        return districts.filter { $0.chapter_id == chapterId }
    }

    // 구역 ID로 검색
    static func getDistrict(id: String, from districts: [District]) -> District? {
        return districts.first { $0.district_id == id }
    }

    // 상인 ID로 구역 검색
    static func getDistrict(byMerchantId merchantId: String, from districts: [District]) -> District? {
        return districts.first { $0.merchant.merchant_id == merchantId }
    }

    // 근처 구역 찾기 (거리순)
    static func getNearbyDistricts(
        from districts: [District],
        userLocation: CLLocationCoordinate2D,
        maxDistance: Double = 5000.0  // 5km
    ) -> [District] {
        return districts
            .filter { $0.merchant.distance(from: userLocation) <= maxDistance }
            .sorted { $0.merchant.distance(from: userLocation) < $1.merchant.distance(from: userLocation) }
    }

    static func merchantId(forQuest questId: String) -> String? {
        if let merchantId = questMerchantMap[questId] {
            return merchantId
        }

        let districts = loadDistricts()
        var updatedMap = questMerchantMap
        for district in districts {
            for quest in district.merchant.sub_quests {
                updatedMap[quest.quest_id] = district.merchant.merchant_id
            }
        }
        questMerchantMap = updatedMap
        return updatedMap[questId]
    }
}

// MARK: - Quest Extensions

extension SubQuest {
    // 퀘스트 완료 가능 여부 확인
    func canComplete(userLocation: CLLocationCoordinate2D) -> Bool {
        // 위치 기반 체크만 처리 (아이템/레벨 등은 QuestManager에서 확인)
        switch type {
        case .trading:
            // 상인 위치 근처에 있어야 함
            if let location = requirements.location {
                let distance = userLocation.distance(to: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ))
                return distance <= Double(location.radius)
            }
            return true

        case .delivery:
            // 목표 지점에 도달해야 함
            if let targetLocation = requirements.target_location {
                let distance = userLocation.distance(to: CLLocationCoordinate2D(
                    latitude: targetLocation.latitude,
                    longitude: targetLocation.longitude
                ))
                return distance <= Double(targetLocation.radius)
            }
            return false

        case .dialogue:
            // 위치 무관
            return true
        }
    }

    // 퀘스트 설명 텍스트
    func getDescription() -> String {
        switch type {
        case .trading:
            if let minPurchase = requirements.min_purchase {
                return "\(minPurchase)원 이상 구매 후 영수증 인증"
            }
            return "영수증 인증 필요"

        case .delivery:
            if let timeLimit = requirements.time_limit {
                let minutes = timeLimit / 60
                return "목표 지점 도달 (제한시간: \(minutes)분)"
            }
            return "목표 지점 도달"

        case .dialogue:
            return "상인과 대화 완료"
        }
    }
}

extension QuestRequirements {
    var requiredItems: [String] { required_items }
    var requiredStoryPieces: [String] { required_story_pieces }
    var requiredMainQuests: [String] { required_main_quests }
    var requiredSubQuests: [String] { required_sub_quests }
    var storyNodeStart: String? { story_node_start }
    var storyNodeComplete: String? { story_node_complete }

    func meetsMetaRequirements(progress: PlayerProgress, playerLevel: Int) -> Bool {
        if let requiredLevel = required_level, playerLevel < requiredLevel {
            return false
        }

        if !required_items.allSatisfy({ progress.hasKeyItem($0) }) {
            return false
        }

        if !required_story_pieces.allSatisfy({ progress.hasStoryPiece($0) }) {
            return false
        }

        if !required_main_quests.allSatisfy({ progress.isMainQuestCompleted($0) }) {
            return false
        }

        if !required_sub_quests.allSatisfy({ progress.isSubQuestCompleted($0) }) {
            return false
        }

        return true
    }
}
