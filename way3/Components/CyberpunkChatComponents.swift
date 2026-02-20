//
//  CyberpunkChatComponents.swift
//  way3 — connect:seoul
//
//  조선사이버펑크 AI 채팅 UI 컴포넌트
//  교서(敎書) 스타일: 단청 테두리 + 네온 말풍선
//

import SwiftUI

// MARK: - 채팅 메시지 모델

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: ChatRole
    let text: String
    let timestamp: Date

    enum ChatRole {
        case player, merchant
    }
}

// MARK: - 말풍선 (Chat Bubble)

struct MerchantChatBubble: View {
    let message: ChatMessage
    let merchantName: String

    var isPlayer: Bool { message.role == .player }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isPlayer { Spacer(minLength: 48) }

            VStack(alignment: isPlayer ? .trailing : .leading, spacing: 4) {
                // 발화자 이름
                if !isPlayer {
                    Text(merchantName)
                        .font(.cyberpunkTechnical(size: 10))
                        .foregroundColor(.joseonCheong)
                        .padding(.leading, 4)
                }

                // 말풍선 본체
                ZStack(alignment: isPlayer ? .bottomTrailing : .bottomLeading) {
                    Text(message.text)
                        .font(.cyberpunkBody(size: 14))
                        .foregroundColor(isPlayer ? .joseonHeuk : .joseonBaek)
                        .lineSpacing(3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleBackground)
                        .clipShape(BubbleShape(isPlayer: isPlayer))
                        .overlay(
                            BubbleShape(isPlayer: isPlayer)
                                .stroke(
                                    isPlayer
                                        ? Color.joseonHwang.opacity(0.6)
                                        : Color.joseonCheong.opacity(0.35),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isPlayer
                                ? Color.joseonHwang.opacity(0.25)
                                : Color.joseonCheong.opacity(0.15),
                            radius: 6
                        )
                }

                // 타임스탬프
                Text(message.timestamp, style: .time)
                    .font(.cyberpunkTechnical(size: 9))
                    .foregroundColor(.joseonBaek.opacity(0.3))
                    .padding(.horizontal, 4)
            }

            if !isPlayer { Spacer(minLength: 48) }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isPlayer {
            // 플레이어: 황금 네온
            LinearGradient(
                colors: [
                    Color.joseonHwang,
                    Color.joseonHwang.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // 상인: 흑(패널) + 단청 테두리
            Color.joseonPanel
        }
    }
}

// MARK: - 말풍선 모양 (꼬리 있는 버블)

struct BubbleShape: Shape {
    let isPlayer: Bool
    let tailSize: CGFloat = 8
    let cornerRadius: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tailWidth: CGFloat = tailSize
        let tailHeight: CGFloat = tailSize * 0.8

        let adjustedRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height - tailHeight
        )

        path.addRoundedRect(in: adjustedRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        // 꼬리
        if isPlayer {
            let tailX = adjustedRect.maxX - cornerRadius - tailWidth
            path.move(to: CGPoint(x: tailX, y: adjustedRect.maxY))
            path.addLine(to: CGPoint(x: tailX + tailWidth, y: adjustedRect.maxY))
            path.addLine(to: CGPoint(x: tailX + tailWidth * 0.6, y: rect.maxY))
            path.closeSubpath()
        } else {
            let tailX = adjustedRect.minX + cornerRadius
            path.move(to: CGPoint(x: tailX, y: adjustedRect.maxY))
            path.addLine(to: CGPoint(x: tailX + tailWidth, y: adjustedRect.maxY))
            path.addLine(to: CGPoint(x: tailX + tailWidth * 0.4, y: rect.maxY))
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - 타이핑 인디케이터

struct MerchantTypingIndicator: View {
    let merchantName: String
    @State private var dot1 = false
    @State private var dot2 = false
    @State private var dot3 = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(merchantName)
                    .font(.cyberpunkTechnical(size: 10))
                    .foregroundColor(.joseonCheong)
                    .padding(.leading, 4)

                HStack(spacing: 5) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.joseonCheong)
                            .frame(width: 6, height: 6)
                            .scaleEffect(dotScale(index: i))
                            .shadow(color: .joseonCheong.opacity(0.8), radius: 3)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.joseonPanel)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.joseonCheong.opacity(0.35), lineWidth: 1)
                )
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .onAppear { startAnimation() }
    }

    private func dotScale(index: Int) -> CGFloat {
        switch index {
        case 0: return dot1 ? 1.4 : 0.7
        case 1: return dot2 ? 1.4 : 0.7
        case 2: return dot3 ? 1.4 : 0.7
        default: return 1.0
        }
    }

    private func startAnimation() {
        let duration = 0.4
        let delay = 0.15
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(0)) {
            dot1 = true
        }
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay)) {
            dot2 = true
        }
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay * 2)) {
            dot3 = true
        }
    }
}

// MARK: - 에피소드 언락 배너

struct EpisodeUnlockBanner: View {
    let episodeTitle: String
    let onTap: () -> Void
    @State private var glowPulse = false
    @State private var sealRotation: Double = -3

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 도장 씰
                ZStack {
                    Circle()
                        .fill(Color.joseonJeok)
                        .frame(width: 36, height: 36)
                        .shadow(color: .joseonJeok.opacity(glowPulse ? 0.9 : 0.4), radius: glowPulse ? 10 : 4)

                    Text("開")
                        .font(.custom("ChosunCentennial", size: 16))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(sealRotation))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("새 이야기가 열렸습니다")
                        .font(.cyberpunkTechnical(size: 10))
                        .foregroundColor(.joseonHwang)
                        .tracking(1.5)

                    Text(episodeTitle)
                        .font(.chosunH3)
                        .foregroundColor(.joseonBaek)
                        .lineLimit(1)
                }

                Spacer()

                // 화살표
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.joseonHwang)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    Color.joseonCard

                    // 단청 좌측 바
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.joseonJeok, .joseonHwang],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [.joseonJeok.opacity(0.6), .joseonHwang.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .joseonJeok.opacity(0.3), radius: 12)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                sealRotation = 3
            }
        }
    }
}

// MARK: - 채팅 입력창

struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            // 입력 필드
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("메시지를 입력하세요...")
                        .font(.cyberpunkBody(size: 14))
                        .foregroundColor(.joseonBaek.opacity(0.3))
                        .padding(.horizontal, 14)
                }

                TextField("", text: $text, axis: .vertical)
                    .font(.cyberpunkBody(size: 14))
                    .foregroundColor(.joseonBaek)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSend()
                        }
                    }
            }
            .background(Color.joseonCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isFocused
                            ? Color.joseonCheong.opacity(0.6)
                            : Color.joseonBorderDim,
                        lineWidth: 1
                    )
            )

            // 전송 버튼
            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(
                            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                                ? Color.joseonPanel
                                : Color.joseonHwang
                        )
                        .frame(width: 40, height: 40)

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .joseonCheong))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(
                                text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color.joseonBaek.opacity(0.2)
                                    : Color.joseonHeuk
                            )
                            .rotationEffect(.degrees(45))
                    }
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color.joseonHeuk.opacity(0.95)
                .overlay(
                    Rectangle()
                        .fill(Color.joseonCheong.opacity(0.12))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}

// MARK: - 채팅 탭 선택기 (에피소드 | 대화)

struct MerchantTabSelector: View {
    @Binding var selectedTab: MerchantTab
    @Namespace private var animation

    enum MerchantTab: CaseIterable {
        case episodes, chat

        var label: String {
            switch self {
            case .episodes: return "에피소드"
            case .chat: return "대화하기"
            }
        }

        var icon: String {
            switch self {
            case .episodes: return "book.fill"
            case .chat: return "bubble.left.and.bubble.right.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MerchantTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11))

                        Text(tab.label)
                            .font(.cyberpunkButton(size: 13))
                    }
                    .foregroundColor(selectedTab == tab ? .joseonHeuk : .joseonBaek.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.joseonHwang)
                                    .matchedGeometryEffect(id: "tab", in: animation)
                                    .shadow(color: .joseonHwang.opacity(0.4), radius: 6)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.joseonCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.joseonBorderDim, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
