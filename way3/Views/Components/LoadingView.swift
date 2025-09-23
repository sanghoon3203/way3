// 📁 Views/Components/LoadingView.swift - 로딩 상태 컴포넌트
import SwiftUI

/// 다양한 로딩 상태를 표시하는 재사용 가능한 컴포넌트
struct LoadingView: View {
    let message: String
    let style: LoadingStyle

    init(message: String = "로딩 중...", style: LoadingStyle = .merchant) {
        self.message = message
        self.style = style
    }

    var body: some View {
        VStack(spacing: 20) {
            // 로딩 애니메이션
            switch style {
            case .merchant:
                merchantLoadingAnimation
            case .simple:
                simpleLoadingAnimation
            case .cyberpunk:
                cyberpunkLoadingAnimation
            }

            // 로딩 메시지
            Text(message)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cyberpunkDarkBg.opacity(0.8))
    }

    // MARK: - 상인 특화 로딩 애니메이션
    private var merchantLoadingAnimation: some View {
        ZStack {
            // 배경 홀로그램 효과
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyberpunkCyan.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(pulseScale)
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(),
                    value: UUID()
                )

            // 중앙 상인 아이콘
            Image(systemName: "person.fill.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.cyberpunkYellow)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    Animation.linear(duration: 2.0).repeatForever(autoreverses: false),
                    value: UUID()
                )

            // 테두리 스캔라인
            Circle()
                .stroke(Color.cyberpunkCyan, lineWidth: 2)
                .frame(width: 100, height: 100)
                .opacity(0.6)
        }
    }

    // MARK: - 단순 로딩 애니메이션
    private var simpleLoadingAnimation: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.cyberpunkCyan)
                    .frame(width: 12, height: 12)
                    .scaleEffect(dotScale(index: index))
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: UUID()
                    )
            }
        }
    }

    // MARK: - 사이버펑크 로딩 애니메이션
    private var cyberpunkLoadingAnimation: some View {
        VStack(spacing: 16) {
            // 메인 로딩 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.cyberpunkDarkBg)
                        .frame(height: 4)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyberpunkCyan, Color.cyberpunkYellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressValue, height: 4)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(),
                            value: UUID()
                        )
                }
            }
            .frame(height: 4)

            // 진행률 텍스트
            Text("\(Int(progressValue * 100))%")
                .font(.cyberpunkTechnical())
                .foregroundColor(.cyberpunkYellow)
        }
        .frame(width: 200)
    }

    // MARK: - 애니메이션 상태
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var progressValue: Double = 0.0

    private func dotScale(index: Int) -> CGFloat {
        let time = Date().timeIntervalSince1970
        return 1.0 + sin(time * 3 + Double(index) * 0.5) * 0.5
    }

    // MARK: - 초기화
    init() {
        self.message = "로딩 중..."
        self.style = .merchant

        // 애니메이션 초기화
        _pulseScale = State(initialValue: 1.0)
        _rotationAngle = State(initialValue: 0)
        _progressValue = State(initialValue: 0.0)

        // 애니메이션 시작
        DispatchQueue.main.async {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever()) {
                pulseScale = 1.3
            }
            withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever()) {
                progressValue = 1.0
            }
        }
    }
}

enum LoadingStyle {
    case merchant   // 상인 특화 로딩
    case simple     // 단순 점 애니메이션
    case cyberpunk  // 사이버펑크 진행률 바
}

// MARK: - 에러 표시 컴포넌트
struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 에러 아이콘
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.cyberpunkRed)

            // 에러 메시지
            VStack(spacing: 8) {
                Text("오류가 발생했습니다")
                    .font(.cyberpunkTitle3())
                    .foregroundColor(.cyberpunkTextPrimary)

                Text(error.localizedDescription)
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // 재시도 버튼
            Button(action: retryAction) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("다시 시도")
                }
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkDarkBg)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.cyberpunkYellow)
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .stroke(Color.cyberpunkBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cyberpunkDarkBg.opacity(0.8))
    }
}

// MARK: - Preview
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView(message: "상인 데이터 로딩 중...", style: .merchant)
                .previewDisplayName("Merchant Loading")

            LoadingView(message: "처리 중...", style: .simple)
                .previewDisplayName("Simple Loading")

            LoadingView(message: "서버 연결 중...", style: .cyberpunk)
                .previewDisplayName("Cyberpunk Loading")

            ErrorView(error: NSError(domain: "Test", code: 404, userInfo: [NSLocalizedDescriptionKey: "테스트 에러 메시지입니다."])) {
                print("Retry tapped")
            }
            .previewDisplayName("Error View")
        }
    }
}