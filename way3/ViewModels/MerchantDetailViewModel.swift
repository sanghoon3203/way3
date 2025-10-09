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
    @Published var isLoading = false
    @Published var error: MerchantDataError?

    // MARK: - UI State
    @Published var selectedTradeType: TradeType = .buy

    // MARK: - Dependencies
    private let dataManager = MerchantDataManager.shared
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

            isLoading = false

        } catch {
            self.error = .networkError(error)
            isLoading = false
        }
    }

    func refreshMerchantData() async {
        guard let merchantId = currentMerchantId else { return }

        do {
            async let detail = dataManager.fetchMerchantDetail(merchantId: merchantId)
            async let inventoryItems = dataManager.fetchMerchantInventory(merchantId: merchantId)
            async let relationshipInfo = dataManager.fetchMerchantRelationship(merchantId: merchantId)

            let (loadedDetail, loadedInventory, loadedRelationship) = try await (detail, inventoryItems, relationshipInfo)

            await MainActor.run {
                self.merchantDetail = loadedDetail
                self.inventory = loadedInventory
                self.relationship = loadedRelationship
            }
        } catch {
            await MainActor.run { self.error = .networkError(error) }
        }
    }

    // MARK: - 아이템 관리
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
