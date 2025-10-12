//
//  StoryRewardService.swift
//  way3
//
//  메인 스토리 챕터 완료 보상을 서버와 동기화하는 헬퍼
//

import Foundation
import os

@MainActor
final class StoryRewardService {
    static let shared = StoryRewardService()

    private let networkManager = NetworkManager.shared
    private let gameManager = GameManager.shared
    private let logger = Logger(subsystem: "com.way3.story", category: "StoryRewardService")

    private init() {}

    func syncChapterReward(
        chapterId: String,
        reward: StoryCompletionReward
    ) async {
        let request = ChapterRewardClaimRequest(
            chapterId: chapterId,
            money: reward.money,
            experience: reward.exp,
            keyItemName: reward.keyItem,
            personalItemTemplateId: templateId(forKeyItem: reward.keyItem)
        )

        do {
            let response = try await networkManager.claimChapterReward(request: request)
            guard response.success else {
                logger.error("❌ 챕터 보상 동기화 실패 \(chapterId, privacy: .public) - \(response.error ?? "unknown", privacy: .public)")
                return
            }

            logger.info("🎁 챕터 보상 동기화 완료 \(chapterId, privacy: .public)")
            await gameManager.refreshPlayerData()
            await gameManager.refreshPersonalItemsData()
        } catch {
            logger.error("❌ 챕터 보상 동기화 오류 \(chapterId, privacy: .public) - \(error.localizedDescription, privacy: .public)")
        }
    }

    private func templateId(forKeyItem keyItem: String?) -> String? {
        guard let keyItem else { return nil }
        switch keyItem {
        case "임시 상인증":
            return "temp_merchant_license"
        default:
            return nil
        }
    }
}
