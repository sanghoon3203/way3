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
        VStack(spacing: 0) {
            // Main Content Area
            TabView(selection: $selectedTab) {
                // 📍 맵 (첫 번째 탭)
                MapView()
                    .tabItem {
                        Image(systemName: "map.fill")
                        Text("맵")
                    }
                    .tag(0)

                // 🎒 인벤토리 (두 번째 탭)
                InventoryView()
                    .tabItem {
                        Image(systemName: "backpack.fill")
                        Text("인벤토리")
                    }
                    .tag(1)

                // ⚔️ 퀘스트 (세 번째 탭)
                QuestView()
                    .tabItem {
                        Image(systemName: "flag.fill")
                        Text("퀘스트")
                    }
                    .tag(2)

                // 🏪 상점 (네 번째 탭) - 경매장과 상점 통합
                ShopView()
                    .tabItem {
                        Image(systemName: "storefront.fill")
                        Text("상점")
                    }
                    .tag(3)

                // 👤 프로필 (다섯 번째 탭)
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("프로필")
                    }
                    .tag(4)
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            setupEnhancedTabBarAppearance()
            FontSystemManager.setupAppFonts()
        }
    }
    
    private func setupEnhancedTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        // 사이버펑크 + 전통한국 테마: 어두운 배경
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.9)

        // 네온 효과를 위한 그림자와 테두리
        appearance.shadowColor = UIColor.cyan.withAlphaComponent(0.3)
        appearance.shadowImage = UIImage()

        // Normal tab styling with cyberpunk theme and ChosunCentennial_otf font
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray4
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray4,
            .font: UIFont(name: "ChosunCentennial_otf", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .regular)
        ]

        // Selected tab styling with neon cyan color and ChosunCentennial_otf font
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.cyan
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.cyan,
            .font: UIFont(name: "ChosunCentennial_otf", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        ]

        // Apply appearance with top margin consideration
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Additional tab bar configuration for spacing
        if let tabBar = UIApplication.shared.windows.first?.rootViewController?.tabBarController?.tabBar {
            tabBar.frame.origin.y -= 40  // Top margin: 40pt as requested
        }
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

// MARK: - 임시 뷰들 제거됨 (별도 파일로 분리 완료)

// ShopView는 별도 파일로 이동됩니다

// ProfileView는 별도 파일로 이동됩니다