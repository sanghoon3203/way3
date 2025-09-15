//
//  PlayerStats.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 2024-12-26.
//  플레이어 스탯 시스템 - 능력치 및 기술 관리
//

import Foundation
import SwiftUI

// MARK: - Player Stats Class
class PlayerStats: ObservableObject, Codable {
    // MARK: - 기본 스탯
    @Published var strength: Int = 10        // 힘 (무거운 아이템 운반)
    @Published var intelligence: Int = 10    // 지능 (아이템 감정, 시장 분석)
    @Published var charisma: Int = 10       // 매력 (거래 가격, 상인 친밀도)
    @Published var luck: Int = 10           // 행운 (희귀 아이템 발견, 크리티컬)

    // MARK: - 거래 기술
    @Published var tradingSkill: Int = 1     // 거래 기술
    @Published var negotiationSkill: Int = 1 // 협상 기술
    @Published var appraisalSkill: Int = 1   // 감정 기술

    // MARK: - 초기화
    init() {}

    // MARK: - Codable 구현
    enum CodingKeys: String, CodingKey {
        case strength, intelligence, charisma, luck
        case tradingSkill, negotiationSkill, appraisalSkill
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        strength = try container.decode(Int.self, forKey: .strength)
        intelligence = try container.decode(Int.self, forKey: .intelligence)
        charisma = try container.decode(Int.self, forKey: .charisma)
        luck = try container.decode(Int.self, forKey: .luck)
        tradingSkill = try container.decode(Int.self, forKey: .tradingSkill)
        negotiationSkill = try container.decode(Int.self, forKey: .negotiationSkill)
        appraisalSkill = try container.decode(Int.self, forKey: .appraisalSkill)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(strength, forKey: .strength)
        try container.encode(intelligence, forKey: .intelligence)
        try container.encode(charisma, forKey: .charisma)
        try container.encode(luck, forKey: .luck)
        try container.encode(tradingSkill, forKey: .tradingSkill)
        try container.encode(negotiationSkill, forKey: .negotiationSkill)
        try container.encode(appraisalSkill, forKey: .appraisalSkill)
    }
}

// MARK: - 스탯 관리 메서드
extension PlayerStats {
    // 스탯 포인트 할당
    func allocateStatPoint(to stat: StatType) -> Bool {
        let maxStat = 100

        switch stat {
        case .strength:
            guard strength < maxStat else { return false }
            strength += 1
        case .intelligence:
            guard intelligence < maxStat else { return false }
            intelligence += 1
        case .charisma:
            guard charisma < maxStat else { return false }
            charisma += 1
        case .luck:
            guard luck < maxStat else { return false }
            luck += 1
        }

        return true
    }

    // 스탯 리셋
    func resetStats() {
        strength = 10
        intelligence = 10
        charisma = 10
        luck = 10
    }

    // 총 스탯 포인트
    var totalStatPoints: Int {
        return strength + intelligence + charisma + luck
    }

    // 스탯별 효과 계산
    func getStatEffect(for stat: StatType) -> Double {
        let statValue = getStatValue(for: stat)
        return Double(statValue) / 100.0
    }

    private func getStatValue(for stat: StatType) -> Int {
        switch stat {
        case .strength: return strength
        case .intelligence: return intelligence
        case .charisma: return charisma
        case .luck: return luck
        }
    }
}

// MARK: - 기술 관리 메서드
extension PlayerStats {
    // 기술 향상
    func improveSkill(_ skill: SkillType, by amount: Int = 1) {
        let maxSkill = 100

        switch skill {
        case .trading:
            tradingSkill = min(tradingSkill + amount, maxSkill)
        case .negotiation:
            negotiationSkill = min(negotiationSkill + amount, maxSkill)
        case .appraisal:
            appraisalSkill = min(appraisalSkill + amount, maxSkill)
        }
    }

    // 기술 레벨 확인
    func getSkillLevel(_ skill: SkillType) -> Int {
        switch skill {
        case .trading: return tradingSkill
        case .negotiation: return negotiationSkill
        case .appraisal: return appraisalSkill
        }
    }

    // 기술 효과 계산 (0.0 ~ 1.0)
    func getSkillEffect(_ skill: SkillType) -> Double {
        let skillValue = getSkillLevel(skill)
        return Double(skillValue) / 100.0
    }

    // 평균 기술 레벨
    var averageSkillLevel: Double {
        return Double(tradingSkill + negotiationSkill + appraisalSkill) / 3.0
    }
}

// MARK: - 전투력 및 능력치 계산
extension PlayerStats {
    // 운반 용량 (힘 기반)
    var carryingCapacity: Int {
        return 5 + (strength - 10) / 2  // 기본 5개 + 힘 보너스
    }

    // 시장 분석 능력 (지능 기반)
    var marketAnalysisBonus: Double {
        return Double(intelligence) / 100.0
    }

    // 거래 가격 보너스 (매력 기반)
    var priceNegotiationBonus: Double {
        return Double(charisma) / 200.0  // 최대 50% 보너스
    }

    // 희귀 아이템 발견률 (행운 기반)
    var rareFindBonus: Double {
        return Double(luck) / 500.0  // 최대 20% 보너스
    }

    // 종합 거래 능력
    var tradingPower: Int {
        let baseScore = (strength + intelligence + charisma + luck) / 4
        let skillBonus = Int(averageSkillLevel / 2)
        return baseScore + skillBonus
    }
}

// MARK: - 스탯 타입
enum StatType: String, CaseIterable {
    case strength = "strength"
    case intelligence = "intelligence"
    case charisma = "charisma"
    case luck = "luck"

    var displayName: String {
        switch self {
        case .strength: return "힘"
        case .intelligence: return "지능"
        case .charisma: return "매력"
        case .luck: return "행운"
        }
    }

    var description: String {
        switch self {
        case .strength: return "무거운 아이템을 더 많이 운반할 수 있습니다"
        case .intelligence: return "시장 분석과 아이템 감정 능력이 향상됩니다"
        case .charisma: return "상인과의 거래에서 더 좋은 가격을 받을 수 있습니다"
        case .luck: return "희귀한 아이템을 발견할 확률이 높아집니다"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining"
        case .intelligence: return "brain.head.profile"
        case .charisma: return "person.2.fill"
        case .luck: return "sparkles"
        }
    }
}

// MARK: - 기술 타입
enum SkillType: String, CaseIterable {
    case trading = "trading"
    case negotiation = "negotiation"
    case appraisal = "appraisal"

    var displayName: String {
        switch self {
        case .trading: return "거래 기술"
        case .negotiation: return "협상 기술"
        case .appraisal: return "감정 기술"
        }
    }

    var description: String {
        switch self {
        case .trading: return "전반적인 거래 능력이 향상됩니다"
        case .negotiation: return "더 유리한 조건으로 거래할 수 있습니다"
        case .appraisal: return "아이템의 정확한 가치를 파악할 수 있습니다"
        }
    }

    var icon: String {
        switch self {
        case .trading: return "arrow.left.arrow.right"
        case .negotiation: return "person.2.wave.2"
        case .appraisal: return "magnifyingglass"
        }
    }
}

// MARK: - 스탯 레벨 정보
struct StatLevel {
    static func getTitle(for value: Int) -> String {
        switch value {
        case 0..<20: return "초보"
        case 20..<40: return "견습"
        case 40..<60: return "숙련"
        case 60..<80: return "전문"
        case 80..<100: return "마스터"
        default: return "전설"
        }
    }

    static func getColor(for value: Int) -> Color {
        switch value {
        case 0..<20: return .gray
        case 20..<40: return .green
        case 40..<60: return .blue
        case 60..<80: return .purple
        case 80..<100: return .orange
        default: return .red
        }
    }
}