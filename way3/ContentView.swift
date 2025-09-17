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
    @StateObject private var player = Player.createDefault()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                LoginView(showLoginView: .constant(true))
                    .environmentObject(authManager)
            } else {
                MainTabView(selectedTab: $selectedTab)
                    .environmentObject(authManager)
                    .environmentObject(locationManager)
                    .environmentObject(player)
            }
        }
        .defaultChosunFont()
        .onAppear {
            // ⚠️ 자동 로그인 금지 - 항상 로그인 화면부터 시작
            // FontSystemManager.setupAppFonts() // 폰트 시스템 설정

            // Chosun 폰트 사용 가능 여부 확인
            if !FontSystemManager.validateChosunFont() {
                print("⚠️ Chosun 폰트가 번들에 없습니다. Info.plist에 폰트를 추가해주세요.")
            }
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(LocationManager())
}
