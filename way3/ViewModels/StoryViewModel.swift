// 📁 ViewModels/StoryViewModel.swift - 스토리 대화 뷰모델
import Foundation
import SwiftUI

@MainActor
class StoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentNode: StoryNode?
    @Published var merchantName: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var showRewardPopup: Bool = false
    @Published var lastRewards: StoryRewards?

    // 🆕 Court Record: Chapter Selection
    @Published var chapters: [StoryChapter]?
    @Published var selectedChapter: StoryChapter?

    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private var merchantId: String = ""

    // MARK: - Initialization
    init() {}

    // MARK: - Public Methods

    /// 스토리 노드 가져오기
    func fetchStory(for merchantId: String) async {
        self.merchantId = merchantId
        self.isLoading = true
        self.error = nil

        do {
            let response = try await networkManager.getMerchantStory(merchantId: merchantId)

            if response.success, let data = response.data {
                self.currentNode = data.node
                self.merchantName = data.merchantName
                GameLogger.shared.logInfo("✅ 스토리 노드 로드 성공: \(data.node.id)", category: .network)
            } else {
                self.error = response.error ?? "스토리를 불러올 수 없습니다."
                GameLogger.shared.logError("❌ 스토리 노드 로드 실패: \(response.error ?? "알 수 없는 오류")", category: .network)
            }
        } catch {
            self.error = "네트워크 오류: \(error.localizedDescription)"
            GameLogger.shared.logError("❌ 스토리 API 호출 실패: \(error)", category: .network)
        }

        self.isLoading = false
    }

    /// 선택지 선택 및 스토리 진행
    func selectChoice(_ choice: StoryChoice) async {
        guard let currentNode = currentNode else { return }

        self.isLoading = true
        self.error = nil

        do {
            let response = try await networkManager.progressMerchantStory(
                merchantId: merchantId,
                nodeId: currentNode.id,
                choiceId: choice.id
            )

            if response.success, let data = response.data {
                GameLogger.shared.logInfo("✅ 스토리 진행 성공: \(data.completedNode)", category: .network)

                // 보상이 있다면 팝업 표시
                if let rewards = data.rewards {
                    self.lastRewards = rewards
                    self.showRewardPopup = true
                }

                // 다음 노드가 있다면 업데이트
                if let nextNode = data.nextNode {
                    self.currentNode = nextNode
                } else {
                    // 스토리 종료
                    self.currentNode = nil
                    GameLogger.shared.logInfo("✅ 스토리 완료", category: .gameplay)
                }
            } else {
                self.error = response.error ?? "스토리를 진행할 수 없습니다."
                GameLogger.shared.logError("❌ 스토리 진행 실패: \(response.error ?? "알 수 없는 오류")", category: .network)
            }
        } catch {
            self.error = "네트워크 오류: \(error.localizedDescription)"
            GameLogger.shared.logError("❌ 스토리 진행 API 호출 실패: \(error)", category: .network)
        }

        self.isLoading = false
    }

    /// 🆕 챕터 목록 가져오기 (Court Record)
    func fetchChapters(for merchantId: String) async {
        self.merchantId = merchantId
        self.isLoading = true
        self.error = nil

        do {
            let response = try await networkManager.getMerchantStoryChapters(merchantId: merchantId)

            if response.success, let data = response.data {
                self.chapters = data.chapters
                GameLogger.shared.logInfo("✅ 스토리 챕터 목록 로드 성공: \(data.chapters.count)개", category: .network)
            } else {
                self.error = response.error ?? "챕터 목록을 불러올 수 없습니다."
                GameLogger.shared.logError("❌ 챕터 목록 로드 실패: \(response.error ?? "알 수 없는 오류")", category: .network)
            }
        } catch {
            self.error = "네트워크 오류: \(error.localizedDescription)"
            GameLogger.shared.logError("❌ 챕터 API 호출 실패: \(error)", category: .network)
        }

        self.isLoading = false
    }

    /// 🆕 챕터 선택 → 초기 노드 로드
    func selectChapter(_ chapter: StoryChapter) async {
        self.selectedChapter = chapter
        self.isLoading = true
        self.error = nil

        do {
            // 챕터의 initialNodeId로 스토리 시작
            let response = try await networkManager.getMerchantStory(merchantId: merchantId)

            if response.success, let data = response.data {
                self.currentNode = data.node
                self.merchantName = data.merchantName
                GameLogger.shared.logInfo("✅ 챕터 \(chapter.chapter) 시작: \(data.node.id)", category: .network)
            } else {
                self.error = response.error ?? "스토리를 시작할 수 없습니다."
                GameLogger.shared.logError("❌ 챕터 시작 실패: \(response.error ?? "알 수 없는 오류")", category: .network)
            }
        } catch {
            self.error = "네트워크 오류: \(error.localizedDescription)"
            GameLogger.shared.logError("❌ 챕터 시작 API 호출 실패: \(error)", category: .network)
        }

        self.isLoading = false
    }

    /// 스토리 초기화
    func reset() {
        self.currentNode = nil
        self.merchantName = ""
        self.error = nil
        self.lastRewards = nil
        self.showRewardPopup = false
        self.merchantId = ""
        self.chapters = nil
        self.selectedChapter = nil
    }
}
