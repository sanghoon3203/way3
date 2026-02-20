# WAY3 — CLAUDE.md

## 프로젝트 개요
- **이름**: connect:seoul (구 WAY3)
- **플랫폼**: iOS SwiftUI (Swift 5.9, iOS 17+, Xcode 15+)
- **장르**: GPS 기반 위치 인증 트레이딩 RPG + Visual Novel
- **배경**: 서울 25개 구 (네오 서울 세계관)
- **서버**: Node.js/Express + SQLite3 → Railway.app

## 소통 언어
**한국어**로 소통합니다.

## 문서 구조
```
claudedocs/
  00_INDEX.md          ← 새 세션 시작 시 첫 참고
  01_PROJECT_OVERVIEW.md ← 게임 컨셉, API, DB 스키마, 로드맵
  02_FIELD_GUIDE.md    ← iOS 코드 구조, 데이터 흐름, 빌드 방법
  03_GAME_SYSTEM.md    ← VNNode/퀘스트 JSON 스키마
  04_UI_SYSTEM.md      ← 조선사이버펑크 디자인 시스템
  05_AI_CHAT_SYSTEM.md ← AI 상인 채팅 시스템
  status/STORY_STATUS.md ← 스토리 노드 완성도 현황
  status/QUEST_STATUS.md ← 퀘스트 현황 + 버그 목록
Story/
  설정집/Main.md       ← 25개 구 세계관 설정
  CharacterStory/      ← 권역별 캐릭터 바이블
  mushoku_style_notes.md ← 문체 가이드 (무직전생 스타일)
```

## iOS 앱 구조 (way3/ 폴더)
```
Core/         — 싱글톤 매니저 (Auth, Network, Quest, Story, Location, Trade...)
Managers/     — 오케스트레이터 (GameManager, StoryFlowManager...)
Models/       — 데이터 구조체 + 서버 DTO
ViewModels/   — 화면별 뷰모델
Views/        — SwiftUI 화면
Components/   — 조선사이버펑크 디자인 시스템 (CyberpunkChatComponents 포함)
Utils/        — CyberpunkDesignSystem (색상/타이포 상수)
GameData/     — 로컬 JSON (권위 데이터): districts.json, main_quests.json, story_main_chapters.json
StoryData/    — VNNode JSON (~668개): Prologue/, Gangnam/, Seocho/, Songpa/, Gangdong/, Substories/
Resources/    — 이미지, 영상, 사운드, font/ (ChosunCentennial + Pretendard)
```

## VNNode JSON 포맷
```json
{
  "node_id": "prologue_001",
  "background_image": "bg_player_room_morning",
  "character_id": "주인공",
  "dialogue_text": "...",
  "next_node_id": "prologue_002"
}
```
타입: `dialogue` / `decision` (choices 배열) / `conditional` / `quest_gate`

## 스토리 데이터 현황
| 챕터 | 노드 수 | 상태 |
|------|--------|------|
| 프롤로그 | 74 | ✅ |
| 강남 | 52 | ✅ |
| 서초 | 77 | ✅ |
| 송파 | 82 | ✅ |
| 강동 | 42 | ⚠️ 018~063 누락 (46개) |
| 서북권 이후 | 0 | ❌ |
| **서브스토리** | 서예나 152 / 앨리스강 59 / 애니박 66 / 진백호 26 / 주블수 20 | |

## 상인 9명
| 상인 | 구역 | 서브스토리 |
|------|------|-----------|
| 서예나 | 강남구 압구정 | ✅ 완성 |
| 앨리스강 | 서초구 서래마을 | ⚠️ 부분 |
| 애니박 | 송파구 잠실 | ⚠️ 부분 |
| 진백호 | 강동구 천호동 | ⚠️ 부분 |
| 주블수 | 강동구 천호동 | ⚠️ 부분 |
| 김세휘 | 관악구 서울대 | ❌ |
| 기주리 | 종로구 경복궁 | ❌ |
| 카타리나 최 | 중구 명동성당 | ❌ |
| 마리 | 마포구 홍대 | ❌ |

## 알려진 버그 (우선순위순)
1. **🔴** `Models/MainQuestDefinition.swift`: `requiredEpisodes`/`requiredSubQuests`가 `= []`로 하드코딩 — JSON 디코딩 안 됨
2. **🔴** `StoryData/Gangdong/`: 018~063 번호 누락 (46개 노드 필요)
3. **🟡** `Views/Shop/ShopView.swift`: 상점 시스템 미구현 (stub 상태)
4. **🟡** `StoryData/Substories/`: 서북권 4명 서브스토리 JSON 없음

## 빌드
```bash
# iOS
open way3.xcodeproj
# Xcode → Signing → Cmd+R

# CLI
xcodebuild -scheme way3 -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## 코딩 컨벤션
- SwiftUI + Combine 패턴 (MVVM)
- **색상**: `.joseonCheong`, `.joseonJeok`, `.joseonHwang`, `.joseonBaek`, `.joseonHeuk` (오방색 네온)
  - `Color(hex:)` 사용 금지 → `Color(red:green:blue:)` 또는 정의된 상수 사용
- **폰트**:
  - 타이틀/헤딩/버튼: `.chosunH1~H3`, `.chosunTitle`, `.chosunButton` (ChosunCentennial)
  - 바디/캡션/기술: `.cyberpunkBody()`, `.cyberpunkCaption()`, `.cyberpunkTechnical()` (Pretendard)
  - 시스템 폰트(`.title2`, `.body` 등) 직접 사용 금지
- 로깅: `GameLogger` (os.Logger 기반)
- 보안: `SecureStorage` (Keychain) — Access Token, Refresh Token, User ID

## 스토리 문체
- 1인칭 내러티브, 짧은 문장 (평균 6단어)
- 감각 묘사 → 감정 서술 순서
- 말줄임표(...) = 머뭇거림
- 참고: `Story/mushoku_style_notes.md`
