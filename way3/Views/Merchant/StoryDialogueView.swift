// 📁 Views/Merchant/StoryDialogueView.swift - 스토리 대화 화면
import SwiftUI

struct StoryDialogueView: View {
    let merchant: Merchant
    @Binding var isPresented: Bool
    @StateObject private var viewModel = StoryViewModel()
    @State private var displayedText = ""
    @State private var isTypingComplete = false

    // 타이핑 효과 타이머
    @State private var typingTimer: Timer?

    var body: some View {
        ZStack {
            // 사이버펑크 다크 배경
            Color.cyberpunkDarkBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 상단 헤더
                storyHeader

                Spacer()

                // 로딩 중
                if viewModel.isLoading {
                    ProgressView("스토리 로딩 중...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkYellow))
                        .foregroundColor(.cyberpunkTextPrimary)
                }
                // 에러 발생
                else if let error = viewModel.error {
                    errorView(error)
                }
                // 스토리 노드 표시
                else if let node = viewModel.currentNode {
                    storyNodeView(node)
                }
                // 스토리 종료
                else {
                    storyCompletedView
                }

                Spacer()
            }

            // 보상 팝업
            if viewModel.showRewardPopup, let rewards = viewModel.lastRewards {
                rewardPopup(rewards)
            }
        }
        .task {
            await viewModel.fetchStory(for: merchant.id)
        }
        .onDisappear {
            typingTimer?.invalidate()
            viewModel.reset()
        }
    }

    // MARK: - 상단 헤더
    private var storyHeader: some View {
        HStack {
            // 상인 이미지
            MerchantImageView(
                merchantName: merchant.name,
                imageFileName: merchant.imageFileName,
                width: 60,
                height: 60
            )
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.cyberpunkBorder, lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(merchant.name)
                    .font(.chosunH2)
                    .foregroundColor(.cyberpunkTextPrimary)

                if let title = merchant.title {
                    Text(title)
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkTextSecondary)
                }
            }

            Spacer()

            // 닫기 버튼
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.cyberpunkTextSecondary)
            }
        }
        .padding()
        .background(Color.cyberpunkCardBg)
        .overlay(
            Rectangle()
                .stroke(Color.cyberpunkBorder, lineWidth: 1),
            alignment: .bottom
        )
    }

    // MARK: - 스토리 노드 뷰
    private func storyNodeView(_ node: StoryNode) -> some View {
        VStack(spacing: 20) {
            // 대화 상자
            dialogueBox(node.content)

            // 선택지 목록
            if let choices = node.choices, !choices.isEmpty {
                choiceList(choices)
            }
        }
        .padding()
    }

    // MARK: - 대화 상자
    private func dialogueBox(_ content: StoryNodeContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 화자 이름
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.cyberpunkYellow)
                Text(content.speaker)
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkYellow)
            }

            Divider()
                .background(Color.cyberpunkBorder)

            // 대화 텍스트 (타이핑 효과)
            Text(displayedText)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextPrimary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            // 타이핑 중 표시
            if !isTypingComplete {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.cyberpunkCyan)
                            .frame(width: 6, height: 6)
                            .scaleEffect(typingDotAnimation(index: index))
                    }
                }
            }
        }
        .padding()
        .background(Color.cyberpunkCardBg)
        .overlay(
            Rectangle()
                .stroke(Color.cyberpunkBorder, lineWidth: 2)
        )
        .onAppear {
            startTypingEffect(content.text)
        }
    }

    // MARK: - 선택지 목록
    private func choiceList(_ choices: [StoryChoice]) -> some View {
        VStack(spacing: 12) {
            ForEach(choices, id: \.id) { choice in
                choiceButton(choice)
            }
        }
    }

    // MARK: - 선택지 버튼
    private func choiceButton(_ choice: StoryChoice) -> some View {
        Button(action: {
            Task {
                await viewModel.selectChoice(choice)
                // 새 노드가 로드되면 타이핑 효과 초기화
                displayedText = ""
                isTypingComplete = false
            }
        }) {
            HStack {
                Text(">")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkCyan)

                Text(choice.text)
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkTextPrimary)

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.cyberpunkYellow)
            }
            .padding()
            .background(Color.cyberpunkPanelBg)
            .overlay(
                Rectangle()
                    .stroke(Color.cyberpunkBorder, lineWidth: 1)
            )
        }
        .disabled(!isTypingComplete) // 타이핑 완료 전에는 선택 불가
    }

    // MARK: - 에러 뷰
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("오류")
                .font(.chosunH2)
                .foregroundColor(.cyberpunkTextPrimary)

            Text(error)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextSecondary)
                .multilineTextAlignment(.center)

            Button("닫기") {
                isPresented = false
            }
            .font(.cyberpunkBody())
            .foregroundColor(.cyberpunkYellow)
            .padding()
            .background(Color.cyberpunkCardBg)
            .overlay(
                Rectangle()
                    .stroke(Color.cyberpunkBorder, lineWidth: 1)
            )
        }
        .padding()
    }

    // MARK: - 스토리 완료 뷰
    private var storyCompletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.cyberpunkYellow)

            Text("스토리 완료!")
                .font(.cyberpunkTitle())
                .foregroundColor(.cyberpunkTextPrimary)

            Text("스토리가 모두 완료되었습니다.")
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextSecondary)

            Button("닫기") {
                isPresented = false
            }
            .font(.cyberpunkBody())
            .foregroundColor(.cyberpunkYellow)
            .padding()
            .background(Color.cyberpunkCardBg)
            .overlay(
                Rectangle()
                    .stroke(Color.cyberpunkBorder, lineWidth: 1)
            )
        }
        .padding()
    }

    // MARK: - 보상 팝업
    private func rewardPopup(_ rewards: StoryRewards) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("보상 획득!")
                    .font(.cyberpunkTitle())
                    .foregroundColor(.cyberpunkYellow)

                VStack(alignment: .leading, spacing: 12) {
                    if let rep = rewards.reputation {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.cyberpunkYellow)
                            Text("평판 +\(rep)")
                                .font(.cyberpunkBody())
                                .foregroundColor(.cyberpunkTextPrimary)
                        }
                    }

                    if let money = rewards.money {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.cyberpunkYellow)
                            Text("골드 +\(money)")
                                .font(.cyberpunkBody())
                                .foregroundColor(.cyberpunkTextPrimary)
                        }
                    }

                    if let exp = rewards.exp {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.cyberpunkCyan)
                            Text("경험치 +\(exp)")
                                .font(.cyberpunkBody())
                                .foregroundColor(.cyberpunkTextPrimary)
                        }
                    }
                }

                Button("확인") {
                    viewModel.showRewardPopup = false
                }
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkYellow)
                .padding()
                .background(Color.cyberpunkCardBg)
                .overlay(
                    Rectangle()
                        .stroke(Color.cyberpunkBorder, lineWidth: 1)
                )
            }
            .padding(30)
            .background(Color.cyberpunkPanelBg)
            .overlay(
                Rectangle()
                    .stroke(Color.cyberpunkYellow, lineWidth: 2)
            )
            .padding(40)
        }
    }

    // MARK: - 타이핑 효과
    private func startTypingEffect(_ fullText: String) {
        displayedText = ""
        isTypingComplete = false
        var currentIndex = 0

        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if currentIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                displayedText += String(fullText[index])
                currentIndex += 1
            } else {
                timer.invalidate()
                isTypingComplete = true
            }
        }
    }

    private func typingDotAnimation(index: Int) -> CGFloat {
        let time = Date().timeIntervalSince1970
        return 1.0 + sin(time * 2 + Double(index) * 0.5) * 0.3
    }
}
