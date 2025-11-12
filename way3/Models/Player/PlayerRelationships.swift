//
//  PlayerRelationships.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 2024-12-26.
//  플레이어 관계 시스템 - 상인 관계, 길드, 소셜 기능 관리
//

import Foundation
import SwiftUI

// MARK: - Player Relationships Class
class PlayerRelationships: ObservableObject, Codable {
    // MARK: - 상인 관계
    @Published var merchantRelationships: [String: MerchantRelationship] = [:]
    @Published var favoredMerchants: [String] = []
    @Published var bannedMerchants: [String] = []

    // MARK: - 길드 시스템
    @Published var guildMembership: GuildMembership?
    @Published var guildInvitations: [GuildInvitation] = []

    // MARK: - 소셜 기능
    @Published var friends: [Friend] = []
    @Published var blockedPlayers: [String] = []
    @Published var friendRequests: [FriendRequest] = []

    // MARK: - 거래 기록
    @Published var tradeHistory: [TradeRecord] = []
    @Published var reputationScore: Int = 0
    @Published var trustLevel: TrustLevel = .unknown

    // MARK: - 초기화
    init() {}

    // MARK: - Codable 구현
    enum CodingKeys: String, CodingKey {
        case merchantRelationships, favoredMerchants, bannedMerchants
        case guildMembership, guildInvitations
        case friends, blockedPlayers, friendRequests
        case tradeHistory, reputationScore, trustLevel
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        merchantRelationships = try container.decode([String: MerchantRelationship].self, forKey: .merchantRelationships)
        favoredMerchants = try container.decode([String].self, forKey: .favoredMerchants)
        bannedMerchants = try container.decode([String].self, forKey: .bannedMerchants)
        guildMembership = try container.decodeIfPresent(GuildMembership.self, forKey: .guildMembership)
        guildInvitations = try container.decode([GuildInvitation].self, forKey: .guildInvitations)
        friends = try container.decode([Friend].self, forKey: .friends)
        blockedPlayers = try container.decode([String].self, forKey: .blockedPlayers)
        friendRequests = try container.decode([FriendRequest].self, forKey: .friendRequests)
        tradeHistory = try container.decode([TradeRecord].self, forKey: .tradeHistory)
        reputationScore = try container.decode(Int.self, forKey: .reputationScore)
        trustLevel = try container.decode(TrustLevel.self, forKey: .trustLevel)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(merchantRelationships, forKey: .merchantRelationships)
        try container.encode(favoredMerchants, forKey: .favoredMerchants)
        try container.encode(bannedMerchants, forKey: .bannedMerchants)
        try container.encodeIfPresent(guildMembership, forKey: .guildMembership)
        try container.encode(guildInvitations, forKey: .guildInvitations)
        try container.encode(friends, forKey: .friends)
        try container.encode(blockedPlayers, forKey: .blockedPlayers)
        try container.encode(friendRequests, forKey: .friendRequests)
        try container.encode(tradeHistory, forKey: .tradeHistory)
        try container.encode(reputationScore, forKey: .reputationScore)
        try container.encode(trustLevel, forKey: .trustLevel)
    }
}

// MARK: - 상인 관계 관리 메서드
extension PlayerRelationships {
    // 상인과의 거래 기록
    func recordTrade(with merchantId: String, itemName: String, tradeType: TradeType, amount: Int, satisfaction: Int) {
        // 거래 기록 추가
        let record = TradeRecord(
            merchantId: merchantId,
            itemName: itemName,
            tradeType: tradeType,
            amount: amount,
            satisfaction: satisfaction,
            date: Date()
        )
        tradeHistory.append(record)

        // 상인 관계 업데이트
        if merchantRelationships[merchantId] == nil {
            merchantRelationships[merchantId] = MerchantRelationship(merchantId: merchantId)
        }

        merchantRelationships[merchantId]?.updateRelationship(satisfaction: satisfaction)

        // 평판 점수 업데이트
        updateReputation(basedOn: satisfaction)
    }

    // 선호 상인 추가
    func addFavoredMerchant(_ merchantId: String) {
        guard !favoredMerchants.contains(merchantId) else { return }
        favoredMerchants.append(merchantId)

        // 차단 목록에서 제거
        if let index = bannedMerchants.firstIndex(of: merchantId) {
            bannedMerchants.remove(at: index)
        }
    }

    // 상인 차단
    func banMerchant(_ merchantId: String) {
        guard !bannedMerchants.contains(merchantId) else { return }
        bannedMerchants.append(merchantId)

        // 선호 목록에서 제거
        if let index = favoredMerchants.firstIndex(of: merchantId) {
            favoredMerchants.remove(at: index)
        }
    }

    // 상인과의 관계 점수
    func getRelationshipScore(with merchantId: String) -> Int {
        return merchantRelationships[merchantId]?.friendshipPoints ?? 0
    }

    // 상인 할인율 계산
    func getDiscountRate(for merchantId: String) -> Double {
        let score = getRelationshipScore(with: merchantId)
        return min(Double(score) / 1000.0 * 0.1, 0.15) // 최대 15% 할인
    }
}

// MARK: - 길드 시스템 메서드
extension PlayerRelationships {
    // 길드 가입
    func joinGuild(_ guild: GuildMembership) {
        guildMembership = guild

        // 길드 초대 목록에서 해당 길드 제거
        guildInvitations.removeAll { $0.guildId == guild.guildId }
    }

    // 길드 탈퇴
    func leaveGuild() {
        guildMembership = nil
    }

    // 길드 초대 수락
    func acceptGuildInvitation(_ invitationId: String) -> Bool {
        guard let invitation = guildInvitations.first(where: { $0.id.uuidString == invitationId }),
              !invitation.isExpired else { return false }

        let membership = GuildMembership(
            guildId: invitation.guildId,
            guildName: invitation.guildName,
            role: .member,
            joinDate: Date()
        )

        joinGuild(membership)
        return true
    }

    // 길드 초대 거절
    func declineGuildInvitation(_ invitationId: String) {
        guildInvitations.removeAll { $0.id.uuidString == invitationId }
    }

    // 길드 혜택 확인
    var guildBenefits: GuildBenefits? {
        return guildMembership?.benefits
    }
}

// MARK: - 친구 시스템 메서드
extension PlayerRelationships {
    // 친구 요청 전송
    func sendFriendRequest(to playerId: String, playerName: String) {
        let request = FriendRequest(
            fromPlayerId: playerId,
            fromPlayerName: playerName,
            status: .sent,
            date: Date()
        )
        friendRequests.append(request)
    }

    // 친구 요청 수락
    func acceptFriendRequest(_ requestId: String) -> Bool {
        guard let index = friendRequests.firstIndex(where: { $0.id.uuidString == requestId }),
              friendRequests[index].status == .received else { return false }

        let request = friendRequests[index]
        let friend = Friend(
            playerId: request.fromPlayerId,
            playerName: request.fromPlayerName,
            friendshipDate: Date(),
            status: .active
        )

        friends.append(friend)
        friendRequests.remove(at: index)
        return true
    }

    // 친구 요청 거절
    func declineFriendRequest(_ requestId: String) {
        friendRequests.removeAll { $0.id.uuidString == requestId }
    }

    // 친구 삭제
    func removeFriend(_ playerId: String) {
        friends.removeAll { $0.playerId == playerId }
    }

    // 플레이어 차단
    func blockPlayer(_ playerId: String) {
        guard !blockedPlayers.contains(playerId) else { return }
        blockedPlayers.append(playerId)

        // 친구 목록에서 제거
        removeFriend(playerId)

        // 친구 요청 제거
        friendRequests.removeAll { $0.fromPlayerId == playerId }
    }

    // 플레이어 차단 해제
    func unblockPlayer(_ playerId: String) {
        blockedPlayers.removeAll { $0 == playerId }
    }
}

// MARK: - 평판 시스템 메서드
extension PlayerRelationships {
    // 평판 업데이트
    private func updateReputation(basedOn satisfaction: Int) {
        let change = satisfaction - 3 // 만족도 3을 중립으로 간주
        reputationScore = max(0, reputationScore + change * 10)

        // 신뢰 등급 업데이트
        updateTrustLevel()
    }

    // 신뢰 등급 업데이트
    private func updateTrustLevel() {
        switch reputationScore {
        case 0..<100:
            trustLevel = .unknown
        case 100..<300:
            trustLevel = .novice
        case 300..<600:
            trustLevel = .reliable
        case 600..<1000:
            trustLevel = .trusted
        case 1000..<1500:
            trustLevel = .expert
        default:
            trustLevel = .master
        }
    }

    // 평판 보너스 계산
    var reputationBonus: Double {
        return Double(reputationScore) / 1000.0 * 0.05 // 최대 5% 보너스
    }

    // 거래 성공률
    var tradeSuccessRate: Double {
        let successfulTrades = tradeHistory.filter { $0.satisfaction >= 3 }.count
        guard tradeHistory.count > 0 else { return 0.0 }
        return Double(successfulTrades) / Double(tradeHistory.count)
    }
}

// MARK: - 지원 구조체들
struct MerchantRelationship: Codable {
    let merchantId: String
    var friendshipPoints: Int = 0
    var trustLevel: Int = 0
    var totalTrades: Int = 0
    var totalSpent: Int = 0
    var lastInteraction: String?
    var notes: String?

    mutating func updateRelationship(satisfaction: Int) {
        totalTrades += 1
        friendshipPoints += (satisfaction - 3) * 5
        friendshipPoints = max(0, friendshipPoints)
        lastInteraction = ISO8601DateFormatter().string(from: Date())

        // 신뢰 레벨 계산 (거래 횟수와 만족도 기반)
        if satisfaction >= 4 {
            trustLevel = min(trustLevel + 1, 100)
        } else if satisfaction <= 2 {
            trustLevel = max(trustLevel - 1, 0)
        }
    }
}

struct GuildMembership: Identifiable, Codable {
    let id = UUID()
    let guildId: String
    let guildName: String
    let role: GuildRole
    let joinDate: Date
    var contributionPoints: Int = 0

    var benefits: GuildBenefits {
        switch role {
        case .member:
            return GuildBenefits(tradeBonus: 0.02, storageBonus: 5, experienceBonus: 0.05)
        case .officer:
            return GuildBenefits(tradeBonus: 0.05, storageBonus: 10, experienceBonus: 0.1)
        case .leader:
            return GuildBenefits(tradeBonus: 0.1, storageBonus: 20, experienceBonus: 0.15)
        }
    }

    enum CodingKeys: String, CodingKey {
        case guildId, guildName, role, joinDate, contributionPoints
    }
}

enum GuildRole: String, Codable {
    case member, officer, leader

    var displayName: String {
        switch self {
        case .member: return "일반 회원"
        case .officer: return "간부"
        case .leader: return "길드장"
        }
    }
}

struct GuildBenefits: Codable {
    let tradeBonus: Double      // 거래 보너스
    let storageBonus: Int       // 창고 용량 보너스
    let experienceBonus: Double // 경험치 보너스
}

struct GuildInvitation: Identifiable, Codable {
    let id = UUID()
    let guildId: String
    let guildName: String
    let inviterName: String
    let inviteDate: Date
    let expiryDate: Date

    var isExpired: Bool {
        return Date() > expiryDate
    }

    enum CodingKeys: String, CodingKey {
        case guildId, guildName, inviterName, inviteDate, expiryDate
    }
}

struct Friend: Identifiable, Codable {
    let id = UUID()
    let playerId: String
    let playerName: String
    let friendshipDate: Date
    let status: FriendStatus

    enum CodingKeys: String, CodingKey {
        case playerId, playerName, friendshipDate, status
    }
}

enum FriendStatus: String, Codable {
    case active, inactive, blocked

    var displayName: String {
        switch self {
        case .active: return "활성"
        case .inactive: return "비활성"
        case .blocked: return "차단됨"
        }
    }
}

struct FriendRequest: Identifiable, Codable {
    let id = UUID()
    let fromPlayerId: String
    let fromPlayerName: String
    let status: RequestStatus
    let date: Date

    enum CodingKeys: String, CodingKey {
        case fromPlayerId, fromPlayerName, status, date
    }
}

enum RequestStatus: String, Codable {
    case sent, received, accepted, declined

    var displayName: String {
        switch self {
        case .sent: return "전송됨"
        case .received: return "수신됨"
        case .accepted: return "수락됨"
        case .declined: return "거절됨"
        }
    }
}

struct TradeRecord: Identifiable, Codable {
    let id = UUID()
    let merchantId: String
    let itemName: String
    let tradeType: TradeType
    let amount: Int
    let satisfaction: Int // 1-5 점수
    let date: Date

    enum CodingKeys: String, CodingKey {
        case merchantId, itemName, tradeType, amount, satisfaction, date
    }
}

// TradeType은 TradeManager.swift에 정의됨

enum TrustLevel: String, Codable, CaseIterable {
    case unknown, novice, reliable, trusted, expert, master

    var displayName: String {
        switch self {
        case .unknown: return "미지"
        case .novice: return "초보"
        case .reliable: return "신뢰할 만한"
        case .trusted: return "신뢰받는"
        case .expert: return "전문가"
        case .master: return "마스터"
        }
    }

    var color: Color {
        switch self {
        case .unknown: return .gray
        case .novice: return .yellow
        case .reliable: return .green
        case .trusted: return .blue
        case .expert: return .purple
        case .master: return .orange
        }
    }
}
