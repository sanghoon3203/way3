// 📁 Extensions/CLLocationCoordinate2D+Codable.swift - CoreLocation Codable 지원
import Foundation
import CoreLocation

/**
 * CLLocationCoordinate2D의 Codable 확장
 *
 * CoreLocation의 CLLocationCoordinate2D는 기본적으로 Codable을 지원하지 않으므로
 * 이 확장을 통해 JSON 직렬화/역직렬화 기능을 추가합니다.
 */
extension CLLocationCoordinate2D: Codable {

    // MARK: - Codable Keys
    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
    }

    // MARK: - Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)

        // CLLocationCoordinate2D 유효성 검증
        guard CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid coordinate values: lat=\(latitude), lng=\(longitude)"
                )
            )
        }

        self.init(latitude: latitude, longitude: longitude)
    }

    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // 유효한 좌표인지 검증
        guard CLLocationCoordinate2DIsValid(self) else {
            throw EncodingError.invalidValue(
                self,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Invalid coordinate values: lat=\(latitude), lng=\(longitude)"
                )
            )
        }

        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

// MARK: - 편의 메서드들
extension CLLocationCoordinate2D {

    /**
     * 서울 지역 여부 확인
     */
    var isInSeoul: Bool {
        // 서울 대략적인 경계
        let seoulLatRange = 37.4...37.7
        let seoulLngRange = 126.8...127.2

        return seoulLatRange.contains(latitude) && seoulLngRange.contains(longitude)
    }

    /**
     * 다른 좌표와의 거리 계산 (미터)
     */
    func distance(from coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        return location1.distance(from: location2)
    }

    /**
     * 좌표의 문자열 표현
     */
    var coordinateString: String {
        return String(format: "%.6f, %.6f", latitude, longitude)
    }

    /**
     * 서울 구별 추정 (간단한 버전)
     */
    var estimatedDistrict: String {
        // 간단한 구별 추정 로직 (실제로는 더 정확한 API나 데이터 필요)
        switch (latitude, longitude) {
        case (37.5...37.6, 127.0...127.1):
            return "강남구"
        case (37.55...37.65, 126.9...127.0):
            return "종로구"
        case (37.5...37.55, 126.9...127.0):
            return "중구"
        case (37.45...37.5, 126.95...127.05):
            return "서초구"
        case (37.6...37.7, 127.0...127.1):
            return "성북구"
        default:
            return "서울시"
        }
    }
}

// MARK: - JSON Helper 구조체
/**
 * 서버 API와의 호환성을 위한 Location 구조체
 */
struct LocationData: Codable {
    let lat: Double
    let lng: Double

    init(coordinate: CLLocationCoordinate2D) {
        self.lat = coordinate.latitude
        self.lng = coordinate.longitude
    }

    init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

// MARK: - 기본 좌표 상수들
extension CLLocationCoordinate2D {

    // 서울 주요 지역 좌표
    static let seoulStationCoordinate = CLLocationCoordinate2D(latitude: 37.5547, longitude: 126.9706)
    static let gangnamStationCoordinate = CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276)
    static let hongikUniversityCoordinate = CLLocationCoordinate2D(latitude: 37.5510, longitude: 126.9225)
    static let itaewonCoordinate = CLLocationCoordinate2D(latitude: 37.5345, longitude: 126.9949)
    static let myeongdongCoordinate = CLLocationCoordinate2D(latitude: 37.5636, longitude: 126.9834)
    static let insadongCoordinate = CLLocationCoordinate2D(latitude: 37.5760, longitude: 126.9815)

    // 기본 서울 중심점
    static let seoulCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    // 유효하지 않은 좌표 (초기값용)
    static let invalid = CLLocationCoordinate2D(latitude: 0, longitude: 0)
}

// MARK: - Equatable은 이미 다른 곳에서 지원됨 (Turf framework)

// MARK: - Hashable 지원
extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}