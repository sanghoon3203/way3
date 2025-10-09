//
//  MainQuestDefinition.swift
//  way3
//
//  메인 스토리 퀘스트 정의 및 로더
//

import Foundation
import CoreLocation

struct MainQuestDefinition: Codable, Identifiable, Hashable {
    let questId: String
    let title: String
    let type: String
    let chapterId: String
    let districtId: String
    let description: String
    let requirements: MainQuestRequirements
    let objectives: [MainQuestObjective]
    let rewards: MainQuestRewards

    var id: String { questId }
}

struct MainQuestRequirements: Codable, Hashable {
    let requiredEpisodes: [String] = []
    let requiredItems: [String] = []
    let requiredLevel: Int
    let requiredSubQuests: [String] = []
}

enum MainQuestObjectiveType: String, Codable, Hashable {
    case delivery
    case trading
    case dialogue
    case interact
}

struct MainQuestObjective: Codable, Hashable {
    let type: MainQuestObjectiveType
    let description: String?
    let targetLocation: QuestLocation?
    let storeId: String?
    let merchantId: String?
    let minPurchase: Int?
    let storyNodeId: String?
}

struct MainQuestRewards: Codable, Hashable {
    let money: Int?
    let exp: Int?
    let inventoryItems: [String] = []
    let storyPieceIds: [String] = []
    let keyItems: [String] = []
    let relationshipChange: RelationshipChange?
}

private struct MainQuestContainer: Codable {
    let quests: [MainQuestDefinition]
}

enum MainQuestRepository {
    private static let fileName = "main_quests"
    private static let directory = "GameData/Quests"

    private static var cachedById: [String: MainQuestDefinition] = [:]

    static func loadAll() -> [MainQuestDefinition] {
        if !cachedById.isEmpty {
            return cachedById.values.sorted { $0.questId < $1.questId }
        }

        guard let path = Bundle.main.path(forResource: fileName, ofType: "json", inDirectory: directory) ??
                Bundle.main.path(forResource: fileName, ofType: "json") else {
            print("❌ \(fileName).json 파일을 찾을 수 없습니다")
            return []
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let container = try decoder.decode(MainQuestContainer.self, from: data)
            cachedById = Dictionary(uniqueKeysWithValues: container.quests.map { ($0.questId, $0) })
            return container.quests
        } catch {
            print("❌ \(fileName).json 파싱 실패: \(error)")
            return []
        }
    }

    static func quest(withId id: String) -> MainQuestDefinition? {
        if let cached = cachedById[id] {
            return cached
        }
        let quests = loadAll()
        return quests.first { $0.questId == id }
    }
}

// MARK: - Requirement Helpers

extension MainQuestRequirements {
    func isSatisfied(by progress: PlayerProgress, playerLevel: Int) -> Bool {
        guard playerLevel >= requiredLevel else { return false }
        let episodeSatisfied = requiredEpisodes.allSatisfy { progress.isEpisodeCompleted($0) }
        let subQuestsSatisfied = requiredSubQuests.allSatisfy { progress.isSubQuestCompleted($0) }
        let itemsSatisfied = requiredItems.allSatisfy { progress.hasKeyItem($0) }
        return episodeSatisfied && subQuestsSatisfied && itemsSatisfied
    }
}

extension MainQuestRewards {
    func asQuestRewards() -> QuestRewards {
        QuestRewards(
            money: money,
            exp: exp,
            storyPieceIds: storyPieceIds,
            inventoryItems: inventoryItems,
            keyItems: keyItems,
            relationshipChange: relationshipChange
        )
    }
}

extension MainQuestDefinition {
    var objectiveCount: Int { objectives.count }
}

extension MainQuestObjective {
    func matchesTrade(merchantId eventMerchantId: String?, storeId eventStoreId: String?, amount: Int) -> Bool {
        guard type == .trading else { return false }

        if let requiredStore = storeId {
            guard let eventStoreId = eventStoreId, requiredStore == eventStoreId else { return false }
        }

        if let requiredMerchant = merchantId {
            guard let eventMerchantId = eventMerchantId, requiredMerchant == eventMerchantId else { return false }
        }

        if let minPurchase = minPurchase, amount < minPurchase {
            return false
        }

        return true
    }

    func matchesLocation(currentLocation: CLLocationCoordinate2D) -> Bool {
        guard type == .delivery, let target = targetLocation else { return false }
        let targetCoord = CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude)
        let distance = currentLocation.distance(to: targetCoord)
        return distance <= Double(target.radius)
    }

    func matchesDialogue(nodeId: String) -> Bool {
        guard type == .dialogue, let requiredNode = storyNodeId else { return false }
        return requiredNode == nodeId
    }

    var displayDescription: String {
        if let description = description { return description }
        switch type {
        case .trading: return "특정 거래 수행"
        case .delivery: return "목표 위치 방문"
        case .dialogue: return "대화 완료"
        case .interact: return "특정 상호작용"
        }
    }
}
