//
//  BundleImage.swift
//  way3 - connect:seoul
//
//  번들 내 이미지 파일을 경로로 직접 로드하는 헬퍼 뷰
//  Asset Catalog에 등록되지 않은 Resources 폴더 이미지용
//

import SwiftUI

/// 번들 내 이미지를 로드하는 뷰
/// - `BundleImage(filename: "TItle", ext: "png")` — Resources 루트의 파일
/// - `BundleImage(path: "images/backgrounds/prologue/bg_Kijuri.png")` — 상대 경로
struct BundleImage: View {
    private let uiImage: UIImage?

    /// Resources 루트 파일 (파일명 + 확장자 분리)
    init(filename: String, ext: String = "png") {
        self.uiImage = UIImage(named: filename)
            ?? {
                if let url = Bundle.main.url(forResource: filename, withExtension: ext),
                   let img = UIImage(contentsOfFile: url.path) { return img }
                return nil
            }()
    }

    /// 상대 경로 (예: "images/backgrounds/prologue/bg_Kijuri.png")
    init(path: String) {
        // 경로에서 파일명과 확장자 분리
        let url = URL(fileURLWithPath: path)
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        self.uiImage = UIImage(named: name)
            ?? {
                // 번들 내 직접 경로 탐색
                if let bundleURL = Bundle.main.url(forResource: name, withExtension: ext),
                   let img = UIImage(contentsOfFile: bundleURL.path) { return img }
                // 전체 경로 시도
                if let bundleRoot = Bundle.main.resourceURL {
                    let fullURL = bundleRoot.appendingPathComponent(path)
                    if let img = UIImage(contentsOfFile: fullURL.path) { return img }
                }
                return nil
            }()
    }

    var body: some View {
        if let img = uiImage {
            Image(uiImage: img)
                .resizable()
        } else {
            // 이미지를 못 찾으면 fallback 그라디언트
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
