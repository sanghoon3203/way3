//
//  ProgressManager.swift
//  way3
//
//  로컬 우선 진행 상태 관리자
//  챕터, 퀘스트, 스토리 조각 진행 상태 추적
//

import Foundation
import os

// MARK: - Player Progress Model

struct PlayerProgress: Codable {
    static let currentVersion: Int = 4

    var version: Int = PlayerProgress.currentVersion
    var completedChapters: [String] = []
    var completedDistricts: [String] = []
    var completedSubQuests: [String] = []
    var completedMainQuests: [String] = []
    var mainQuestObjectiveProgress: [String: [Int]] = [:]
    var completedEpisodes: [String] = []
    var unlockedEpisodes: [String] = []
    var collectedStoryPieces: [String] = []
    var keyItems: [String] = []
    var currentChapterID: String?
    var lastSyncedAt: Date?

    enum CodingKeys: String, CodingKey {
        case version
        case completedChapters
        case completedDistricts
        case completedSubQuests
        case completedQuests // legacy
        case completedMainQuests
        case mainQuestObjectiveProgress
        case completedEpisodes
        case unlockedEpisodes
        case collectedStoryPieces
        case keyItems
        case currentChapterID
        case lastSyncedAt
    }

    init() { }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        completedChapters = try container.decodeIfPresent([String].self, forKey: .completedChapters) ?? []
        completedDistricts = try container.decodeIfPresent([String].self, forKey: .completedDistricts) ?? []

        if let subQuests = try container.decodeIfPresent([String].self, forKey: .completedSubQuests) {
            completedSubQuests = subQuests
        } else if let legacyQuests = try container.decodeIfPresent([String].self, forKey: .completedQuests) {
            completedSubQuests = legacyQuests
        } else {
            completedSubQuests = []
        }

        completedMainQuests = try container.decodeIfPresent([String].self, forKey: .completedMainQuests) ?? []
        mainQuestObjectiveProgress = try container.decodeIfPresent([String: [Int]].self, forKey: .mainQuestObjectiveProgress) ?? [:]
        completedEpisodes = try container.decodeIfPresent([String].self, forKey: .completedEpisodes) ?? []
        unlockedEpisodes = try container.decodeIfPresent([String].self, forKey: .unlockedEpisodes) ?? []
        collectedStoryPieces = try container.decodeIfPresent([String].self, forKey: .collectedStoryPieces) ?? []
        keyItems = try container.decodeIfPresent([String].self, forKey: .keyItems) ?? []
        currentChapterID = try container.decodeIfPresent(String.self, forKey: .currentChapterID)
        lastSyncedAt = try container.decodeIfPresent(Date.self, forKey: .lastSyncedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(version, forKey: .version)
        try container.encode(completedChapters, forKey: .completedChapters)
        try container.encode(completedDistricts, forKey: .completedDistricts)
        try container.encode(completedSubQuests, forKey: .completedSubQuests)
        try container.encode(completedMainQuests, forKey: .completedMainQuests)
        if !mainQuestObjectiveProgress.isEmpty {
            try container.encode(mainQuestObjectiveProgress, forKey: .mainQuestObjectiveProgress)
        }
        try container.encode(completedEpisodes, forKey: .completedEpisodes)
        try container.encode(unlockedEpisodes, forKey: .unlockedEpisodes)
        try container.encode(collectedStoryPieces, forKey: .collectedStoryPieces)
        try container.encode(keyItems, forKey: .keyItems)
        try container.encodeIfPresent(currentChapterID, forKey: .currentChapterID)
        try container.encodeIfPresent(lastSyncedAt, forKey: .lastSyncedAt)
    }

    // 진행률 계산용
    var completionPercentage: Double {
        // 전체 챕터 6개 기준 (5개 지역 + 1개 최종)
        let totalChapters = 6
        let totalDistricts = 25

        let chapterProgress = Double(completedChapters.count) / Double(totalChapters)
        let districtProgress = Double(completedDistricts.count) / Double(totalDistricts)

        // 챕터 완료도 60%, 구역 완료도 40% 비중
        return (chapterProgress * 0.6 + districtProgress * 0.4) * 100
    }

    // 챕터별 진행 상태
    func isChapterCompleted(_ chapterId: String) -> Bool {
        return completedChapters.contains(chapterId)
    }

    func isDistrictCompleted(_ districtId: String) -> Bool {
        return completedDistricts.contains(districtId)
    }

    func isQuestCompleted(_ questId: String) -> Bool {
        return isSubQuestCompleted(questId)
    }

    func isSubQuestCompleted(_ questId: String) -> Bool {
        return completedSubQuests.contains(questId)
    }

    func isMainQuestCompleted(_ questId: String) -> Bool {
        return completedMainQuests.contains(questId)
    }

    func isEpisodeCompleted(_ episodeId: String) -> Bool {
        return completedEpisodes.contains(episodeId)
    }

    func isEpisodeUnlocked(_ episodeId: String) -> Bool {
        // 기본적으로 완료한 에피소드는 항상 언락 처리로 간주
        return unlockedEpisodes.contains(episodeId) || completedEpisodes.contains(episodeId)
    }

    func hasStoryPiece(_ storyPieceId: String) -> Bool {
        return collectedStoryPieces.contains(storyPieceId)
    }

    func hasKeyItem(_ itemId: String) -> Bool {
        return keyItems.contains(itemId)
    }

    func hasAllRegionalKeys() -> Bool {
        let requiredKeys = [
            "key_item_gangnam",
            "key_item_northwest",
            "key_item_northeast",
            "key_item_southwest",
            "key_item_eastwest"
        ]
        return requiredKeys.allSatisfy { keyItems.contains($0) }
    }
    func migrated() -> PlayerProgress {
        var copy = self

        if copy.version < 3 {
            // v2 → v3: 신규 필드 기본값 채움
            if copy.completedMainQuests.isEmpty { copy.completedMainQuests = [] }
            if copy.completedEpisodes.isEmpty { copy.completedEpisodes = [] }
            if copy.unlockedEpisodes.isEmpty { copy.unlockedEpisodes = [] }
        }

        if copy.version < 4 {
            if copy.mainQuestObjectiveProgress.isEmpty { copy.mainQuestObjectiveProgress = [:] }
        }

        copy.version = PlayerProgress.currentVersion
        return copy
    }
}

// MARK: - Progress Manager

// MARK: - Progress Manager

@MainActor
class ProgressManager: ObservableObject {
    static let shared = ProgressManager()

    @Published var progress: PlayerProgress

    private let userDefaultsKey = "player_progress_v4"
    private let legacyKeys = ["player_progress_v3", "player_progress_v2", "player_progress_v1", "player_progress"]
    private let logger = Logger(subsystem: "com.way3.progress", category: "ProgressManager")

    private init() {
        if let current = ProgressManager.loadProgress(forKey: userDefaultsKey) {
            let migrated = current.migrated()
            self.progress = migrated
            logger.info("✅ 저장된 진행 상태 로드 완료 (버전 \(self.progress.version))")
        } else if let legacyResult = ProgressManager.loadLegacyProgress(keys: legacyKeys) {
            let migrated = legacyResult.progress.migrated()
            self.progress = migrated
            logger.info("♻️ 레거시 진행 상태 변환 완료 (key: \(legacyResult.key), 버전 \(self.progress.version))")
            save()
        } else {
            self.progress = PlayerProgress()
            logger.info("🆕 새 진행 상태 생성")
        }
    }

    // MARK: - Save/Load

    func save() {
        do {
            progress.version = PlayerProgress.currentVersion
            let data = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            legacyKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
            logger.info("💾 진행 상태 저장 완료")
        } catch {
            logger.error("❌ 진행 상태 저장 실패: \(error.localizedDescription)")
        }
    }

    func reset() {
        progress = PlayerProgress()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        logger.info("🔄 진행 상태 초기화")
    }

    // MARK: - Chapter Management

    func completeChapter(_ chapterId: String) {
        guard !progress.completedChapters.contains(chapterId) else {
            logger.debug("⏭️ 챕터 '\(chapterId)' 이미 완료됨")
            return
        }

        progress.completedChapters.append(chapterId)
        save()
        logger.info("✅ 챕터 '\(chapterId)' 완료 처리")
    }

    func setCurrentChapter(_ chapterId: String) {
        progress.currentChapterID = chapterId
        save()
        logger.info("📍 현재 챕터 설정: \(chapterId)")
    }

    // MARK: - District Management

    func completeDistrict(_ districtId: String) {
        guard !progress.completedDistricts.contains(districtId) else {
            logger.debug("⏭️ 구역 '\(districtId)' 이미 완료됨")
            return
        }

        progress.completedDistricts.append(districtId)
        save()
        logger.info("✅ 구역 '\(districtId)' 완료 처리")
    }

    // MARK: - Quest Management

    func completeSubQuest(_ questId: String) {
        guard !progress.completedSubQuests.contains(questId) else {
            logger.debug("⏭️ 서브 퀘스트 '\(questId)' 이미 완료됨")
            return
        }

        progress.completedSubQuests.append(questId)
        save()
        logger.info("✅ 서브 퀘스트 '\(questId)' 완료 처리")
    }

    /// 기존 코드 호환용 (서브 퀘스트 전용)
    func completeQuest(_ questId: String) {
        completeSubQuest(questId)
    }

    func isSubQuestCompleted(_ questId: String) -> Bool {
        return progress.completedSubQuests.contains(questId)
    }

    // MARK: - Main Quest Management

    func completeMainQuest(_ questId: String) {
        guard !progress.completedMainQuests.contains(questId) else {
            logger.debug("⏭️ 메인 퀘스트 '\(questId)' 이미 완료됨")
            return
        }

        progress.completedMainQuests.append(questId)
        save()
        logger.info("🏁 메인 퀘스트 '\(questId)' 완료 처리")
    }

    func isMainQuestCompleted(_ questId: String) -> Bool {
        return progress.completedMainQuests.contains(questId)
    }

    func completeMainQuestObjective(_ questId: String, objectiveIndex: Int) {
        var set = Set(progress.mainQuestObjectiveProgress[questId] ?? [])
        guard !set.contains(objectiveIndex) else {
            logger.debug("⏭️ 메인 퀘스트 목표 \(objectiveIndex) 이미 완료 (\(questId))")
            return
        }

        set.insert(objectiveIndex)
        progress.mainQuestObjectiveProgress[questId] = Array(set).sorted()
        save()
        logger.info("✅ 메인 퀘스트 목표 완료: \(questId) [\(objectiveIndex)]")
    }

    func isMainQuestObjectiveCompleted(_ questId: String, objectiveIndex: Int) -> Bool {
        return progress.mainQuestObjectiveProgress[questId]?.contains(objectiveIndex) ?? false
    }

    func completedObjectives(for questId: String) -> [Int] {
        return progress.mainQuestObjectiveProgress[questId] ?? []
    }

    func clearMainQuestObjectives(for questId: String) {
        progress.mainQuestObjectiveProgress.removeValue(forKey: questId)
        save()
        logger.debug("🗑️ 메인 퀘스트 목표 진행 초기화: \(questId)")
    }

    // MARK: - Episode Management

    func unlockEpisode(_ episodeId: String) {
        guard !progress.unlockedEpisodes.contains(episodeId) else {
            logger.debug("⏭️ 에피소드 '\(episodeId)' 이미 언락됨")
            return
        }

        progress.unlockedEpisodes.append(episodeId)
        save()
        logger.info("🔓 에피소드 '\(episodeId)' 언락")
    }

    func unlockEpisodes(_ episodeIds: [String]) {
        var changed = false

        for episodeId in episodeIds where !progress.unlockedEpisodes.contains(episodeId) {
            progress.unlockedEpisodes.append(episodeId)
            logger.debug("🔓 에피소드 '\(episodeId)' 언락 예정")
            changed = true
        }

        if changed {
            save()
            logger.info("🔓 에피소드 \(episodeIds) 언락 처리")
        }
    }

    func isEpisodeUnlocked(_ episodeId: String) -> Bool {
        return progress.isEpisodeUnlocked(episodeId)
    }

    func isEpisodeCompleted(_ episodeId: String) -> Bool {
        return progress.isEpisodeCompleted(episodeId)
    }

    func completeEpisode(_ episodeId: String) {
        guard !progress.completedEpisodes.contains(episodeId) else {
            logger.debug("⏭️ 에피소드 '\(episodeId)' 이미 완료됨")
            return
        }

        progress.completedEpisodes.append(episodeId)

        // 완료된 에피소드는 자동으로 언락 상태로 유지
        if !progress.unlockedEpisodes.contains(episodeId) {
            progress.unlockedEpisodes.append(episodeId)
        }

        save()
        logger.info("✅ 에피소드 '\(episodeId)' 완료 처리")
    }

    // MARK: - Story Piece Management

    func collectStoryPiece(_ storyPieceId: String) {
        guard !progress.collectedStoryPieces.contains(storyPieceId) else {
            logger.debug("⏭️ 스토리 조각 '\(storyPieceId)' 이미 수집됨")
            return
        }

        progress.collectedStoryPieces.append(storyPieceId)
        save()
        logger.info("📜 스토리 조각 '\(storyPieceId)' 수집")
    }

    // MARK: - Key Item Management

    func acquireKeyItem(_ itemId: String) {
        guard !progress.keyItems.contains(itemId) else {
            logger.debug("⏭️ 증표 아이템 '\(itemId)' 이미 보유")
            return
        }

        progress.keyItems.append(itemId)
        save()
        logger.info("🔑 증표 아이템 '\(itemId)' 획득")
    }

    func hasAllRegionalKeys() -> Bool {
        let requiredKeys = [
            "key_item_gangnam",
            "key_item_northwest",
            "key_item_northeast",
            "key_item_southwest",
            "key_item_eastwest"
        ]

        return requiredKeys.allSatisfy { progress.keyItems.contains($0) }
    }

    // MARK: - District Completion Check

    func getDistrictProgress(for chapterId: String, allDistricts: [String]) -> (completed: Int, total: Int) {
        let completedCount = allDistricts.filter { progress.completedDistricts.contains($0) }.count
        return (completedCount, allDistricts.count)
    }

    // 챕터의 모든 구역이 완료되었는지 확인
    func isChapterFullyCompleted(chapterId: String, districts: [String]) -> Bool {
        return districts.allSatisfy { progress.completedDistricts.contains($0) }
    }

    // MARK: - Sync (Optional - 서버 동기화용)

    func syncToServer() async throws {
        // TODO: 서버 API 연동 시 구현
        // POST /api/progress/sync
        progress.lastSyncedAt = Date()
        save()
        logger.info("☁️ 서버 동기화 완료")
    }

    func syncFromServer() async throws {
        // TODO: 서버 API 연동 시 구현
        // GET /api/progress
        logger.info("☁️ 서버에서 진행 상태 복구")
    }

    // MARK: - Debug

    func printProgress() {
        logger.debug("""
        📊 진행 상태:
        - 완료 챕터: \(self.progress.completedChapters.count)개
        - 완료 구역: \(self.progress.completedDistricts.count)개
        - 완료 서브 퀘스트: \(self.progress.completedSubQuests.count)개
        - 완료 메인 퀘스트: \(self.progress.completedMainQuests.count)개
        - 메인 퀘스트 목표: \(self.progress.mainQuestObjectiveProgress.values.reduce(0) { $0 + $1.count })개
        - 완료 에피소드: \(self.progress.completedEpisodes.count)개
        - 스토리 조각: \(self.progress.collectedStoryPieces.count)개
        - 증표 아이템: \(self.progress.keyItems.count)개
        - 전체 진행률: \(String(format: "%.1f", self.progress.completionPercentage))%
        """)
    }

    // MARK: - Private Helpers

    private static func loadProgress(forKey key: String) -> PlayerProgress? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlayerProgress.self, from: data)
    }

    private static func loadLegacyProgress(keys: [String]) -> (progress: PlayerProgress, key: String)? {
        for key in keys {
            if let legacy = loadProgress(forKey: key) {
                return (legacy, key)
            }
        }
        return nil
    }
}
