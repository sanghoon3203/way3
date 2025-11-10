//
//  CharacterState.swift
//  way3
//
//  Created for Visual Novel Hero Section
//  Character animation state management
//

import Foundation

/// 캐릭터 애니메이션 상태
/// PNG (idle) 또는 MOV (다양한 감정) 표현
enum CharacterState: String, CaseIterable {
    case idle        // 기본 대기 상태 (PNG)
    case talking     // 말하는 중 (MOV)
    case happy       // 기쁨 (MOV)
    case sad         // 슬픔 (MOV)
    case angry       // 화남 (MOV)
    case surprised   // 놀람 (MOV)

    /// MOV 비디오 파일인지 여부
    var isAnimated: Bool {
        return self != .idle
    }

    /// 파일 확장자
    var fileExtension: String {
        return isAnimated ? "mov" : "png"
    }

    /// 파일명 suffix (예: "seoyena_idle.png", "seoyena_talking.mov")
    var fileSuffix: String {
        return "_\(self.rawValue)"
    }
}

/// 캐릭터 애니메이션 상태 관리 헬퍼
extension CharacterState {
    /// 대사 길이에 따라 적절한 상태 추천
    static func recommendedState(for dialogue: String) -> CharacterState {
        let length = dialogue.count

        if length > 50 {
            return .talking  // 긴 대사는 talking 애니메이션
        } else if dialogue.contains("!") || dialogue.contains("?!") {
            return .surprised  // 느낌표 많으면 surprised
        } else if dialogue.contains("...") {
            return .sad  // 말줄임표는 sad
        } else {
            return .idle  // 기본은 idle
        }
    }

    /// 감정 키워드 기반 상태 추천
    static func stateForEmotion(keyword: String) -> CharacterState {
        switch keyword.lowercased() {
        case "happy", "joy", "기쁨", "좋아":
            return .happy
        case "sad", "sorrow", "슬픔", "아쉬움":
            return .sad
        case "angry", "mad", "화", "분노":
            return .angry
        case "surprised", "shock", "놀람", "깜짝":
            return .surprised
        case "talking", "speaking", "말하는", "대화":
            return .talking
        default:
            return .idle
        }
    }
}
