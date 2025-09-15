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
        .onAppear {
            // 앱 시작시 저장된 인증 정보 자동 로드
            authManager.loadStoredCredentials()
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(LocationManager())
}
