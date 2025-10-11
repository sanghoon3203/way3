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

private struct OrderedSet<Element: Hashable> {
    private var set = Set<Element>()
    private(set) var elements: [Element] = []

    mutating func append(_ element: Element) {
        guard set.insert(element).inserted else { return }
        elements.append(element)
    }
}

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

        var candidates = OrderedSet<String>()

        // 서버에서 제공한 파일명이 있다면 우선적으로 후보에 포함
        if let imageFileName,
           !imageFileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let sanitized = sanitizeFileComponent(imageFileName)
            candidates.append(sanitized)
            if !sanitized.lowercased().hasSuffix("_face") {
                candidates.append("\(sanitized)_face")
            }
        }

        // 2. 기본 이름 패턴 (Face 강제)
        let romanized = romanizedMerchantName(for: merchantName)
        let baseNames = [
            merchantName,
            merchantName.replacingOccurrences(of: " ", with: ""),
            cleanName,
            romanized,
            romanized.replacingOccurrences(of: " ", with: ""),
            romanized.lowercased()
        ]
        for base in baseNames where !base.isEmpty {
            let normalized = base.replacingOccurrences(of: " ", with: "")
            let faceName = normalized.lowercased().hasSuffix("_face") ? normalized : "\(normalized)_face"
            candidates.append(faceName)
            let capitalizedFace = faceName.prefix(1).uppercased() + faceName.dropFirst()
            candidates.append(capitalizedFace)
        }

        // 3. 이미지 존재 확인
        for imageName in candidates.elements {
            if UIImage(named: imageName) != nil {
                #if DEBUG
                print("✅ Found merchant image: \(imageName) for \(merchantName)")
                #endif
                return imageName
            }
        }

        // 4. Asset 폴더 기반 탐색 (_face 기준)
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

        let romanized = romanizedMerchantName(for: merchantName)
        let baseCandidates: [String] = [
            merchantName,
            merchantName.replacingOccurrences(of: " ", with: ""),
            cleanName,
            romanized,
            romanized.replacingOccurrences(of: " ", with: ""),
            romanized.lowercased()
        ]

        var faceFileNames: [String] = []
        for base in baseCandidates where !base.isEmpty {
            let normalized = base.replacingOccurrences(of: " ", with: "")
            let candidate = normalized.lowercased().hasSuffix("_face") ? normalized : "\(normalized)_face"
            faceFileNames.append(candidate)
        }
        faceFileNames.append("face")

        for folderName in assetFolderNames {
            for fileName in faceFileNames {
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

        if let localImage = Self.loadLocalImage(named: imageFileName) {
            imageCache[cacheKey] = localImage
            return localImage
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
    static func loadLocalImage(named imageFileName: String) -> UIImage? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }

        let sanitized = imageFileName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\", with: "/")

        let merchantsDirectory = URL(fileURLWithPath: resourcePath)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("Merchant", isDirectory: true)

        let fileManager = FileManager.default

        func imageFromURL(_ url: URL) -> UIImage? {
            guard fileManager.fileExists(atPath: url.path) else { return nil }
            return UIImage(contentsOfFile: url.path)
        }

        if sanitized.contains("/") {
            let directURL = merchantsDirectory.appendingPathComponent(sanitized)
                if let image = imageFromURL(directURL) {
                    #if DEBUG
                    print("📄 Found merchant image in bundle: \(directURL.lastPathComponent)")
                    #endif
                    return image
                }
            }

        let targetFileName = sanitized.contains(".") ? sanitized : "\(sanitized).png"

        guard let enumerator = fileManager.enumerator(at: merchantsDirectory, includingPropertiesForKeys: nil) else {
            return nil
        }

        for case let url as URL in enumerator {
            if url.lastPathComponent.compare(targetFileName, options: [.caseInsensitive]) == .orderedSame {
                if let image = imageFromURL(url) {
                    #if DEBUG
                    print("📄 Found merchant image in bundle: \(url.lastPathComponent)")
                    #endif
                    return image
                }
            }
        }

        return nil
    }

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

    static func sanitizeFileComponent(_ fileName: String) -> String {
        let sanitized = fileName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\", with: "/")

        let lastComponent = sanitized.components(separatedBy: "/").last ?? sanitized
        if let dotIndex = lastComponent.firstIndex(of: ".") {
            return String(lastComponent[..<dotIndex])
        }
        return lastComponent
    }

    static func romanizedMerchantName(for name: String) -> String {
        if name.canBeConverted(to: .ascii) {
            return name
        }

        let key = name.replacingOccurrences(of: " ", with: "")
        let mapping: [String: String] = [
            "서예나": "Seoyena",
            "서 예나": "Seoyena",
            "서예 나": "Seoyena",
            "앨리스강": "Alicegang",
            "알리스강": "Alicegang",
            "애니박": "Anipark",
            "카타리나최": "Catarinachoi",
            "카타리나 최": "Catarinachoi",
            "진백호": "Jinbaekho",
            "주블수": "Jubulsu",
            "주불수": "Jubulsu",
            "기주리": "Kijuri",
            "김세휘": "Kimsehwui",
            "마리": "Mari"
        ]

        if let mapped = mapping[key] {
            return mapped
        }
        if let mapped = mapping[name] {
            return mapped
        }
        return name
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
