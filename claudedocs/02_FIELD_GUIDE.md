# WAY3 Project Field Guide

WAY3 iOS 클라이언트의 런타임 아키텍처와 코드 레벨 구조를 빠르게 파악하기 위한 레퍼런스 문서입니다.
새로운 개발자/AI 에이전트가 즉시 투입될 수 있도록 핵심 정보를 압축했습니다.

---

## 1. 기술 스택 요약

| 분류 | 기술 |
|------|------|
| 언어 | Swift 5.9 |
| UI 프레임워크 | SwiftUI + Combine |
| 지도 | MapboxMaps (3D Puck, 45° bearing, 65° pitch) |
| 위치 | CoreLocation |
| 네트워크 | URLSession (커스텀 NetworkManager) |
| 실시간 | Socket.IO Swift 클라이언트 |
| 보안 | iOS Keychain (SecureStorage) |
| 로컬 저장 | JSON 파일 (PlayerDataManager) + UserDefaults |
| 폰트 | ChosunCentennial_otf.otf (커스텀 한글 폰트) |
| OCR | Vision framework (영수증 인증, 구현 예정) |
| 오디오 | AVFoundation (SFXManager, LoopingVideoPlayer) |

---

## 2. 앱 진입점 및 생명주기

```
way3App.swift (@main)
  - 환경 객체 등록: NetworkManager, LocationManager, GameManager,
                    AuthManager, ProgressManager, QuestManager,
                    StoryFlowManager, MerchantDataManager,
                    DialogueDataManager, TradeManager, AuctionManager,
                    SocketManager, PlayerDataManager
  - LocationManager (CLLocationDelegate) 초기화

ContentView.swift
  - 인증 상태에 따라 라우팅:
    StartView → LoginView → MainTabView
  - ScenePhase 감시 → 백그라운드 전환 시 자동 저장
  - FontSystemManager.validateChosunFont() 호출
```

---

## 3. 디렉토리 구조 (코드)

```
way3/
├── way3App.swift
├── ContentView.swift
│
├── Core/                       ← 핵심 싱글톤 매니저
│   ├── AuthManager.swift       — JWT 로그인/회원가입/로그아웃/비밀번호 재설정
│   ├── NetworkManager.swift    — REST 클라이언트, 토큰 관리, 재시도 로직
│   ├── QuestManager.swift      — 퀘스트 실행 엔진 (GPS/OCR/스토리 검증)
│   ├── ProgressManager.swift   — 오프라인 저장 (챕터/에피소드/퀘스트 진행도)
│   ├── StoryCore.swift         — VN 엔진 (VNNode, TypewriterEngine, SFXManager)
│   ├── StoryUnlockEvaluator.swift — StoryUnlockCondition 평가
│   ├── MerchantDataManager.swift  — 상인 인벤토리/관계도 캐시
│   ├── DialogueDataManager.swift  — 상인 대화 스크립트 로더
│   ├── LocationVerifier.swift  — GPS 위치 검증
│   ├── ReceiptVerifier.swift   — 영수증 OCR 검증 (Vision)
│   ├── RewardProcessor.swift   — 퀘스트 보상 처리
│   ├── TradeManager.swift      — 거래 로직, 가격 계산
│   ├── SocketManager.swift     — Socket.IO (근처 플레이어, 가격 변동)
│   ├── APIResponse.swift       — 서버 응답 래퍼
│   ├── ErrorAlert.swift        — 에러 표시 헬퍼
│   └── GameLogger.swift        — os.Logger 기반 구조적 로깅
│
├── Managers/                   ← 상위 오케스트레이터
│   ├── GameManager.swift       — 중앙 게임 상태 허브 (플레이어, 상인, 알림)
│   ├── StoryFlowManager.swift  — 에피소드 완료 파이프라인
│   ├── StoryHubDataProvider.swift — Story Hub UI용 데이터 빌더
│   └── StoryRewardService.swift   — 스토리 보상 배포
│
├── Models/                     ← 데이터 구조
│   ├── Player/
│   │   ├── PlayerCore.swift        — 이름/레벨/돈/경험치
│   │   ├── PlayerStats.swift       — 힘/지능/매력/행운 + 스킬
│   │   ├── PlayerInventory.swift   — 인벤토리 + 창고
│   │   ├── PlayerRelationships.swift — 상인 관계도
│   │   ├── PlayerAchievements.swift  — 업적
│   │   └── PlayerDataManager.swift   — JSON 직렬화, 자동 백업
│   ├── QuestModels.swift       — SubQuest, QuestRequirements, QuestRewards
│   ├── MainQuestDefinition.swift — MainQuestDefinition + MainQuestRepository
│   ├── StoryChapterDefinition.swift — 챕터/지역/에피소드 구조
│   ├── StoryChapterAPI.swift   — 서버 응답 DTO
│   ├── Merchant.swift          — Merchant 구조체
│   ├── GameEnums.swift         — ItemGrade, LicenseLevel, SeoulDistrict 등
│   ├── TradeItem.swift         — 거래 아이템
│   ├── PersonalItem.swift      — 장비 아이템
│   ├── Achievement.swift       — 업적 정의
│   ├── District.swift          — DistrictLoader
│   └── CharacterState.swift    — VN 캐릭터 표시 상태
│
├── ViewModels/
│   ├── StoryViewModel.swift         — 스토리 허브 뷰 로직
│   └── MerchantDetailViewModel.swift — 상인 상세 화면 로직
│
├── Views/
│   ├── Game/MainTabView.swift       — CyberpunkEnhancedTabView (5탭)
│   ├── Map/MapView.swift            — Mapbox 3D 맵 + 상인 핀
│   ├── Merchant/
│   │   ├── MerchantDetailView.swift       — JRPG 스타일 상인 대화
│   │   └── MerchantDetailViewExtensions.swift
│   ├── Quest/
│   │   ├── QuestCenterView.swift    — 퀘스트 허브
│   │   ├── QuestDetailView.swift    — 퀘스트 상세 + 실행
│   │   └── QuestView.swift          — Quest 탭 래퍼
│   ├── Story/
│   │   ├── StoryHubTabView.swift    — 스토리 허브 (메인/상인 필터)
│   │   ├── StoryView.swift          — VN 렌더러
│   │   └── StoryChapterDetailView.swift — 챕터 진행도
│   ├── Auth/
│   │   ├── StartView.swift, LoginView.swift, RegisterView.swift
│   │   ├── ProfileInputView.swift, ForgotPasswordView.swift
│   ├── Player/
│   │   ├── InventoryView.swift, SkillTreeView.swift
│   ├── Profile/ProfileView.swift
│   ├── Shop/ShopView.swift
│   └── Components/
│       ├── BackgroundImageView.swift, BackgroundVideoLayer.swift
│       ├── CharacterAnimationView.swift, LoadingView.swift
│       ├── LoopingVideoPlayer.swift, VisualNovelDialogueBox.swift
│
├── Components/                 ← 사이버펑크 디자인 시스템
│   ├── CyberpunkComponents.swift          — 버튼, 카드, 오버레이
│   ├── CyberpunkInventoryComponents.swift — 인벤토리 그리드/카드
│   ├── CyberpunkNavigationComponents.swift — 네비게이션 바
│   ├── CyberpunkProfileComponents.swift   — 프로필 스탯 바
│   └── CyberpunkQuestComponents.swift     — 퀘스트 카드
│
├── Utils/
│   ├── CyberpunkDesignSystem.swift  — 색상/타이포/간격 상수
│   └── MerchantImageManager.swift   — 상인 이미지 로더
│
├── Extensions/
│   ├── Color+GameColors.swift       — .cyberpunkYellow, .cyberpunkCyan 등
│   ├── Font+ChosunSystem.swift      — .cyberpunkCaption(), defaultChosunFont()
│   └── CLLocationCoordinate2D+Codable.swift
│
└── Security/
    └── SecureStorage.swift          — iOS Keychain 래퍼
```

---

## 4. 핵심 데이터 흐름

### 4.1 스토리 진행 흐름

```
StoryHubTabView (에피소드 선택)
  → StoryView (VN 렌더링)
    → StoryCore.VNLoader (JSON 로드)
    → TypewriterEngine (타이핑 애니메이션)
    → SFXManager (효과음)
  → StoryFlowManager.makeCompletionHandler()
    → ProgressManager.markEpisodeComplete()
    → StoryUnlockEvaluator (다음 에피소드 조건 평가)
    → MainQuestRepository (post_quest_id → MainQuestDefinition)
    → QuestManager.enqueueMainQuest()
    → RewardProcessor (보상 지급)
```

### 4.2 퀘스트 실행 흐름

```
QuestCenterView (퀘스트 목록)
  → DistrictLoader (districts.json)
  → QuestManager.activateSubQuest()
    ├── [dialogue] VNNode 완료 감지
    ├── [delivery] LocationVerifier.verifyLocationWithAccuracy()
    └── [trading]  GPS + ReceiptVerifier.verifyReceipt() (OCR)
  → 검증 성공 → RewardProcessor
    → ProgressManager.markSubQuestComplete()
    → 다음 체인 퀘스트 해금
```

### 4.3 거래 흐름

```
MapView (상인 핀 탭)
  → MerchantDetailView
    → MerchantDetailViewModel
      → MerchantDataManager.fetchInventory()
      → TradeManager.executeTrade()
        → NetworkManager POST /api/trade/execute
        → PlayerInventory 업데이트
```

---

## 5. VNNode JSON 구조

### dialogue 노드 (기본)
```json
{
  "node_id": "prologue_001",
  "background_image": "bg_player_room_morning",
  "character_id": "주인공",
  "character_sprite": null,
  "dialogue_text": "...",
  "dialogue_sound_id": null,
  "sound_effect": null,
  "next_node_id": "prologue_002"
}
```

### decision 노드 (선택지)
```json
{
  "node_id": "gangnam_015",
  "type": "decision",
  "dialogue_text": "어떻게 할까요?",
  "choices": [
    {"text": "받아들인다", "next_node_id": "gangnam_016a"},
    {"text": "거절한다",  "next_node_id": "gangnam_016b"}
  ]
}
```

### TypewriterEngine 속도 태그
- `<s>` — 느리게
- `<n>` — 보통
- `<f>` — 빠르게
- `<t>` — 순간 표시

---

## 6. PlayerProgress 구조 (로컬 저장, v4)

```swift
struct PlayerProgress: Codable {
  var completedChapters:    [String]        // "ch0_prologue", "ch1_gangnam"
  var completedDistricts:   [String]        // "gangnam_gu"
  var completedSubQuests:   [String]        // "subquest_seoyena_01_dialogue"
  var completedMainQuests:  [String]        // "mainquest_gangnam_1_1"
  var completedEpisodes:    [String]        // 에피소드 ID
  var unlockedEpisodes:     [String]        // 해금된 에피소드
  var collectedStoryPieces: [String]        // 스토리 조각 ID
  var keyItems:             [String]        // "key_item_gangnam" 등
}
```

---

## 7. 알려진 이슈 및 TODO

| 우선순위 | 이슈 | 위치 |
|---------|------|------|
| 🔴 높음 | `MainQuestDefinition`의 `requiredEpisodes`/`requiredSubQuests`가 JSON 디코딩 안 됨 (항상 `[]`) | `Models/MainQuestDefinition.swift` |
| 🔴 높음 | 강동 스토리 노드 018–063 누락 | `StoryData/Gangdong/` |
| 🟡 중간 | 경매 Socket.IO 이벤트 미구현 (`get_auctions`, `create_auction`, `cancel_bid`) | `Core/AuctionManager.swift`, `Core/SocketManager.swift` |
| 🟡 중간 | 서북권 서브스토리 JSON 없음 (기주리, 카타리나 최, 마리, 김세휘) | `StoryData/Substories/` |
| 🟢 낮음 | `theway_server/` 소스가 리포에 없음 → 외부 저장소 연동 필요 | 리포 루트 |
| 🟢 낮음 | MapboxMaps `@_spi(Experimental)` import 사용 → SDK 업데이트 시 빌드 이슈 가능 | `Views/Map/MapView.swift` |
| 🟢 낮음 | 대형 에셋 (영상/사운드) Git LFS 전략 미수립 | `Resources/` |

---

## 8. 빌드 및 실행

```bash
# iOS 앱
open way3.xcodeproj
# Xcode → Signing 설정 → Cmd+R

# CLI 빌드
xcodebuild -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build

# 테스트
xcodebuild test -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# 스토리 데이터 변경 후 앱 재실행 → ProgressManager가 자동 갱신
```

---

## 9. 콘텐츠 데이터 위치

| 데이터 | 경로 | 비고 |
|--------|------|------|
| 챕터/에피소드 정의 | `GameData/Story/story_main_chapters.json` | 7개 챕터 |
| 지역/상인/서브퀘스트 | `GameData/Districts/districts.json` | 25개 구 |
| 메인 퀘스트 | `GameData/Quests/main_quests.json` | ch1–ch2 완성 |
| 서브퀘스트 상세 | `GameData/Story/SubQuests/` | Seoyena, Alicegang |
| VN 스토리 노드 | `StoryData/` | ~668개 JSON |
| 상인 리소스 | `Resources/Merchant/` | 9명 이미지/영상 |
| 배경 이미지 | `Resources/images/backgrounds/` | 강남/서예나/프롤로그 |
| 캐릭터 이미지 | `Resources/images/characters/` | kijuri.png, seoyena.png |
| 사운드 | `Resources/Sound/` | BGM + SFX |

---

**버전**: 2.0.0
**최종 업데이트**: 2026-02-12
