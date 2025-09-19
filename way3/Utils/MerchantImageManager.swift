//
//  MerchantImageManager.swift
//  way3 - Way Trading Game
//
//  상인 이미지 동적 로드 및 관리 시스템
//  Asset 폴더의 이미지 파일과 상인 이름을 자동 매칭
//

import SwiftUI
import UIKit

// MARK: - 상인 이미지 관리자
class MerchantImageManager: ObservableObject {
    static let shared = MerchantImageManager()

    // MARK: - 이미지 캐시
    @Published private var imageCache: [String: UIImage] = [:]
    private var loadingImages: Set<String> = []

    private init() {
        preloadCommonImages()
    }

    // MARK: - 상인 이미지 이름 매칭
    static func getImageName(for merchantName: String) -> String {
        // 1. 기본 변환: 공백 제거, 특수문자 정리
        let cleanName = merchantName
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .lowercased()

        // 2. 가능한 이미지 파일명 패턴들
        let possibleNames = [
            // 직접 매칭
            merchantName,                           // "Alice Gang"
            cleanName,                             // "alicegang"
            merchantName.replacingOccurrences(of: " ", with: ""), // "AliceGang"

            // Asset 폴더명 기반 매칭
            "\(cleanName)/image",                  // "alicegang/image"
            "\(cleanName)/portrait",               // "alicegang/portrait"
            "\(cleanName)/character",              // "alicegang/character"
            "\(cleanName)/merchant",               // "alicegang/merchant"

            // 소문자 변형
            cleanName.lowercased(),                // "alicegang"
            merchantName.lowercased().replacingOccurrences(of: " ", with: ""),

            // Prefix/Suffix 패턴
            "merchant_\(cleanName)",               // "merchant_alicegang"
            "\(cleanName)_merchant",               // "alicegang_merchant"
            "char_\(cleanName)",                   // "char_alicegang"
            "\(cleanName)_char"                    // "alicegang_char"
        ]

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

        // 5. 기본 이미지 반환
        #if DEBUG
        print("⚠️ No image found for merchant: \(merchantName), using default")
        #endif
        return "default_merchant"
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
    func loadImage(for merchantName: String) -> UIImage? {
        let imageName = Self.getImageName(for: merchantName)

        // 캐시에서 확인
        if let cachedImage = imageCache[imageName] {
            return cachedImage
        }

        // 이미 로딩 중인지 확인
        guard !loadingImages.contains(imageName) else {
            return nil
        }

        // 로딩 시작
        loadingImages.insert(imageName)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let image = UIImage(named: imageName) {
                DispatchQueue.main.async {
                    self?.imageCache[imageName] = image
                    self?.loadingImages.remove(imageName)
                    self?.objectWillChange.send()
                }
            } else {
                DispatchQueue.main.async {
                    self?.loadingImages.remove(imageName)
                }
            }
        }

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

// MARK: - SwiftUI View Extension
extension View {
    func merchantImage(merchantName: String, width: CGFloat = 120, height: CGFloat = 120) -> some View {
        MerchantImageView(merchantName: merchantName, width: width, height: height)
    }
}

// MARK: - 상인 이미지 뷰 컴포넌트
struct MerchantImageView: View {
    let merchantName: String
    let width: CGFloat
    let height: CGFloat

    @StateObject private var imageManager = MerchantImageManager.shared

    var body: some View {
        Group {
            if let image = imageManager.loadImage(for: merchantName) {
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
                .stroke(Color.gold, lineWidth: 3)
                .shadow(color: Color.gold.opacity(0.5), radius: 8)
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
                            Color.gold.opacity(0.8),
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

// MARK: - 상인 타입별 기본 색상 확장
extension MerchantType {
    var jrpgColor: Color {
        switch self {
        case .general:
            return .blue
        case .weaponsmith:
            return .red
        case .armorsmith:
            return .orange
        case .potion:
            return .green
        case .magic:
            return .purple
        case .rare:
            return .gold
        }
    }

    var jrpgIconName: String {
        switch self {
        case .general:
            return "bag.fill"
        case .weaponsmith:
            return "hammer.fill"
        case .armorsmith:
            return "shield.fill"
        case .potion:
            return "flask.fill"
        case .magic:
            return "sparkles"
        case .rare:
            return "star.fill"
        }
    }
}