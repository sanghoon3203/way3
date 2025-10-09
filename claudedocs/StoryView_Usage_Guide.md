# StoryView Usage Guide

## ✅ 수정 완료 사항

### 1. 동적 스토리 ID 지원
- **이전**: `StoryView()`는 항상 `"prologue_01"`부터 시작
- **이후**: 어떤 스토리 노드든 시작 가능

```swift
// 프롤로그 시작
StoryView(startNodeID: "prologue_01")

// 챕터1 시작
StoryView(startNodeID: "chapter1_01")

// 상인별 스토리 시작
StoryView(startNodeID: "merchant_seoyena_01")
```

### 2. 스토리 완료 콜백 추가
- 스토리가 끝났을 때 호출되는 콜백 함수 지원

```swift
StoryView(startNodeID: "prologue_01") {
    print("프롤로그 완료!")
    // 보상 지급, 다음 화면 이동 등
}
```

### 3. JSON 파일 로드 개선
- **3단계 검색 전략**으로 파일을 더 잘 찾음:
  1. Bundle 직접 검색
  2. 서브디렉토리 검색 (`StoryData`, `Resources/Story` 등)
  3. URL 기반 전체 번들 검색

## 📖 사용 방법

### 기본 사용법

```swift
import SwiftUI

struct MyView: View {
    @State private var showStory = false

    var body: some View {
        Button("스토리 시작") {
            showStory = true
        }
        .sheet(isPresented: $showStory) {
            StoryView(startNodeID: "prologue_01")
        }
    }
}
```

### 상인 스토리 시작

```swift
struct MerchantView: View {
    let merchant: Merchant
    @State private var showStory = false

    var body: some View {
        Button("대화하기") {
            showStory = true
        }
        .fullScreenCover(isPresented: $showStory) {
            // 상인별 스토리 ID 사용
            StoryView(startNodeID: "\(merchant.id)_story_01") {
                print("상인 \(merchant.name)의 스토리 완료!")
            }
        }
    }
}
```

### 챕터 선택 시스템

```swift
struct ChapterSelectView: View {
    let chapters = ["prologue_01", "chapter1_01", "chapter2_01"]
    @State private var selectedChapter: String?

    var body: some View {
        List {
            ForEach(chapters, id: \.self) { chapterID in
                Button("챕터 \(chapterID)") {
                    selectedChapter = chapterID
                }
            }
        }
        .sheet(item: $selectedChapter) { chapterID in
            StoryView(startNodeID: chapterID) {
                print("챕터 \(chapterID) 완료!")
            }
        }
    }
}
```

### 보상 시스템과 통합

```swift
struct StoryWithRewards: View {
    @EnvironmentObject var player: Player
    @State private var showStory = false

    var body: some View {
        Button("스토리 플레이") {
            showStory = true
        }
        .fullScreenCover(isPresented: $showStory) {
            StoryView(startNodeID: "quest_merchant_01") {
                // 스토리 완료 시 보상
                player.core.earnMoney(5000)
                player.core.gainExperience(100)
                print("보상 지급 완료!")
            }
        }
    }
}
```

## 🔧 JSON 파일 구조

스토리 JSON 파일은 다음과 같은 구조여야 합니다:

```json
{
  "node_id": "prologue_01",
  "background_image": "bg_seoul_night",
  "character_id": "narrator",
  "character_sprite": "narrator_neutral",
  "dialogue_text": "서울의 밤이 깊어간다...",
  "dialogue_sound_id": null,
  "sound_effect": null,
  "next_node_id": "prologue_02"
}
```

### 필수 필드
- `node_id`: 노드 고유 ID
- `dialogue_text`: 대사 텍스트

### 선택 필드
- `background_image`: 배경 이미지 이름 (없으면 검은색 그라데이션)
- `character_id`: 캐릭터 ID (화자 표시)
- `character_sprite`: 캐릭터 스프라이트 이미지
- `next_node_id`: 다음 노드 ID (없으면 스토리 종료)

## 🗂️ 파일 위치

JSON 파일은 다음 위치 중 하나에 배치:

1. **추천**: `way3/StoryData/`
2. `way3/Resources/Story/`
3. `way3/Resources/StoryData/`

**중요**: Xcode에서 파일을 프로젝트에 추가할 때 **"Add to targets: way3"** 체크 필수!

## 🎬 스토리 노드 체인 예시

```
prologue_01 → prologue_02 → prologue_03 → ... → prologue_end
                                                      ↓
                                              chapter1_01 → ...
```

각 노드는 `next_node_id`로 다음 노드를 지정하여 체인 형성.

## 🐛 트러블슈팅

### "file not found" 에러가 발생하면:

1. **Xcode 프로젝트에 파일 추가 확인**:
   - 프로젝트 네비게이터에서 파일이 보이는지 확인
   - 파일 인스펙터에서 "Target Membership"이 체크되어 있는지 확인

2. **파일 이름 확인**:
   - `prologue_01.json` (정확한 이름)
   - 대소문자 구분됨

3. **Clean Build**:
   - Xcode → Product → Clean Build Folder (⇧⌘K)
   - 다시 빌드

### 로그 확인하기

```swift
// Xcode Console에서 다음 로그 확인:
// ✅ decoded node_id=prologue_01 next=prologue_02
// ❌ file not found: prologue_01.json in bundle
```

## 📝 체크리스트

- [ ] JSON 파일이 Xcode 프로젝트에 추가되어 있음
- [ ] Target Membership이 체크되어 있음
- [ ] 파일 이름이 정확함 (`.json` 확장자 포함)
- [ ] `node_id`와 파일 이름이 일치함
- [ ] `next_node_id`가 실제 존재하는 노드를 가리킴
- [ ] Clean Build 후 테스트 완료

---

**업데이트**: 2025-01-09
**버전**: Way3 v1.0
