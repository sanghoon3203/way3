//
//  PlayerCore.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 2024-12-26.
//  플레이어 핵심 정보 - 기본 데이터만 관리
//

import Foundation
import SwiftUI

// MARK: - Core Player Class
class PlayerCore: ObservableObject, Codable {
    // MARK: - 식별 정보
    @Published var id: String
    @Published var userId: String?
    @Published var name: String = ""
    @Published var email: String?

    // MARK: - 프로필 정보
    @Published var age: Int = 0
    @Published var personality: String = ""
    @Published var gender: String = ""

    // MARK: - 게임 기본 스탯
    @Published var money: Int = 50000
    @Published var trustPoints: Int = 0
    @Published var reputation: Int = 0
    @Published var currentLicense: LicenseLevel = .beginner

    // MARK: - 레벨 시스템
    @Published var level: Int = 1
    @Published var experience: Int = 0
    @Published var statPoints: Int = 0
    @Published var skillPoints: Int = 0

    // MARK: - 시간 정보
    @Published var createdAt: Date = Date()
    @Published var lastActive: Date = Date()
    @Published var totalPlayTime: TimeInterval = 0
    @Published var dailyPlayTime: TimeInterval = 0

    // MARK: - 초기화
    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        name: String = "",
        email: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.email = email
    }

    // MARK: - Codable 구현
    enum CodingKeys: String, CodingKey {
        case id, userId, name, email
        case age, personality, gender
        case money, trustPoints, reputation, currentLicense
        case level, experience, statPoints, skillPoints
        case createdAt, lastActive, totalPlayTime, dailyPlayTime
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 0
        personality = try container.decodeIfPresent(String.self, forKey: .personality) ?? ""
        gender = try container.decodeIfPresent(String.self, forKey: .gender) ?? ""
        money = try container.decode(Int.self, forKey: .money)
        trustPoints = try container.decode(Int.self, forKey: .trustPoints)
        reputation = try container.decode(Int.self, forKey: .reputation)
        currentLicense = try container.decode(LicenseLevel.self, forKey: .currentLicense)
        level = try container.decode(Int.self, forKey: .level)
        experience = try container.decode(Int.self, forKey: .experience)
        statPoints = try container.decode(Int.self, forKey: .statPoints)
        skillPoints = try container.decode(Int.self, forKey: .skillPoints)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastActive = try container.decode(Date.self, forKey: .lastActive)
        totalPlayTime = try container.decode(TimeInterval.self, forKey: .totalPlayTime)
        dailyPlayTime = try container.decode(TimeInterval.self, forKey: .dailyPlayTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(age, forKey: .age)
        try container.encode(personality, forKey: .personality)
        try container.encode(gender, forKey: .gender)
        try container.encode(money, forKey: .money)
        try container.encode(trustPoints, forKey: .trustPoints)
        try container.encode(reputation, forKey: .reputation)
        try container.encode(currentLicense, forKey: .currentLicense)
        try container.encode(level, forKey: .level)
        try container.encode(experience, forKey: .experience)
        try container.encode(statPoints, forKey: .statPoints)
        try container.encode(skillPoints, forKey: .skillPoints)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastActive, forKey: .lastActive)
        try container.encode(totalPlayTime, forKey: .totalPlayTime)
        try container.encode(dailyPlayTime, forKey: .dailyPlayTime)
    }
}

// MARK: - 레벨 시스템 메서드
extension PlayerCore {
    // 경험치 획득
    func gainExperience(_ amount: Int) {
        experience += amount
        checkLevelUp()
    }

    // 레벨업 확인
    private func checkLevelUp() {
        let requiredExp = experienceRequired(for: level + 1)

        while experience >= requiredExp && level < 100 {
            levelUp()
        }
    }

    // 레벨업 실행
    private func levelUp() {
        level += 1
        statPoints += 3
        skillPoints += 1

        #if DEBUG
        print("🎉 레벨업! 새 레벨: \(level)")
        #endif
    }

    // 다음 레벨 필요 경험치
    func experienceRequired(for targetLevel: Int) -> Int {
        return targetLevel * 1000 + (targetLevel - 1) * 500
    }

    // 현재 레벨 진행률 (0.0 ~ 1.0)
    var levelProgress: Double {
        let currentLevelExp = experienceRequired(for: level)
        let nextLevelExp = experienceRequired(for: level + 1)
        let progressExp = experience - currentLevelExp
        let requiredExp = nextLevelExp - currentLevelExp

        return Double(progressExp) / Double(requiredExp)
    }
}

// MARK: - 돈 관리 메서드
extension PlayerCore {
    // 돈 획득
    func earnMoney(_ amount: Int) {
        money += amount
    }

    // 돈 사용 (실패 시 false 반환)
    func spendMoney(_ amount: Int) -> Bool {
        guard money >= amount else { return false }
        money -= amount
        return true
    }

    // 돈 충분한지 확인
    func canAfford(_ amount: Int) -> Bool {
        return money >= amount
    }
}

// MARK: - 시간 관리 메서드
extension PlayerCore {
    // 플레이 시간 추가
    func addPlayTime(_ duration: TimeInterval) {
        totalPlayTime += duration
        dailyPlayTime += duration
        lastActive = Date()
    }

    // 일일 플레이 시간 리셋
    func resetDailyPlayTime() {
        dailyPlayTime = 0
    }

    // 플레이 시간 포맷팅
    var formattedTotalPlayTime: String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        return "\(hours)시간 \(minutes)분"
    }
}

// LicenseLevel은 GameEnums.swift에서 정의됨