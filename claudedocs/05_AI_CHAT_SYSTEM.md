# AI 상인 채팅 시스템

connect:seoul의 Gemini 기반 AI 자유대화 시스템 레퍼런스.

**설계 문서**: `docs/plans/2026-02-20-ai-merchant-chat-design.md`
**최종 업데이트**: 2026-02-20

---

## 1. 개요

상인별 AI 인격을 부여하여 플레이어가 고정 VN 스토리 외에도 자유롭게 대화할 수 있는 시스템.

- **VN 에피소드**: 고정 스토리 (기존 방식 유지)
- **AI 자유대화**: Gemini API 실시간 생성 (새로 추가)
- **에피소드 언락**: 특정 대화 주제가 새 VN 에피소드 트리거 역할

---

## 2. 아키텍처

```
iOS 앱 (MerchantAIChatView)
  └─ POST /api/merchant-chat  (Bearer Token)
       └─ way-server (Node.js)
            ├─ merchantPersonas.js  (상인별 시스템 프롬프트)
            ├─ merchantChatService.js  (Gemini API 호출)
            └─ Gemini API (gemini-1.5-flash)
```

---

## 3. iOS 파일

### `Components/CyberpunkChatComponents.swift`

| 컴포넌트 | 설명 |
|---------|------|
| `ChatMessage` | role(.player/.merchant), text, timestamp |
| `MerchantChatBubble` | 말풍선. 플레이어=joseonHwang 배경, 상인=joseonPanel+joseonCheong 테두리 |
| `BubbleShape` | 꼬리 있는 말풍선 Shape (좌/우 방향) |
| `MerchantTypingIndicator` | joseonCheong 3점 펄싱 애니메이션 |
| `EpisodeUnlockBanner` | 開 도장 씰 + 단청 그라디언트 바, 8초 자동 닫힘 |
| `ChatInputBar` | multiline TextField (최대 4줄) + 전송 버튼 |
| `MerchantTabSelector` | 에피소드 ↔ 대화하기 탭, matchedGeometryEffect 슬라이더 |

### `Views/Merchant/MerchantAIChatView.swift`

**MerchantChatViewModel** (`@MainActor ObservableObject`)

| 프로퍼티/메서드 | 설명 |
|--------------|------|
| `messages: [ChatMessage]` | 채팅 내역 |
| `isLoading: Bool` | API 호출 중 여부 |
| `unlockedEpisode: EpisodeMeta?` | 언락된 에피소드 정보 |
| `showUnlockBanner: Bool` | 배너 표시 여부 |
| `sendMessage()` | 메시지 전송 + API 호출 |
| `callMerchantChatAPI(userMessage:)` | `POST /api/merchant-chat` 호출 |

**MerchantAIChatView**
- ScrollView + LazyVStack (자동 하단 스크롤)
- 언락 배너: ZStack 플로팅 오버레이, `.padding(.bottom, 80)`

### `MerchantDetailView` 수정 내역

```swift
// MerchantDetailTab에 .chat 추가
enum MerchantDetailTab { case dialogue, trade, story, chat }

// MerchantActionMenu에 AI 대화 버튼 추가
MerchantActionMenu(onChat: { selectTab(.chat) })

// .chat 탭 → MerchantAIChatView 렌더링
```

---

## 4. API 명세

### `POST /api/merchant-chat`

**Request** (Bearer Token 필수)
```json
{
  "merchantId": "seoyena",
  "message": "오늘 날씨가 좋네요",
  "history": [
    { "role": "user", "text": "안녕하세요" },
    { "role": "model", "text": "어서 오세요!" }
  ]
}
```

**Response (정상)**
```json
{
  "reply": "그러게요, 압구정 봄바람이 참 좋죠.",
  "unlockedEpisode": null
}
```

**Response (언락 발생)**
```json
{
  "reply": "...사실 그 이야기라면 따로 할 말이 있어요.",
  "unlockedEpisode": {
    "episode_id": "seo_yena_family_01",
    "title": "압구정의 비밀",
    "entry_node": "sy_secret_001",
    "unlock_requirements": []
  }
}
```

**제약**
- `merchantId`: 9명 허용 값 중 하나
- `message`: 1~500자
- `history`: 최대 20개 (iOS에서 최근 10개 전송)

---

## 5. 서버 파일

### `src/constants/merchantPersonas.js`

상인별 AI 인격 정의. 구조:

```js
{
  seoyena: {
    name: "서예나",
    district: "강남구 압구정",
    basePrompt: `[캐릭터 정보]\n이름: 서예나\n...`,
    unlockTriggers: [
      {
        keywords: ["어머니", "가족", "과거"],
        episodeId: "seo_yena_family_01",
        episodeTitle: "압구정의 비밀",
        entryNode: "sy_secret_001"
      }
    ]
  },
  // ... 8명 더
}
```

### `src/services/merchantChatService.js`

| 함수 | 설명 |
|------|------|
| `sendMerchantChat(merchantId, message, history, playerContext)` | 메인 진입점 |
| `buildSystemPrompt(persona, playerContext)` | Gemini 시스템 프롬프트 조립 |
| `checkUnlockTriggers(message, triggers)` | 키워드 매칭 → 언락 에피소드 반환 |
| `buildGeminiHistory(history)` | iOS history → Gemini 형식 변환 |

- 모델: `gemini-1.5-flash`
- `maxOutputTokens`: 300, `temperature`: 0.85

---

## 6. 환경 변수

`way-server/.env`에 추가 필요:
```env
GEMINI_API_KEY=your_gemini_api_key_here
```

Google AI Studio(https://aistudio.google.com/app/apikey)에서 발급.

---

## 7. 언락 트리거 동작

1. 사용자 메시지 수신 시 `checkUnlockTriggers()` 즉시 실행 (Gemini 호출 전)
2. 키워드 매칭 시 해당 에피소드 정보를 응답에 포함
3. iOS: `unlockedEpisode != null` → `EpisodeUnlockBanner` 표시
4. 배너 탭 → `onEpisodeUnlock(episode)` 콜백 → 에피소드 즉시 재생

> 동일 트리거가 중복 발동되는 것은 서버에서 현재 방어하지 않음.
> 향후 `completedEpisodes` 체크로 방어 로직 추가 예정.
