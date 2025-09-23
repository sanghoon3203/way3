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
    @Published var cachedMerchants: [String: MerchantProfile] = [:]
    @Published var cachedInventories: [String: [TradeItem]] = [:]
    @Published var cachedRelationships: [String: MerchantRelationship] = [:]

    // MARK: - Dependencies
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 상인 프로필 조회
    /// 상인 기본 정보를 서버에서 가져옴
    /// - Parameter merchantId: 상인 ID
    /// - Returns: 상인 프로필 정보
    func fetchMerchantProfile(merchantId: String) async throws -> MerchantProfile {
        // 캐시 확인
        if let cached = cachedMerchants[merchantId] {
            return cached
        }

        // 서버에서 가져오기
        let response = try await networkManager.getMerchantDetail(merchantId: merchantId)

        let profile = MerchantProfile(from: response)

        // 캐시 저장
        cachedMerchants[merchantId] = profile

        return profile
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

        let relationship = MerchantRelationship(from: response.relationship)

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
        cachedMerchants.removeValue(forKey: merchantId)
        cachedInventories.removeValue(forKey: merchantId)
        cachedRelationships.removeValue(forKey: merchantId)
    }

    /// 모든 캐시를 무효화
    func invalidateAllCache() {
        cachedMerchants.removeAll()
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
    let inventoryCount: Int
}

// MARK: - 모델 변환 확장
extension MerchantProfile {
    init(from response: MerchantDetailResponse) {
        self.init(
            id: response.id,
            name: response.name,
            title: response.title,
            type: MerchantType(rawValue: response.type) ?? .retail,
            personality: PersonalityType(rawValue: response.personality) ?? .calm,
            district: SeoulDistrict(rawValue: response.district) ?? .jongno,
            coordinate: CLLocationCoordinate2D(
                latitude: response.location.lat,
                longitude: response.location.lng
            ),
            requiredLicense: LicenseLevel(rawValue: response.requiredLicense) ?? .beginner,
            reputationRequirement: response.reputationRequirement,
            priceModifier: response.priceModifier,
            negotiationDifficulty: response.negotiationDifficulty,
            preferredCategories: response.preferredCategories,
            dislikedCategories: response.dislikedCategories
        )
    }
}

extension MerchantRelationship {
    init(from response: RelationshipResponse) {
        self.init(
            friendshipPoints: response.friendshipPoints,
            trustLevel: response.trustLevel,
            totalTrades: response.totalTrades,
            totalSpent: response.totalSpent,
            lastInteraction: response.lastInteraction,
            notes: response.notes
        )
    }
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
        }
    }
}