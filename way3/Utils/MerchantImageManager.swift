//
//  MerchantImageManager.swift
//  way3 - Way Trading Game
//
//  상인 이미지 동적 로드 및 관리 시스템
//  Asset 폴더의 이미지 파일과 상인 이름을 자동 매칭
//

import SwiftUI
import UIKit
import Foundation

// MARK: - 상인 이미지 관리자
class MerchantImageManager: ObservableObject {
    static let shared = MerchantImageManager()

    // MARK: - 이미지 캐시
    @Published private var imageCache: [String: UIImage] = [:]
    private var loadingImages: Set<String> = []
    private var failedRemoteImages: Set<String> = []

    private init() {
        preloadCommonImages()
    }

    // MARK: - 상인 이미지 이름 매칭
    static func getImageName(for merchantName: String, imageFileName: String?) -> String? {
        // 1. 기본 변환: 공백 제거, 특수문자 정리
        let cleanName = merchantName
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .lowercased()

        // 서버에서 제공한 파일명이 있다면 우선적으로 후보에 포함
        var possibleNames: [String] = []
        if let imageFileName,
           !imageFileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let sanitized = imageFileName
                .replacingOccurrences(of: "\\", with: "/")
                .components(separatedBy: "/")
                .last ?? imageFileName

            let baseName = sanitized
                .replacingOccurrences(of: ".png", with: "")
                .replacingOccurrences(of: ".jpg", with: "")
                .replacingOccurrences(of: ".jpeg", with: "")

            possibleNames.append(contentsOf: [
                baseName,
                baseName.replacingOccurrences(of: " ", with: ""),
                baseName.lowercased()
            ])
        }

        // 2. 기존 이름 기반 패턴
        possibleNames.append(contentsOf: [
            merchantName,
            cleanName,
            merchantName.replacingOccurrences(of: " ", with: ""),
            "\(cleanName)/image",
            "\(cleanName)/portrait",
            "\(cleanName)/character",
            "\(cleanName)/merchant",
            cleanName.lowercased(),
            merchantName.lowercased().replacingOccurrences(of: " ", with: ""),
            "merchant_\(cleanName)",
            "\(cleanName)_merchant",
            "char_\(cleanName)",
            "\(cleanName)_char"
        ])

        // 3. 이미지 존재 확인
        for imageName in possibleNames {
            if UIImage(named: imageName) != nil {
                #if DEBUG
                print("✅ Found merchant image: \(imageName) for \(merchantName)")
                #endif
                return imageName
            }
        }

        // 4. Asset 폴더 기반 탐색
        if let assetImageName = findImageInAssetFolder(merchantName: merchantName) {
            return assetImageName
        }

        // 기본값 없음 (플레이스홀더로 처리)
        return nil
    }

    // MARK: - Asset 폴더 내 이미지 탐색
    private static func findImageInAssetFolder(merchantName: String) -> String? {
        let cleanName = merchantName.replacingOccurrences(of: " ", with: "").lowercased()

        // Asset 폴더 구조 기반 탐색
        let assetFolderNames = [
            merchantName.replacingOccurrences(of: " ", with: ""), // "AliceGang"
            cleanName,                                            // "alicegang"
            merchantName.capitalized.replacingOccurrences(of: " ", with: ""), // "Alicegang"
        ]

        let imageFileNames = [
            "image", "portrait", "character", "merchant", "main", "default",
            cleanName, merchantName.replacingOccurrences(of: " ", with: "")
        ]

        for folderName in assetFolderNames {
            for fileName in imageFileNames {
                let fullPath = "\(folderName)/\(fileName)"
                if UIImage(named: fullPath) != nil {
                    #if DEBUG
                    print("📁 Found in asset folder: \(fullPath)")
                    #endif
                    return fullPath
                }
            }
        }

        return nil
    }

    // MARK: - 비동기 이미지 로드
    func loadImage(for merchantName: String, imageFileName: String?) -> UIImage? {
        if let assetName = Self.getImageName(for: merchantName, imageFileName: imageFileName) {
            if let cachedImage = imageCache[assetName] {
                return cachedImage
            }

            guard !loadingImages.contains(assetName) else {
                return nil
            }

            loadingImages.insert(assetName)

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                if let image = UIImage(named: assetName) {
                    DispatchQueue.main.async {
                        self?.imageCache[assetName] = image
                        self?.loadingImages.remove(assetName)
                        self?.objectWillChange.send()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.loadingImages.remove(assetName)
                    }
                }
            }

            return nil
        }

        guard let imageFileName,
              !imageFileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let cacheKey = "remote::\(imageFileName)"

        if let cachedImage = imageCache[cacheKey] {
            return cachedImage
        }

        guard !loadingImages.contains(cacheKey), !failedRemoteImages.contains(cacheKey) else {
            return nil
        }

        guard let remoteURL = Self.remoteImageURL(for: imageFileName) else {
            failedRemoteImages.insert(cacheKey)
            return nil
        }

        loadingImages.insert(cacheKey)

        let request = URLRequest(url: remoteURL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.loadingImages.remove(cacheKey)
            }

            guard error == nil,
                  let data,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.failedRemoteImages.insert(cacheKey)
                }
                return
            }

            DispatchQueue.main.async {
                self?.imageCache[cacheKey] = image
                self?.objectWillChange.send()
            }
        }.resume()

        return nil
    }

    // MARK: - 일반적인 이미지들 미리 로드
    private func preloadCommonImages() {
        let commonImages = ["default_merchant", "placeholder_merchant"]

        for imageName in commonImages {
            if let image = UIImage(named: imageName) {
                imageCache[imageName] = image
            }
        }
    }

    // MARK: - 캐시 관리
    func clearCache() {
        imageCache.removeAll()
        loadingImages.removeAll()
        failedRemoteImages.removeAll()
    }

    func getCachedImage(name: String) -> UIImage? {
        return imageCache[name]
    }

    // MARK: - 디버그 정보
    var debugInfo: String {
        return """
        🖼️ Cached Images: \(imageCache.count)
        ⏳ Loading Images: \(loadingImages.count)
        📁 Total Memory: ~\(imageCache.values.map { $0.size.width * $0.size.height * 4 }.reduce(0, +) / 1024 / 1024) MB
        """
    }
}

// MARK: - Remote Utilities
private extension MerchantImageManager {
    static func remoteImageURL(for fileName: String) -> URL? {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let sanitized = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmed

        // 서버에서 절대 경로를 내려주지 않는다면 기본 public 경로를 사용
        let baseURL = NetworkConfiguration.baseURL

        if sanitized.hasPrefix("http://") || sanitized.hasPrefix("https://") {
            return URL(string: sanitized)
        }

        if sanitized.hasPrefix("/") {
            return URL(string: "\(baseURL)\(sanitized)")
        }

        return URL(string: "\(baseURL)/public/merchants/\(sanitized)")
    }
}

// MARK: - SwiftUI View Extension
extension View {
    func merchantImage(merchantName: String, width: CGFloat = 120, height: CGFloat = 120) -> some View {
        MerchantImageView(merchantName: merchantName, imageFileName: nil, width: width, height: height)
    }
}

// MARK: - 상인 이미지 뷰 컴포넌트
struct MerchantImageView: View {
    let merchantName: String
    let imageFileName: String?
    let width: CGFloat
    let height: CGFloat

    @StateObject private var imageManager = MerchantImageManager.shared

    var body: some View {
        Group {
            if let image = imageManager.loadImage(for: merchantName, imageFileName: imageFileName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                // 로딩 중이거나 이미지가 없는 경우
                JRPGMerchantPlaceholder(merchantName: merchantName)
                    .frame(width: width, height: height)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.commonGray, lineWidth: 3)
                .shadow(color: Color.commonGray.opacity(0.5), radius: 8)
        )
    }
}

// MARK: - JRPG 스타일 플레이스홀더
struct JRPGMerchantPlaceholder: View {
    let merchantName: String

    var body: some View {
        ZStack {
            // 배경 그라데이션
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.commonGray.opacity(0.8),
                            Color.orange.opacity(0.6),
                            Color.red.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                // 기본 아이콘
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)

                // 상인 이름 (축약)
                Text(abbreviatedName)
                    .font(.jrpgUI())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var abbreviatedName: String {
        let words = merchantName.split(separator: " ")
        if words.count > 1 {
            return words.map { String($0.prefix(1)) }.joined()
        } else {
            return String(merchantName.prefix(4))
        }
    }
}
