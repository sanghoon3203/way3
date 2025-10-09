//
//  LocationVerifier.swift
//  way3
//
//  GPS 기반 위치 인증 시스템
//  Delivery 퀘스트용 위치 도달 검증
//

import Foundation
import CoreLocation
import os

// MARK: - Location Verification Result

struct LocationVerificationResult {
    let verified: Bool
    let distance: Double  // 목표 지점까지의 거리 (미터)
    let timestamp: Date
    let accuracy: Double  // GPS 정확도 (미터)
}

enum LocationVerificationError: Error {
    case locationServicesDisabled
    case locationPermissionDenied
    case inaccurateLocation(accuracy: Double)
    case outOfRange(distance: Double, required: Double)
    case unknownError

    var localizedDescription: String {
        switch self {
        case .locationServicesDisabled:
            return "위치 서비스가 비활성화되어 있습니다"
        case .locationPermissionDenied:
            return "위치 권한이 거부되었습니다"
        case .inaccurateLocation(let accuracy):
            return "GPS 정확도가 낮습니다 (현재: \(Int(accuracy))m)"
        case .outOfRange(let distance, let required):
            return "목표 지점에서 \(Int(distance - required))m 더 가까이 가야 합니다"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}

// MARK: - Location Verifier

@MainActor
class LocationVerifier: NSObject, ObservableObject {
    static let shared = LocationVerifier()

    @Published var isTracking: Bool = false
    @Published var currentDistance: Double?

    private var locationManager: CLLocationManager
    private var targetLocation: CLLocationCoordinate2D?
    private var targetRadius: Double = 50.0
    private var onArrival: ((LocationVerificationResult) -> Void)?

    private let logger = Logger(subsystem: "com.way3.location", category: "LocationVerifier")

    override private init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10m 이동마다 업데이트
    }

    // MARK: - Immediate Verification

    /// 현재 위치가 목표 지점 반경 내에 있는지 즉시 확인
    func verifyLocation(
        userLocation: CLLocationCoordinate2D,
        targetLocation: CLLocationCoordinate2D,
        radius: Double
    ) -> Bool {
        let distance = userLocation.distance(to: targetLocation)
        logger.debug("📍 거리 확인: \(String(format: "%.1f", distance))m / \(Int(radius))m")
        return distance <= radius
    }

    /// CLLocation 객체로 검증 (정확도 체크 포함)
    func verifyLocationWithAccuracy(
        userLocation: CLLocation,
        targetLocation: CLLocationCoordinate2D,
        radius: Double,
        requiredAccuracy: Double = 50.0
    ) throws -> LocationVerificationResult {
        // GPS 정확도 체크
        guard userLocation.horizontalAccuracy >= 0 && userLocation.horizontalAccuracy <= requiredAccuracy else {
            throw LocationVerificationError.inaccurateLocation(accuracy: userLocation.horizontalAccuracy)
        }

        let distance = userLocation.coordinate.distance(to: targetLocation)
        let verified = distance <= radius

        if !verified {
            throw LocationVerificationError.outOfRange(distance: distance, required: radius)
        }

        logger.info("✅ 위치 인증 성공: \(String(format: "%.1f", distance))m (정확도: \(String(format: "%.1f", userLocation.horizontalAccuracy))m)")

        QuestManager.shared.recordLocationEvent(currentLocation: userLocation.coordinate)

        return LocationVerificationResult(
            verified: true,
            distance: distance,
            timestamp: Date(),
            accuracy: userLocation.horizontalAccuracy
        )
    }

    // MARK: - Continuous Tracking

    /// 특정 위치로 가는 것을 추적 (배달 퀘스트용)
    func startLocationTracking(
        questID: String,
        targetLocation: CLLocationCoordinate2D,
        radius: Double = 50.0,
        onArrival: @escaping (LocationVerificationResult) -> Void
    ) {
        self.targetLocation = targetLocation
        self.targetRadius = radius
        self.onArrival = onArrival
        self.isTracking = true

        // 위치 권한 확인
        checkLocationAuthorization()

        logger.info("🎯 위치 추적 시작 - Quest: \(questID), 반경: \(Int(radius))m")
        locationManager.startUpdatingLocation()
    }

    /// 위치 추적 중단
    func stopLocationTracking() {
        isTracking = false
        targetLocation = nil
        onArrival = nil
        currentDistance = nil
        locationManager.stopUpdatingLocation()
        logger.info("⏹️ 위치 추적 중단")
    }

    // MARK: - Permission Check

    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            logger.error("❌ 위치 권한 거부됨")
        case .authorizedAlways, .authorizedWhenInUse:
            logger.info("✅ 위치 권한 승인됨")
        @unknown default:
            logger.warning("⚠️ 알 수 없는 위치 권한 상태")
        }
    }

    // MARK: - Distance Calculation

    func calculateDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        return from.distance(to: to)
    }

    // MARK: - Geofencing (Optional - 고급 기능)

    func setupGeofence(
        identifier: String,
        center: CLLocationCoordinate2D,
        radius: Double
    ) {
        let geofenceRegion = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: identifier
        )
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = false

        locationManager.startMonitoring(for: geofenceRegion)
        logger.info("🚧 Geofence 설정: \(identifier), 반경 \(Int(radius))m")
    }

    func removeGeofence(identifier: String) {
        for region in locationManager.monitoredRegions {
            if region.identifier == identifier {
                locationManager.stopMonitoring(for: region)
                logger.info("🗑️ Geofence 제거: \(identifier)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationVerifier: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last,
              let target = targetLocation else { return }

        let distance = currentLocation.coordinate.distance(to: target)
        currentDistance = distance

        logger.debug("📍 현재 거리: \(String(format: "%.1f", distance))m")

        // 목표 지점 도달 확인
        if distance <= targetRadius {
            do {
                let result = try verifyLocationWithAccuracy(
                    userLocation: currentLocation,
                    targetLocation: target,
                    radius: targetRadius
                )

                onArrival?(result)
                stopLocationTracking()
            } catch {
                logger.error("❌ 위치 검증 실패: \(error.localizedDescription)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("❌ 위치 업데이트 실패: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }

    // Geofencing delegate
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        logger.info("🎯 Geofence 진입: \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        logger.info("🚪 Geofence 이탈: \(region.identifier)")
    }
}

// MARK: - CLLocationCoordinate2D Extension
// distance(to:) 함수는 TradeItem.swift에 이미 정의되어 있음
