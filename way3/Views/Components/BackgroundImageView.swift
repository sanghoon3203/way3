//
//  BackgroundImageView.swift
//  way3
//
//  Visual Novel Hero Section - Background Layer
//  1600×1440 배경 이미지 (10:9 비율)
//

import SwiftUI

/// 상인별 배경 이미지 뷰
/// 배경 이미지가 없으면 검은색 배경으로 fallback
struct BackgroundImageView: View {
    let merchantId: String

    /// merchantId (소문자) → 파일명 (첫 글자 대문자)
    private var capitalizedName: String {
        return merchantId.prefix(1).uppercased() + merchantId.dropFirst()
    }

    var body: some View {
        // 배경 이미지 로드 ({Name}_background)
        if let uiImage = UIImage(named: "\(capitalizedName)_background") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            // 배경 이미지 없으면 검은색 fallback
            Color.black
        }
    }
}

// MARK: - Preview
#Preview {
    BackgroundImageView(merchantId: "seoyena")
        .frame(height: 480)
}
