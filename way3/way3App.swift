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
    @StateObject private var socketManager = SocketManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkManager)
                .environmentObject(locationManager)
                .environmentObject(gameManager)
                .environmentObject(authManager)
                .environmentObject(socketManager)
        }
    }
}

// MARK: - 위치 관리자
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
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
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        GameLogger.shared.logError("Location error: \(error.localizedDescription)", category: .system)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}
