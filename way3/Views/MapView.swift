import SwiftUI
@_spi(Experimental) import MapboxMaps
import CoreLocation

struct MapView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        zoom: 14,
        bearing: 0,
        pitch: 60
    )
    @State private var showingMerchantSheet = false
    @State private var selectedMerchant: Merchant?
    @State private var userLocation: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    
    // 플레이어 위치를 동기화하기 위한 computed property
    private var synchronizedLocation: CLLocationCoordinate2D? {
        // gameManager의 위치가 있으면 사용, 없으면 userLocation 사용
        if let playerLocation = gameManager.player.currentLocation {
            return playerLocation
        }
        return userLocation
    }
    @State private var isTracking = true
    
    // 오프라인 데이터 생성기
    private let offlineDataGenerator = OfflineDataGenerator()
    
    // 모든 상인을 표시 (거래는 상인 마커에서 거리 체크)
    private var allMerchants: [Merchant] {
        return offlineDataGenerator.generateOfflineData().merchants
    }
    
    var body: some View {
        ZStack {
            // 실제 상인 마커들이 표시되는 맵
            Map(viewport: $viewport) {
                // 플레이어 위치 표시
                Puck2D(bearing: .heading)
                    .showsAccuracyRing(false)
                    .pulsing(.default)
                
                // 실제 상인들을 지도 좌표에 표시
                ForEvery(allMerchants) { merchant in
                    MapViewAnnotation(coordinate: merchant.coordinate) {
                        MerchantAnnotationView(
                            merchant: merchant,
                            userLocation: synchronizedLocation
                        )
                        .onTapGesture {
                            // 500m 이내에서만 거래 가능
                            if let syncLocation = synchronizedLocation {
                                let merchantLocation = CLLocation(latitude: merchant.coordinate.latitude, longitude: merchant.coordinate.longitude)
                                let userLocationCL = CLLocation(latitude: syncLocation.latitude, longitude: syncLocation.longitude)
                                let distance = userLocationCL.distance(from: merchantLocation)
                                
                                if distance <= 500 {
                                    selectedMerchant = merchant
                                    showingMerchantSheet = true
                                    print("상인 선택됨: \(merchant.name) (거리: \(Int(distance))m)")
                                } else {
                                    print("거래 불가: \(merchant.name) (거리: \(Int(distance))m > 500m)")
                                }
                            }
                        }
                    }
                    .allowOverlap(true)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            simpleOverlay
            
            // 디버깅용 - 상인 개수 표시
            VStack {
                Spacer()
                HStack {
                    Text("전체 상인: \(allMerchants.count)개 표시 중")
                        .font(.caption)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(4)
                    Spacer()
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showingMerchantSheet) {
            if let selectedMerchant = selectedMerchant {
                MerchantDetailSheet(merchant: selectedMerchant)
                    .environmentObject(gameManager)
            }
        }
    }
    
    private var simpleOverlay: some View {
        VStack {
            // 상단 플레이어 정보 (등급)
            HStack {
                Spacer()
                PlayerInfoOverlayLisenceInfo()
                    .environmentObject(gameManager)
            }
            .padding(.top, 10)
            .padding(.horizontal, 16)
            
            Spacer()
            
            // 하단 정보 및 버튼들
            HStack {
                PlayerInfoOverlayMoneyInfo()
                    .environmentObject(gameManager)
                    .padding(.leading, 5)
                
                Spacer()
                
                    .padding(.trailing, 20)
            }
            .padding(.bottom, 10)
        }
        .padding()
    }
    
    
    private func stopTracking() {
        isTracking = false
        viewport = .idle
    }
}
