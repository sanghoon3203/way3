import Foundation
import AVFoundation
import os

// MARK: - Logging

enum AppLog {
    static let loader = Logger(subsystem: "com.yourapp.story", category: "VNLoader")
    static let story  = Logger(subsystem: "com.yourapp.story", category: "StoryView")
    static let type   = Logger(subsystem: "com.yourapp.story", category: "Typewriter")
    static let sfx    = Logger(subsystem: "com.yourapp.story", category: "SFX")
}

// MARK: - Node Model

enum VNNodeType: String, Decodable {
    case dialogue
    case decision
    case conditional
    case questGate = "quest_gate"
}

struct VNDialogueContent: Decodable {
    let text: String
    let speakerId: String?
    let speakerName: String?
    let backgroundImage: String?
    let characterSprite: String?
    let soundEffect: String?
    let dialogueSoundId: String?
    let nextNodeId: String?

    enum CodingKeys: String, CodingKey {
        case text
        case speakerId = "speaker_id"
        case speakerName = "speaker_name"
        case backgroundImage = "background_image"
        case characterSprite = "character_sprite"
        case soundEffect = "sound_effect"
        case dialogueSoundId = "dialogue_sound_id"
        case nextNodeId = "next_node_id"
    }

    init(
        text: String,
        speakerId: String?,
        speakerName: String?,
        backgroundImage: String?,
        characterSprite: String?,
        soundEffect: String?,
        dialogueSoundId: String?,
        nextNodeId: String?
    ) {
        self.text = text
        self.speakerId = speakerId
        self.speakerName = speakerName
        self.backgroundImage = backgroundImage
        self.characterSprite = characterSprite
        self.soundEffect = soundEffect
        self.dialogueSoundId = dialogueSoundId
        self.nextNodeId = nextNodeId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        speakerId = try container.decodeIfPresent(String.self, forKey: .speakerId)
        speakerName = try container.decodeIfPresent(String.self, forKey: .speakerName)
        backgroundImage = try container.decodeIfPresent(String.self, forKey: .backgroundImage)
        characterSprite = try container.decodeIfPresent(String.self, forKey: .characterSprite)
        soundEffect = try container.decodeIfPresent(String.self, forKey: .soundEffect)
        dialogueSoundId = try container.decodeIfPresent(String.self, forKey: .dialogueSoundId)
        nextNodeId = try container.decodeIfPresent(String.self, forKey: .nextNodeId)
    }

    func mergingLegacyDefaults(
        speakerId legacySpeakerId: String?,
        speakerName legacySpeakerName: String?,
        backgroundImage legacyBackgroundImage: String?,
        characterSprite legacyCharacterSprite: String?,
        soundEffect legacySoundEffect: String?,
        dialogueSoundId legacyDialogueSoundId: String?,
        nextNodeId legacyNextNodeId: String?,
        fallbackText: String?
    ) -> VNDialogueContent {
        VNDialogueContent(
            text: text.isEmpty ? (fallbackText ?? "") : text,
            speakerId: speakerId ?? legacySpeakerId,
            speakerName: speakerName ?? legacySpeakerName,
            backgroundImage: backgroundImage ?? legacyBackgroundImage,
            characterSprite: characterSprite ?? legacyCharacterSprite,
            soundEffect: soundEffect ?? legacySoundEffect,
            dialogueSoundId: dialogueSoundId ?? legacyDialogueSoundId,
            nextNodeId: nextNodeId ?? legacyNextNodeId
        )
    }

    var displaySpeaker: String? {
        if let name = speakerName, !name.isEmpty {
            return name
        }
        return speakerId
    }
}

struct VNChoice: Decodable, Identifiable {
    let id: String
    let text: String
    let nextNodeId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case nextNodeId = "next_node_id"
    }
}

struct VNDecisionContent: Decodable {
    let prompt: String?
    let speakerId: String?
    let speakerName: String?
    let choices: [VNChoice]

    enum CodingKeys: String, CodingKey {
        case prompt
        case speakerId = "speaker_id"
        case speakerName = "speaker_name"
        case choices
    }

    init(prompt: String?, speakerId: String?, speakerName: String?, choices: [VNChoice]) {
        self.prompt = prompt
        self.speakerId = speakerId
        self.speakerName = speakerName
        self.choices = choices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        speakerId = try container.decodeIfPresent(String.self, forKey: .speakerId)
        speakerName = try container.decodeIfPresent(String.self, forKey: .speakerName)
        choices = try container.decodeIfPresent([VNChoice].self, forKey: .choices) ?? []
    }

    var speakerDisplayName: String? {
        if let name = speakerName, !name.isEmpty { return name }
        return speakerId
    }
}

struct VNConditionalContent: Decodable {
    let condition: StoryUnlockCondition
    let successNodeId: String
    let failureNodeId: String

    enum CodingKeys: String, CodingKey {
        case condition
        case successNodeId = "on_success"
        case failureNodeId = "on_failure"
    }
}

struct VNQuestGateContent: Decodable {
    let questId: String
    let autoStart: Bool
    let nextNodeId: String?

    enum CodingKeys: String, CodingKey {
        case questId = "quest_id"
        case autoStart = "auto_start"
        case nextNodeId = "next_node_id"
    }
}

struct VNNode: Decodable {
    let nodeId: String
    let type: VNNodeType
    let dialogue: VNDialogueContent?
    let decision: VNDecisionContent?
    let conditional: VNConditionalContent?
    let questGate: VNQuestGateContent?

    enum CodingKeys: String, CodingKey {
        case nodeId = "node_id"
        case type
        case backgroundImage = "background_image"
        case characterId = "character_id"
        case characterSprite = "character_sprite"
        case dialogueText = "dialogue_text"
        case dialogueSoundId = "dialogue_sound_id"
        case soundEffect = "sound_effect"
        case nextNodeId = "next_node_id"
        case speakerName = "speaker_name"
        case dialogue
        case decision
        case choices
        case prompt
        case conditional
        case condition
        case successNodeId = "on_success"
        case failureNodeId = "on_failure"
        case questGate = "quest_gate"
        case questId = "quest_id"
        case autoStart = "auto_start"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nodeId = try container.decode(String.self, forKey: .nodeId)

        let legacyBackground = try container.decodeIfPresent(String.self, forKey: .backgroundImage)
        let legacyCharacterId = try container.decodeIfPresent(String.self, forKey: .characterId)
        let legacyCharacterSprite = try container.decodeIfPresent(String.self, forKey: .characterSprite)
        let legacyDialogueText = try container.decodeIfPresent(String.self, forKey: .dialogueText)
        let legacyDialogueSoundId = try container.decodeIfPresent(String.self, forKey: .dialogueSoundId)
        let legacySoundEffect = try container.decodeIfPresent(String.self, forKey: .soundEffect)
        let legacyNextNodeId = try container.decodeIfPresent(String.self, forKey: .nextNodeId)
        let legacySpeakerName = try container.decodeIfPresent(String.self, forKey: .speakerName)

        if let explicitType = try container.decodeIfPresent(VNNodeType.self, forKey: .type) {
            type = explicitType
        } else if container.contains(.decision) || container.contains(.choices) {
            type = .decision
        } else if container.contains(.conditional) || container.contains(.condition) || container.contains(.successNodeId) {
            type = .conditional
        } else if container.contains(.questGate) || container.contains(.questId) {
            type = .questGate
        } else {
            type = .dialogue
        }

        switch type {
        case .dialogue:
            if let payload = try container.decodeIfPresent(VNDialogueContent.self, forKey: .dialogue) {
                dialogue = payload.mergingLegacyDefaults(
                    speakerId: legacyCharacterId,
                    speakerName: legacySpeakerName,
                    backgroundImage: legacyBackground,
                    characterSprite: legacyCharacterSprite,
                    soundEffect: legacySoundEffect,
                    dialogueSoundId: legacyDialogueSoundId,
                    nextNodeId: legacyNextNodeId,
                    fallbackText: legacyDialogueText
                )
            } else {
                dialogue = VNDialogueContent(
                    text: legacyDialogueText ?? "",
                    speakerId: legacyCharacterId,
                    speakerName: legacySpeakerName,
                    backgroundImage: legacyBackground,
                    characterSprite: legacyCharacterSprite,
                    soundEffect: legacySoundEffect,
                    dialogueSoundId: legacyDialogueSoundId,
                    nextNodeId: legacyNextNodeId
                )
            }
            decision = nil
            conditional = nil
            questGate = nil
        case .decision:
            if let payload = try? container.decodeIfPresent(VNDecisionContent.self, forKey: .decision) {
                decision = payload
            } else {
                let choices = (try? container.decodeIfPresent([VNChoice].self, forKey: .choices)) ?? []
                let promptText = legacyDialogueText ?? (try? container.decodeIfPresent(String.self, forKey: .prompt))
                decision = VNDecisionContent(
                    prompt: promptText,
                    speakerId: legacyCharacterId,
                    speakerName: legacySpeakerName,
                    choices: choices
                )
            }
            dialogue = nil
            conditional = nil
            questGate = nil
        case .conditional:
            if let payload = try container.decodeIfPresent(VNConditionalContent.self, forKey: .conditional) {
                conditional = payload
            } else {
                let condition = try container.decode(StoryUnlockCondition.self, forKey: .condition)
                let success = try container.decode(String.self, forKey: .successNodeId)
                let failure = try container.decode(String.self, forKey: .failureNodeId)
                conditional = VNConditionalContent(condition: condition, successNodeId: success, failureNodeId: failure)
            }
            dialogue = nil
            decision = nil
            questGate = nil
        case .questGate:
            if let payload = try container.decodeIfPresent(VNQuestGateContent.self, forKey: .questGate) {
                questGate = payload
            } else {
                let questId = try container.decode(String.self, forKey: .questId)
                let autoStart = try container.decodeIfPresent(Bool.self, forKey: .autoStart) ?? false
                questGate = VNQuestGateContent(questId: questId, autoStart: autoStart, nextNodeId: legacyNextNodeId)
            }
            dialogue = nil
            decision = nil
            conditional = nil
        }
    }
}

extension VNNode {
    var primaryNextNodeId: String? {
        switch type {
        case .dialogue:
            return dialogue?.nextNodeId
        case .decision:
            return nil
        case .conditional:
            return nil
        case .questGate:
            return questGate?.nextNodeId
        }
    }

    var displaySpeaker: String? {
        if let decisionSpeaker = decision?.speakerDisplayName {
            return decisionSpeaker
        }
        return dialogue?.displaySpeaker
    }
}

// MARK: - Loader (Unified JSON Support)

// 통합 챕터 파일 디코딩 구조체
private struct UnifiedChapterFile: Decodable {
    let id: String
    let nodes: [VNNode]
}

private struct ChapterIndex: Decodable {
    let chapters: [ChapterIndexEntry]
}

private struct ChapterIndexEntry: Decodable {
    let id: String
}

enum VNLoader {

    // MARK: - Cache (inner class: enum은 stored property 불가)
    private final class NodeCache {
        var nodes: [String: VNNode] = [:]       // node_id → VNNode
        var loadedChapterIds: Set<String> = []   // 로드 시도한 챕터 ID
    }
    private static let cache = NodeCache()

    // index.json에서 읽어온 메인 챕터 ID 목록
    private static let mainChapterIds: Set<String> = loadMainChapterIds()

    // MARK: - Public Interface

    /// 통합 JSON 캐시 → 개별 파일 fallback 순으로 노드 로드
    static func loadNode(id: String) -> VNNode? {
        let name = id.replacingOccurrences(of: ".json", with: "")

        // 1단계: 캐시 확인
        if let cached = cache.nodes[name] {
            AppLog.loader.debug("⚡️ cache hit: \(name, privacy: .public)")
            return cached
        }

        // 2단계: 통합 JSON에서 로드
        if let chapterId = chapterIdForNode(name) {
            if !cache.loadedChapterIds.contains(chapterId) {
                _ = loadUnifiedChapter(id: chapterId)
            }
            if let node = cache.nodes[name] {
                return node
            }
            AppLog.loader.warning("⚠️ '\(name, privacy: .public)' not in unified '\(chapterId, privacy: .public)', trying fallback")
        }

        // 3단계: 기존 개별 파일 fallback (Substories 등)
        guard let url = nodeURL(for: name) else {
            AppLog.loader.error("❌ file not found: \(name, privacy: .public).json")
            AppLog.loader.error("   searched: unified files + subdirs: \(searchDirectories.joined(separator: ", "))")
            return nil
        }
        return decodeNode(from: url)
    }

    static func canLoadNode(id: String) -> Bool {
        let name = id.replacingOccurrences(of: ".json", with: "")

        if cache.nodes[name] != nil { return true }

        if let chapterId = chapterIdForNode(name) {
            if !cache.loadedChapterIds.contains(chapterId) {
                _ = loadUnifiedChapter(id: chapterId)
            }
            if cache.nodes[name] != nil { return true }
        }

        return nodeURL(for: name) != nil
    }

    // MARK: - Unified JSON Loading

    /// index.json을 읽어 챕터 ID Set 반환
    private static func loadMainChapterIds() -> Set<String> {
        let candidates = [
            Bundle.main.path(forResource: "index", ofType: "json", inDirectory: "StoryData"),
            Bundle.main.path(forResource: "index", ofType: "json")
        ]
        for path in candidates.compactMap({ $0 }) {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let index = try? JSONDecoder().decode(ChapterIndex.self, from: data) else { continue }
            let ids = Set(index.chapters.map(\.id))
            AppLog.loader.info("📋 index.json loaded: \(ids.sorted().joined(separator: ", "), privacy: .public)")
            return ids
        }
        AppLog.loader.warning("⚠️ index.json not found, using hardcoded chapter IDs")
        return ["prologue", "gangnam", "gangdong", "seocho", "songpa"]
    }

    /// 노드 ID → 챕터 ID 추정
    /// "chapter_gangnam_001" → "gangnam" / "prologue_01" → "prologue"
    private static func chapterIdForNode(_ nodeId: String) -> String? {
        for chapterId in mainChapterIds {
            if nodeId.contains(chapterId) {
                return chapterId
            }
        }
        return nil
    }

    /// 통합 챕터 JSON을 로드하여 캐시에 등록
    @discardableResult
    private static func loadUnifiedChapter(id: String) -> Bool {
        cache.loadedChapterIds.insert(id)

        let searchPaths: [(String?, String)] = [
            ("StoryData", id),
            (nil, id)
        ]

        for (directory, resource) in searchPaths {
            let path: String?
            if let dir = directory {
                path = Bundle.main.path(forResource: resource, ofType: "json", inDirectory: dir)
            } else {
                path = Bundle.main.path(forResource: resource, ofType: "json")
            }

            guard let filePath = path,
                  let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { continue }

            do {
                let chapter = try JSONDecoder().decode(UnifiedChapterFile.self, from: data)
                for node in chapter.nodes {
                    cache.nodes[node.nodeId] = node
                }
                AppLog.loader.info("✅ unified '\(id, privacy: .public)' loaded: \(chapter.nodes.count) nodes")
                return true
            } catch {
                AppLog.loader.error("❌ unified '\(id, privacy: .public)' decode error: \(error.localizedDescription, privacy: .public)")
            }
        }

        AppLog.loader.warning("⚠️ unified chapter file '\(id, privacy: .public).json' not found in bundle")
        return false
    }

    // MARK: - Individual File Fallback (Substories 등)

    private static func decodeNode(from url: URL) -> VNNode? {
        do {
            let data = try Data(contentsOf: url)
            AppLog.loader.debug("📦 data bytes: \(data.count)")
            let node = try JSONDecoder().decode(VNNode.self, from: data)
            AppLog.loader.info("✅ decoded node_id=\(node.nodeId, privacy: .public) type=\(node.type.rawValue, privacy: .public) next=\(node.primaryNextNodeId ?? "nil", privacy: .public)")
            return node
        } catch {
            AppLog.loader.error("❌ decode error for \(url.lastPathComponent): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // Substories 개별 파일 탐색 경로 (메인 챕터 폴더 제거)
    private static let searchDirectories = [
        "StoryData",
        "StoryData/Substories/Seoyena",
        "StoryData/Substories/Alicegang",
        "StoryData/Substories/Anipark",
        "StoryData/Substories/Jinbaekho",
        "StoryData/Substories/Jubulsu",
        "Resources/Story",
        "Story"
    ]

    private static func nodeURL(for name: String) -> URL? {
        if let path = Bundle.main.path(forResource: name, ofType: "json") {
            return URL(fileURLWithPath: path)
        }

        for dir in searchDirectories {
            if let path = Bundle.main.path(forResource: name, ofType: "json", inDirectory: dir) {
                AppLog.loader.debug("➡️ found \(name).json in \(dir)")
                return URL(fileURLWithPath: path)
            }
        }

        if let url = searchInStoryDataSubdirectories(name: name) {
            return url
        }

        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            AppLog.loader.debug("➡️ found \(name).json via URL search")
            return url
        }

        return nil
    }

    private static func searchInStoryDataSubdirectories(name: String) -> URL? {
        guard let baseURL = Bundle.main.url(forResource: "StoryData", withExtension: nil) else {
            return nil
        }

        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: baseURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return nil }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "json" &&
               fileURL.deletingPathExtension().lastPathComponent == name {
                AppLog.loader.debug("➡️ found \(name).json via recursive StoryData search")
                return fileURL
            }
        }

        return nil
    }
}

// MARK: - SFX

final class SFXManager {
    static let shared = SFXManager()
    private init() {}

    private var players: [String: [AVAudioPlayer]] = [:]
    private let maxPool = 6

    private func key(_ name: String, _ ext: String) -> String { "\(name).\(ext)" }

    func preload(name: String, ext: String) {
        let full = key(name, ext)
        guard players[full] == nil else { return }
        var pool: [AVAudioPlayer] = []
        for _ in 0..<maxPool {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                if let p = try? AVAudioPlayer(contentsOf: url) {
                    p.prepareToPlay()
                    pool.append(p)
                }
            }
        }
        players[full] = pool
        AppLog.sfx.info("🔈 preload \(full) count=\(pool.count)")
    }

    func play(_ filename: String) {
        let comps = filename.split(separator: ".")
        guard comps.count == 2 else {
            AppLog.sfx.error("❌ invalid sfx filename \(filename)")
            return
        }
        let name = String(comps[0]), ext = String(comps[1])
        let full = key(name, ext)
        if players[full] == nil { preload(name: name, ext: ext) }
        guard var pool = players[full], !pool.isEmpty else {
            AppLog.sfx.error("❌ no player pool for \(full)")
            return
        }
        let idx = pool.firstIndex(where: { !$0.isPlaying }) ?? 0
        pool[idx].currentTime = 0
        pool[idx].play()
        players[full] = pool
        AppLog.sfx.debug("▶️ play \(full) using idx=\(idx)")
    }
}

// MARK: - Typewriter

final class TypewriterEngine: ObservableObject {
    @Published var displayed: AttributedString = ""
    @Published var isCompleted: Bool = false

    private var speedSlow: Double = 0.09
    private var speedNormal: Double = 0.06
    private var speedFast: Double = 0.03
    private var speedTypewriter: Double = 0.15
    private var currentSpeed: Double = 0.06

    private var fullText: String = ""
    private var timer: DispatchSourceTimer?
    private var cursor: Int = 0
    private var skipMode: Bool = false
    private var lastEmit: Double = 0

    var blipKey: String = "sfx-blipmale.wav"
    private var blipEveryOther = true
    private var oddToggle = false

    func configure(text: String, blipKey: String?) {
        stop()
        self.fullText = text
        self.blipKey = blipKey ?? "sfx-blipmale.wav"
        self.displayed = ""
        self.isCompleted = false
        self.cursor = 0
        self.currentSpeed = speedNormal
        self.skipMode = false
        self.oddToggle = false
        AppLog.type.info("📝 configure len=\(text.count) blip=\(self.blipKey, privacy: .public)")
    }

    func start() {
        SFXManager.shared.preload(name: "sfx-blipmale", ext: "wav")
        SFXManager.shared.preload(name: "sfx-blipfemale", ext: "wav")
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: .milliseconds(8))
        t.setEventHandler { [weak self] in self?.tick() }
        timer = t
        t.resume()
        AppLog.type.info("⏱️ start typewriter")
    }

    func stop() {
        timer?.cancel()
        timer = nil
        AppLog.type.info("⏹️ stop typewriter")
    }

    func skipOrNext() {
        if !isCompleted { skipMode = true }
    }

    private func tick() {
        guard cursor <= fullText.count, !isCompleted else { return }
        if skipMode {
            while cursor < fullText.count { _ = appendNextChar(playAudio: false) }
            isCompleted = true
            stop()
            AppLog.type.info("✅ line complete (skip)")
            return
        }
        let now = CACurrentMediaTime()
        if now - lastEmit >= currentSpeed {
            _ = appendNextChar(playAudio: true)
            lastEmit = now
            if cursor >= fullText.count {
                isCompleted = true
                stop()
                AppLog.type.info("✅ line complete (len=\(self.fullText.count))")
            }
        }
    }

    private func appendNextChar(playAudio: Bool) -> Bool {
        guard cursor < fullText.count else { return false }
        let idx = fullText.index(fullText.startIndex, offsetBy: cursor)
        let ch = fullText[idx]

        if ch == "<" {
            let rest = String(fullText[idx...])
            if rest.hasPrefix("<s>") { currentSpeed = speedSlow;  cursor += 3; AppLog.type.debug("⏪ <s>"); return true }
            if rest.hasPrefix("<n>") { currentSpeed = speedNormal;cursor += 3; AppLog.type.debug("⏩ <n>"); return true }
            if rest.hasPrefix("<f>") { currentSpeed = speedFast;  cursor += 3; AppLog.type.debug("⚡️ <f>"); return true }
            if rest.hasPrefix("<t>") { currentSpeed = speedTypewriter; cursor += 3; AppLog.type.debug("⌨️ <t>"); return true }
        }
        if ch == "_" { cursor += 1; AppLog.type.debug("⏸️ _"); return true }
        if ch == "\\" {
            cursor += 1
            displayed.append(AttributedString("\n"))
            AppLog.type.debug("↩︎ newline")
            return true
        }

        displayed.append(AttributedString(String(ch)))
        if playAudio,
           ch != " " && ch != "\n" && ch != "\t" &&
           ch != "<" && ch != "_" && ch != "\\" && ch != "\"" {
            oddToggle.toggle()
            if !blipEveryOther || oddToggle {
                SFXManager.shared.play(blipKey)
            }
        }
        cursor += 1
        if cursor % 10 == 0 { AppLog.type.debug("… cursor=\(self.cursor)") }
        return false
    }
}

// MARK: - Character → Blip

enum CharacterGender: String, Codable {
    case male
    case female
    case neutral
    case typer
}

struct CharacterProfile: Codable {
    let gender: CharacterGender?
    let blip: String?
}

private func loadCharacterMap() -> [String: CharacterProfile] {
    let candidates: [(directory: String?, resource: String)] = [
        ("StoryData/Characters", "characters"),
        ("StoryData/Characters", "Characters"),
        ("StoryData", "characters"),
        ("StoryData", "Characters"),
        ("Resources/Story/Characters", "characters"),
        ("Resources/Story/Characters", "Characters"),
        ("Resources/StoryData/Characters", "characters"),
        ("Resources/StoryData/Characters", "Characters"),
        (nil, "characters"),
        (nil, "Characters")
    ]

    for candidate in candidates {
        if let path = Bundle.main.path(
            forResource: candidate.resource,
            ofType: "json",
            inDirectory: candidate.directory
        ), let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let dict = try? JSONDecoder().decode([String: CharacterProfile].self, from: data) {
            AppLog.loader.info("👥 loaded characters.json from \(candidate.directory ?? "bundle root")")
            return dict
        }
    }

    AppLog.loader.error("👥 characters.json not found; using defaults")
    return [:]
}

enum CharacterBlip {
    static let map: [String: CharacterProfile] = loadCharacterMap()

    static func blipKey(for id: String?) -> String? {
        guard let id, !id.isEmpty else { return "sfx-blipmale.wav" }

        let normalized = id.trimmingCharacters(in: .whitespacesAndNewlines)
        if let explicit = map[normalized]?.blip, !explicit.isEmpty { return explicit }

        // NPC는 자동으로 타자기 사운드를 사용
        if normalized.caseInsensitiveCompare("npc") == .orderedSame {
            return "sfx-typwriter.wav"
        }

        switch map[normalized]?.gender ?? .male {
        case .male:    return "sfx-blipmale.wav"
        case .female:  return "sfx-blipfemale.wav"
        case .neutral: return ""
        case .typer:   return "sfx-typwriter.wav" // 타자기 효과음
        }
    }
}

// MARK: - Story Library (허브 메타)

struct MerchantEpisodeMeta: Codable, Identifiable, Hashable {
    var id: String { episode_id }
    let episode_id: String
    let merchant_id: String
    let title: String
    let entry_node: String
    let locked: Bool?
}

enum StoryLibrary {
    static func loadMerchantEpisodes(merchantIds: [String]) -> [MerchantEpisodeMeta] {
        var all: [MerchantEpisodeMeta] = []
        for mid in merchantIds {
            let directory = "Resources/Story/Merchant/\(mid)"
            let candidateNames = ["episodes_\(mid)", "episodes"]

            let data: Data? = candidateNames.compactMap { name in
                guard let path = Bundle.main.path(forResource: name, ofType: "json", inDirectory: directory) else {
                    return nil
                }
                return try? Data(contentsOf: URL(fileURLWithPath: path))
            }.first

            guard let fileData = data,
                  let eps = try? JSONDecoder().decode([MerchantEpisodeMeta].self, from: fileData) else {
                continue
            }

            let fixed = eps.map { e in
                if e.merchant_id.isEmpty {
                    return MerchantEpisodeMeta(episode_id: e.episode_id, merchant_id: mid, title: e.title, entry_node: e.entry_node, locked: e.locked)
                } else { return e }
            }
            all.append(contentsOf: fixed)
        }
        return all
    }
}
