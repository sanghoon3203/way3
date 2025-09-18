//
//  StartView.swift
//  way3 - Way Trading Game
//
//  네오-서울 트레이딩 게임 시작 화면
//  배경 영상 + 로고 + 타이핑 애니메이션
//

import SwiftUI
import AVKit

struct StartView: View {
    @Binding var isPresented: Bool
    @State private var showLoginView = false

    init(isPresented: Binding<Bool> = .constant(true)) {
        self._isPresented = isPresented
    }

    var body: some View {
        ZStack {
            // 1. 배경 영상 레이어 (랜덤 선택 + 이미지 전환)
            StartViewBackgroundLayer()

            // 2. 반투명 오버레이
            OverlayLayer()

            // 3. 컨텐츠 레이어
            ContentLayer()

            // 4. 전체 화면 터치 감지
            TouchDetectionLayer(onTouch: {
                showLoginView = true
            })
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView(showLoginView: $showLoginView)
                .onDisappear {
                    isPresented = false
                }
        }
    }
}


// MARK: - Overlay Layer
struct OverlayLayer: View {
    var body: some View {
        Color.black.opacity(0.35)
            .ignoresSafeArea()
    }
}

// MARK: - Content Layer
struct ContentLayer: View {
    var body: some View {
        VStack {
            Spacer()

            // 로고 컴포넌트 (상단 1/3)
            LogoComponent()

            Spacer()
            Spacer()

            // 타이핑 애니메이션 (하단 1/4)
            TypingAnimationComponent()

            Spacer()
        }
    }
}

// MARK: - Logo Component
struct LogoComponent: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0

    var body: some View {
        VStack(spacing: 16) {
            // 게임 로고 텍스트 (실제 로고 이미지로 교체 가능)
            Text("네오-서울")
                .font(.chosunOrFallback(size: 36, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 0)

            Text("트레이딩 게임")
                .font(.chosunOrFallback(size: 18, weight: .medium))
                .foregroundColor(.cyan)
                .shadow(color: .cyan.opacity(0.3), radius: 5, x: 0, y: 0)
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

// MARK: - Typing Animation Component
struct TypingAnimationComponent: View {
    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var isTyping = true
    @State private var showCursor = true

    private let fullText = "터치하여 로그인하기"
    private let typingSpeed = 0.1
    private let pauseDuration = 2.0
    private let deletingSpeed = 0.05
    private let cursorBlinkSpeed = 0.8

    var body: some View {
        HStack {
            Text(displayedText)
                .font(.chosunOrFallback(size: 18))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.5), radius: 3, x: 0, y: 0)

            // 깜박이는 커서
            Text("|")
                .font(.chosunOrFallback(size: 18))
                .foregroundColor(.white)
                .opacity(showCursor ? 1 : 0)
                .animation(.easeInOut(duration: cursorBlinkSpeed).repeatForever(), value: showCursor)
        }
        .onAppear {
            startCursorBlink()
            startTypingCycle()
        }
    }

    private func startCursorBlink() {
        showCursor.toggle()
    }

    private func startTypingCycle() {
        typingPhase()
    }

    private func typingPhase() {
        guard currentIndex < fullText.count else {
            // 타이핑 완료 후 대기
            DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) {
                deletingPhase()
            }
            return
        }

        let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
        displayedText = String(fullText[..<index])
        currentIndex += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed) {
            typingPhase()
        }
    }

    private func deletingPhase() {
        guard currentIndex > 0 else {
            // 삭제 완료 후 대기
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startTypingCycle()
            }
            return
        }

        currentIndex -= 1
        let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
        displayedText = String(fullText[..<index])

        DispatchQueue.main.asyncAfter(deadline: .now() + deletingSpeed) {
            deletingPhase()
        }
    }
}

// MARK: - Touch Detection Layer
struct TouchDetectionLayer: View {
    let onTouch: () -> Void

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                handleTouch()
            }
    }

    private func handleTouch() {
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // 터치 콜백 실행
        onTouch()
    }
}

// MARK: - Preview
#Preview {
    StartView()
}