// 📁 Core/MerchantDataManager.swift - 상인 데이터 관리자
import Foundation
import Combine
import CoreLocation

/// 상인 관련 서버 데이터를 관리하는 매니저
/// 기존 하드코딩을 대체하여 실시간 서버 데이터 활용
@MainActor
class MerchantDataManager: ObservableObject {

    // MARK: - Singleton
    static let shared = MerchantDataManager()
    private init() {}

    // MARK: - Published Properties
    @Published var cachedInventories: [String: [TradeItem]] = [:]
    @Published var cachedRelationships: [String: MerchantRelationship] = [:]

    // MARK: - Dependencies
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 상인 상세 정보 조회
    /// 상인 상세 정보를 서버에서 직접 가져옴 (서버 응답 그대로)
    /// - Parameter merchantId: 상인 ID
    /// - Returns: 서버 응답 상세 정보
    func fetchMerchantDetail(merchantId: String) async throws -> MerchantDetailResponse {
        return try await networkManager.getMerchantDetail(merchantId: merchantId)
    }


    // MARK: - 상인 인벤토리 조회
    /// 상인의 실시간 인벤토리를 서버에서 가져옴 (하드코딩 대체)
    /// - Parameter merchantId: 상인 ID
    /// - Returns: 거래 가능한 아이템 목록
    func fetchMerchantInventory(merchantId: String) async throws -> [TradeItem] {
        let response = try await networkManager.getMerchantDetail(merchantId: merchantId)

        // 서버 응답을 TradeItem으로 변환
        let tradeItems = response.inventory.map { serverItem in
            TradeItem(
                itemId: serverItem.itemTemplateId,
                name: serverItem.name,
                category: serverItem.category,
                grade: ItemGrade(rawValue: serverItem.grade) ?? .common,
                requiredLicense: LicenseLevel(rawValue: serverItem.requiredLicense) ?? .beginner,
                basePrice: serverItem.basePrice,
                currentPrice: serverItem.currentPrice,
                weight: serverItem.weight,
                description: serverItem.description,
                iconId: serverItem.iconId
            )
        }

        // 캐시 저장
        cachedInventories[merchantId] = tradeItems

        return tradeItems
    }

    // MARK: - 상인 관계 조회
    /// 플레이어와 상인의 관계 정보를 가져옴
    /// - Parameter merchantId: 상인 ID
    /// - Returns: 상인 관계 정보
    func fetchMerchantRelationship(merchantId: String) async throws -> MerchantRelationship {
        let response = try await networkManager.getMerchantDetail(merchantId: merchantId)

        let relationship = MerchantRelationship(
            merchantId: merchantId,
            friendshipPoints: response.relationship.friendshipPoints,
            trustLevel: response.relationship.trustLevel,
            totalTrades: response.relationship.totalTrades,
            totalSpent: response.relationship.totalSpent,
            lastInteraction: response.relationship.lastInteraction,
            notes: response.relationship.notes
        )

        // 캐시 저장
        cachedRelationships[merchantId] = relationship

        return relationship
    }

    // MARK: - 근처 상인 조회
    /// 위치 기반으로 근처 상인들을 조회
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - radius: 반경 (미터)
    /// - Returns: 근처 상인 목록
    func fetchNearbyMerchants(
        latitude: Double,
        longitude: Double,
        radius: Double = 1000
    ) async throws -> [MerchantPreview] {
        let response = try await networkManager.getNearbyMerchants(
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )

        return response.merchants.map { MerchantPreview(from: $0) }
    }

    // MARK: - 캐시 관리
    /// 특정 상인의 캐시를 무효화
    func invalidateCache(for merchantId: String) {
        cachedInventories.removeValue(forKey: merchantId)
        cachedRelationships.removeValue(forKey: merchantId)
    }

    /// 모든 캐시를 무효화
    func invalidateAllCache() {
        cachedInventories.removeAll()
        cachedRelationships.removeAll()
    }

    // MARK: - 실시간 업데이트
    /// WebSocket을 통한 실시간 인벤토리 업데이트 수신
    func startRealtimeUpdates() {
        // TODO: WebSocket 연결 및 실시간 업데이트 처리
        // 현재는 NetworkManager의 WebSocket 기능 활용
    }
}

// MARK: - 응답 모델들
struct MerchantDetailResponse: Codable {
    let id: String
    let name: String
    let title: String?
    let type: String
    let personality: String
    let district: String
    let location: LocationResponse
    let requiredLicense: Int
    let reputationRequirement: Int
    let priceModifier: Double
    let negotiationDifficulty: Int
    let lastRestocked: String
    let preferredCategories: [String]
    let dislikedCategories: [String]
    let inventory: [InventoryItemResponse]
    let relationship: RelationshipResponse
}

struct InventoryItemResponse: Codable {
    let id: String
    let itemTemplateId: String
    let name: String
    let category: String
    let grade: Int
    let basePrice: Int
    let currentPrice: Int
    let quantity: Int
    let weight: Double
    let description: String
    let iconId: Int
    let requiredLicense: Int
    let lastUpdated: String
}

struct RelationshipResponse: Codable {
    let friendshipPoints: Int
    let trustLevel: Int
    let totalTrades: Int
    let totalSpent: Int
    let lastInteraction: String?
    let notes: String?
}

struct LocationResponse: Codable {
    let lat: Double
    let lng: Double
}

/// 근처 상인 미리보기 정보 (지도용)
struct MerchantPreview: Identifiable {
    let id: String
    let name: String
    let title: String?
    let type: MerchantType
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    let distance: Double
    let canTrade: Bool
    let inventoryCount: Int

    var distanceText: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }

    var statusEmoji: String {
        if !canTrade {
            return "🔒"
        } else if inventoryCount == 0 {
            return "📦"
        } else {
            return "💼"
        }
    }
}

struct NearbyMerchantsResponse: Codable {
    let merchants: [MerchantPreviewResponse]
    let total: Int
}

struct MerchantPreviewResponse: Codable {
    let id: String
    let name: String
    let title: String?
    let type: String
    let district: String
    let location: LocationResponse
    let distance: Int
    let canTrade: Bool
    let requiredLicense: Int
    let reputationRequirement: Int
    let priceModifier: Double
    let negotiationDifficulty: Int
    let inventoryCount: Int
    let lastRestocked: String
}



extension MerchantPreview {
    init(from response: MerchantPreviewResponse) {
        self.init(
            id: response.id,
            name: response.name,
            title: response.title,
            type: MerchantType(rawValue: response.type) ?? .retail,
            district: SeoulDistrict(rawValue: response.district) ?? .jongno,
            coordinate: CLLocationCoordinate2D(
                latitude: response.location.lat,
                longitude: response.location.lng
            ),
            distance: Double(response.distance),
            canTrade: response.canTrade,
            inventoryCount: response.inventoryCount
        )
    }
}

// MARK: - 에러 타입
enum MerchantDataError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case merchantNotFound
    case cacheError
    case tradeValidationFailed(String)
    case tradeExecutionFailed(String)
    case insufficientFunds
    case insufficientItems

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .invalidResponse:
            return "서버 응답이 유효하지 않습니다"
        case .merchantNotFound:
            return "상인을 찾을 수 없습니다"
        case .cacheError:
            return "캐시 처리 중 오류가 발생했습니다"
        case .tradeValidationFailed(let message):
            return "거래 검증 실패: \(message)"
        case .tradeExecutionFailed(let message):
            return "거래 실행 실패: \(message)"
        case .insufficientFunds:
            return "보유 금액이 부족합니다"
        case .insufficientItems:
            return "보유 아이템이 부족합니다"
        }
    }
}

// MARK: - MerchantDetailResponse Extensions
extension MerchantDetailResponse {
    /// 서버 문자열을 MerchantType enum으로 변환
    var merchantType: MerchantType {
        return MerchantType(rawValue: type) ?? .retail
    }

    /// 서버 문자열을 PersonalityType enum으로 변환
    var personalityType: PersonalityType {
        return PersonalityType(rawValue: personality) ?? .balanced
    }

    /// 서버 문자열을 SeoulDistrict enum으로 변환
    var seoulDistrict: SeoulDistrict {
        return SeoulDistrict(rawValue: district) ?? .jung
    }

    /// 서버 location을 CLLocationCoordinate2D로 변환
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
    }

    /// 서버 정수를 LicenseLevel enum으로 변환
    var licenseLevel: LicenseLevel {
        return LicenseLevel(rawValue: requiredLicense) ?? .beginner
    }

    /// 표시용 제목 (MerchantProfile과 동일한 인터페이스)
    var displayTitle: String {
        return title ?? merchantType.displayName
    }

    /// 접근성 설명 (MerchantProfile과 동일한 인터페이스)
    var accessibilityDescription: String {
        let licenseText = licenseLevel == .beginner ? "누구나" : "\(licenseLevel.displayName) 이상"
        return "\(name), \(displayTitle), \(seoulDistrict.displayName), \(licenseText) 거래 가능"
    }
}
