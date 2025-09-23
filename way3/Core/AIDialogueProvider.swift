// 📁 Core/AIDialogueProvider.swift - AI 대화 공급자 인터페이스
import Foundation
import Combine

/// AI 기반 대화 생성을 위한 확장 가능한 인터페이스
/// Phase 4: 온디바이스 AI 및 클라우드 AI 통합 준비
protocol AIDialogueProvider {
    /// AI 모델 타입
    var modelType: AIModelType { get }

    /// 모델 준비 상태
    var isReady: Bool { get async }

    /// 컨텍스트 기반 대화 생성
    func generateDialogue(
        context: AIDialogueContext
    ) async throws -> AIDialogueResponse

    /// 대화 스타일 분석 및 적용
    func analyzeDialogueStyle(
        samples: [String],
        personality: String
    ) async throws -> DialogueStyleProfile

    /// 모델 초기화
    func initialize() async throws

    /// 리소스 정리
    func cleanup() async
}

// MARK: - AI 모델 타입
enum AIModelType: String, CaseIterable {
    case onDevice = "on_device"           // 온디바이스 AI
    case openAI = "openai"               // OpenAI GPT
    case anthropic = "anthropic"         // Claude API
    case local = "local"                 // 로컬 LLM 서버
    case hybrid = "hybrid"               // 하이브리드 모드

    var displayName: String {
        switch self {
        case .onDevice: return "온디바이스 AI"
        case .openAI: return "OpenAI GPT"
        case .anthropic: return "Claude"
        case .local: return "로컬 LLM"
        case .hybrid: return "하이브리드"
        }
    }

    var requiresNetwork: Bool {
        switch self {
        case .onDevice: return false
        case .openAI, .anthropic: return true
        case .local: return false
        case .hybrid: return false  // 온디바이스 우선, 필요시 네트워크
        }
    }
}

// MARK: - AI 대화 컨텍스트
struct AIDialogueContext {
    let merchantProfile: MerchantProfile
    let playerContext: PlayerDialogueContext
    let situationContext: SituationContext
    let relationshipContext: RelationshipContext
    let environmentContext: EnvironmentContext

    /// JSON 대화 샘플 (학습용)
    let existingDialogues: [String]

    /// 요청된 대화 카테고리
    let requestedCategory: DialogueCategory

    /// 이전 대화 이력
    let conversationHistory: [DialogueTurn]
}

struct PlayerDialogueContext {
    let playerName: String
    let playerLevel: Int
    let playerReputation: Int
    let recentActions: [String]
    let preferredStyle: String?
}

struct SituationContext {
    let currentAction: DialogueAction
    let urgency: DialogueUrgency
    let mood: String?
    let constraints: [String]
}

struct RelationshipContext {
    let friendshipLevel: Int
    let trustLevel: Int
    let sharedHistory: [String]
    let lastInteraction: Date?
}

struct EnvironmentContext {
    let timeOfDay: String
    let weather: String?
    let crowdLevel: String
    let marketConditions: String?
}

struct DialogueTurn {
    let speaker: String
    let message: String
    let timestamp: Date
    let emotion: String?
}

enum DialogueAction: String, CaseIterable {
    case greeting, trading, negotiating, leaving, browsing, questioning
}

enum DialogueUrgency: String, CaseIterable {
    case low, normal, high, urgent
}

// MARK: - AI 응답 모델
struct AIDialogueResponse {
    let generatedText: String
    let confidence: Double
    let emotion: String?
    let suggestedActions: [String]
    let metadata: AIResponseMetadata
}

struct AIResponseMetadata {
    let modelUsed: AIModelType
    let processingTime: TimeInterval
    let tokens: Int?
    let fallbackUsed: Bool
}

struct DialogueStyleProfile {
    let personality: String
    let speechPatterns: [String]
    let vocabulary: [String]
    let emotionalRange: [String]
    let communicationStyle: String
}

// MARK: - AI 대화 매니저
@MainActor
class AIDialogueManager: ObservableObject {

    // MARK: - Published Properties
    @Published var currentProvider: AIDialogueProvider?
    @Published var availableProviders: [AIModelType] = []
    @Published var isInitializing = false
    @Published var lastError: AIDialogueError?

    // MARK: - Private Properties
    private var providers: [AIModelType: AIDialogueProvider] = [:]
    private let configuration: AIConfiguration

    // MARK: - 초기화
    init(configuration: AIConfiguration = .default) {
        self.configuration = configuration
        setupProviders()
    }

    private func setupProviders() {
        // 온디바이스 AI 준비
        if configuration.enableOnDevice {
            providers[.onDevice] = OnDeviceAIProvider()
        }

        // 클라우드 AI 준비
        if let openAIKey = configuration.openAIKey {
            providers[.openAI] = OpenAIProvider(apiKey: openAIKey)
        }

        if let anthropicKey = configuration.anthropicKey {
            providers[.anthropic] = AnthropicProvider(apiKey: anthropicKey)
        }

        // 하이브리드 모드
        if configuration.enableHybrid {
            providers[.hybrid] = HybridAIProvider(
                primary: providers[.onDevice],
                fallback: providers[.openAI] ?? providers[.anthropic]
            )
        }

        availableProviders = Array(providers.keys)
    }

    // MARK: - AI 기반 대화 생성
    func generateAIDialogue(
        context: AIDialogueContext,
        preferredModel: AIModelType? = nil
    ) async throws -> AIDialogueResponse {

        let modelType = preferredModel ?? configuration.defaultModel

        guard let provider = providers[modelType] else {
            throw AIDialogueError.providerNotAvailable(modelType)
        }

        // 모델 준비 확인
        guard await provider.isReady else {
            isInitializing = true
            defer { isInitializing = false }
            try await provider.initialize()
        }

        do {
            let response = try await provider.generateDialogue(context: context)
            lastError = nil
            return response
        } catch {
            lastError = .generationFailed(error)

            // 폴백 전략
            if modelType != .hybrid, let fallbackProvider = providers[.hybrid] {
                return try await fallbackProvider.generateDialogue(context: context)
            }

            throw error
        }
    }

    // MARK: - 대화 스타일 분석
    func analyzeExistingDialogues(
        merchantId: String,
        dialogues: [String],
        personality: String
    ) async throws -> DialogueStyleProfile {

        guard let provider = currentProvider ?? providers[configuration.defaultModel] else {
            throw AIDialogueError.noProviderSelected
        }

        return try await provider.analyzeDialogueStyle(
            samples: dialogues,
            personality: personality
        )
    }

    // MARK: - 공급자 전환
    func switchProvider(to modelType: AIModelType) async throws {
        guard let provider = providers[modelType] else {
            throw AIDialogueError.providerNotAvailable(modelType)
        }

        currentProvider = provider

        if !await provider.isReady {
            isInitializing = true
            defer { isInitializing = false }
            try await provider.initialize()
        }
    }

    // MARK: - 리소스 정리
    func cleanup() async {
        for provider in providers.values {
            await provider.cleanup()
        }
    }
}

// MARK: - AI 설정
struct AIConfiguration {
    let enableOnDevice: Bool
    let enableCloud: Bool
    let enableHybrid: Bool
    let defaultModel: AIModelType
    let openAIKey: String?
    let anthropicKey: String?
    let maxTokens: Int
    let temperature: Double
    let timeout: TimeInterval

    static let `default` = AIConfiguration(
        enableOnDevice: true,
        enableCloud: false,  // 기본적으로 비활성화
        enableHybrid: true,
        defaultModel: .hybrid,
        openAIKey: nil,
        anthropicKey: nil,
        maxTokens: 150,
        temperature: 0.7,
        timeout: 30.0
    )

    /// 환경변수에서 설정 로드
    static func fromEnvironment() -> AIConfiguration {
        return AIConfiguration(
            enableOnDevice: true,
            enableCloud: ProcessInfo.processInfo.environment["ENABLE_CLOUD_AI"] == "true",
            enableHybrid: true,
            defaultModel: .hybrid,
            openAIKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
            anthropicKey: ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
            maxTokens: Int(ProcessInfo.processInfo.environment["AI_MAX_TOKENS"] ?? "150") ?? 150,
            temperature: Double(ProcessInfo.processInfo.environment["AI_TEMPERATURE"] ?? "0.7") ?? 0.7,
            timeout: Double(ProcessInfo.processInfo.environment["AI_TIMEOUT"] ?? "30.0") ?? 30.0
        )
    }
}

// MARK: - 에러 타입
enum AIDialogueError: LocalizedError {
    case providerNotAvailable(AIModelType)
    case noProviderSelected
    case generationFailed(Error)
    case initializationFailed(Error)
    case configurationError(String)
    case networkError
    case rateLimitExceeded

    var errorDescription: String? {
        switch self {
        case .providerNotAvailable(let type):
            return "\(type.displayName) AI 모델을 사용할 수 없습니다"
        case .noProviderSelected:
            return "AI 공급자가 선택되지 않았습니다"
        case .generationFailed(let error):
            return "대화 생성 실패: \(error.localizedDescription)"
        case .initializationFailed(let error):
            return "AI 모델 초기화 실패: \(error.localizedDescription)"
        case .configurationError(let message):
            return "설정 오류: \(message)"
        case .networkError:
            return "네트워크 연결 오류"
        case .rateLimitExceeded:
            return "API 사용량 한도 초과"
        }
    }
}

// MARK: - 임시 구현체 (향후 실제 구현으로 대체)
class OnDeviceAIProvider: AIDialogueProvider {
    let modelType: AIModelType = .onDevice

    var isReady: Bool {
        get async { true }  // 임시로 항상 준비됨
    }

    func generateDialogue(context: AIDialogueContext) async throws -> AIDialogueResponse {
        // 임시 구현: 기존 대화에서 변형 생성
        let baseDialogue = context.existingDialogues.randomElement() ?? "안녕하세요!"

        return AIDialogueResponse(
            generatedText: "\(baseDialogue) (AI 생성)",
            confidence: 0.8,
            emotion: "friendly",
            suggestedActions: ["continue", "trade"],
            metadata: AIResponseMetadata(
                modelUsed: .onDevice,
                processingTime: 0.1,
                tokens: 20,
                fallbackUsed: false
            )
        )
    }

    func analyzeDialogueStyle(samples: [String], personality: String) async throws -> DialogueStyleProfile {
        return DialogueStyleProfile(
            personality: personality,
            speechPatterns: ["정중한 어조", "친근한 표현"],
            vocabulary: ["어서오세요", "감사합니다"],
            emotionalRange: ["friendly", "professional"],
            communicationStyle: "formal"
        )
    }

    func initialize() async throws {
        // 온디바이스 모델 로딩 로직
    }

    func cleanup() async {
        // 리소스 정리
    }
}

class OpenAIProvider: AIDialogueProvider {
    let modelType: AIModelType = .openAI
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    var isReady: Bool {
        get async { !apiKey.isEmpty }
    }

    func generateDialogue(context: AIDialogueContext) async throws -> AIDialogueResponse {
        // OpenAI API 호출 로직
        throw AIDialogueError.configurationError("OpenAI 구현 필요")
    }

    func analyzeDialogueStyle(samples: [String], personality: String) async throws -> DialogueStyleProfile {
        throw AIDialogueError.configurationError("OpenAI 분석 구현 필요")
    }

    func initialize() async throws {}
    func cleanup() async {}
}

class AnthropicProvider: AIDialogueProvider {
    let modelType: AIModelType = .anthropic
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    var isReady: Bool {
        get async { !apiKey.isEmpty }
    }

    func generateDialogue(context: AIDialogueContext) async throws -> AIDialogueResponse {
        // Anthropic API 호출 로직
        throw AIDialogueError.configurationError("Claude API 구현 필요")
    }

    func analyzeDialogueStyle(samples: [String], personality: String) async throws -> DialogueStyleProfile {
        throw AIDialogueError.configurationError("Claude 분석 구현 필요")
    }

    func initialize() async throws {}
    func cleanup() async {}
}

class HybridAIProvider: AIDialogueProvider {
    let modelType: AIModelType = .hybrid
    private let primaryProvider: AIDialogueProvider?
    private let fallbackProvider: AIDialogueProvider?

    init(primary: AIDialogueProvider?, fallback: AIDialogueProvider?) {
        self.primaryProvider = primary
        self.fallbackProvider = fallback
    }

    var isReady: Bool {
        get async {
            if let primary = primaryProvider {
                return await primary.isReady
            }
            if let fallback = fallbackProvider {
                return await fallback.isReady
            }
            return false
        }
    }

    func generateDialogue(context: AIDialogueContext) async throws -> AIDialogueResponse {
        // 온디바이스 우선 시도
        if let primary = primaryProvider, await primary.isReady {
            do {
                return try await primary.generateDialogue(context: context)
            } catch {
                // 실패시 클라우드 폴백
                if let fallback = fallbackProvider {
                    var response = try await fallback.generateDialogue(context: context)
                    response.metadata = AIResponseMetadata(
                        modelUsed: .hybrid,
                        processingTime: response.metadata.processingTime,
                        tokens: response.metadata.tokens,
                        fallbackUsed: true
                    )
                    return response
                }
                throw error
            }
        }

        // 온디바이스 불가능시 클라우드 직접 사용
        if let fallback = fallbackProvider {
            return try await fallback.generateDialogue(context: context)
        }

        throw AIDialogueError.noProviderSelected
    }

    func analyzeDialogueStyle(samples: [String], personality: String) async throws -> DialogueStyleProfile {
        if let primary = primaryProvider, await primary.isReady {
            return try await primary.analyzeDialogueStyle(samples: samples, personality: personality)
        }

        if let fallback = fallbackProvider {
            return try await fallback.analyzeDialogueStyle(samples: samples, personality: personality)
        }

        throw AIDialogueError.noProviderSelected
    }

    func initialize() async throws {
        try? await primaryProvider?.initialize()
        try? await fallbackProvider?.initialize()
    }

    func cleanup() async {
        await primaryProvider?.cleanup()
        await fallbackProvider?.cleanup()
    }
}