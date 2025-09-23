// 📁 ViewModels/MerchantDetailViewModel.swift - 상인 상세 뷰모델
import Foundation
import SwiftUI
import Combine

/// MerchantDetailView를 위한 통합 뷰모델
/// 하드코딩된 sampleItems를 대체하여 실시간 서버 데이터 활용
@MainActor
class MerchantDetailViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var merchantProfile: MerchantProfile?
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
    @StateObject private var cartManager = CartManager()

    private var cancellables = Set<AnyCancellable>()
    private var currentMerchantId: String?

    // MARK: - Computed Properties
    var playerInventory: [TradeItem] {
        // TODO: GameManager에서 플레이어 인벤토리 가져오기
        return []
    }

    var canTrade: Bool {
        guard let profile = merchantProfile else { return false }
        // TODO: 플레이어 라이센스/평판 확인
        return true
    }

    // MARK: - 초기화
    init() {
        setupBindings()
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
            async let profile = dataManager.fetchMerchantProfile(merchantId: id)
            async let inventory = dataManager.fetchMerchantInventory(merchantId: id)
            async let relationship = dataManager.fetchMerchantRelationship(merchantId: id)

            // 결과 받기
            let (loadedProfile, loadedInventory, loadedRelationship) = try await (profile, inventory, relationship)

            // UI 업데이트
            self.merchantProfile = loadedProfile
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
        guard let merchantId = merchantProfile?.id else { return }

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
        guard let merchantId = merchantProfile?.id else { return }

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
            lastInteractionTime: nil, // TODO: 실제 마지막 상호작용 시간
            currentMood: nil,
            recentPurchases: [] // TODO: 최근 구매 이력
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
        cartManager.addItem(item, quantity: quantity, type: selectedTradeType)
        showQuantityPopup = false
        selectedItem = nil
    }

    /// 거래 실행
    func executeTrade() async {
        guard !cartManager.items.isEmpty else { return }

        isLoading = true

        do {
            // TODO: 서버에 거래 요청 전송
            // let tradeResult = try await TradeManager.shared.executeTrade(cartManager.items)

            // 성공 시 인벤토리 갱신
            if let merchantId = currentMerchantId {
                inventory = try await dataManager.fetchMerchantInventory(merchantId: merchantId)
            }

            // 장바구니 비우기
            cartManager.clearCart()
            showPurchaseConfirmation = true

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


// MARK: - 에러 타입
enum MerchantDataError: LocalizedError {
    case networkError(Error)
    case invalidData
    case merchantNotFound
    case tradeFailed

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .invalidData:
            return "데이터가 유효하지 않습니다"
        case .merchantNotFound:
            return "상인을 찾을 수 없습니다"
        case .tradeFailed:
            return "거래에 실패했습니다"
        }
    }
}