//
//  way3App.swift
//  way3 - Way Trading Game
//
//  Created by 김상훈 on 9/12/25.
//  복원된 프로젝트 - 서울 지역별 상인 거래 게임
//

import SwiftUI
import CoreLocation

@main
struct way3App: App {
    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var locationManager = LocationManager()
    @StateObject private var gameManager = GameManager.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var progressManager = ProgressManager.shared
    @StateObject private var questManager = QuestManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkManager)
                .environmentObject(locationManager)
                .environmentObject(gameManager)
                .environmentObject(authManager)
                .environmentObject(progressManager)
                .environmentObject(questManager)
        }
    }
}

// MARK: - 위치 관리자
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 서울 시청 기본값
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var isLocationAvailable: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 최고 정확도
        locationManager.distanceFilter = 10  // 10m마다 업데이트
        locationManager.allowsBackgroundLocationUpdates = false  // 백그라운드 업데이트 끄기
        locationManager.pausesLocationUpdatesAutomatically = true  // 자동 일시정지
        locationManager.requestWhenInUseAuthorization()

        GameLogger.shared.logInfo("📍 LocationManager 초기화 완료", category: .system)
    }

    func requestLocation() {
        locationManager.requestLocation()
    }

    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            GameLogger.shared.logDebug(
                "📍 GPS 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude) (정확도: \(location.horizontalAccuracy)m)",
                category: .system
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        GameLogger.shared.logError("❌ GPS 오류: \(error.localizedDescription)", category: .system)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            let statusText: String
            switch manager.authorizationStatus {
            case .authorizedWhenInUse:
                statusText = "✅ 앱 사용 중 위치 권한 허용"
            case .authorizedAlways:
                statusText = "✅ 항상 위치 권한 허용"
            case .denied:
                statusText = "❌ 위치 권한 거부됨"
            case .restricted:
                statusText = "⚠️ 위치 권한 제한됨"
            case .notDetermined:
                statusText = "❓ 위치 권한 미결정"
            @unknown default:
                statusText = "❓ 알 수 없는 권한 상태"
            }

            GameLogger.shared.logInfo("🔐 위치 권한 상태 변경: \(statusText)", category: .system)
        }
    }
}
