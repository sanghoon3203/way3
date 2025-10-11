//
//  RewardProcessor.swift
//  way3
//
//  퀘스트/스토리 보상을 플레이어에게 적용하는 헬퍼
//

import Foundation
import os

@MainActor
struct RewardProcessor {
    private let progressManager: ProgressManager
    private let logger = Logger(subsystem: "com.way3.quest", category: "RewardProcessor")

    init(progressManager: ProgressManager? = nil) {
        self.progressManager = progressManager ?? ProgressManager.shared
    }

    func apply(rewards: QuestRewards, questId: String) {
        guard let player = GameManager.shared.currentPlayer else {
            logger.error("❌ 보상 적용 실패 - 플레이어 정보 없음 (퀘스트: \(questId))")
            return
        }

        if let money = rewards.money, money > 0 {
            player.core.earnMoney(money)
            GameManager.shared.addNotification(
                title: "보상 획득",
                message: "골드코인 \(money.formatted())원을 획득했습니다.",
                type: .success
            )
        }

        if let exp = rewards.exp, exp > 0 {
            player.core.gainExperience(exp)
        }

        if !rewards.storyPieceIds.isEmpty {
            for storyPiece in rewards.storyPieceIds {
                progressManager.collectStoryPiece(storyPiece)
            }
        }

        if !rewards.keyItems.isEmpty {
            for keyItem in rewards.keyItems {
                progressManager.acquireKeyItem(keyItem)
            }
        }

        if let relationshipChange = rewards.relationshipChange {
            player.relationships.adjustTrust(for: relationshipChange.merchantId, amount: relationshipChange.trust)
        }

        if !rewards.inventoryItems.isEmpty {
            logger.info("ℹ️ 인벤토리 보상 \(rewards.inventoryItems) 는 아직 자동 지급 로직이 구현되지 않았습니다.")
        }
    }
}
