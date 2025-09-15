//
//  PokemonGOMapView.swift
//  way3 - Pokemon GO Style Enhanced Map Interface
//
//  Pokemon GO 스타일의 위치기반 거래 게임 맵 인터페이스
//

import SwiftUI
@_spi(Experimental) import MapboxMaps
import CoreLocation

struct PokemonGOMapView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var player: Player
    @StateObject private var districtManager = DistrictManager.shared
    @StateObject private var socketManager = SocketManager.shared
    
    // MARK: - State Properties
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        zoom: 15,
        bearing: 0,
        pitch: 60
    )
    
    @State private var merchants: [EnhancedMerchant] = []
    @State private var selectedMerchant: EnhancedMerchant?
    @State private var showMerchantDetail = false
    @State private var showNearbyPlayers = false
    @State private var showTradeActivity = false
    @State private var showDistrictInfo = false
    
    // MARK: - Location Tracking
    @State private var lastLocationUpdate = Date()
    @State private var isLocationTracking = true
    
    var body: some View {
        ZStack {
            // 메인 맵
            Map(viewport: $viewport) {
                // 플레이어 위치 표시 (Pokemon GO 스타일 펄스)
                Puck2D(bearing: .heading)
                    .showsAccuracyRing(false)
                    .pulsing(.default)
                    .puckBearingEnabled(true)
                
                // 구역 경계선 표시
                ForEvery(districtManager.getDistrictBoundaries()) { boundary in
                    boundary
                }
                
                // 상인 마커 (Pokemon GO 스타일 애니메이션)
                ForEvery(merchants) { merchant in
                    MapViewAnnotation(coordinate: merchant.location) {
                        EnhancedMerchantPin(
                            merchant: merchant,
                            playerLocation: locationManager.currentLocation,
                            district: districtManager.currentDistrict
                        )
                        .onTapGesture {
                            handleMerchantTap(merchant)
                        }
                    }
                    .allowOverlap(true)
                }
                
                // 근처 플레이어 표시
                ForEvery(socketManager.nearbyPlayers) { nearbyPlayer in
                    MapViewAnnotation(coordinate: nearbyPlayer.location) {
                        NearbyPlayerPin(player: nearbyPlayer)
                            .onTapGesture {
                                // 플레이어 정보 표시 또는 거래 제안
                            }
                    }
                    .allowOverlap(true)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .onMapTapGesture { coordinate in
                // 맵 탭 시 선택 해제
                selectedMerchant = nil
            }
            
            // Pokemon GO 스타일 UI 오버레이
            pokemonGOStyleOverlay
            
            // 실시간 활동 피드
            if !socketManager.recentTradeActivity.isEmpty {
                tradeActivityFeed
            }
            
            // 시장 가격 업데이트 알림
            if !socketManager.marketPriceUpdates.isEmpty {
                priceUpdateNotifications
            }
        }
        .sheet(isPresented: $showMerchantDetail) {
            if let merchant = selectedMerchant {
                EnhancedMerchantDetailView(merchant: merchant)
                    .environmentObject(networkManager)
                    .environmentObject(socketManager)
            }
        }
        .sheet(isPresented: $showNearbyPlayers) {
            NearbyPlayersView()
                .environmentObject(socketManager)
        }
        .sheet(isPresented: $showTradeActivity) {
            TradeActivityView()
                .environmentObject(socketManager)
        }
        .onAppear {
            setupMapView()
        }
        .onReceive(locationManager.$currentLocation) { location in
            if let location = location {
                handleLocationUpdate(location)
            }
        }
    }
    
    // MARK: - Pokemon GO Style Overlay
    private var pokemonGOStyleOverlay: some View {
        VStack {
            // 상단 UI
            HStack {
                // 현재 구역 정보
                districtInfoCard
                
                Spacer()
                
                // 플레이어 정보
                playerInfoCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            Spacer()
            
            // 하단 UI
            VStack(spacing: 12) {
                // 근처 상인 표시기
                nearbyMerchantsIndicator
                
                // 액션 버튼들
                HStack(spacing: 20) {
                    // 근처 플레이어
                    actionButton(
                        icon: "person.2.fill",
                        count: socketManager.nearbyPlayers.count,
                        color: .gameBlue
                    ) {
                        showNearbyPlayers = true
                    }
                    
                    // 거래 활동
                    actionButton(
                        icon: "chart.line.uptrend.xyaxis",
                        count: socketManager.recentTradeActivity.count,
                        color: .gameGreen
                    ) {
                        showTradeActivity = true
                    }
                    
                    // 중앙 위치 버튼
                    Button(action: centerOnPlayer) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 4)
                    }
                    
                    // 인벤토리 빠른 접근
                    actionButton(
                        icon: "bag.fill",
                        count: player.inventory.count,
                        color: .gamePurple
                    ) {
                        // 인벤토리 뷰로 이동
                    }
                    
                    // 설정
                    actionButton(
                        icon: "gearshape.fill",
                        count: 0,
                        color: .gray
                    ) {
                        // 설정 화면
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // 탭바 공간 확보
            }
        }
    }
    
    // MARK: - UI Components
    private var districtInfoCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(districtManager.currentDistrict.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(districtManager.currentDistrict.displayName)
                        .font(.chosunBody)
                        .fontWeight(.bold)
                    
                    Text(districtManager.currentDistrict.description)
                        .font(.chosunCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(districtManager.currentDistrict.color.opacity(0.9))
                .shadow(radius: 4)
        )
        .foregroundColor(.white)
        .onTapGesture {
            showDistrictInfo = true
        }
    }
    
    private var playerInfoCard: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Lv.\(player.level)")
                    .font(.chosunBody)
                    .fontWeight(.bold)
                
                Text(formatMoney(player.money))
                    .font(.chosunCaption)
                    .foregroundColor(.green)
            }
            
            // 경험치 바
            ProgressView(value: Double(player.experience % 1000), total: 1000)
                .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                .frame(height: 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .shadow(radius: 2)
        )
        .foregroundColor(.white)
    }
    
    private var nearbyMerchantsIndicator: some View {
        HStack {
            ForEach(merchants.prefix(3)) { merchant in
                Button(action: {
                    selectedMerchant = merchant
                    showMerchantDetail = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: merchant.type.icon)
                            .font(.title3)
                            .foregroundColor(merchant.type.color)
                        
                        Text(merchant.name)
                            .font(.chosunCaption)
                            .foregroundColor(.primary)
                        
                        Text("\(Int(merchant.distanceFromPlayer ?? 0))m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 2)
                    )
                }
                .disabled((merchant.distanceFromPlayer ?? 1000) > 400)
                .opacity((merchant.distanceFromPlayer ?? 1000) > 400 ? 0.5 : 1.0)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func actionButton(icon: String, count: Int, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .shadow(radius: 3)
                
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // MARK: - Trade Activity Feed
    private var tradeActivityFeed: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 8) {
                    ForEach(socketManager.recentTradeActivity.prefix(3)) { activity in
                        HStack {
                            Text(activity.activityText)
                                .font(.chosunCaption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.8))
                                )
                            
                            Spacer()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 120)
            
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Price Update Notifications
    private var priceUpdateNotifications: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(socketManager.marketPriceUpdates.prefix(2)) { update in
                        HStack {
                            Text(update.changeText)
                                .font(.chosunCaption)
                                .fontWeight(.semibold)
                            
                            Text(update.itemName)
                                .font(.chosunCaption)
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                        )
                        .foregroundColor(.white)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .padding(.leading, 16)
                
                Spacer()
            }
            .padding(.top, 200)
            
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Methods
    private func setupMapView() {
        loadNearbyMerchants()
        
        if let token = networkManager.authToken {
            socketManager.connect(with: token)
        }
    }
    
    private func handleLocationUpdate(_ location: CLLocationCoordinate2D) {
        // 지역 업데이트
        districtManager.updateCurrentDistrict(for: location)
        
        // 위치 추적이 활성화된 경우 카메라 업데이트
        if isLocationTracking {
            viewport = .camera(center: location, zoom: 15, bearing: 0, pitch: 60)
        }
        
        // 소켓으로 위치 전송 (1초 간격)
        let now = Date()
        if now.timeIntervalSince(lastLocationUpdate) >= 1.0 {
            socketManager.updateLocation(lat: location.latitude, lng: location.longitude)
            socketManager.searchNearbyPlayers(lat: location.latitude, lng: location.longitude)
            lastLocationUpdate = now
        }
        
        // 상인 거리 업데이트
        updateMerchantDistances(from: location)
    }
    
    private func handleMerchantTap(_ merchant: EnhancedMerchant) {
        selectedMerchant = merchant
        
        if let distance = merchant.distanceFromPlayer, distance <= 400 {
            showMerchantDetail = true
        } else {
            // 거리가 멀다는 피드백
        }
    }
    
    private func centerOnPlayer() {
        if let location = locationManager.currentLocation {
            viewport = .camera(center: location, zoom: 16, bearing: 0, pitch: 60)
            isLocationTracking = true
        }
    }
    
    private func loadNearbyMerchants() {
        // 실제로는 서버에서 가져옴
        // 여기서는 예시 데이터
        merchants = [
            EnhancedMerchant(
                id: "1",
                name: "김테크",
                title: "전자제품 전문가",
                type: .electronics,
                location: CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276),
                district: .gangnam,
                priceModifier: 1.2,
                negotiationDifficulty: 4,
                reputationRequirement: 50
            ),
            EnhancedMerchant(
                id: "2",
                name: "박전통",
                title: "한국 문화 전문가",
                type: .cultural,
                location: CLLocationCoordinate2D(latitude: 37.5636, longitude: 126.9970),
                district: .jung,
                priceModifier: 1.1,
                negotiationDifficulty: 2,
                reputationRequirement: 0
            )
        ]
    }
    
    private func updateMerchantDistances(from playerLocation: CLLocationCoordinate2D) {
        let playerCLLocation = CLLocation(latitude: playerLocation.latitude, longitude: playerLocation.longitude)
        
        for i in merchants.indices {
            let merchantLocation = CLLocation(
                latitude: merchants[i].location.latitude,
                longitude: merchants[i].location.longitude
            )
            merchants[i].distanceFromPlayer = playerCLLocation.distance(from: merchantLocation)
        }
    }
    
    private func formatMoney(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "0")원"
    }
}

// MARK: - Enhanced Merchant Model
struct EnhancedMerchant: Identifiable {
    let id: String
    let name: String
    let title: String
    let type: MerchantType
    let location: CLLocationCoordinate2D
    let district: DistrictManager.GameDistrict
    let priceModifier: Double
    let negotiationDifficulty: Int
    let reputationRequirement: Int
    var distanceFromPlayer: Double?
    
    enum MerchantType {
        case electronics, cultural, antique, artist, craftsman, scholar, foodMaster, trader, importer
        
        var icon: String {
            switch self {
            case .electronics: return "desktopcomputer"
            case .cultural: return "building.columns"
            case .antique: return "crown"
            case .artist: return "paintbrush"
            case .craftsman: return "hammer"
            case .scholar: return "book"
            case .foodMaster: return "leaf"
            case .trader: return "dollarsign.circle"
            case .importer: return "airplane"
            }
        }
        
        var color: Color {
            switch self {
            case .electronics: return .blue
            case .cultural: return .red
            case .antique: return .brown
            case .artist: return .purple
            case .craftsman: return .orange
            case .scholar: return .indigo
            case .foodMaster: return .green
            case .trader: return .yellow
            case .importer: return .cyan
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PokemonGOMapView()
        .environmentObject(NetworkManager.shared)
        .environmentObject(LocationManager())
        .environmentObject(Player())
}