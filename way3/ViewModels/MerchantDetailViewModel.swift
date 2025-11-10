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
    private let permitTierMapping: [String: Int] = [
        "Merchantpermit_1": 1,
        "Merchantpermit_2": 2,
        "Merchantpermit_3": 3,
        "Merchantpermit_4": 4
    ]
    private let gradeCapByTier: [Int: Int] = [
        1: 0,
        2: 1,
        3: 2,
        4: 5
    ]
    private let defaultGradeRequirement: [Int: Int] = [
        0: 1,
        1: 2,
        2: 3,
        3: 4,
        4: 4,
        5: 4
    ]
    private let stageRequirements: [Int: Int] = [
        0: 3,
        1: 3,
        2: 5,
        3: 5,
        4: 0
    ]
    private let maxPermitTier = 4

    // MARK: - Computed Properties
    var playerInventory: [TradeItem] {
        return gameManager.currentPlayer?.inventory.inventory ?? []
    }

    private var accessControl: AccessControlResponse? {
        merchantDetail?.accessControl
    }

    private var gradeRequirementMap: [Int: Int] {
        var requirements = defaultGradeRequirement
        if let serverMap = accessControl?.requiredTierForGrade {
            for (key, value) in serverMap {
                if let grade = Int(key) {
                    requirements[grade] = value
                }
            }
        }
        return requirements
    }

    private var normalizedRelationshipStage: Int {
        if let stage = accessControl?.relationshipStage {
            return stage
        }
        if let trust = relationship?.trustLevel {
            return min(max(trust, 0), 4)
        }
        return 0
    }

    private var resolvedPermitTier: Int {
        let localTier = gameManager.personalItems
            .compactMap { permitTierMapping[$0.itemTemplateId] }
            .max() ?? 0
        if let serverTier = accessControl?.permitTier {
            return max(serverTier, localTier)
        }
        return localTier
    }

    private var permitGradeCap: Int {
        gradeCap(for: resolvedPermitTier)
    }

    private var relationshipGradeCap: Int {
        gradeCap(for: normalizedRelationshipStage)
    }

    private var effectiveMaxGrade: Int {
        guard permitGradeCap >= 0, relationshipGradeCap >= 0 else {
            return -1
        }
        return min(permitGradeCap, relationshipGradeCap)
    }

    var relationshipStage: Int {
        normalizedRelationshipStage
    }

    var stageProgress: Int {
        if let progress = accessControl?.stageProgress {
            return progress
        }
        return relationship?.stageProgress ?? 0
    }

    var stageRequirement: Int {
        if let requirement = accessControl?.stageRequirement {
            return requirement
        }
        return stageRequirements[normalizedRelationshipStage] ?? 0
    }

    var permitTier: Int {
        resolvedPermitTier
    }

    var canUpgradePermit: Bool {
        resolvedPermitTier < maxPermitTier && normalizedRelationshipStage >= resolvedPermitTier + 1
    }

    var tradeEntryRestrictionMessage: String? {
        if normalizedRelationshipStage <= 0 {
            let requirement = stageRequirement(forStage: normalizedRelationshipStage)
            if requirement > 0 {
                return "관계도 1단계를 달성해야 거래가 열립니다. 서브 퀘스트 진행 \(stageProgress)/\(requirement)."
            }
            return "해당 상인과 대화를 진행해야 거래가 열립니다."
        }
        if resolvedPermitTier <= 0 {
            let nextTier = min(maxPermitTier, resolvedPermitTier + 1)
            return "상인 허가증이 필요합니다. 허가증을 Lv.\(nextTier)까지 승급하세요."
        }
        return nil
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

        gameManager.$personalItems
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func ensurePersonalItemsLoaded() async {
        if !gameManager.personalItems.isEmpty {
            return
        }

        if gameManager.personalItemsViewState.isLoading {
            return
        }

        await gameManager.loadPersonalItemsData()
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
            async let personalItemsLoad = ensurePersonalItemsLoaded()
            async let detail = dataManager.fetchMerchantDetail(merchantId: id)
            async let inventory = dataManager.fetchMerchantInventory(merchantId: id)
            async let relationship = dataManager.fetchMerchantRelationship(merchantId: id)

            // 결과 받기
            let (loadedDetail, loadedInventory, loadedRelationship) = try await (detail, inventory, relationship)
            await personalItemsLoad

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
            await ensurePersonalItemsLoaded()
            async let detail = dataManager.fetchMerchantDetail(merchantId: merchantId, forceRefresh: true)
            async let inventoryItems = dataManager.fetchMerchantInventory(merchantId: merchantId, forceRefresh: true)
            async let relationshipInfo = dataManager.fetchMerchantRelationship(merchantId: merchantId, forceRefresh: true)

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
    private func gradeCap(for tier: Int) -> Int {
        guard tier > 0 else { return -1 }
        return gradeCapByTier[tier] ?? -1
    }

    private func requiredTier(for grade: Int) -> Int {
        return gradeRequirementMap[grade] ?? 4
    }

    private func stageRequirement(forStage stage: Int) -> Int {
        if stage == normalizedRelationshipStage, let requirement = accessControl?.stageRequirement {
            return requirement
        }
        return stageRequirements[stage] ?? 0
    }

    func tradeLockInfo(for item: TradeItem) -> TradeLockInfo {
        if let entryMessage = tradeEntryRestrictionMessage {
            return TradeLockInfo(isLocked: true, reason: entryMessage)
        }

        let itemGrade = item.grade.rawValue

        if effectiveMaxGrade >= 0 && itemGrade <= effectiveMaxGrade {
            return .unlocked
        }

        if permitGradeCap < itemGrade {
            let requiredTierLevel = requiredTier(for: itemGrade)
            let currentTier = resolvedPermitTier
            return TradeLockInfo(
                isLocked: true,
                reason: "상인 허가증을 Lv.\(requiredTierLevel)까지 승급해야 거래할 수 있습니다. (현재 Lv.\(currentTier))"
            )
        }

        if relationshipGradeCap < itemGrade {
            let requiredStage = requiredTier(for: itemGrade)
            let requirement = stageRequirement(forStage: normalizedRelationshipStage)
            let progressValue = stageProgress
            let baseMessage = "관계도를 \(requiredStage)단계까지 올려야 거래할 수 있습니다."
            if requirement > 0 {
                let progressText = " 현재 진행 \(progressValue)/\(requirement)."
                return TradeLockInfo(
                    isLocked: true,
                    reason: baseMessage + progressText
                )
            }
            return TradeLockInfo(
                isLocked: true,
                reason: baseMessage
            )
        }

        return TradeLockInfo(isLocked: true, reason: "거래 조건을 충족하지 못했습니다.")
    }

    func upgradePermit(for merchantId: String) async throws -> String {
        do {
            let response = try await dataManager.upgradePermit(merchantId: merchantId)
            guard response.success else {
                let message = response.error ?? response.message ?? "허가증 업그레이드에 실패했습니다."
                throw MerchantDataError.tradeValidationFailed(message)
            }

            await gameManager.loadPersonalItemsData()
            await refreshMerchantData()

            return response.message ?? "상인 허가증이 업그레이드되었습니다."
        } catch let dataError as MerchantDataError {
            throw dataError
        } catch {
            throw MerchantDataError.networkError(error)
        }
    }

    struct TradeLockInfo {
        let isLocked: Bool
        let reason: String?

        static let unlocked = TradeLockInfo(isLocked: false, reason: nil)
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
