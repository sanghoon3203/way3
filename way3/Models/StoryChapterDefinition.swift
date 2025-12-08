//
//  StoryChapterDefinition.swift
//  way3
//
//  메인 스토리 챕터/구역/에피소드 정의 및 로더
//

import Foundation

// MARK: - Top Level Definitions

struct StoryChapterDefinition: Codable, Identifiable, Hashable {
    let chapterId: String
    let title: String
    let order: Int
    let region: String?
    let summary: String?
    let mainStoryEntry: String?
    let districts: [StoryDistrictDefinition]
    let unlockConditions: [StoryUnlockCondition]
    let entryRequirements: EntryRequirements?
    let completionReward: StoryCompletionReward?

    var id: String { chapterId }

    enum CodingKeys: String, CodingKey {
        case chapterId
        case title
        case order
        case region
        case summary
        case mainStoryEntry
        case districts
        case unlockConditions
        case entryRequirements
        case completionReward
    }

    init(
        chapterId: String,
        title: String,
        order: Int,
        region: String?,
        summary: String?,
        mainStoryEntry: String?,
        districts: [StoryDistrictDefinition],
        unlockConditions: [StoryUnlockCondition] = [],
        entryRequirements: EntryRequirements?,
        completionReward: StoryCompletionReward?
    ) {
        self.chapterId = chapterId
        self.title = title
        self.order = order
        self.region = region
        self.summary = summary
        self.mainStoryEntry = mainStoryEntry
        self.districts = districts
        self.unlockConditions = unlockConditions
        self.entryRequirements = entryRequirements
        self.completionReward = completionReward
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chapterId = try container.decode(String.self, forKey: .chapterId)
        title = try container.decode(String.self, forKey: .title)
        order = try container.decode(Int.self, forKey: .order)
        region = try container.decodeIfPresent(String.self, forKey: .region)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        mainStoryEntry = try container.decodeIfPresent(String.self, forKey: .mainStoryEntry)
        districts = try container.decode([StoryDistrictDefinition].self, forKey: .districts)
        unlockConditions = try container.decodeIfPresent([StoryUnlockCondition].self, forKey: .unlockConditions) ?? []
        entryRequirements = try container.decodeIfPresent(EntryRequirements.self, forKey: .entryRequirements)
        completionReward = try container.decodeIfPresent(StoryCompletionReward.self, forKey: .completionReward)
    }
}

struct EntryRequirements: Codable, Hashable {
    let minLevel: Int?
    let requiredItems: [String]?
}

struct StoryDistrictDefinition: Codable, Identifiable, Hashable {
    let districtId: String
    let name: String
    let merchantId: String?
    let synopsis: String?
    let episodes: [StoryEpisodeDefinition]

    var id: String { districtId }
}

struct StoryEpisodeDefinition: Codable, Identifiable, Hashable {
    let episodeId: String
    let title: String
    let storyNodeId: String
    let order: Int
    let unlockConditions: [StoryUnlockCondition]
    let postQuestId: String?

    var id: String { episodeId }

    enum CodingKeys: String, CodingKey {
        case episodeId
        case title
        case storyNodeId
        case order
        case unlockConditions
        case postQuestId
    }

    init(
        episodeId: String,
        title: String,
        storyNodeId: String,
        order: Int,
        unlockConditions: [StoryUnlockCondition] = [],
        postQuestId: String?
    ) {
        self.episodeId = episodeId
        self.title = title
        self.storyNodeId = storyNodeId
        self.order = order
        self.unlockConditions = unlockConditions
        self.postQuestId = postQuestId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        episodeId = try container.decode(String.self, forKey: .episodeId)
        title = try container.decode(String.self, forKey: .title)
        storyNodeId = try container.decode(String.self, forKey: .storyNodeId)
        order = try container.decode(Int.self, forKey: .order)
        unlockConditions = try container.decodeIfPresent([StoryUnlockCondition].self, forKey: .unlockConditions) ?? []
        postQuestId = try container.decodeIfPresent(String.self, forKey: .postQuestId)
    }
}

struct StoryCompletionReward: Codable, Hashable {
    let keyItem: String?
    let money: Int?
    let exp: Int?
}

// MARK: - Unlock Conditions

enum StoryUnlockConditionType: String, Codable, Hashable {
    case episode
    case quest
    case subQuest
    case keyItem
    case item
}

struct StoryUnlockCondition: Codable, Hashable {
    let type: StoryUnlockConditionType
    let value: String
}

// MARK: - Container & Loader

private struct StoryChapterContainer: Codable {
    let chapters: [StoryChapterDefinition]
}

enum StoryChapterRepository {
    private static let fileName = "story_main_chapters"
    private static let directory = "GameData/Story"

    static func loadChapters() -> [StoryChapterDefinition] {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "json", inDirectory: directory) ??
                Bundle.main.path(forResource: fileName, ofType: "json") else {
            print("❌ \(fileName).json 파일을 찾을 수 없습니다")
            return []
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let container = try decoder.decode(StoryChapterContainer.self, from: data)
            return container.chapters.sorted { $0.order < $1.order }
        } catch {
            print("❌ \(fileName).json 파싱 실패: \(error)")
            return []
        }
    }

    static func chapter(withId id: String, in chapters: [StoryChapterDefinition]) -> StoryChapterDefinition? {
        chapters.first { $0.chapterId == id }
    }
}

// MARK: - Progress Helpers

extension StoryChapterDefinition {
    var allEpisodes: [StoryEpisodeDefinition] {
        districts.flatMap { $0.episodes.sorted { $0.order < $1.order } }
    }

    func isUnlocked(progress: PlayerProgress) -> Bool {
        unlockConditions.isSatisfied(by: progress)
    }

    func isCompleted(progress: PlayerProgress) -> Bool {
        progress.isChapterCompleted(chapterId)
    }

    func completedEpisodeCount(progress: PlayerProgress) -> Int {
        allEpisodes.filter { progress.isEpisodeCompleted($0.episodeId) }.count
    }

    func totalEpisodeCount() -> Int {
        allEpisodes.count
    }
}

extension StoryDistrictDefinition {
    var sortedEpisodes: [StoryEpisodeDefinition] {
        episodes.sorted { $0.order < $1.order }
    }
}

extension StoryEpisodeDefinition {
    func isCompleted(progress: PlayerProgress) -> Bool {
        progress.isEpisodeCompleted(episodeId)
    }

    func isUnlocked(progress: PlayerProgress) -> Bool {
        if progress.isEpisodeCompleted(episodeId) { return true }
        if progress.isEpisodeUnlocked(episodeId) { return true }
        if unlockConditions.isEmpty { return true }
        return unlockConditions.isSatisfied(by: progress)
    }

    func shouldAutoUnlock(progress: PlayerProgress) -> Bool {
        if progress.isEpisodeCompleted(episodeId) { return false }
        if progress.isEpisodeUnlocked(episodeId) { return false }
        if unlockConditions.isEmpty { return true }
        return unlockConditions.isSatisfied(by: progress)
    }
}

// MARK: - Unlock Condition Helpers

extension Array where Element == StoryUnlockCondition {
    func isSatisfied(by progress: PlayerProgress) -> Bool {
        guard !isEmpty else { return true }
        return allSatisfy { $0.isSatisfied(by: progress) }
    }
}

extension StoryUnlockCondition {
    func isSatisfied(by progress: PlayerProgress) -> Bool {
        switch type {
        case .episode:
            return progress.isEpisodeCompleted(value)
        case .quest:
            return progress.isMainQuestCompleted(value)
        case .subQuest:
            return progress.isSubQuestCompleted(value)
        case .keyItem, .item:
            return progress.hasKeyItem(value)
        }
    }
}
