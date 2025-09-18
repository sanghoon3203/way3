//
//  PlayerDataManager.swift
//  way3 - Way Trading Game
//
//  로컬 파일 저장 시스템 - 플레이어 데이터 영속성 관리
//  앱 종료/강제종료 시에도 게임 진행도 유지
//

import Foundation
import SwiftUI

// MARK: - Player Data Manager
@MainActor
class PlayerDataManager: ObservableObject {
    static let shared = PlayerDataManager()

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var lastSaveTime: Date?
    @Published var lastError: DataManagerError?

    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // 저장 위치 설정
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var playerDataURL: URL {
        documentsURL.appendingPathComponent("player_data.json")
    }

    // 백업 파일 관리 (최대 3개)
    private func backupURL(index: Int) -> URL {
        documentsURL.appendingPathComponent("player_data_backup_\(index).json")
    }

    // 자동 저장 타이머
    private var autoSaveTimer: Timer?
    private let autoSaveInterval: TimeInterval = 30.0 // 30초

    // MARK: - Initialization
    private init() {
        setupEncoder()
        setupErrorHandling()

        #if DEBUG
        print("📁 PlayerDataManager initialized")
        print("📁 Documents path: \(documentsURL.path)")
        #endif
    }

    private func setupEncoder() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        decoder.dateDecodingStrategy = .iso8601
    }

    private func setupErrorHandling() {
        // 에러 상태 5초 후 자동 클리어
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            if self?.lastError != nil {
                self?.lastError = nil
            }
        }
    }

    deinit {
        stopAutoSave()
    }
}

// MARK: - Core Save/Load Methods
extension PlayerDataManager {

    // 플레이어 데이터 저장
    func savePlayer(_ player: Player) async -> Bool {
        await MainActor.run { isLoading = true }

        do {
            let saveData = PlayerSaveData(
                version: "1.0.0",
                savedAt: Date(),
                playerData: player
            )

            let data = try encoder.encode(saveData)

            // 백업 생성 (기존 파일이 있다면)
            await createBackupIfNeeded()

            // 메인 파일 저장
            try data.write(to: playerDataURL, options: .atomic)

            await MainActor.run {
                self.lastSaveTime = Date()
                self.lastError = nil
                self.isLoading = false
            }

            #if DEBUG
            print("💾 Player data saved successfully at \(Date())")
            print("📊 Data size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
            #endif

            return true

        } catch {
            await MainActor.run {
                self.lastError = .saveFailed(error.localizedDescription)
                self.isLoading = false
            }

            #if DEBUG
            print("❌ Save failed: \(error)")
            #endif

            return false
        }
    }

    // 플레이어 데이터 로드
    func loadPlayer() async -> Player? {
        await MainActor.run { isLoading = true }

        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }

        // 메인 파일 먼저 시도
        if let player = await loadFromFile(playerDataURL) {
            await MainActor.run { self.lastError = nil }
            return player
        }

        // 백업 파일들 순서대로 시도
        for i in 1...3 {
            if let player = await loadFromFile(backupURL(index: i)) {
                await MainActor.run {
                    self.lastError = .recoveredFromBackup("백업 파일 \(i)에서 복구됨")
                }

                #if DEBUG
                print("🔄 Recovered from backup file \(i)")
                #endif

                return player
            }
        }

        await MainActor.run {
            self.lastError = .loadFailed("저장된 플레이어 데이터를 찾을 수 없습니다")
        }

        return nil
    }

    private func loadFromFile(_ url: URL) async -> Player? {
        do {
            let data = try Data(contentsOf: url)
            let saveData = try decoder.decode(PlayerSaveData.self, from: data)

            #if DEBUG
            print("📂 Loaded player data from: \(url.lastPathComponent)")
            print("📅 Save date: \(saveData.savedAt)")
            print("🏷️ Version: \(saveData.version)")
            #endif

            return saveData.playerData

        } catch {
            #if DEBUG
            print("⚠️ Failed to load from \(url.lastPathComponent): \(error)")
            #endif
            return nil
        }
    }
}

// MARK: - Backup Management
extension PlayerDataManager {

    private func createBackupIfNeeded() async {
        guard fileManager.fileExists(atPath: playerDataURL.path) else { return }

        do {
            // 백업 파일들을 한 칸씩 밀기 (3 -> 삭제, 2 -> 3, 1 -> 2)
            let backup3 = backupURL(index: 3)
            let backup2 = backupURL(index: 2)
            let backup1 = backupURL(index: 1)

            // 백업 3이 있다면 삭제
            if fileManager.fileExists(atPath: backup3.path) {
                try fileManager.removeItem(at: backup3)
            }

            // 백업 2 -> 백업 3으로 이동
            if fileManager.fileExists(atPath: backup2.path) {
                try fileManager.moveItem(at: backup2, to: backup3)
            }

            // 백업 1 -> 백업 2로 이동
            if fileManager.fileExists(atPath: backup1.path) {
                try fileManager.moveItem(at: backup1, to: backup2)
            }

            // 현재 파일 -> 백업 1로 복사
            try fileManager.copyItem(at: playerDataURL, to: backup1)

            #if DEBUG
            print("📋 Backup created successfully")
            #endif

        } catch {
            #if DEBUG
            print("⚠️ Backup creation failed: \(error)")
            #endif
        }
    }

    func getBackupInfo() -> [BackupInfo] {
        var backups: [BackupInfo] = []

        for i in 1...3 {
            let url = backupURL(index: i)
            if fileManager.fileExists(atPath: url.path) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: url.path)
                    let creationDate = attributes[.creationDate] as? Date ?? Date()
                    let fileSize = attributes[.size] as? Int64 ?? 0

                    backups.append(BackupInfo(
                        index: i,
                        creationDate: creationDate,
                        fileSize: fileSize,
                        url: url
                    ))
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to get backup \(i) info: \(error)")
                    #endif
                }
            }
        }

        return backups.sorted { $0.creationDate > $1.creationDate }
    }
}

// MARK: - Auto Save System
extension PlayerDataManager {

    func startAutoSave(for player: Player) {
        stopAutoSave() // 기존 타이머 정리

        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.savePlayer(player)
            }
        }

        #if DEBUG
        print("⏰ Auto-save started (interval: \(autoSaveInterval)s)")
        #endif
    }

    nonisolated func stopAutoSave() {
        Task { @MainActor in
            autoSaveTimer?.invalidate()
            autoSaveTimer = nil

            #if DEBUG
            print("⏰ Auto-save stopped")
            #endif
        }
    }
}

// MARK: - Utility Methods
extension PlayerDataManager {

    // 저장된 데이터 존재 확인
    func hasSavedData() -> Bool {
        return fileManager.fileExists(atPath: playerDataURL.path)
    }

    // 저장된 데이터 크기 확인
    func getSavedDataSize() -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: playerDataURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    // 저장된 데이터 삭제 (신규 게임 시작)
    func clearSavedData() async -> Bool {
        do {
            // 메인 파일 삭제
            if fileManager.fileExists(atPath: playerDataURL.path) {
                try fileManager.removeItem(at: playerDataURL)
            }

            // 백업 파일들 삭제
            for i in 1...3 {
                let backupURL = backupURL(index: i)
                if fileManager.fileExists(atPath: backupURL.path) {
                    try fileManager.removeItem(at: backupURL)
                }
            }

            await MainActor.run {
                self.lastSaveTime = nil
                self.lastError = nil
            }

            #if DEBUG
            print("🗑️ All saved data cleared")
            #endif

            return true
        } catch {
            await MainActor.run {
                self.lastError = .deleteFailed(error.localizedDescription)
            }
            return false
        }
    }
}

// MARK: - Data Models
struct PlayerSaveData: Codable {
    let version: String
    let savedAt: Date
    let playerData: Player
}

struct BackupInfo {
    let index: Int
    let creationDate: Date
    let fileSize: Int64
    let url: URL

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}

// MARK: - Error Types
enum DataManagerError: LocalizedError {
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case recoveredFromBackup(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "저장 실패: \(message)"
        case .loadFailed(let message):
            return "로드 실패: \(message)"
        case .deleteFailed(let message):
            return "삭제 실패: \(message)"
        case .recoveredFromBackup(let message):
            return "복구됨: \(message)"
        }
    }

    var isError: Bool {
        switch self {
        case .recoveredFromBackup:
            return false
        default:
            return true
        }
    }
}