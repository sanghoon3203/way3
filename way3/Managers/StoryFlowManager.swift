//
//  StoryFlowManager.swift
//  way3
//
//  에피소드 완료, 메인 퀘스트 생성, 보상 지급을 담당하는 중앙 컨트롤러
//

import Foundation
import os

@MainActor
final class StoryFlowManager: ObservableObject {
    static let shared = StoryFlowManager()

    private let progressManager: ProgressManager
    private let questManager: QuestManager
    private let logger = Logger(subsystem: "com.way3.story", category: "StoryFlowManager")

    private init(
        progressManager: ProgressManager? = nil,
        questManager: QuestManager? = nil
    ) {
        self.progressManager = progressManager ?? ProgressManager.shared
        self.questManager = questManager ?? QuestManager.shared
    }

    // MARK: - Episode Completion

    func handleEpisodeCompletion(_ episode: StoryEpisodeDefinition) {
        logger.info("🎬 에피소드 완료 처리: \(episode.episodeId)")

        let alreadyCompleted = progressManager.isEpisodeCompleted(episode.episodeId)
        progressManager.completeEpisode(episode.episodeId)

        guard !alreadyCompleted else {
            logger.debug("⏭️ 에피소드 \(episode.episodeId) 이미 완료 상태 - 보상 스킵")
            return
        }

        if let questId = episode.postQuestId,
           let mainQuest = MainQuestRepository.quest(withId: questId) {
            createMainQuest(mainQuest)
        }

        unlockNextEpisodes(after: episode)
        handleChapterCompletionIfNeeded(for: episode)
    }

    func makeCompletionHandler(for episode: StoryEpisodeDefinition?) -> () -> Void {
        { [weak self] in
            guard let self = self else { return }
            if let episode = episode {
                self.handleEpisodeCompletion(episode)
            }
        }
    }

    private func unlockNextEpisodes(after episode: StoryEpisodeDefinition) {
        guard let chapter = StoryChapterRepository.chapter(
            withId: episodeChapterId(for: episode),
            in: StoryChapterRepository.loadChapters()
        ) else { return }

        let episodes = chapter.allEpisodes.sorted { $0.order < $1.order }
        guard let index = episodes.firstIndex(where: { $0.episodeId == episode.episodeId }) else { return }

        let remaining = episodes.suffix(from: episodes.index(after: index))
        let unlockables = remaining.filter { $0.shouldAutoUnlock(progress: progressManager.progress) }
        if !unlockables.isEmpty {
            let ids = unlockables.map { $0.episodeId }
            progressManager.unlockEpisodes(ids)
            logger.info("🔓 다음 에피소드 언락: \(ids)")
        }
    }

    private func episodeChapterId(for episode: StoryEpisodeDefinition) -> String {
        let chapters = StoryChapterRepository.loadChapters()
        for chapter in chapters {
            if chapter.allEpisodes.contains(where: { $0.episodeId == episode.episodeId }) {
                return chapter.chapterId
            }
        }
        return ""
    }

    // MARK: - Main Quest Creation

    private func createMainQuest(_ questDef: MainQuestDefinition) {
        guard !progressManager.isMainQuestCompleted(questDef.questId) else {
            logger.debug("⏭️ 메인 퀘스트 \(questDef.questId) 이미 완료")
            return
        }

        let requirements = questDef.requirements
        guard requirements.isSatisfied(by: progressManager.progress, playerLevel: currentPlayerLevel()) else {
            logger.debug("⏳ 메인 퀘스트 \(questDef.questId) 요구조건 미충족")
            return
        }

        questManager.enqueueMainQuest(questDef)
        logger.info("📝 메인 퀘스트 생성: \(questDef.questId)")
    }

    private func currentPlayerLevel() -> Int {
        GameManager.shared.currentPlayer?.core.level ?? 1
    }

    // MARK: - Quest Completion (Main)

    func completeMainQuest(_ quest: MainQuestDefinition) {
        _ = questManager.completeMainQuest(quest)
    }

    private func handleChapterCompletionIfNeeded(for episode: StoryEpisodeDefinition) {
        let chapters = StoryChapterRepository.loadChapters()
        guard let chapter = StoryChapterRepository.chapter(withId: episodeChapterId(for: episode), in: chapters) else { return }

        let alreadyCompleted = progressManager.progress.isChapterCompleted(chapter.chapterId)
        let isNowCompleted = chapter.isCompleted(progress: progressManager.progress)

        guard isNowCompleted, !alreadyCompleted else { return }

        progressManager.completeChapter(chapter.chapterId)

        if let reward = chapter.completionReward {
            let keyItems = reward.keyItem.map { [$0] } ?? []
            let questReward = QuestRewards(
                money: reward.money,
                exp: reward.exp,
                storyPieceIds: [],
                inventoryItems: [],
                keyItems: keyItems,
                relationshipChange: nil
            )

            RewardProcessor(progressManager: progressManager).apply(
                rewards: questReward,
                questId: "chapter: \(chapter.chapterId)"
            )
        }
    }
}
