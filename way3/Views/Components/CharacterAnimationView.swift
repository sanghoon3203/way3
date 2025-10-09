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
            if state.isAnimated {
                // MOV 비디오 애니메이션 (투명 배경)
                LoopingVideoPlayer(videoName: characterVideoPath)
                    .aspectRatio(673/1200, contentMode: .fit)
                    .transition(.opacity)
            } else {
                // 정적 PNG 이미지 - UIImage로 로드
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
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        )
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
    
    /// merchantId (소문자) → 파일명 (첫 글자 대문자)
    private var capitalizedName: String {
        return merchantId.prefix(1).uppercased() + merchantId.dropFirst()
    }
    
    /// 캐릭터 PNG 이미지 로드 (idle 상태용)
    private func loadCharacterImage() -> UIImage? {
        // CharacterState의 파일 명명 규칙에 따라 경로 생성
        let possiblePaths = [
            "\(capitalizedName)",  // Seoyena.png
            "\(capitalizedName)_idle",  // Seoyena_idle.png
            "\(capitalizedName)\(state.fileSuffix)",  // Seoyena_idle.png
            "Merchant/\(capitalizedName)/\(capitalizedName)",  // Merchant/Seoyena/Seoyena.png
            "Merchant/\(capitalizedName)/\(capitalizedName)_idle",  // Merchant/Seoyena/Seoyena_idle.png
            "\(merchantId)",  // seoyena.png (소문자)
            "\(merchantId)_idle"  // seoyena_idle.png (소문자)
        ]
        
        for path in possiblePaths {
            // .png 확장자로 시도
            if let image = UIImage(named: path) {
                print("✅ 캐릭터 이미지 로드 성공: \(path)")
                return image
            }
            // 명시적으로 .png 확장자 추가해서 시도
            if let image = UIImage(named: "\(path).png") {
                print("✅ 캐릭터 이미지 로드 성공: \(path).png")
                return image
            }
        }
        
        print("⚠️ 캐릭터 이미지를 찾을 수 없음. 시도한 경로:")
        possiblePaths.forEach { print("  - \($0)") }
        return nil
    }
    
    /// 캐릭터 MOV 비디오 파일 경로 (animated 상태용)
    private var characterVideoPath: String {
        // CharacterState에 맞는 비디오 파일 경로 생성
        // 예: talking → Seoyena_talking.mov 또는 Seoyena_talk_1.mov
        
        let basePath = "Merchant/\(capitalizedName)/\(capitalizedName)"
        
        // 상태별 비디오 파일 매핑
        switch state {
        case .talking:
            // talk_1과 talk_2 중 랜덤 선택 (다양성)
            let talkNumber = Int.random(in: 1...2)
            let videoPath = "\(basePath)_talk_\(talkNumber)"
            print("🎬 Talking 비디오 경로: \(videoPath)")
            return videoPath
            
        case .happy:
            let videoPath = "\(basePath)_happy"
            print("🎬 Happy 비디오 경로: \(videoPath)")
            return videoPath
            
        case .sad:
            let videoPath = "\(basePath)_sad"
            print("🎬 Sad 비디오 경로: \(videoPath)")
            return videoPath
            
        case .angry:
            let videoPath = "\(basePath)_angry"
            print("🎬 Angry 비디오 경로: \(videoPath)")
            return videoPath
            
        case .surprised:
            let videoPath = "\(basePath)_surprised"
            print("🎬 Surprised 비디오 경로: \(videoPath)")
            return videoPath
            
        default:
            // idle 또는 기타 상태는 여기 오면 안 됨
            let videoPath = "\(basePath)_idle"
            print("⚠️ Unexpected state for video: \(state)")
            return videoPath
        }
    }
}
