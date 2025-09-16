// 📁 Core/ErrorAlert.swift - 사용자 친화적 에러 메시지 시스템
import SwiftUI

// MARK: - 에러 알림 매니저
class ErrorAlertManager: ObservableObject {
    @Published var currentAlert: ErrorAlertData?
    @Published var isShowingAlert = false

    static let shared = ErrorAlertManager()

    private init() {}

    // 에러 표시 메서드
    func showError(_ error: Error, title: String = "오류", dismissAction: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertData = ErrorAlertData(
                title: title,
                message: self.getUserFriendlyMessage(for: error),
                suggestion: self.getRecoverySuggestion(for: error),
                dismissAction: dismissAction
            )

            self.currentAlert = alertData
            self.isShowingAlert = true
        }
    }

    // NetworkManager의 에러를 사용자 친화적 메시지로 변환
    private func getUserFriendlyMessage(for error: Error) -> String {
        if let networkError = error as? NetworkManager.NetworkError {
            return networkError.errorDescription ?? "알 수 없는 오류가 발생했습니다"
        }

        // 기타 에러 타입 처리
        return error.localizedDescription
    }

    // 복구 제안사항 추출
    private func getRecoverySuggestion(for error: Error) -> String? {
        if let networkError = error as? NetworkManager.NetworkError {
            return networkError.recoverySuggestion
        }

        return nil
    }

    // 알림 해제
    func dismissAlert() {
        currentAlert?.dismissAction?()
        currentAlert = nil
        isShowingAlert = false
    }
}

// MARK: - 에러 알림 데이터 모델
struct ErrorAlertData {
    let title: String
    let message: String
    let suggestion: String?
    let dismissAction: (() -> Void)?

    init(title: String, message: String, suggestion: String? = nil, dismissAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.suggestion = suggestion
        self.dismissAction = dismissAction
    }
}

// MARK: - 에러 알림 뷰 컴포넌트
struct ErrorAlertView: View {
    let alertData: ErrorAlertData
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 에러 아이콘
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)

            // 제목
            Text(alertData.title)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // 메시지
            Text(alertData.message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // 제안사항 (있는 경우만)
            if let suggestion = alertData.suggestion, !suggestion.isEmpty {
                Text(suggestion)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            // 확인 버튼
            Button("확인") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
        .frame(maxWidth: 320)
    }
}

// MARK: - 에러 알림 모디파이어
struct ErrorAlertModifier: ViewModifier {
    @StateObject private var errorManager = ErrorAlertManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if errorManager.isShowingAlert, let alertData = errorManager.currentAlert {
                        // 배경 오버레이
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .transition(.opacity)

                        // 에러 알림
                        ErrorAlertView(alertData: alertData) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                errorManager.dismissAlert()
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: errorManager.isShowingAlert)
            )
    }
}

// MARK: - 편의 확장
extension View {
    func errorAlert() -> some View {
        self.modifier(ErrorAlertModifier())
    }
}

// MARK: - 에러 처리 헬퍼 메서드들
extension View {
    // 비동기 작업에서 에러 처리를 위한 헬퍼
    func handleAsyncError<T>(
        operation: () async throws -> T,
        onSuccess: @escaping (T) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        Task {
            do {
                let result = try await operation()
                await MainActor.run {
                    onSuccess(result)
                }
            } catch {
                await MainActor.run {
                    ErrorAlertManager.shared.showError(error)
                    onError(error)
                }
            }
        }
    }

    // 게임별 특화 에러 처리
    func handleGameError<T>(
        operation: () async throws -> T,
        successMessage: String? = nil,
        onSuccess: @escaping (T) -> Void = { _ in }
    ) {
        handleAsyncError(operation: operation) { result in
            if let message = successMessage {
                // 성공 메시지 표시 (토스트 등)
                print("✅ \(message)")
            }
            onSuccess(result)
        }
    }
}

// MARK: - 프리뷰
struct ErrorAlertView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 기본 에러
            ErrorAlertView(
                alertData: ErrorAlertData(
                    title: "네트워크 오류",
                    message: "인터넷 연결을 확인해주세요"
                )
            ) {}
            .previewDisplayName("기본 에러")

            // 제안사항 포함 에러
            ErrorAlertView(
                alertData: ErrorAlertData(
                    title: "자금 부족",
                    message: "💰 자금이 부족합니다",
                    suggestion: "돈을 더 벌거나 더 저렴한 상품을 선택해보세요"
                )
            ) {}
            .previewDisplayName("제안사항 포함")

            // 긴 메시지 에러
            ErrorAlertView(
                alertData: ErrorAlertData(
                    title: "서버 오류",
                    message: "서버에서 예상치 못한 오류가 발생했습니다. 잠시 후 다시 시도해주시기 바랍니다.",
                    suggestion: "문제가 계속되면 고객센터로 문의해주세요"
                )
            ) {}
            .previewDisplayName("긴 메시지")
        }
        .padding()
        .background(Color.gray.opacity(0.3))
    }
}