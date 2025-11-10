import Foundation

struct StoryUnlockState {
    let isUnlocked: Bool
    let isCompleted: Bool
    let pendingConditions: [StoryUnlockCondition]
}

struct StoryUnlockEvaluator {
    let progress: PlayerProgress

    func chapterState(for chapter: StoryChapterDefinition) -> StoryUnlockState {
        StoryUnlockState(
            isUnlocked: chapter.isUnlocked(progress: progress),
            isCompleted: chapter.isCompleted(progress: progress),
            pendingConditions: chapter.unlockConditions.pendingConditions(progress: progress)
        )
    }

    func episodeState(for episode: StoryEpisodeDefinition) -> StoryUnlockState {
        StoryUnlockState(
            isUnlocked: episode.isUnlocked(progress: progress),
            isCompleted: episode.isCompleted(progress: progress),
            pendingConditions: episode.unlockConditions.pendingConditions(progress: progress)
        )
    }

    func merchantStoryState(for meta: MerchantEpisodeMeta) -> StoryUnlockState {
        StoryUnlockState(
            isUnlocked: true,
            isCompleted: progress.isEpisodeCompleted(meta.episode_id),
            pendingConditions: []
        )
    }
}

private extension Array where Element == StoryUnlockCondition {
    func pendingConditions(progress: PlayerProgress) -> [StoryUnlockCondition] {
        filter { condition in
            condition.isSatisfied(by: progress) == false
        }
    }
}
