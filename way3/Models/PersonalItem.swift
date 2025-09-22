//
//  PersonalItem.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 2025-01-XX.
//  개인 아이템 시스템 - 능력치/효과 아이템 관리
//

import Foundation
import SwiftUI

// MARK: - Personal Item Model
struct PersonalItem: Identifiable, Codable {
    let id: String
    let itemTemplateId: String
    let name: String
    let type: PersonalItemType
    let grade: ItemGrade
    let quantity: Int
    let maxStack: Int
    let cooldown: TimeInterval
    let usageLimit: Int?
    let isEquipped: Bool
    let equipSlot: String?
    let description: String
    let iconId: Int
    let effects: [ItemEffect]
    let lastUsed: Date?
    let canUse: Bool
    let usageToday: Int
    let acquiredAt: Date

    // 사용 가능 여부 확인
    var isUsable: Bool {
        return type == .consumable && canUse && quantity > 0
    }

    // 장착 가능 여부 확인
    var isEquippable: Bool {
        return type == .equipment
    }

    // 쿨타임 남은 시간 (초)
    var remainingCooldown: TimeInterval {
        guard let lastUsed = lastUsed, cooldown > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(lastUsed)
        return max(0, cooldown - elapsed)
    }

    // 일일 사용 가능 여부
    var canUseToday: Bool {
        guard let limit = usageLimit else { return true }
        return usageToday < limit
    }

    // 표시용 쿨타임 텍스트
    var cooldownText: String? {
        let remaining = remainingCooldown
        guard remaining > 0 else { return nil }

        if remaining >= 3600 {
            let hours = Int(remaining / 3600)
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)시간 \(minutes)분"
        } else if remaining >= 60 {
            let minutes = Int(remaining / 60)
            let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(Int(remaining))초"
        }
    }

    // 일일 사용 제한 텍스트
    var usageLimitText: String? {
        guard let limit = usageLimit else { return nil }
        return "\(usageToday)/\(limit)"
    }
}

// MARK: - Personal Item Type
enum PersonalItemType: String, Codable, CaseIterable {
    case consumable = "consumable"  // 소비 아이템
    case equipment = "equipment"    // 장비 아이템
    case artifact = "artifact"      // 특수 아이템

    var displayName: String {
        switch self {
        case .consumable: return "소비품"
        case .equipment: return "장비"
        case .artifact: return "특수"
        }
    }

    var color: Color {
        switch self {
        case .consumable: return .green
        case .equipment: return .blue
        case .artifact: return .purple
        }
    }
}

// MARK: - Item Effect
struct ItemEffect: Codable {
    let type: EffectType
    let value: Int
    let duration: TimeInterval
    let description: String

    // 효과 지속 시간 텍스트
    var durationText: String {
        if duration == 0 {
            return "즉시"
        } else if duration == -1 {
            return "영구"
        } else if duration >= 3600 {
            let hours = Int(duration / 3600)
            return "\(hours)시간"
        } else if duration >= 60 {
            let minutes = Int(duration / 60)
            return "\(minutes)분"
        } else {
            return "\(Int(duration))초"
        }
    }

    // 효과 값 표시 텍스트
    var valueText: String {
        switch type {
        case .healthBoost:
            return "+\(value)"
        case .tradeSuccessRate, .negotiationPower, .appraisalBonus, .movementSpeed, .experienceBonus:
            return "+\(value)%"
        case .instantTeleport, .priceVisibility:
            return ""
        }
    }
}

// MARK: - Effect Type
enum EffectType: String, Codable, CaseIterable {
    case healthBoost = "health_boost"
    case tradeSuccessRate = "trade_success_rate"
    case negotiationPower = "negotiation_power"
    case movementSpeed = "movement_speed"
    case experienceBonus = "experience_bonus"
    case appraisalBonus = "appraisal_bonus"
    case instantTeleport = "instant_teleport"
    case priceVisibility = "price_visibility"

    var displayName: String {
        switch self {
        case .healthBoost: return "체력 회복"
        case .tradeSuccessRate: return "거래 성공률"
        case .negotiationPower: return "가격 협상력"
        case .movementSpeed: return "이동 속도"
        case .experienceBonus: return "경험치 보너스"
        case .appraisalBonus: return "감정 능력"
        case .instantTeleport: return "순간 이동"
        case .priceVisibility: return "가격 정보"
        }
    }

    var icon: String {
        switch self {
        case .healthBoost: return "heart.fill"
        case .tradeSuccessRate: return "chart.line.uptrend.xyaxis"
        case .negotiationPower: return "person.2.fill"
        case .movementSpeed: return "figure.run"
        case .experienceBonus: return "star.fill"
        case .appraisalBonus: return "eye.fill"
        case .instantTeleport: return "location.fill"
        case .priceVisibility: return "dollarsign.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .healthBoost: return .red
        case .tradeSuccessRate: return .green
        case .negotiationPower: return .blue
        case .movementSpeed: return .orange
        case .experienceBonus: return .yellow
        case .appraisalBonus: return .purple
        case .instantTeleport: return .cyan
        case .priceVisibility: return .mint
        }
    }
}

// MARK: - Active Effect (지속 효과)
struct ActiveEffect: Identifiable, Codable {
    let id: Int
    let itemTemplateId: String
    let itemName: String
    let effectType: EffectType
    let effectValue: Int
    let startTime: Date
    let duration: TimeInterval
    let expiresAt: Date
    let remainingTime: TimeInterval

    // 남은 시간 텍스트
    var remainingTimeText: String {
        if remainingTime <= 0 {
            return "만료됨"
        } else if remainingTime >= 3600 {
            let hours = Int(remainingTime / 3600)
            let minutes = Int((remainingTime.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)시간 \(minutes)분"
        } else if remainingTime >= 60 {
            let minutes = Int(remainingTime / 60)
            let seconds = Int(remainingTime.truncatingRemainder(dividingBy: 60))
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(Int(remainingTime))초"
        }
    }

    // 진행률 (0.0 ~ 1.0)
    var progress: Double {
        guard duration > 0, remainingTime >= 0 else { return 0.0 }
        return max(0.0, min(1.0, (duration - remainingTime) / duration))
    }
}

// MARK: - Permanent Effect (영구 효과)
struct PermanentEffect: Codable {
    let itemTemplateId: String
    let itemName: String
    let effectType: EffectType
    let effectValue: Int
    let isPermanent: Bool

    var description: String {
        return "\(effectType.displayName) \(effectValue > 0 ? "+" : "")\(effectValue)\(effectType == .healthBoost ? "" : "%")"
    }
}

// MARK: - Server Response Models
struct PersonalItemsResponse: Codable {
    let success: Bool
    let data: PersonalItemsData
}

struct PersonalItemsData: Codable {
    let personalItems: [PersonalItemServerData]
    let total: Int
}

struct PersonalItemServerData: Codable {
    let id: String
    let itemTemplateId: String
    let name: String
    let type: String
    let grade: Int
    let quantity: Int
    let maxStack: Int
    let cooldown: Int
    let usageLimit: Int?
    let isEquipped: Bool
    let equipSlot: String?
    let description: String
    let iconId: Int
    let effects: [ItemEffectServerData]
    let lastUsed: String?
    let canUse: Bool
    let usageToday: Int
    let acquiredAt: String
}

struct ItemEffectServerData: Codable {
    let type: String
    let value: Int
    let duration: Int
    let description: String
}

struct ActiveEffectsResponse: Codable {
    let success: Bool
    let data: ActiveEffectsData
}

struct ActiveEffectsData: Codable {
    let temporaryEffects: [ActiveEffectServerData]
    let permanentEffects: [PermanentEffectServerData]
}

struct ActiveEffectServerData: Codable {
    let id: Int
    let itemTemplateId: String
    let itemName: String
    let effectType: String
    let effectValue: Int
    let startTime: String
    let duration: Int
    let expiresAt: String
    let remainingTime: Int
}

struct PermanentEffectServerData: Codable {
    let itemTemplateId: String
    let itemName: String
    let effectType: String
    let effectValue: Int
    let isPermanent: Bool
}

// MARK: - Data Conversion Extensions
extension PersonalItem {
    static func from(serverData: PersonalItemServerData) -> PersonalItem {
        let effects = serverData.effects.map { effectData in
            ItemEffect(
                type: EffectType(rawValue: effectData.type) ?? .healthBoost,
                value: effectData.value,
                duration: TimeInterval(effectData.duration),
                description: effectData.description
            )
        }

        return PersonalItem(
            id: serverData.id,
            itemTemplateId: serverData.itemTemplateId,
            name: serverData.name,
            type: PersonalItemType(rawValue: serverData.type) ?? .consumable,
            grade: ItemGrade.fromServerGrade(serverData.grade),
            quantity: serverData.quantity,
            maxStack: serverData.maxStack,
            cooldown: TimeInterval(serverData.cooldown),
            usageLimit: serverData.usageLimit,
            isEquipped: serverData.isEquipped,
            equipSlot: serverData.equipSlot,
            description: serverData.description,
            iconId: serverData.iconId,
            effects: effects,
            lastUsed: parseDate(serverData.lastUsed),
            canUse: serverData.canUse,
            usageToday: serverData.usageToday,
            acquiredAt: parseDate(serverData.acquiredAt) ?? Date()
        )
    }

    private static func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

extension ActiveEffect {
    static func from(serverData: ActiveEffectServerData) -> ActiveEffect {
        let formatter = ISO8601DateFormatter()

        return ActiveEffect(
            id: serverData.id,
            itemTemplateId: serverData.itemTemplateId,
            itemName: serverData.itemName,
            effectType: EffectType(rawValue: serverData.effectType) ?? .healthBoost,
            effectValue: serverData.effectValue,
            startTime: formatter.date(from: serverData.startTime) ?? Date(),
            duration: TimeInterval(serverData.duration),
            expiresAt: formatter.date(from: serverData.expiresAt) ?? Date(),
            remainingTime: TimeInterval(serverData.remainingTime)
        )
    }
}

extension PermanentEffect {
    static func from(serverData: PermanentEffectServerData) -> PermanentEffect {
        return PermanentEffect(
            itemTemplateId: serverData.itemTemplateId,
            itemName: serverData.itemName,
            effectType: EffectType(rawValue: serverData.effectType) ?? .healthBoost,
            effectValue: serverData.effectValue,
            isPermanent: serverData.isPermanent
        )
    }
}