// 📁 Models/Achievement.swift - 업적 모델
import Foundation
import SwiftUI

struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: AchievementCategory
    let conditionType: String
    let conditionValue: Int
    let rewardType: String
    let rewardValue: String
    let iconId: Int
    let isHidden: Bool
    
    // 진행도 정보 (서버에서 조회 시)
    var currentProgress: Int = 0
    var isCompleted: Bool = false
    var completedAt: Date?
    var claimed: Bool = false
    
    init(
        id: String,
        name: String,
        description: String,
        category: AchievementCategory = .trading,
        conditionType: String,
        conditionValue: Int,
        rewardType: String = "exp",
        rewardValue: String = "{}",
        iconId: Int = 1,
        isHidden: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.conditionType = conditionType
        self.conditionValue = conditionValue
        self.rewardType = rewardType
        self.rewardValue = rewardValue
        self.iconId = iconId
        self.isHidden = isHidden
    }
    
    // 서버 응답으로부터 초기화
    init(from serverResponse: ServerAchievementResponse) {
        self.id = serverResponse.id
        self.name = serverResponse.name
        self.description = serverResponse.description
        self.category = AchievementCategory(rawValue: serverResponse.category) ?? .trading
        self.conditionType = serverResponse.condition_type
        self.conditionValue = serverResponse.condition_value
        self.rewardType = serverResponse.reward_type
        self.rewardValue = serverResponse.reward_value
        self.iconId = serverResponse.icon_id
        self.isHidden = serverResponse.is_hidden
        
        // 진행도 정보
        self.currentProgress = serverResponse.current_progress ?? 0
        self.isCompleted = serverResponse.is_completed ?? false
        self.completedAt = serverResponse.completed_at != nil ? 
            Date(timeIntervalSince1970: serverResponse.completed_at!) : nil
        self.claimed = serverResponse.claimed ?? false
    }
    
    // 진행률 계산
    var progressPercentage: Double {
        guard conditionValue > 0 else { return 0 }
        return min(Double(currentProgress) / Double(conditionValue), 1.0)
    }
    
    // 진행률 텍스트
    var progressText: String {
        return "\(currentProgress) / \(conditionValue)"
    }
    
    // 보상 정보 파싱
    var rewardInfo: AchievementReward? {
        guard let data = rewardValue.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return AchievementReward(from: json, type: rewardType)
    }
    
    // 완료 가능 여부
    var canComplete: Bool {
        return currentProgress >= conditionValue && !isCompleted
    }
    
    // 보상 수령 가능 여부
    var canClaim: Bool {
        return isCompleted && !claimed
    }
}

// MARK: - Supporting Types

enum AchievementCategory: String, CaseIterable, Codable {
    case trading = "trading"
    case character = "character"
    case social = "social"
    case exploration = "exploration"
    case collection = "collection"
    
    var displayName: String {
        switch self {
        case .trading: return "거래"
        case .character: return "캐릭터"
        case .social: return "사교"
        case .exploration: return "탐험"
        case .collection: return "수집"
        }
    }
    
    var icon: String {
        switch self {
        case .trading: return "dollarsign.circle"
        case .character: return "person.circle"
        case .social: return "heart.circle"
        case .exploration: return "map.circle"
        case .collection: return "star.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .trading: return .treasureGold
        case .character: return .expGreen
        case .social: return .compass
        case .exploration: return .oceanTeal
        case .collection: return .goldYellow
        }
    }
}

struct AchievementReward {
    let type: String
    let gold: Int?
    let experience: Int?
    let cosmeticId: Int?
    let title: String?
    let skillPoints: Int?
    
    init(from json: [String: Any], type: String) {
        self.type = type
        self.gold = json["gold"] as? Int
        self.experience = json["experience"] as? Int
        self.cosmeticId = json["cosmetic_id"] as? Int
        self.title = json["title"] as? String
        self.skillPoints = json["skill_points"] as? Int
    }
    
    var displayText: String {
        var rewards: [String] = []
        
        if let gold = gold {
            rewards.append("골드 \(gold)")
        }
        if let exp = experience {
            rewards.append("경험치 \(exp)")
        }
        if let title = title {
            rewards.append("칭호: \(title)")
        }
        if let skill = skillPoints {
            rewards.append("스킬 포인트 \(skill)")
        }
        if let cosmetic = cosmeticId {
            rewards.append("코스메틱 #\(cosmetic)")
        }
        
        return rewards.joined(separator: ", ")
    }
}

// MARK: - Server Response Models

struct ServerAchievementResponse: Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let condition_type: String
    let condition_value: Int
    let reward_type: String
    let reward_value: String
    let icon_id: Int
    let is_hidden: Bool
    
    // Progress fields (optional)
    let current_progress: Int?
    let is_completed: Bool?
    let completed_at: TimeInterval?
    let claimed: Bool?
}

struct AchievementProgressResponse: Codable {
    let success: Bool
    let data: [ServerAchievementResponse]
}

struct AchievementClaimResponse: Codable {
    let success: Bool
    let data: AchievementClaimData?
    let error: String?
}

struct AchievementClaimData: Codable {
    let message: String
    let rewards: RewardData
    
    struct RewardData: Codable {
        let gold: Int?
        let experience: Int?
        let cosmetic_id: Int?
        let title: String?
        let skill_points: Int?
        
        enum CodingKeys: String, CodingKey {
            case gold, experience, cosmetic_id, title, skill_points
        }
    }
}

// MARK: - Sample Data

extension Achievement {
    static let sampleAchievements: [Achievement] = [
        Achievement(
            id: "first_trade",
            name: "첫 거래",
            description: "첫 번째 거래를 완료하세요",
            category: .trading,
            conditionType: "trade_count",
            conditionValue: 1,
            rewardValue: #"{"experience": 50}"#
        ),
        Achievement(
            id: "money_maker_1",
            name: "돈벌이 초보",
            description: "10만원을 벌어보세요",
            category: .trading,
            conditionType: "money_earned",
            conditionValue: 100000,
            rewardValue: #"{"gold": 5000}"#
        ),
        Achievement(
            id: "collector_1",
            name: "수집가",
            description: "10개의 서로 다른 아이템을 수집하세요",
            category: .collection,
            conditionType: "unique_items",
            conditionValue: 10,
            rewardValue: #"{"cosmetic_id": 101}"#
        ),
        Achievement(
            id: "friend_maker",
            name: "친구 만들기",
            description: "상인과 친구가 되세요",
            category: .social,
            conditionType: "merchant_friendship",
            conditionValue: 1,
            rewardValue: #"{"experience": 100}"#
        )
    ]
}
