// 📁 ViewModels/MerchantDetailViewModel.swift - 상인 상세 뷰모델
import Foundation
import SwiftUI
import Combine

/// MerchantDetailView를 위한 통합 뷰모델
/// 하드코딩된 sampleItems를 대체하여 실시간 서버 데이터 활용
@MainActor
class MerchantDetailViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var merchantDetail: MerchantDetailResponse?
    @Published var inventory: [TradeItem] = []
    @Published var relationship: MerchantRelationship?
    @Published var currentDialogue: String = ""
    @Published var isLoading = false
    @Published var error: MerchantDataError?

    // MARK: - UI State
    @Published var currentMode: MerchantInteractionMode = .dialogue
    @Published var selectedTradeType: TradeType = .buy
    @Published var showQuantityPopup = false
    @Published var selectedItem: TradeItem?
    @Published var showCartDetail = false
    @Published var showPurchaseConfirmation = false

    // MARK: - 대화 상태
    @Published var displayedText = ""
    @Published var isTypingComplete = false
    @Published var showNextArrow = false
    @Published var currentDialogueIndex = 0

    // MARK: - Dependencies
    private let dataManager = MerchantDataManager.shared
    private let dialogueManager = DialogueDataManager.shared
    private var cartManager = CartManager()
    private let gameManager = GameManager.shared

    private var cancellables = Set<AnyCancellable>()
    private var currentMerchantId: String?

    // MARK: - Computed Properties
    var playerInventory: [TradeItem] {
        return gameManager.currentPlayer?.inventory.inventory ?? []
    }

    var canTrade: Bool {
        guard let profile = merchantDetail else { return false }
        guard let player = gameManager.currentPlayer else { return false }

        // TODO: 플레이어 라이센스/평판 확인
        // 기본 거래 가능성 체크
        return player.core.money > 0 && player.core.currentLicense.rawValue >= 0
    }

    // MARK: - 초기화
    init() {
        setupBindings()
    }

    func attachCartManager(_ manager: CartManager) {
        self.cartManager = manager
    }

    private func setupBindings() {
        // 에러 발생 시 로딩 상태 해제
        $error
            .sink { [weak self] error in
                if error != nil {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)

        // 플레이어 인벤토리 변경 감지
        gameManager.$currentPlayer
            .compactMap { $0?.inventory.inventory }
            .sink { [weak self] _ in
                // UI 업데이트 트리거
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - 상인 데이터 로딩
    /// 상인 정보를 서버에서 로딩 (하드코딩 대체)
    /// - Parameter merchantId: 상인 ID
    func loadMerchant(id: String) async {
        guard currentMerchantId != id else { return }

        isLoading = true
        error = nil
        currentMerchantId = id

        do {
            // 병렬로 데이터 로딩
            async let detail = dataManager.fetchMerchantDetail(merchantId: id)
            async let inventory = dataManager.fetchMerchantInventory(merchantId: id)
            async let relationship = dataManager.fetchMerchantRelationship(merchantId: id)

            // 결과 받기
            let (loadedDetail, loadedInventory, loadedRelationship) = try await (detail, inventory, relationship)

            // UI 업데이트
            self.merchantDetail = loadedDetail
            self.inventory = loadedInventory
            self.relationship = loadedRelationship

            // 초기 대화 설정
            startDialogue()

            isLoading = false

        } catch {
            self.error = .networkError(error)
            isLoading = false
        }
    }

    // MARK: - 대화 시스템
    /// 대화 시작 (JSON 및 컨텍스트 기반 시스템)
    func startDialogue() {
        guard let merchantId = merchantDetail?.id else { return }

        Task {
            let greeting = await dialogueManager.getDialogue(
                merchantId: merchantId,
                category: .greeting,
                context: createDialogueContext()
            )

            await MainActor.run {
                startTypingAnimation(text: greeting)
            }
        }
    }

    func continueDialogue() {
        guard let merchantId = merchantDetail?.id else { return }

        Task {
            let dialogue = await dialogueManager.getDialogue(
                merchantId: merchantId,
                category: .trading,
                context: createDialogueContext()
            )

            await MainActor.run {
                startTypingAnimation(text: dialogue)
            }
        }
    }

    func showThankYouDialogue() {
        guard let merchantId = merchantDetail?.id else { return }

        Task {
            let farewell = await dialogueManager.getDialogue(
                merchantId: merchantId,
                category: .goodbye,
                context: createDialogueContext()
            )

            await MainActor.run {
                startTypingAnimation(text: farewell)
            }
        }
    }

    // MARK: - 대화 컨텍스트 생성
    private func createDialogueContext() -> DialogueContext {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let timeOfDay = {
            switch currentHour {
            case 6..<12: return "morning"
            case 12..<18: return "afternoon"
            case 18..<22: return "evening"
            default: return "night"
            }
        }()

        return DialogueContext(
            playerRelationshipLevel: relationship?.friendshipPoints ?? 0,
            timeOfDay: timeOfDay,
            lastInteractionTime: relationship?.lastInteraction,
            currentMood: nil, // MerchantRelationship에 mood 필드 없음
            recentPurchases: [] // TODO: 최근 구매 이력 - TradeHistory에서 가져오기
        )
    }

    func startTrading() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentMode = .trading
        }
    }

    func closeDialogue() {
        // 부모 뷰에서 처리
    }

    // MARK: - 타이핑 애니메이션
    private func startTypingAnimation(text: String) {
        displayedText = ""
        isTypingComplete = false
        showNextArrow = false

        let words = text.split(separator: " ").map(String.init)
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if currentIndex < words.count {
                if currentIndex == 0 {
                    self.displayedText = words[currentIndex]
                } else {
                    self.displayedText += " " + words[currentIndex]
                }
                currentIndex += 1
            } else {
                timer.invalidate()
                self.isTypingComplete = true
                self.showNextArrow = true
            }
        }
    }

    // MARK: - 아이템 관리
    /// 상인 인벤토리 아이템 선택
    func selectMerchantItem(_ item: TradeItem) {
        selectedItem = item
        showQuantityPopup = true
    }

    /// 플레이어 인벤토리 아이템 선택
    func selectPlayerItem(_ item: TradeItem) {
        selectedItem = item
        showQuantityPopup = true
    }

    /// 장바구니에 아이템 추가
    func addToCart(item: TradeItem, quantity: Int) {
        // 판매 시 플레이어 인벤토리 확인
        if selectedTradeType == .sell {
            let availableQuantity = playerInventory.first { $0.id == item.id }?.quantity ?? 0
            guard quantity <= availableQuantity else {
                error = .insufficientItems
                return
            }
        }

        // 구매 시 플레이어 자금 확인
        if selectedTradeType == .buy {
            let totalCost = item.basePrice * quantity
            let playerMoney = gameManager.currentPlayer?.core.money ?? 0
            guard totalCost <= playerMoney else {
                error = .insufficientFunds
                return
            }
        }

        cartManager.addItem(item, quantity: quantity, type: selectedTradeType)
        showQuantityPopup = false
        selectedItem = nil
    }

    // MARK: - 거래 잠금 정보
    struct TradeLockInfo {
        let isLocked: Bool
        let reason: String?
    }

    /// 아이템별 거래 가능 여부와 잠금 사유를 계산
    func tradeLockInfo(for item: TradeItem) -> TradeLockInfo {
        let playerLicense = gameManager.currentPlayer?.core.currentLicense ?? .beginner

        if item.requiredLicense.rawValue > playerLicense.rawValue {
            return TradeLockInfo(
                isLocked: true,
                reason: "허가증 레벨이 부족합니다."
            )
        }

        return TradeLockInfo(isLocked: false, reason: nil)
    }

    /// 거래 실행
    func executeTrade() async {
        guard !cartManager.items.isEmpty else { return }
        guard let merchantId = currentMerchantId else { return }

        isLoading = true

        do {
            // 거래 유효성 검증
            let playerMoney = gameManager.currentPlayer?.core.money ?? 0
            let validation = TradeManager.shared.validateTrade(
                cartItems: cartManager.items,
                playerMoney: playerMoney,
                playerInventory: playerInventory
            )

            guard validation.isValid else {
                self.error = .tradeValidationFailed(validation.message)
                isLoading = false
                return
            }

            // 서버에 거래 요청 전송
            let tradeResult = try await TradeManager.shared.executeTrade(
                with: merchantId,
                cartItems: cartManager.items
            )

            if tradeResult.success {
                // 거래 성공 시 플레이어 데이터 갱신
                await gameManager.refreshPlayerData()

                // 상인 인벤토리 갱신
                inventory = try await dataManager.fetchMerchantInventory(merchantId: merchantId)

                // 장바구니 비우기
                cartManager.clearCart()
                showPurchaseConfirmation = true

                // 성공 피드백
                TradeManager.shared.triggerSuccessHaptic()
            } else {
                self.error = .tradeExecutionFailed(tradeResult.message)
            }

        } catch {
            self.error = .networkError(error)
        }

        isLoading = false
    }

    // MARK: - 에러 처리
    func clearError() {
        error = nil
    }

    func retryLoading() {
        guard let merchantId = currentMerchantId else { return }
        Task {
            await loadMerchant(id: merchantId)
        }
    }
}
