// 📁 Core/DialogueDataManager.swift - 대화 데이터 관리자
import Foundation
import Combine
import CoreLocation

// MARK: - Local MerchantProfile for AI compatibility
struct MerchantProfile {
    let id: String
    let name: String
    let title: String?
    let type: MerchantType
    let personality: PersonalityType
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    let requiredLicense: LicenseLevel
    let reputationRequirement: Int
    let priceModifier: Double
    let preferredCategories: [String]
    let dislikedCategories: [String]

    init(
        id: String,
        name: String,
        title: String? = nil,
        type: MerchantType,
        personality: PersonalityType,
        district: SeoulDistrict,
        coordinate: CLLocationCoordinate2D,
        requiredLicense: LicenseLevel = .beginner,
        reputationRequirement: Int = 0,
        priceModifier: Double = 1.0,
        preferredCategories: [String] = [],
        dislikedCategories: [String] = []
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.type = type
        self.personality = personality
        self.district = district
        self.coordinate = coordinate
        self.requiredLicense = requiredLicense
        self.reputationRequirement = reputationRequirement
        self.priceModifier = priceModifier
        self.preferredCategories = preferredCategories
        self.dislikedCategories = dislikedCategories
    }
}

/// JSON 및 서버 대화 데이터를 통합 관리하는 매니저
/// Phase 3: 로컬 JSON 대화 + 향후 AI 확장 준비
@MainActor
class DialogueDataManager: ObservableObject {

    // MARK: - Singleton
    static let shared = DialogueDataManager()
    private init() {}

    // MARK: - Published Properties
    @Published var cachedDialogues: [String: MerchantDialogueSet] = [:]
    @Published var isLoading = false
    @Published var lastError: DialogueError?

    // MARK: - Dependencies
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 대화 데이터 로딩
    /// 상인의 대화 데이터를 로컬 JSON 또는 서버에서 가져옴
    /// - Parameter merchantId: 상인 ID
    /// - Returns: 대화 세트
    func fetchDialogues(for merchantId: String) async throws -> MerchantDialogueSet {
        // 캐시 확인
        if let cached = cachedDialogues[merchantId] {
            return cached
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // 1. 로컬 JSON에서 대화 로딩 시도
            if let localDialogues = loadLocalDialogues(merchantId: merchantId) {
                cachedDialogues[merchantId] = localDialogues
                return localDialogues
            }

            // 2. 서버에서 대화 데이터 가져오기
            let serverDialogues = try await loadServerDialogues(merchantId: merchantId)
            cachedDialogues[merchantId] = serverDialogues
            return serverDialogues

        } catch {
            lastError = .loadingFailed(error)
            throw error
        }
    }

    // MARK: - 로컬 JSON 대화 로딩
    private func loadLocalDialogues(merchantId: String) -> MerchantDialogueSet? {
        // Resources/Merchant/{merchantId}/{merchantId}.json 경로
        guard let path = Bundle.main.path(forResource: merchantId, ofType: "json", inDirectory: "Merchant/\(merchantId.capitalized)"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let npcs = jsonData["npcs"] as? [String: Any],
              let npcData = npcs[merchantId] as? [String: Any] else {
            return nil
        }

        // 대화 데이터 추출
        let dialogues = npcData["dialogue"] as? [String] ?? []
        let profile = npcData["profile"] as? String ?? ""

        return MerchantDialogueSet(
            merchantId: merchantId,
            merchantName: npcData["name"] as? String ?? merchantId,
            dialogues: [
                "greeting": dialogues,
                "trading": generateTradingDialogues(from: profile),
                "goodbye": ["또 오세요!", "좋은 하루 되세요!"],
                "relationship": generateRelationshipDialogues(from: profile)
            ],
            personality: extractPersonality(from: profile),
            lastUpdated: Date()
        )
    }

    // MARK: - 서버 대화 로딩
    private func loadServerDialogues(merchantId: String) async throws -> MerchantDialogueSet {
        // 서버 API에서 대화 데이터 가져오기
        let response = try await networkManager.getMerchantDialogues(merchantId: merchantId)

        return MerchantDialogueSet(
            merchantId: merchantId,
            merchantName: response.merchantName,
            dialogues: response.dialogues,
            personality: response.personality,
            lastUpdated: Date()
        )
    }

    // MARK: - 상황별 대화 생성
    func getDialogue(
        merchantId: String,
        category: DialogueCategory,
        context: DialogueContext? = nil,
        useAI: Bool = false
    ) async -> String {
        do {
            let dialogueSet = try await fetchDialogues(for: merchantId)

            return selectAppropriateDialogue(
                from: dialogueSet,
                category: category,
                context: context
            )
        } catch {
            return getFallbackDialogue(category: category)
        }
    }

    // MARK: - 헬퍼 메서드
    private func selectAppropriateDialogue(
        from dialogueSet: MerchantDialogueSet,
        category: DialogueCategory,
        context: DialogueContext?
    ) -> String {
        let categoryDialogues = dialogueSet.dialogues[category.rawValue] ?? []

        if categoryDialogues.isEmpty {
            return getFallbackDialogue(category: category)
        }

        // 컨텍스트 기반 대화 선택 (향후 AI 확장 지점)
        if let context = context {
            return selectContextualDialogue(
                from: categoryDialogues,
                context: context,
                personality: dialogueSet.personality
            )
        }

        // 랜덤 선택
        return categoryDialogues.randomElement() ?? getFallbackDialogue(category: category)
    }

    private func selectContextualDialogue(
        from dialogues: [String],
        context: DialogueContext,
        personality: String
    ) -> String {
        // 현재는 단순 랜덤, 향후 AI 기반 선택으로 확장
        // TODO: AI 모델을 통한 컨텍스트 기반 대화 선택
        return dialogues.randomElement() ?? getFallbackDialogue(category: .greeting)
    }   

    // MARK: - 대화 생성 헬퍼
    private func generateTradingDialogues(from profile: String) -> [String] {
        var dialogues = ["무엇을 도와드릴까요?", "어떤 상품을 찾고 계신가요?"]

        if profile.contains("검") || profile.contains("무기") {
            dialogues.append("좋은 무기를 찾고 계신군요.")
        }
        if profile.contains("커피") {
            dialogues.append("신선한 원두로 내린 커피는 어떠세요?")
        }
        if profile.contains("경매") || profile.contains("아레나") {
            dialogues.append("특별한 상품들을 준비해뒀습니다.")
        }

        return dialogues
    }

    private func generateRelationshipDialogues(from profile: String) -> [String] {
        return [
            "항상 감사합니다!",
            "좋은 거래 관계를 이어가요.",
            "믿을 만한 고객이시군요."
        ]
    }

    private func extractPersonality(from profile: String) -> String {
        if profile.contains("차가운") { return "cold" }
        if profile.contains("젊은") { return "energetic" }
        if profile.contains("친절") { return "friendly" }
        return "neutral"
    }

    private func getFallbackDialogue(category: DialogueCategory) -> String {
        switch category {
        case .greeting:
            return "안녕하세요! 어서 오세요!"
        case .trading:
            return "무엇을 도와드릴까요?"
        case .goodbye:
            return "또 오세요!"
        case .relationship:
            return "항상 감사합니다!"
        case .special:
            return "특별한 상품이 있어요!"
        }
    }

    // MARK: - 캐시 관리
    func invalidateCache(for merchantId: String) {
        cachedDialogues.removeValue(forKey: merchantId)
    }

    func invalidateAllCache() {
        cachedDialogues.removeAll()
    }
}

// MARK: - 대화 모델
struct MerchantDialogueSet {
    let merchantId: String
    let merchantName: String
    let dialogues: [String: [String]]  // category -> dialogues
    let personality: String
    let lastUpdated: Date
}

struct DialogueContext {
    let playerRelationshipLevel: Int
    let timeOfDay: String
    let lastInteractionTime: String?
    let currentMood: String?
    let recentPurchases: [String]

    init(
        playerRelationshipLevel: Int = 0,
        timeOfDay: String = "morning",
        lastInteractionTime: String? = nil,
        currentMood: String? = nil,
        recentPurchases: [String] = []
    ) {
        self.playerRelationshipLevel = playerRelationshipLevel
        self.timeOfDay = timeOfDay
        self.lastInteractionTime = lastInteractionTime
        self.currentMood = currentMood
        self.recentPurchases = recentPurchases
    }
}

enum DialogueCategory: String, CaseIterable {
    case greeting = "greeting"
    case trading = "trading"
    case goodbye = "goodbye"
    case relationship = "relationship"
    case special = "special"
}

enum DialogueError: LocalizedError {
    case loadingFailed(Error)
    case invalidData
    case networkError

    var errorDescription: String? {
        switch self {
        case .loadingFailed(let error):
            return "대화 로딩 실패: \(error.localizedDescription)"
        case .invalidData:
            return "대화 데이터가 유효하지 않습니다"
        case .networkError:
            return "네트워크 오류가 발생했습니다"
        }
    }
}

// MARK: - NetworkManager 확장
extension NetworkManager {
    func getMerchantDialogues(merchantId: String) async throws -> MerchantDialogueResponse {
        return try await makeRequest(
            endpoint: "/merchants/\(merchantId)/dialogues",
            requiresAuth: true,
            responseType: MerchantDialogueResponse.self,
            useCache: true
        )
    }
}

struct MerchantDialogueResponse: Codable {
    let merchantId: String
    let merchantName: String
    let dialogues: [String: [String]]
    let personality: String
    let lastUpdated: String
}
