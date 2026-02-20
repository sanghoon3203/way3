# AI 상인 채팅 시스템 설계 문서
**날짜**: 2026-02-20
**방향**: B안 — 통합 컨텍스트 AI (VN 스토리 + AI 자유대화 공존)

---

## 개요

상인별 AI 인격을 부여하여 플레이어가 자유롭게 대화할 수 있는 시스템.
VN 에피소드(핵심 스토리)는 고정, 일상 대화는 AI가 실시간 생성.
특정 대화 주제가 새 VN 에피소드를 언락하는 트리거 역할.

---

## 아키텍처

```
iOS 앱
  └─ MerchantAIChatView
       └─ POST /api/merchant-chat
            └─ Node.js 서버
                 └─ Gemini API (Google Generative AI)
```

---

## iOS 신규 파일

| 파일 | 역할 |
|------|------|
| `Components/CyberpunkChatComponents.swift` | 말풍선, 타이핑 인디케이터, 언락 배너, 입력창, 탭 선택기 |
| `Views/Merchant/MerchantAIChatView.swift` | AI 채팅 뷰 + 뷰모델 |

### MerchantDetailView 수정
- `MerchantDetailTab`에 `.chat` 케이스 추가
- `MerchantActionMenu`에 `onChat` 클로저 + "AI와 대화하기" 버튼 추가
- `.chat` 탭 → `MerchantAIChatView` 표시

---

## 백엔드 신규 엔드포인트

### `POST /api/merchant-chat`

**Request:**
```json
{
  "merchantId": "seo_yena",
  "message": "오늘 날씨가 좋네요",
  "history": [
    { "role": "user", "text": "안녕하세요" },
    { "role": "model", "text": "어서 오세요!" }
  ]
}
```

**Response:**
```json
{
  "reply": "그러게요, 압구정 봄바람이 참 좋죠. 혹시 새 입고품 보셨어요?",
  "unlockedEpisode": null
}
```

**언락 발생 시:**
```json
{
  "reply": "...사실 그 이야기라면 따로 할 말이 있어요.",
  "unlockedEpisode": {
    "episode_id": "seo_yena_secret_01",
    "title": "압구정의 비밀",
    "entry_node": "sy_secret_001",
    "unlock_requirements": []
  }
}
```

---

## Gemini 시스템 프롬프트 구조

```
[캐릭터 정보]
이름: 서예나
위치: 강남구 압구정 로데오거리
성격: 세련되고 직설적, 패션에 민감, 서울 상류층 문화에 정통
말투: 존댓말이지만 친근함, 패션/트렌드 용어 자주 사용

[게임 컨텍스트]
플레이어 레벨: {level}
완료된 에피소드: {completedEpisodes}
현재 관계도: {relationshipLevel} (0~100)
최근 거래: {recentTrades}

[언락 트리거]
다음 키워드/주제가 대화에 등장하면 unlockedEpisode를 반환:
- "어머니", "가족", "과거" → episode: seo_yena_family_01
- "경쟁", "라이벌", "시장" → episode: seo_yena_rival_01

[제약]
- 항상 한국어로 응답
- 게임 세계관(네오 서울, 2030년대) 내에서만 이야기
- 실제 AI/챗봇임을 언급하지 않음
- 응답은 2~4문장으로 간결하게
```

---

## 구현 우선순위

1. **백엔드** — `/api/merchant-chat` 엔드포인트 구현 (Gemini API 연동)
2. **백엔드** — 상인별 시스템 프롬프트 JSON 파일 작성 (9명)
3. **백엔드** — 에피소드 언락 트리거 로직
4. **iOS** — `SecureStorage.shared.getAccessToken()` API 확인
5. **iOS** — `NetworkConfiguration.baseURL` 연동 확인 (✅ 이미 존재)

---

## UI 컴포넌트 디자인

### 말풍선
- **플레이어**: `joseonHwang` 배경 + `joseonHeuk` 텍스트 + 황금 그림자
- **상인**: `joseonPanel` 배경 + `joseonBaek` 텍스트 + 청(靑) 테두리

### 에피소드 언락 배너
- 좌측 적(赤)→황(黃) 단청 그라디언트 바
- 開 도장 씰 (joseonJeok 원형, 좌우 흔들림 애니메이션)
- 8초 자동 닫힘 + 탭 시 에피소드 즉시 재생

### 탭 선택기
- `matchedGeometryEffect`로 황금 슬라이딩 인디케이터
- 에피소드 | 대화하기 2탭 구조
