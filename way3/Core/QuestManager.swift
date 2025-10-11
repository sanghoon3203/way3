//
//  QuestManager.swift
//  way3
//
//  퀘스트 실행 및 보상 처리, 메인/서브 퀘스트 상태 관리
//

import Foundation
import UIKit
import CoreLocation
import os

@MainActor
final class QuestManager: ObservableObject {
    static let shared = QuestManager()

    @Published private(set) var activeQuest: SubQuest?
    @Published private(set) var queuedMainQuests: [MainQuestDefinition] = []
    @Published private(set) var isExecuting: Bool = false

    private let progressManager = ProgressManager.shared
    private let locationVerifier = LocationVerifier.shared
    private let receiptVerifier = ReceiptVerifier.shared
    private let rewardProcessor = RewardProcessor()
    private let logger = Logger(subsystem: "com.way3.quest", category: "QuestManager")

    private init() {}

    // MARK: - Sub Quest Execution

    func executeTradingQuest(
        quest: SubQuest,
        receiptImage: UIImage,
        userLocation: CLLocationCoordinate2D
    ) async throws -> QuestExecutionResult {
        guard quest.type == .trading else {
            throw QuestExecutionError.wrongQuestType
        }

        try ensureMetaRequirements(for: quest)

        isExecuting = true
        defer { isExecuting = false }

        logger.info("🛒 Trading 퀘스트 실행: \(quest.title)")

        if let location = quest.requirements.location {
            let merchantLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let distance = userLocation.distance(to: merchantLocation)
            guard distance <= Double(location.radius) else {
                throw QuestExecutionError.notInRange(distance: Int(distance), required: location.radius)
            }
        }

        let verificationResult = try await receiptVerifier.verifyReceipt(
            image: receiptImage,
            minPurchase: quest.requirements.min_purchase ?? 0,
            requiredLocation: nil,
            questId: quest.quest_id
        )

        return finalizeSubQuest(
            quest,
            message: "거래가 완료되었습니다! ₩\(verificationResult.amount ?? 0) 인증됨",
            verificationData: verificationResult
        )
    }

    func executeDeliveryQuest(
        quest: SubQuest,
        userLocation: CLLocation
    ) async throws -> QuestExecutionResult {
        guard quest.type == .delivery else {
            throw QuestExecutionError.wrongQuestType
        }

        try ensureMetaRequirements(for: quest)

        isExecuting = true
        defer { isExecuting = false }

        logger.info("🚚 Delivery 퀘스트 실행: \(quest.title)")

        guard let targetLocation = quest.requirements.target_location else {
            throw QuestExecutionError.missingRequirements
        }

        let target = CLLocationCoordinate2D(latitude: targetLocation.latitude, longitude: targetLocation.longitude)
        let verificationResult = try locationVerifier.verifyLocationWithAccuracy(
            userLocation: userLocation,
            targetLocation: target,
            radius: Double(targetLocation.radius)
        )

        return finalizeSubQuest(
            quest,
            message: "목표 지점에 도착했습니다! (\(String(format: "%.1f", verificationResult.distance))m)",
            verificationData: verificationResult
        )
    }

    func executeDialogueQuest(
        quest: SubQuest,
        completedStoryNode: String
    ) async throws -> QuestExecutionResult {
        guard quest.type == .dialogue else {
            throw QuestExecutionError.wrongQuestType
        }

        try ensureMetaRequirements(for: quest)

        logger.info("💬 Dialogue 퀘스트 실행: \(quest.title)")

        guard let requiredNode = quest.requirements.story_node_complete else {
            throw QuestExecutionError.missingRequirements
        }

        guard completedStoryNode == requiredNode else {
            throw QuestExecutionError.verificationFailed(reason: "필요한 대화를 완료하지 않았습니다.")
        }

        return finalizeSubQuest(
            quest,
            message: "대화가 완료되었습니다!",
            verificationData: completedStoryNode
        )
    }

    // MARK: - Sub Quest Helpers

    private func finalizeSubQuest(
        _ quest: SubQuest,
        message: String,
        verificationData: Any?
    ) -> QuestExecutionResult {
        progressManager.completeSubQuest(quest.quest_id)
        rewardProcessor.apply(rewards: quest.rewards, questId: quest.quest_id)

        logger.info("✅ 서브 퀘스트 완료: \(quest.quest_id)")

        return QuestExecutionResult(
            success: true,
            questId: quest.quest_id,
            questType: .sub,
            message: message,
            verificationData: verificationData
        )
    }

    private func ensureMetaRequirements(for quest: SubQuest) throws {
        let progress = progressManager.progress
        let playerLevel = GameManager.shared.currentPlayer?.core.level ?? 1
        guard quest.requirements.meetsMetaRequirements(progress: progress, playerLevel: playerLevel) else {
            throw QuestExecutionError.requirementsNotMet
        }
    }

    // MARK: - Location Tracking

    func startLocationTracking(
        for quest: SubQuest,
        onArrival: @escaping (LocationVerificationResult) -> Void
    ) {
        guard quest.type == .delivery,
              let targetLocation = quest.requirements.target_location else {
            logger.error("❌ Delivery 퀘스트가 아니거나 목표 위치가 없습니다")
            return
        }

        activeQuest = quest

        let target = CLLocationCoordinate2D(
            latitude: targetLocation.latitude,
            longitude: targetLocation.longitude
        )

        locationVerifier.startLocationTracking(
            questID: quest.quest_id,
            targetLocation: target,
            radius: Double(targetLocation.radius),
            onArrival: { result in
                Task { @MainActor in
                    onArrival(result)
                    self.activeQuest = nil
                }
            }
        )

        logger.info("🎯 위치 추적 시작: \(quest.title)")
    }

    func stopLocationTracking() {
        locationVerifier.stopLocationTracking()
        activeQuest = nil
        logger.info("⏹️ 위치 추적 중단")
    }

    // MARK: - Main Quest Handling

    func enqueueMainQuest(_ quest: MainQuestDefinition) {
        guard !queuedMainQuests.contains(where: { $0.questId == quest.questId }) else {
            logger.debug("⏭️ 메인 퀘스트 \(quest.questId) 이미 대기열에 존재")
            return
        }

        queuedMainQuests.append(quest)
        logger.info("📝 메인 퀘스트 대기열 등록: \(quest.questId)")
        GameManager.shared.addNotification(
            title: "새로운 메인 퀘스트",
            message: "\(quest.title) 퀘스트가 활성화되었습니다.",
            type: .info
        )
        evaluateMainQuestCompletion(for: quest)
    }

    @discardableResult
    func completeMainQuest(_ quest: MainQuestDefinition) -> Bool {
        let progress = progressManager.progress
        let playerLevel = GameManager.shared.currentPlayer?.core.level ?? 1

        guard quest.requirements.isSatisfied(by: progress, playerLevel: playerLevel) else {
            logger.error("❌ 메인 퀘스트 완료 실패 - 요구조건 미충족: \(quest.questId)")
            return false
        }

        progressManager.completeMainQuest(quest.questId)
        progressManager.clearMainQuestObjectives(for: quest.questId)
        rewardProcessor.apply(rewards: quest.rewards.asQuestRewards(), questId: quest.questId)
        queuedMainQuests.removeAll { $0.questId == quest.questId }
        logger.info("🏁 메인 퀘스트 완료: \(quest.questId)")

        GameManager.shared.addNotification(
            title: "메인 퀘스트 완료",
            message: "\(quest.title)을(를) 완료했습니다!",
            type: .success
        )
        return true
    }

    // MARK: - Objective Event Hooks

    func recordTradeEvent(merchantId: String?, storeId: String?, amount: Int) {
        let quests = queuedMainQuests
        for quest in quests {
            var updated = false
            for (index, objective) in quest.objectives.enumerated() {
                guard !progressManager.isMainQuestObjectiveCompleted(quest.questId, objectiveIndex: index) else { continue }
                guard objective.matchesTrade(merchantId: merchantId, storeId: storeId, amount: amount) else { continue }
                progressManager.completeMainQuestObjective(quest.questId, objectiveIndex: index)
                logger.info("🧩 메인 퀘스트 목표 달성 (거래): \(quest.questId) [\(index)]")
                updated = true
            }
            if updated {
                GameManager.shared.addNotification(
                    title: "목표 달성",
                    message: "\(quest.title)의 목표가 진행되었습니다.",
                    type: .success
                )
                evaluateMainQuestCompletion(for: quest)
            }
        }
    }

    func recordLocationEvent(currentLocation: CLLocationCoordinate2D) {
        let quests = queuedMainQuests
        for quest in quests {
            var updated = false
            for (index, objective) in quest.objectives.enumerated() {
                guard !progressManager.isMainQuestObjectiveCompleted(quest.questId, objectiveIndex: index) else { continue }
                guard objective.matchesLocation(currentLocation: currentLocation) else { continue }
                progressManager.completeMainQuestObjective(quest.questId, objectiveIndex: index)
                logger.info("🧭 메인 퀘스트 목표 달성 (위치): \(quest.questId) [\(index)]")
                updated = true
            }
            if updated {
                GameManager.shared.addNotification(
                    title: "목표 달성",
                    message: "\(quest.title)의 목표가 진행되었습니다.",
                    type: .success
                )
                evaluateMainQuestCompletion(for: quest)
            }
        }
    }

    func recordDialogueEvent(nodeId: String) {
        let quests = queuedMainQuests
        for quest in quests {
            var updated = false
            for (index, objective) in quest.objectives.enumerated() {
                guard !progressManager.isMainQuestObjectiveCompleted(quest.questId, objectiveIndex: index) else { continue }
                guard objective.matchesDialogue(nodeId: nodeId) else { continue }
                progressManager.completeMainQuestObjective(quest.questId, objectiveIndex: index)
                logger.info("💬 메인 퀘스트 목표 달성 (대화): \(quest.questId) [\(index)]")
                updated = true
            }
            if updated {
                GameManager.shared.addNotification(
                    title: "목표 달성",
                    message: "\(quest.title)의 목표가 진행되었습니다.",
                    type: .success
                )
                evaluateMainQuestCompletion(for: quest)
            }
        }
    }

    private func evaluateMainQuestCompletion(for quest: MainQuestDefinition) {
        let allComplete = quest.objectives.enumerated().allSatisfy { index, _ in
            progressManager.isMainQuestObjectiveCompleted(quest.questId, objectiveIndex: index)
        }

        if allComplete {
            _ = completeMainQuest(quest)
        }
    }

    // MARK: - Status Helpers

    func isQuestCompleted(_ questId: String) -> Bool {
        return progressManager.progress.isSubQuestCompleted(questId)
    }

    func canStartQuest(_ quest: SubQuest, userLocation: CLLocationCoordinate2D) -> Bool {
        guard !isQuestCompleted(quest.quest_id) else { return false }

        let progress = progressManager.progress
        let playerLevel = GameManager.shared.currentPlayer?.core.level ?? 1
        guard quest.requirements.meetsMetaRequirements(progress: progress, playerLevel: playerLevel) else {
            return false
        }

        switch quest.type {
        case .trading:
            if let location = quest.requirements.location {
                let distance = userLocation.distance(to: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                return distance <= Double(location.radius)
            }
            return true

        case .delivery:
            if let target = quest.requirements.target_location {
                let distance = userLocation.distance(to: CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude))
                return distance <= Double(target.radius)
            }
            return false

        case .dialogue:
            return true
        }
    }
}

// MARK: - Quest Execution Error

enum QuestExecutionError: Error {
    case wrongQuestType
    case missingRequirements
    case notInRange(distance: Int, required: Int)
    case verificationFailed(reason: String)
    case requirementsNotMet

    var localizedDescription: String {
        switch self {
        case .wrongQuestType:
            return "잘못된 퀘스트 타입입니다"
        case .missingRequirements:
            return "퀘스트 요구사항이 부족합니다"
        case .notInRange(let distance, let required):
            return "상인에게서 \(distance - required)m 더 가까이 가야 합니다"
        case .verificationFailed(let reason):
            return "검증 실패: \(reason)"
        case .requirementsNotMet:
            return "필수 조건이 충족되지 않았습니다"
        }
    }
}

// MARK: - Result Model

struct QuestExecutionResult {
    enum QuestType {
        case sub
        case main
    }

    let success: Bool
    let questId: String
    let questType: QuestType
    let message: String
    let verificationData: Any?
}
