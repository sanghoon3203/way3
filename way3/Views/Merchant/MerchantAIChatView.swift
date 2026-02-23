//
//  MerchantAIChatView.swift
//  way3 — connect:seoul
//
//  AI 상인 채팅 뷰
//  Gemini API (서버 중계) 기반 캐릭터 대화 시스템
//

import SwiftUI

// MARK: - AI 채팅 뷰모델

@MainActor
class MerchantChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var unlockedEpisode: EpisodeMeta? = nil
    @Published var showUnlockBanner: Bool = false
    @Published var errorMessage: String? = nil

    let merchant: Merchant

    private let maxHistoryCount = 10

    init(merchant: Merchant) {
        self.merchant = merchant
        addWelcomeMessage()
    }

    private func addWelcomeMessage() {
        let greeting = ChatMessage(
            role: .merchant,
            text: "어서 오세요. 오늘은 어떤 이야기를 나눠볼까요?",
            timestamp: Date()
        )
        messages.append(greeting)
    }

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }

        let playerMessage = ChatMessage(role: .player, text: trimmed, timestamp: Date())
        messages.append(playerMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await callMerchantChatAPI(userMessage: trimmed)
                let merchantMessage = ChatMessage(role: .merchant, text: response.reply, timestamp: Date())
                messages.append(merchantMessage)

                if let episode = response.unlockedEpisode {
                    unlockedEpisode = episode
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showUnlockBanner = true
                    }
                    // 8초 후 자동 닫기
                    try? await Task.sleep(nanoseconds: 8_000_000_000)
                    withAnimation { showUnlockBanner = false }
                }
            } catch {
                errorMessage = "연결이 불안정합니다. 잠시 후 다시 시도해주세요."
            }
            isLoading = false
        }
    }

    func dismissUnlockBanner() {
        withAnimation(.easeOut(duration: 0.3)) {
            showUnlockBanner = false
        }
    }

    // MARK: - API 호출 (서버 → Gemini)

    private func callMerchantChatAPI(userMessage: String) async throws -> MerchantChatResponse {
        guard let url = URL(string: "\(NetworkConfiguration.baseURL)/api/merchant-chat") else {
            throw URLError(.badURL)
        }

        let recentHistory = Array(messages.suffix(maxHistoryCount))
        let historyPayload = recentHistory.map {
            ["role": $0.role == .player ? "user" : "model",
             "text": $0.text]
        }

        let body: [String: Any] = [
            "merchantId": merchant.id,
            "message": userMessage,
            "history": historyPayload
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // 인증 토큰 추가
        if let token = try? SecureStorage.shared.loadAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(MerchantChatResponse.self, from: data)
    }
}

// MARK: - API 응답 모델

struct MerchantChatResponse: Decodable {
    let reply: String
    let unlockedEpisode: EpisodeMeta?
}

// MARK: - 메인 채팅 뷰

struct MerchantAIChatView: View {
    @StateObject private var viewModel: MerchantChatViewModel
    @Namespace private var bottomID
    let onEpisodeUnlock: (EpisodeMeta) -> Void

    init(merchant: Merchant, onEpisodeUnlock: @escaping (EpisodeMeta) -> Void) {
        self._viewModel = StateObject(wrappedValue: MerchantChatViewModel(merchant: merchant))
        self.onEpisodeUnlock = onEpisodeUnlock
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // 채팅 메시지 영역
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // 상단 여백
                            Color.clear.frame(height: 8)

                            ForEach(viewModel.messages) { message in
                                MerchantChatBubble(
                                    message: message,
                                    merchantName: viewModel.merchant.name
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: message.role == .player ? .trailing : .leading).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }

                            // 타이핑 인디케이터
                            if viewModel.isLoading {
                                MerchantTypingIndicator(merchantName: viewModel.merchant.name)
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                            }

                            // 에러 메시지
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.cyberpunkCaption())
                                    .foregroundColor(.joseonJeok)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            // 스크롤 앵커
                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.messages)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isLoading) { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                }

                // 입력창
                ChatInputBar(
                    text: $viewModel.inputText,
                    isLoading: viewModel.isLoading,
                    onSend: viewModel.sendMessage
                )
            }
            .background(Color.joseonHeuk)

            // 에피소드 언락 배너 (플로팅)
            if viewModel.showUnlockBanner, let episode = viewModel.unlockedEpisode {
                EpisodeUnlockBanner(episodeTitle: episode.title) {
                    viewModel.dismissUnlockBanner()
                    onEpisodeUnlock(episode)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
    }
}
