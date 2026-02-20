//
//  CharacterAnimationView.swift
//  way3
//
//  Visual Novel Hero Section - Character Animation Layer
//  673×1200 캐릭터 이미지 (PNG for idle, MOV for emotions)
//

import SwiftUI

/// 상인 캐릭터 애니메이션 뷰
struct CharacterAnimationView: View {
    let merchantId: String
    let state: CharacterState
    
    var body: some View {
        Group {
            if let uiImage = loadCharacterImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(673/1200, contentMode: .fit)
                    .transition(.opacity)
            } else {
                // 이미지를 찾을 수 없을 때 플레이스홀더
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(673/1200, contentMode: .fit)
                    .overlay(
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
                            Text(capitalizedName)
                                .font(.cyberpunkCaption())
                                .foregroundColor(.white.opacity(0.5))
                        }
                    )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
    
    /// merchantId (소문자) → 파일명 (첫 글자 대문자)
    private var capitalizedName: String {
        return merchantId.prefix(1).uppercased() + merchantId.dropFirst()
    }
    
    /// 캐릭터 PNG 이미지 로드
    private func loadCharacterImage() -> UIImage? {
        for path in characterImageCandidates() {
            if let image = UIImage(named: path) {
                return image
            }
            if let image = UIImage(named: "\(path).png") {
                return image
            }
        }
        return nil
    }
    
    private func characterImageCandidates() -> [String] {
        var ordered = [String]()
        var seen = Set<String>()
        func append(_ value: String) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { return }
            seen.insert(trimmed)
            ordered.append(trimmed)
        }

        let base = capitalizedName.replacingOccurrences(of: " ", with: "")
        let lowerMerchant = merchantId.replacingOccurrences(of: " ", with: "").lowercased()

        for suffix in state.imageSuffixCandidates {
            append("\(base)\(suffix)")
            append("Merchant/\(base)/\(base)\(suffix)")
            append("Merchant_\(lowerMerchant)\(suffix)")
            append("Merchant/\(base)/Merchant_\(lowerMerchant)\(suffix)")
        }

        append("Merchant_\(lowerMerchant)_face")
        append("Merchant/\(base)/Merchant_\(lowerMerchant)_face")
        append("\(lowerMerchant)")
        append("\(lowerMerchant)_idle")

        return ordered
    }
}
