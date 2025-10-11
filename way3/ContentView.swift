//
//  ContentView.swift
//  way3 - Way Trading Game 메인 화면
//
//  Created by 김상훈 on 9/12/25.
//  복원된 프로젝트 - 메인 게임 인터페이스
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var gameManager = GameManager.shared
    @StateObject private var player = Player.createDefault()
    @State private var showStartView = true

    // 로컬 저장 시스템
    @StateObject private var dataManager = PlayerDataManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var isDataLoaded = false

    var body: some View {
        Group {
            if showStartView {
                StartView(isPresented: $showStartView)
            } else if !authManager.isAuthenticated {
                LoginView(showLoginView: .constant(true))
                    .environmentObject(authManager)
            } else {
                MainTabView(
                    selectedTab: Binding(
                        get: { gameManager.activeMainTab },
                        set: { gameManager.activeMainTab = $0 }
                    )
                )
                    .environmentObject(authManager)
                    .environmentObject(gameManager)
                    .environmentObject(locationManager)
                    .environmentObject(player)
            }
        }
        .defaultChosunFont()
        .onAppear {
            setupApp()
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhaseChange(phase)
        }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                loadPlayerData()
                // 게임 데이터 초기화
                Task {
                    await gameManager.loadPersonalItemsData()
                }
            } else {
                player.stopAutoSave()
            }
        }
    }
}

// MARK: - Data Management Methods
extension ContentView {

    private func setupApp() {
        // 폰트 시스템 검증
        if !FontSystemManager.validateChosunFont() {
            print("⚠️ Chosun 폰트가 번들에 없습니다. Info.plist에 폰트를 추가해주세요.")
        }

        #if DEBUG
        print("📱 앱 시작됨")
        print("💾 저장된 데이터 존재: \(Player.hasSavedData())")
        #endif
    }

    private func loadPlayerData() {
        guard !isDataLoaded else { return }

        Task { @MainActor in
            #if DEBUG
            print("📂 플레이어 데이터 로드 시작...")
            #endif

            if let savedPlayer = await Player.load() {
                // 저장된 데이터로 현재 플레이어 업데이트
                updatePlayerWith(savedPlayer)
                player.startAutoSave()

                #if DEBUG
                print("✅ 플레이어 데이터 로드 완료")
                print("👤 플레이어: \(player.name), 레벨: \(player.level), 돈: \(player.money)")
                #endif
            } else {
                // 저장된 데이터가 없으면 새 게임으로 시작
                player.startAutoSave()

                #if DEBUG
                print("🆕 새 게임으로 시작")
                #endif
            }

            isDataLoaded = true
        }
    }

    private func updatePlayerWith(_ savedPlayer: Player) {
        // 저장된 플레이어 데이터를 현재 플레이어에 복사
        player.core = savedPlayer.core
        player.stats = savedPlayer.stats
        player.inventory = savedPlayer.inventory
        player.relationships = savedPlayer.relationships
        player.achievements = savedPlayer.achievements

        // 게임 상태 정보도 복사
        player.currentLocation = savedPlayer.currentLocation
        player.currentDistrict = savedPlayer.currentDistrict
        player.gameMode = savedPlayer.gameMode
        player.lastSaveTime = savedPlayer.lastSaveTime
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            #if DEBUG
            print("🟢 앱 활성화됨")
            #endif
            // 앱이 활성화될 때 특별한 동작 없음 (이미 로드됨)

        case .inactive:
            #if DEBUG
            print("🟡 앱 비활성화됨")
            #endif
            // 비활성화 시 저장 (홈 버튼, 멀티태스킹 등)
            savePlayerData()

        case .background:
            #if DEBUG
            print("⚫ 앱 백그라운드로 이동")
            #endif
            // 백그라운드 진입 시 저장
            savePlayerData()

        @unknown default:
            break
        }
    }

    private func savePlayerData() {
        guard authManager.isAuthenticated && isDataLoaded else { return }

        Task { @MainActor in
            let success = await player.save()
            #if DEBUG
            print("💾 앱 생명주기 저장: \(success ? "성공" : "실패")")
            #endif
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(LocationManager())
}
