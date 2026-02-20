# connect:seoul 워크플로우 상세 문서

현재 구현된 시스템의 전체 동작 흐름을 코드 레벨로 기술합니다.

**최종 업데이트**: 2026-02-20

---

## 1. 앱 진입 흐름

### 1.1 앱 시작 및 환경 객체 초기화

```
way3App.swift (@main)
  ├─ NetworkManager.shared          — REST 클라이언트, 토큰 자동 갱신
  ├─ LocationManager()              — CLLocationManager 래퍼, GPS 스트림
  ├─ GameManager.shared             — 중앙 게임 상태 (플레이어, 상인 캐시)
  └─ AuthManager.shared             — JWT 로그인/회원가입/로그아웃
```

### 1.2 인증 라우팅

```
ContentView.swift
  │
  ├─ authManager.isAuthenticated == false
  │    └─ StartView
  │         ├─ → LoginView
  │         │    └─ AuthManager.login(email, password)
  │         │         → POST /api/auth/login
  │         │         → SecureStorage에 accessToken, refreshToken 저장
  │         │         → authManager.isAuthenticated = true
  │         │
  │         └─ → RegisterView
  │              └─ AuthManager.register(...)
  │                   → POST /api/auth/register
  │                   → 자동 로그인 처리
  │
  └─ authManager.isAuthenticated == true
       └─ MainTabView (5탭)
```

### 1.3 토큰 만료 처리

```
NetworkManager.request()
  └─ 서버 401 응답 수신
       └─ AuthManager.refreshTokenIfNeeded()
            → POST /api/auth/refresh (Refresh Token 사용)
            ├─ 성공 → 새 accessToken 저장 후 원래 요청 재시도
            └─ 실패 → SecureStorage 초기화 → LoginView로 이동
```

---

## 2. 핵심 게임 루프

### 2.1 맵 화면 → 상인 탭

```
MapView.swift
  │
  ├─ onAppear
  │    └─ GameManager.loadMerchants()
  │         → GET /api/merchants/nearby?lat=&lng=&radius=
  │         → merchantAnnotations 업데이트 (Mapbox 핀)
  │
  ├─ GPS 위치 갱신 (LocationManager)
  │    └─ MapboxMaps 카메라 추적 (45° bearing, 65° pitch)
  │
  └─ 상인 핀 탭
       └─ MerchantDetailView(merchant:)  [sheet 또는 push]
```

### 2.2 MerchantDetailView 4탭 구조

```swift
enum MerchantDetailTab {
    case dialogue   // VN 스토리 에피소드 목록
    case trade      // 상인 인벤토리 거래
    case story      // 관계도 진행 현황
    case chat       // AI 자유대화 (Gemini)
}
```

```
MerchantDetailView
  ├─ [대화] 탭 ─────────────────────── 섹션 3 참조
  ├─ [거래] 탭 ─────────────────────── 섹션 4.1 참조
  ├─ [스토리] 탭 ── 관계도 단계(0~4) + 서브퀘스트 진행 현황 표시
  └─ [AI대화] 탭 ──────────────────── 섹션 4.2 참조
```

---

## 3. 스토리/VN 진행 흐름

### 3.1 에피소드 목록 구성

```
StoryHubTabView (스토리 탭)
  └─ StoryHubDataProvider.buildSections()
       ├─ story_main_chapters.json  (챕터/에피소드 정의)
       ├─ ProgressManager.completedEpisodes  (완료 여부)
       └─ StoryUnlockEvaluator.isUnlocked(episode)
            └─ 조건 평가: 레벨, key_item, completedEpisodes
```

### 3.2 VN 에피소드 재생

```
StoryView.swift
  │
  ├─ onAppear
  │    └─ StoryCore.VNLoader.loadNodes(episodeId)
  │         → StoryData/{챕터}/{episodeId}.json 로드
  │         → [VNNode] 배열 반환
  │
  ├─ 대화 진행 (TypewriterEngine)
  │    ├─ dialogue 노드 → 텍스트 타이핑 애니메이션
  │    │    └─ 속도 태그: <s>느리게 <n>보통 <f>빠르게 <t>순간표시
  │    ├─ decision 노드 → 선택지 버튼 렌더링 → 분기 이동
  │    ├─ conditional 노드 → PlayerProgress/인벤토리 조건 평가 후 분기
  │    └─ quest_gate 노드 → QuestManager 상태 체크
  │
  ├─ 배경/캐릭터 이미지
  │    └─ background_image → Resources/images/backgrounds/{id}.jpg
  │    └─ character_sprite → Resources/images/characters/{id}.png
  │
  └─ 에피소드 완료 (마지막 노드 도달)
       └─ StoryFlowManager.makeCompletionHandler(episode)
            ├─ ProgressManager.markEpisodeComplete(episodeId)  [로컬 저장]
            ├─ POST /{merchantId}/story/progress               [서버 동기화]
            ├─ StoryUnlockEvaluator → 다음 에피소드 해금 여부 평가
            ├─ MainQuestRepository.findQuest(post_quest_id)
            │    → QuestManager.enqueueMainQuest()
            └─ RewardProcessor.grantRewards(episode.rewards)
                 ├─ 돈, 경험치 → PlayerCore 업데이트
                 └─ key_item → PlayerInventory에 추가
```

### 3.3 챕터 해금 체인

```
ch0_prologue  ──────────────────────────── 항상 해금
  └─ ch1_gangnam                           레벨 1+
       └─ ch2_northwest                    key_item_gangnam + 레벨 5+
            └─ ch3_northeast              key_item_northwest + 레벨 10+
                 └─ ch4_southwest         key_item_northeast + 레벨 15+
                      └─ ch5_eastwest     key_item_southwest + 레벨 20+
                           └─ ch6_final  5개 열쇠 아이템 ALL + 레벨 25+
```

---

## 4. 거래 및 AI 채팅 흐름

### 4.1 아이템 거래 흐름

```
MerchantDetailView [거래] 탭
  │
  ├─ onAppear
  │    └─ MerchantDataManager.fetchInventory(merchantId)
  │         → GET /api/merchants/{id}
  │         → 상인 인벤토리 캐시 업데이트
  │
  ├─ 매입 (플레이어가 구매)
  │    └─ TradeManager.executeTrade(type: .buy, item, quantity)
  │         ├─ 라이선스 등급 체크 (item.required_license ≤ player.license)
  │         ├─ 잔액 체크 (player.money ≥ totalPrice)
  │         └─ POST /api/trade/execute
  │              → trade_records DB 저장
  │              → PlayerInventory.addItem()
  │              └─ 경험치 지급 → LevelUpProcessor
  │
  └─ 매도 (플레이어가 판매)
       └─ TradeManager.executeTrade(type: .sell, item, quantity)
            ├─ PlayerInventory에 해당 아이템 존재 여부 체크
            └─ POST /api/trade/execute
                 → player.money 증가
                 → PlayerInventory.removeItem()
```

### 4.2 AI 상인 채팅 흐름

```
MerchantDetailView [AI대화] 탭
  │
  └─ MerchantAIChatView(merchant:)
       │
       ├─ init
       │    └─ MerchantChatViewModel(merchant:)
       │         └─ addWelcomeMessage()  — 첫 인사 메시지 추가
       │
       ├─ 메시지 전송 (ChatInputBar → 전송 버튼 / Return 키)
       │    └─ MerchantChatViewModel.sendMessage()
       │         ├─ messages에 플레이어 메시지 추가
       │         ├─ isLoading = true  (타이핑 인디케이터 표시)
       │         └─ callMerchantChatAPI(userMessage)
       │              │
       │              ├─ Request Body
       │              │    {
       │              │      merchantId: merchant.id,
       │              │      message: userMessage,
       │              │      history: messages.suffix(10)  // 최근 10개
       │              │    }
       │              │
       │              ├─ Header: Authorization: Bearer {accessToken}
       │              │
       │              └─ POST /api/merchant-chat
       │                   │
       │                   └─ way-server
       │                        ├─ merchantPersonas[merchantId].basePrompt 조합
       │                        ├─ checkUnlockTriggers(message)  키워드 매칭
       │                        └─ Gemini 1.5 Flash API 호출
       │                             └─ { reply, unlockedEpisode }
       │
       ├─ 응답 처리
       │    ├─ messages에 상인 메시지 추가
       │    └─ unlockedEpisode != null ?
       │         └─ EpisodeUnlockBanner 표시 (8초 자동 닫힘)
       │              └─ 배너 탭
       │                   ├─ dismissUnlockBanner()
       │                   └─ onEpisodeUnlock(episode) 콜백
       │                        → StoryView(entryNode: episode.entry_node) 재생
       │
       └─ UI 구성
            ├─ ScrollView + LazyVStack (신규 메시지 → 자동 하단 스크롤)
            ├─ MerchantChatBubble
            │    ├─ 플레이어: 우측 정렬, joseonHwang 배경, 꼬리 오른쪽
            │    └─ 상인: 좌측 정렬, joseonPanel 배경, joseonCheong 테두리, 꼬리 왼쪽
            ├─ MerchantTypingIndicator (isLoading 중)
            └─ ChatInputBar (multiline, 최대 4줄)
```

---

## 5. 퀘스트 시스템 흐름

### 5.1 퀘스트 구조

```
MainQuest (메인 퀘스트)
  └─ 에피소드 완료 → StoryFlowManager가 자동 생성
       → post_quest_id 필드로 연결

SubQuest (서브 퀘스트)
  └─ 상인 관계도 단계별 수동 수락
       단계 0→1: 3개 서브퀘스트
       단계 1→2: 3개 서브퀘스트
       단계 2→3: 5개 서브퀘스트
       단계 3→4: 5개 서브퀘스트
```

### 5.2 서브퀘스트 타입별 검증

```
QuestManager.validateSubQuest(quest)

[dialogue 타입]
  └─ StoryCore: 특정 VNNode ID 도달 감지
       → ProgressManager.isNodeVisited(nodeId) == true

[delivery 타입]
  └─ LocationVerifier.verifyLocationWithAccuracy(
         target: quest.targetCoordinate,
         radius: quest.radiusMeters  // 보통 100m
     )
     └─ CLLocation.distance(from:) 계산
          ├─ 범위 내 → 검증 성공
          └─ 범위 외 → "더 가까이 이동해주세요" 안내

[trading 타입]
  └─ [1단계] GPS: LocationVerifier → 상인 400m 이내 확인
  └─ [2단계] OCR: ReceiptVerifier.verifyReceipt(image)
                   └─ Vision framework → 텍스트 추출
                        → 가격/날짜/매장명 패턴 매칭
```

### 5.3 퀘스트 완료 처리

```
QuestManager.completeSubQuest(quest)
  ├─ POST /api/quests/{id}/complete
  ├─ POST /api/merchants/{id}/relationship/progress
  │    → merchant_relationship_quest_log 기록
  │    → friendship_points 증가
  ├─ RewardProcessor.grantRewards(quest.rewards)
  └─ 다음 체인 퀘스트 자동 해금
       └─ quest.next_quest_id → QuestManager.unlockQuest()
```

---

## 6. 데이터 레이어 구조

### 6.1 로컬 vs 서버 데이터 분리 원칙

| 데이터 | 저장소 | 이유 |
|--------|--------|------|
| VNNode JSON | 앱 번들 (읽기 전용) | 오프라인 플레이, 빠른 로드 |
| 플레이어 진행도 | ProgressManager (UserDefaults + JSON) | 오프라인 우선 |
| 플레이어 스탯/돈 | PlayerCore (메모리 + 서버 동기화) | 실시간 반영 |
| 거래 기록 | SQLite (서버) | 통계, 영속성 |
| 상인 관계도 | SQLite (서버) | 멀티 디바이스 동기화 |
| AI 대화 히스토리 | 메모리 (세션 한정) | 서버 미저장, 최근 10개만 전송 |
| Gemini API Key | 서버 환경 변수 | 클라이언트 노출 차단 |
| JWT 토큰 | iOS Keychain (SecureStorage) | 보안 저장소 |

### 6.2 오프라인 우선 전략

```
앱 시작
  └─ ProgressManager.load()
       → UserDefaults / JSON 파일에서 로컬 진행도 로드

네트워크 연결 시
  └─ GameManager.syncProgress()
       → 로컬 데이터를 서버에 동기화 (일부 구현)

오프라인 상태
  └─ VN 스토리 / 퀘스트 진행 → 로컬 JSON으로 계속 가능
     거래 / 관계도 갱신 → 네트워크 필요 (실패 시 에러 표시)
```

### 6.3 PlayerProgress 로컬 저장 구조

```swift
struct PlayerProgress: Codable {
    var completedChapters:    [String]   // "ch0_prologue"
    var completedDistricts:   [String]   // "gangnam_gu"
    var completedSubQuests:   [String]   // "subquest_seoyena_01_dialogue"
    var completedMainQuests:  [String]   // "mainquest_gangnam_1_1"
    var completedEpisodes:    [String]   // 에피소드 ID
    var unlockedEpisodes:     [String]   // AI 채팅 트리거 등으로 해금된 에피소드
    var collectedStoryPieces: [String]   // 스토리 조각
    var keyItems:             [String]   // "key_item_gangnam" 등
}
```

`ProgressManager`가 `PlayerDataManager`를 통해 JSON 파일로 직렬화.
앱 백그라운드 전환(`scenePhase == .background`) 시 자동 저장.

### 6.4 서버 DB 핵심 테이블 관계

```
users (1)
  └─ players (1:1)
       ├─ player_items (1:N)       ← 인벤토리
       ├─ trade_records (1:N)      ← 거래 기록
       └─ merchant_relationships (1:N per merchant)
            └─ merchant_relationship_quest_log (1:N)

merchants (1)
  ├─ merchant_inventory (1:N)     ← 상인 판매 아이템
  ├─ merchant_dialogues (1:N)     ← 대화 스크립트 (레거시)
  └─ story_nodes (1:N)            ← 서버측 스토리 참조 (iOS 번들 우선)

item_templates (1)
  ├─ player_items (N)
  └─ trade_records (N)
```

### 6.5 인증 토큰 흐름

```
로그인 성공
  └─ SecureStorage.saveTokens(access, refresh)
       → iOS Keychain에 암호화 저장

매 API 요청
  └─ NetworkManager.request()
       → Authorization: Bearer {accessToken} 헤더 추가

accessToken 만료 (401)
  └─ NetworkManager.refreshTokenIfNeeded()
       → POST /api/auth/refresh { refreshToken }
       ├─ 성공: 새 accessToken 저장 → 원래 요청 재시도
       └─ 실패: SecureStorage.clear() → 로그인 화면으로

로그아웃
  └─ AuthManager.logout()
       → POST /api/auth/logout (서버 세션 무효화)
       → SecureStorage.clear()
       → authManager.isAuthenticated = false
```

---

## 관련 파일 빠른 참조

| 기능 | iOS 파일 | 서버 파일 |
|------|----------|----------|
| 인증 | `Core/AuthManager.swift` | `routes/api/auth.js` |
| 네트워크 | `Core/NetworkManager.swift` | — |
| VN 엔진 | `Core/StoryCore.swift` | — |
| 스토리 흐름 | `Managers/StoryFlowManager.swift` | `routes/api/story.js` |
| 퀘스트 | `Core/QuestManager.swift` | `routes/api/quests.js` |
| 거래 | `Core/TradeManager.swift` | `routes/api/trade.js` |
| AI 채팅 | `Views/Merchant/MerchantAIChatView.swift` | `routes/api/merchant-chat.js` |
| AI 인격 | — | `constants/merchantPersonas.js` |
| 진행도 저장 | `Core/ProgressManager.swift` | — |
| GPS 검증 | `Core/LocationVerifier.swift` | — |
| 보안 저장 | `Security/SecureStorage.swift` | — |
