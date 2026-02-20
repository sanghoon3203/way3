//
//  VisualNovelDialogueBox.swift
//  way3
//
//  Visual Novel Hero Section - Dialogue Box Layer
//  Fixed 180pt height, 50% opacity, full width
//

import SwiftUI

/// 비주얼노벨 스타일 대사창
/// - 고정 높이: 180pt
/// - 투명도: 50%
/// - 좌우 꽉 찬 직사각형
struct VisualNovelDialogueBox: View {
    let merchantName: String
    let dialogue: String
    let showContinue: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상인 이름 (좌측 상단)
            Text(merchantName)
                .font(.cyberpunkHeading(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // 대사 텍스트
            ScrollView {
                Text(dialogue)
                    .font(.cyberpunkBody(size: 15))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // CONTINUE 버튼 (항상 공간 확보, opacity로만 제어)
            HStack {
                Spacer()
                Button(action: onContinue) {
                    HStack(spacing: 4) {
                        Text("CONTINUE")
                            .font(.cyberpunkCaption())
                            .foregroundColor(.white.opacity(0.9))

                        Image(systemName: "chevron.down")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .opacity(showContinue ? 1.0 : 0.0)  // 버튼은 항상 있지만 보이지 않게
                .allowsHitTesting(showContinue)  // showContinue가 false면 터치 불가
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .frame(height: 44)  // 버튼 영역 고정 높이
        }
        .frame(height: 180)  // 전체 고정 높이
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.5))  // 50% 투명도
        )
    }
}

// MARK: - Preview
#Preview("With Continue") {
    VStack {
        Spacer()
        VisualNovelDialogueBox(
            merchantName: "서예나",
            dialogue: "안녕하세요! 오늘도 멋진 아이템들을 준비했어요. 어떤 걸 찾고 계신가요?",
            showContinue: true,
            onContinue: { print("Continue tapped") }
        )
    }
    .background(
        Image(systemName: "photo")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .foregroundColor(.gray)
    )
}

#Preview("Without Continue") {
    VStack {
        Spacer()
        VisualNovelDialogueBox(
            merchantName: "서예나",
            dialogue: "안녕하세요! 오늘도 멋진 아이템들을 준비했어요.",
            showContinue: false,
            onContinue: { }
        )
    }
    .background(
        Image(systemName: "photo")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .foregroundColor(.gray)
    )
}
