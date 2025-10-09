//
//  DistrictManager.swift
//  way3 - Seoul District Management System
//
//  서울 구별 지역 관리 및 Pokemon GO 스타일 구역 시스템
//

import SwiftUI
import CoreLocation
import MapboxMaps

class DistrictManager: ObservableObject {
    static let shared = DistrictManager()
    
    // MARK: - Published Properties
    @Published var currentDistrict: GameDistrict = .other
    @Published var nearbyMerchants: [Merchant] = []
    @Published var districtActivity: [DistrictActivity] = []
    
    // MARK: - District Definitions
    enum GameDistrict: String, CaseIterable {
        case gangnam = "강남구"
        case jung = "중구"
        case mapo = "마포구"
        case jongno = "종로구"
        case yongsan = "용산구"
        case other = "기타"
        
        var color: Color {
            switch self {
            case .gangnam: return .gameGold
            case .jung: return .gameRed
            case .mapo: return .gamePurple
            case .jongno: return .gameBlue
            case .yongsan: return .gameGreen
            case .other: return .gray
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
        
        var emoji: String {
            switch self {
            case .gangnam: return "🏢"
            case .jung: return "🏛️"
            case .mapo: return "🎨"
            case .jongno: return "📚"
            case .yongsan: return "🚅"
            case .other: return "📍"
            }
        }
        
        var description: String {
            switch self {
            case .gangnam: return "IT & 금융의 중심"
            case .jung: return "전통 문화의 보고"
            case .mapo: return "창의와 예술의 거리"
            case .jongno: return "역사와 지혜의 터"
            case .yongsan: return "국제 교역의 허브"
            case .other: return "미지의 영역"
            }
        }
    }
    
    // MARK: - District Activity
    struct DistrictActivity: Identifiable {
        let id = UUID()
        let playerId: String
        let playerName: String
        let merchantName: String
        let itemName: String
        let tradeType: String
        let isProfit: Bool
        let timestamp: Date
        let district: GameDistrict
        
        var timeAgo: String {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.localizedString(for: timestamp, relativeTo: Date())
        }
    }
    
    // MARK: - District Boundaries
    private let districtBoundaries: [GameDistrict: (center: CLLocationCoordinate2D, bounds: (minLat: Double, maxLat: Double, minLng: Double, maxLng: Double))] = [
        .gangnam: (
            center: CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276),
            bounds: (minLat: 37.48, maxLat: 37.52, minLng: 127.00, maxLng: 127.06)
        ),
        .jung: (
            center: CLLocationCoordinate2D(latitude: 37.5636, longitude: 126.9970),
            bounds: (minLat: 37.55, maxLat: 37.58, minLng: 126.97, maxLng: 127.02)
        ),
        .mapo: (
            center: CLLocationCoordinate2D(latitude: 37.5219, longitude: 126.8954),
            bounds: (minLat: 37.50, maxLat: 37.55, minLng: 126.85, maxLng: 126.95)
        ),
        .jongno: (
            center: CLLocationCoordinate2D(latitude: 37.5729, longitude: 126.9794),
            bounds: (minLat: 37.56, maxLat: 37.59, minLng: 126.95, maxLng: 127.01)
        ),
        .yongsan: (
            center: CLLocationCoordinate2D(latitude: 37.5311, longitude: 126.9810),
            bounds: (minLat: 37.52, maxLat: 37.55, minLng: 126.95, maxLng: 127.01)
        )
    ]
    
    // MARK: - Public Methods
    func getDistrict(for location: CLLocationCoordinate2D) -> GameDistrict {
        for (district, boundary) in districtBoundaries {
            let bounds = boundary.bounds
            if location.latitude >= bounds.minLat && location.latitude <= bounds.maxLat &&
               location.longitude >= bounds.minLng && location.longitude <= bounds.maxLng {
                return district
            }
        }
        return .other
    }
    
    func updateCurrentDistrict(for location: CLLocationCoordinate2D) {
        let newDistrict = getDistrict(for: location)
        if newDistrict != currentDistrict {
            currentDistrict = newDistrict
            print("🏛️ 지역 변경: \(currentDistrict.displayName)")
        }
    }
    
    func getDistrictBoundaries() -> [PolygonAnnotation] {
        var annotations: [PolygonAnnotation] = []
        
        for (district, boundary) in districtBoundaries {
            let bounds = boundary.bounds
            let coordinates = [
                CLLocationCoordinate2D(latitude: bounds.minLat, longitude: bounds.minLng),
                CLLocationCoordinate2D(latitude: bounds.minLat, longitude: bounds.maxLng),
                CLLocationCoordinate2D(latitude: bounds.maxLat, longitude: bounds.maxLng),
                CLLocationCoordinate2D(latitude: bounds.maxLat, longitude: bounds.minLng),
                CLLocationCoordinate2D(latitude: bounds.minLat, longitude: bounds.minLng)
            ]
            
            var annotation = PolygonAnnotation(polygon: Polygon([coordinates]))
            annotation.fillColor = StyleColor(UIColor(district.color.opacity(0.2)))
            annotation.fillOutlineColor = StyleColor(UIColor(district.color))
            
            annotations.append(annotation)
        }
        
        return annotations
    }
    
    func addDistrictActivity(_ activity: DistrictActivity) {
        districtActivity.insert(activity, at: 0)
        
        // 최대 50개 활동만 유지
        if districtActivity.count > 50 {
            districtActivity.removeLast()
        }
    }
    
    func getDistrictCenter(_ district: GameDistrict) -> CLLocationCoordinate2D? {
        return districtBoundaries[district]?.center
    }
}

// MARK: - Color Extensions
extension Color {
    static let gameGold = Color(red: 1.0, green: 0.84, blue: 0.0)      // 강남구
    static let gameRed = Color(red: 0.82, green: 0.18, blue: 0.18)     // 중구
    static let gamePurple = Color(red: 0.61, green: 0.35, blue: 0.71)  // 마포구
    static let gameBlue = Color(red: 0.12, green: 0.35, blue: 0.61)    // 종로구
    static let gameGreen = Color(red: 0.13, green: 0.69, blue: 0.30)   // 용산구
    static let seaBlue = Color(red: 0.0, green: 0.6, blue: 0.8)        // 바다색 스킬
    static let manaBlue = Color(red: 0.2, green: 0.4, blue: 0.9)       // 마나색 스킬
}