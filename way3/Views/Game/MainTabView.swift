//
//  MainTabView.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  메인 탭 뷰 - Pokemon GO 스타일 네비게이션
//

import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showProfile = false
    @State private var showSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 메인 맵
            MapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("맵")
                        .font(.custom("ChosunCentennial", size: 12))
                }
                .tag(0)
            
            // 인벤토리
            InventoryView()
                .tabItem {
                    Image(systemName: "backpack.fill")
                    Text("인벤토리")
                        .font(.custom("ChosunCentennial", size: 12))
                }
                .tag(1)
            
            // 경매장
            AuctionHallView()
                .tabItem {
                    Image(systemName: "hammer.fill")
                    Text("경매장")
                        .font(.custom("ChosunCentennial", size: 12))
                }
                .tag(2)
            
            // 상점
            ShopView()
                .tabItem {
                    Image(systemName: "storefront.fill")
                    Text("상점")
                        .font(.custom("ChosunCentennial", size: 12))
                }
                .tag(3)
            
            // 프로필
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("프로필")
                        .font(.custom("ChosunCentennial", size: 12))
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // 선택된 탭 스타일
        appearance.selectionIndicatorTintColor = UIColor.systemBlue
        
        // 일반 탭 스타일
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont(name: "ChosunCentennial", size: 12) ?? UIFont.systemFont(ofSize: 12)
        ]
        
        // 선택된 탭 스타일
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont(name: "ChosunCentennial", size: 12) ?? UIFont.systemFont(ofSize: 12)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - 인벤토리 뷰
// InventoryView 정의는 Views/InventoryView.swift에 있습니다

// MARK: - 인벤토리 아이템 카드
// InventoryItemCard 정의는 Components/InventoryItemCard.swift에 있습니다

// MARK: - 아이템 상세 뷰
struct ItemDetailView: View {
    let item: TradeItem
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 아이템 이미지
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(item.grade.color.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 60))
                        .foregroundColor(item.grade.color)
                }
                
                VStack(spacing: 12) {
                    Text(item.name)
                        .font(.custom("ChosunCentennial", size: 28))
                        .fontWeight(.bold)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("등급")
                                .font(.custom("ChosunCentennial", size: 14))
                                .foregroundColor(.secondary)
                            Text(item.grade.displayName)
                                .font(.custom("ChosunCentennial", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(item.grade.color)
                        }
                        
                        VStack {
                            Text("카테고리")
                                .font(.custom("ChosunCentennial", size: 14))
                                .foregroundColor(.secondary)
                            Text(item.category)
                                .font(.custom("ChosunCentennial", size: 16))
                                .fontWeight(.semibold)
                        }
                        
                        VStack {
                            Text("보유 수량")
                                .font(.custom("ChosunCentennial", size: 14))
                                .foregroundColor(.secondary)
                            Text("\(item.quantity)개")
                                .font(.custom("ChosunCentennial", size: 16))
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Divider()
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("현재 가치")
                                .font(.custom("ChosunCentennial", size: 16))
                            Spacer()
                            Text("₩\(item.currentPrice)")
                                .font(.custom("ChosunCentennial", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("총 가치")
                                .font(.custom("ChosunCentennial", size: 16))
                            Spacer()
                            Text("₩\(item.currentPrice * item.quantity)")
                                .font(.custom("ChosunCentennial", size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // 액션 버튼들
                VStack(spacing: 12) {
                    Button(action: {
                        // 판매하기
                    }) {
                        Text("판매하기")
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.orange)
                            )
                    }
                    
                    Button(action: {
                        // 사용하기 (소모품인 경우)
                    }) {
                        Text("사용하기")
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                }
            }
            .padding()
            .navigationTitle("아이템 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        isPresented = false
                    }
                    .font(.custom("ChosunCentennial", size: 16))
                }
            }
        }
    }
}

// MARK: - 임시 뷰들 (나중에 별도 파일로 분리)
struct QuestView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("퀘스트 시스템")
                    .font(.custom("ChosunCentennial", size: 24))
                    .fontWeight(.bold)
                Text("곧 구현 예정입니다!")
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.secondary)
            }
            .navigationTitle("퀘스트")
        }
    }
}

struct ShopView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("글로벌 상점")
                    .font(.custom("ChosunCentennial", size: 24))
                    .fontWeight(.bold)
                Text("곧 구현 예정입니다!")
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.secondary)
            }
            .navigationTitle("상점")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 프로필 이미지
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                if let player = authManager.currentPlayer {
                    VStack(spacing: 8) {
                        Text(player.name)
                            .font(.custom("ChosunCentennial", size: 24))
                            .fontWeight(.bold)
                        
                        Text("Lv. \(player.level)")
                            .font(.custom("ChosunCentennial", size: 18))
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                        
                        Text("₩\(Int(player.money))")
                            .font(.custom("ChosunCentennial", size: 20))
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await authManager.logout()
                    }
                }) {
                    Text("로그아웃")
                        .font(.custom("ChosunCentennial", size: 18))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.red, lineWidth: 2)
                        )
                }
            }
            .padding()
            .navigationTitle("프로필")
        }
    }
}