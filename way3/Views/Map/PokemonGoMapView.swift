//
//  PokemonGoMapView.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  Pokemon GO 스타일 메인 맵 화면
//

import SwiftUI
import MapKit
import CoreLocation

struct PokemonGoMapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var mapManager = MapManager()
    @StateObject private var merchantManager = MerchantManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울시청
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var showMerchantDetail = false
    @State private var selectedMerchant: Merchant?
    @State private var playerEnergy = 85
    @State private var playerMoney = 15420
    
    var body: some View {
        ZStack {
            // 메인 맵
            Map(coordinateRegion: $region, 
                showsUserLocation: true,
                userTrackingMode: .constant(.none),
                annotationItems: merchantManager.nearbyMerchants) { merchant in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: merchant.latitude,
                    longitude: merchant.longitude
                )) {
                    MerchantMapPin(merchant: merchant) {
                        selectedMerchant = merchant
                        showMerchantDetail = true
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                setupMap()
            }
            .onChange(of: locationManager.currentLocation) { location in
                if let location = location {
                    updateRegion(to: location)
                    merchantManager.updateLocation(location)
                }
            }
            
            // 상단 상태 바
            VStack {
                HStack {
                    // 에너지
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        Text("\(playerEnergy)")
                            .font(.custom("ChosunCentennial", size: 18))
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                    )
                    
                    Spacer()
                    
                    // 소지금
                    HStack(spacing: 5) {
                        Image(systemName: "wonsign.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("\(playerMoney)")
                            .font(.custom("ChosunCentennial", size: 18))
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // 하단 컨트롤들
            VStack {
                Spacer()
                
                HStack {
                    // 위치 재설정 버튼
                    Button(action: {
                        centerOnPlayer()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                                    .shadow(radius: 8)
                            )
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // 메뉴 버튼들
                    VStack(spacing: 15) {
                        // 인벤토리
                        MenuButton(icon: "backpack.fill", color: .green) {
                            // 인벤토리 화면으로 이동
                        }
                        
                        // 퀘스트
                        MenuButton(icon: "list.bullet.clipboard", color: .purple) {
                            // 퀘스트 화면으로 이동
                        }
                        
                        // 상점
                        MenuButton(icon: "storefront.fill", color: .orange) {
                            // 상점 화면으로 이동
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 30)
            }
            
            // 근처 상인 알림
            if let nearestMerchant = merchantManager.nearestMerchant {
                VStack {
                    Spacer()
                    
                    NearbyMerchantNotification(merchant: nearestMerchant) {
                        selectedMerchant = nearestMerchant
                        showMerchantDetail = true
                    }
                    .padding(.bottom, 150)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // 파티클 효과 (아이템 발견 등)
            if mapManager.showItemDiscovery {
                ItemDiscoveryEffect()
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showMerchantDetail) {
            if let merchant = selectedMerchant {
                MerchantDetailView(merchant: merchant, isPresented: $showMerchantDetail)
            }
        }
        .onAppear {
            merchantManager.startLocationUpdates()
        }
    }
    
    private func setupMap() {
        if let location = locationManager.currentLocation {
            region.center = location
        }
    }
    
    private func updateRegion(to location: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 1.0)) {
            region.center = location
        }
    }
    
    private func centerOnPlayer() {
        if let location = locationManager.currentLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                region.center = location
                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        }
    }
}

// MARK: - 상인 맵 핀
struct MerchantMapPin: View {
    let merchant: Merchant
    let onTap: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 외곽 링
                Circle()
                    .stroke(merchant.pinColor, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .opacity(isAnimating ? 0.3 : 0.8)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                
                // 메인 핀
                ZStack {
                    Circle()
                        .fill(merchant.pinColor)
                        .frame(width: 45, height: 45)
                        .shadow(radius: 8)
                    
                    Image(systemName: merchant.iconName)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                // 상인 이름 라벨
                VStack {
                    Spacer()
                    Text(merchant.name)
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                        )
                        .offset(y: 35)
                }
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}

// MARK: - 메뉴 버튼
struct MenuButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(radius: 8)
                )
        }
    }
}

// MARK: - 근처 상인 알림
struct NearbyMerchantNotification: View {
    let merchant: Merchant
    let onTap: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // 상인 아이콘
                ZStack {
                    Circle()
                        .fill(merchant.pinColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: merchant.iconName)
                        .foregroundColor(.white)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(merchant.name) 발견!")
                        .font(.custom("ChosunCentennial", size: 16))
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    
                    Text("거리: \(Int(merchant.distance))m")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 10)
            )
            .padding(.horizontal, 20)
        }
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - 아이템 발견 효과
struct ItemDiscoveryEffect: View {
    @State private var particles: [DiscoveryParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Image(systemName: "star.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        particles = (0..<8).map { _ in
            DiscoveryParticle(
                id: UUID(),
                x: centerX,
                y: centerY,
                opacity: 1.0,
                scale: 0.5
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: 1.5)) {
            for i in particles.indices {
                let angle = Double(i) * (360.0 / 8.0) * .pi / 180.0
                particles[i].x += CGFloat(cos(angle)) * 100
                particles[i].y += CGFloat(sin(angle)) * 100
                particles[i].opacity = 0.0
                particles[i].scale = 1.0
            }
        }
    }
}

struct DiscoveryParticle {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var scale: CGFloat
}

// MARK: - 맵 매니저
class MapManager: ObservableObject {
    @Published var showItemDiscovery = false
    
    func triggerItemDiscovery() {
        showItemDiscovery = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showItemDiscovery = false
        }
    }
}

// MARK: - 상인 매니저
class MerchantManager: ObservableObject {
    @Published var nearbyMerchants: [Merchant] = []
    @Published var nearestMerchant: Merchant?
    
    private var currentLocation: CLLocationCoordinate2D?
    private let proximityThreshold: CLLocationDistance = 50.0 // 50m
    
    func startLocationUpdates() {
        // 샘플 상인 데이터 생성
        generateSampleMerchants()
    }
    
    func updateLocation(_ location: CLLocationCoordinate2D) {
        currentLocation = location
        updateMerchantDistances()
        checkNearbyMerchants()
    }
    
    private func generateSampleMerchants() {
        nearbyMerchants = [
            Merchant(
                id: "1",
                name: "김씨 상점",
                type: .foodMerchant,
                district: .jung,
                coordinate: CLLocationCoordinate2D(latitude: 37.5670, longitude: 126.9780),
                requiredLicense: .beginner
            ),
            Merchant(
                id: "2",
                name: "한강 공예품",
                type: .craftsman,
                district: .jung,
                coordinate: CLLocationCoordinate2D(latitude: 37.5650, longitude: 126.9800),
                requiredLicense: .beginner
            ),
            Merchant(
                id: "3",
                name: "명동 보석상",
                type: .luxury,
                district: .jung,
                coordinate: CLLocationCoordinate2D(latitude: 37.5680, longitude: 126.9760),
                requiredLicense: .beginner
            )
        ]
    }
    
    private func updateMerchantDistances() {
        guard let location = currentLocation else { return }
        
        for i in nearbyMerchants.indices {
            let merchantLocation = CLLocation(
                latitude: nearbyMerchants[i].latitude,
                longitude: nearbyMerchants[i].longitude
            )
            let playerLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            nearbyMerchants[i].distance = playerLocation.distance(from: merchantLocation)
        }
    }
    
    private func checkNearbyMerchants() {
        let nearby = nearbyMerchants.filter { $0.distance <= proximityThreshold }
        
        if let closest = nearby.min(by: { $0.distance < $1.distance }) {
            if nearestMerchant?.id != closest.id {
                nearestMerchant = closest
            }
        } else {
            nearestMerchant = nil
        }
    }
}