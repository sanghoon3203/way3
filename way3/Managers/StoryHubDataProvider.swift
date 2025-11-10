import Foundation

struct StoryHubChapterSnapshot: Identifiable {
    let definition: StoryChapterDefinition
    let isUnlocked: Bool
    let isCompleted: Bool
    let completedEpisodes: Int
    let totalEpisodes: Int
    let pendingConditions: [StoryUnlockCondition]

    var id: String { definition.chapterId }
    var introNodeId: String? { definition.mainStoryEntry }
}

struct StoryHubMerchantStorySnapshot: Identifiable {
    let meta: MerchantEpisodeMeta
    let isUnlocked: Bool
    let isCompleted: Bool
    let pendingConditions: [StoryUnlockCondition]

    var id: String { meta.episode_id }
    var merchantId: String { meta.merchant_id }
    var entryNodeId: String { meta.entry_node }
    var title: String { meta.title }
}

struct StoryHubSnapshot {
    let chapters: [StoryHubChapterSnapshot]
    let merchantStories: [StoryHubMerchantStorySnapshot]
}

final class StoryHubDataProvider {
    static let shared = StoryHubDataProvider()

    func makeSnapshot(progress: PlayerProgress) -> StoryHubSnapshot {
        let chapters = StoryChapterRepository.loadChapters()
        let evaluator = StoryUnlockEvaluator(progress: progress)
        let chapterSnapshots = chapters.map { chapter -> StoryHubChapterSnapshot in
            let state = evaluator.chapterState(for: chapter)
            return StoryHubChapterSnapshot(
                definition: chapter,
                isUnlocked: state.isUnlocked,
                isCompleted: state.isCompleted,
                completedEpisodes: chapter.completedEpisodeCount(progress: progress),
                totalEpisodes: max(chapter.totalEpisodeCount(), 1),
                pendingConditions: state.pendingConditions
            )
        }

        let merchantIds = Set(
            chapters
                .flatMap { $0.districts }
                .compactMap { $0.merchantId }
        )
        let merchantMetas = StoryLibrary
            .loadMerchantEpisodes(merchantIds: Array(merchantIds))
            .sorted { ($0.merchant_id, $0.episode_id) < ($1.merchant_id, $1.episode_id) }

        let merchantSnapshots = merchantMetas.map { meta -> StoryHubMerchantStorySnapshot in
            let state = evaluator.merchantStoryState(for: meta)
            return StoryHubMerchantStorySnapshot(
                meta: meta,
                isUnlocked: state.isUnlocked,
                isCompleted: state.isCompleted,
                pendingConditions: state.pendingConditions
            )
        }

        return StoryHubSnapshot(chapters: chapterSnapshots, merchantStories: merchantSnapshots)
    }
}
