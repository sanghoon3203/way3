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

struct VNNode: Decodable {
    let node_id: String
    let background_image: String?
    let character_id: String?
    let character_sprite: String?
    let dialogue_text: String
    let dialogue_sound_id: String?   // ← (미사용/역호환)
    let sound_effect: String?        // ← (미사용/역호환)
    let next_node_id: String?
}

// MARK: - Loader

enum VNLoader {
    /// Flexible story node loader - searches multiple locations
    static func loadNode(id: String) -> VNNode? {
        let name = id.replacingOccurrences(of: ".json", with: "")

        // Strategy 1: Try direct bundle lookup (no subdirectory)
        if let path = Bundle.main.path(forResource: name, ofType: "json") {
            return decodeNode(from: path, filename: "\(name).json")
        }

        // Strategy 2: Try common subdirectories
        let searchDirs = ["StoryData", "Resources/Story", "Resources/StoryData", "Story"]
        for dir in searchDirs {
            if let path = Bundle.main.path(forResource: name, ofType: "json", inDirectory: dir) {
                AppLog.loader.debug("➡️ found \(name).json in \(dir)")
                return decodeNode(from: path, filename: "\(name).json")
            }
        }

        // Strategy 3: Try URL-based search in all bundle resources
        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            AppLog.loader.debug("➡️ found \(name).json via URL search")
            return decodeNode(from: url.path, filename: "\(name).json")
        }

        AppLog.loader.error("❌ file not found: \(name).json in bundle")
        AppLog.loader.error("   searched: main bundle + subdirs: \(searchDirs.joined(separator: ", "))")
        return nil
    }

    private static func decodeNode(from path: String, filename: String) -> VNNode? {
        do {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            AppLog.loader.debug("📦 data bytes: \(data.count)")
            let node = try JSONDecoder().decode(VNNode.self, from: data)
            AppLog.loader.info("✅ decoded node_id=\(node.node_id, privacy: .public) next=\(node.next_node_id ?? "nil", privacy: .public)")
            return node
        } catch {
            AppLog.loader.error("❌ decode error for \(filename): \(error.localizedDescription, privacy: .public)")
            return nil
        }
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

enum CharacterGender: String, Codable { case male, female, neutral }

struct CharacterProfile: Codable {
    let gender: CharacterGender?
    let blip: String?
}

private func loadCharacterMap() -> [String: CharacterProfile] {
    let searchDirs = [
        "StoryData/Characters",
        "Resources/Story/Characters",
        "Resources/StoryData/Characters"
    ]
    for dir in searchDirs {
        if let path = Bundle.main.path(forResource: "characters", ofType: "json", inDirectory: dir),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let dict = try? JSONDecoder().decode([String: CharacterProfile].self, from: data) {
            AppLog.loader.info("👥 loaded characters.json from \(dir)")
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
        if let explicit = map[id]?.blip, !explicit.isEmpty { return explicit }
        switch map[id]?.gender ?? .male {
        case .male:    return "sfx-blipmale.wav"
        case .female:  return "sfx-blipfemale.wav"
        case .neutral: return "" // 무음
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
            if let path = Bundle.main.path(forResource: "episodes", ofType: "json", inDirectory: "Resources/Story/Merchant/\(mid)"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let eps = try? JSONDecoder().decode([MerchantEpisodeMeta].self, from: data) {
                let fixed = eps.map { e in
                    if e.merchant_id.isEmpty {
                        return MerchantEpisodeMeta(episode_id: e.episode_id, merchant_id: mid, title: e.title, entry_node: e.entry_node, locked: e.locked)
                    } else { return e }
                }
                all.append(contentsOf: fixed)
            }
        }
        return all
    }
}
