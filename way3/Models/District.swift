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

    static func subQuest(withId questId: String) -> SubQuest? {
        for district in loadDistricts() {
            if let quest = district.merchant.sub_quests.first(where: { $0.quest_id == questId }) {
                return quest
            }
        }
        return nil
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
    var storyNodeStart: String? { story_node_start }
    var storyNodeComplete: String? { story_node_complete }

    func meetsMetaRequirements(progress: PlayerProgress, playerLevel: Int) -> Bool {
        if let requiredLevel = required_level, playerLevel < requiredLevel {
            return false
        }

        if let requiredItems = requiredItems,
           !requiredItems.allSatisfy({ progress.hasKeyItem($0) }) {
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
