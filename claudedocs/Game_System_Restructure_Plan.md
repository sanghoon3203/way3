# WAY3 게임 시스템 구조 설계 (로컬 우선 아키텍처)

로컬 JSON 기반 "오프라인 우선" 게임 구조의 스키마 및 구현 계획.
현재 상태: **ch0 프롤로그 + ch1 강남권 구현 완료, ch2 이후 진행 중.**

---

## 1. 전체 아키텍처 원칙

```
로컬 JSON (GameData/, StoryData/)
  ↓ 앱 번들에 포함, VNLoader가 읽음
ProgressManager (오프라인 상태 관리)
  ↓ JSON 파일로 로컬 저장
서버 API (선택적 동기화)
  ↓ 거래 기록, 관계도, 리더보드 등 공유 데이터만
Socket.IO (실시간)
  ↓ 근처 플레이어, 가격 변동 (선택적)
```

**오프라인에서도 스토리/퀘스트 진행 가능. 서버는 거래/사회적 기능에 집중.**

---

## 2. 챕터 구조

### story_main_chapters.json 스키마

```json
{
  "chapters": [
    {
      "chapter_id": "ch1_gangnam",
      "title": "강남권: 번영의 그림자",
      "entry_requirements": {
        "min_level": 1,
        "required_chapters": []
      },
      "districts": [
        {
          "district_id": "gangnam_gu",
          "district_name": "강남구",
          "merchant_id": "merchant_seoyena",
          "episodes": [
            {
              "episode_id": "ep_seoyena_01",
              "title": "로데오 아레나의 주인",
              "start_node_id": "sub1_001",
              "unlock_condition": {
                "type": "always"
              },
              "post_quest_id": "mainquest_gangnam_1_1"
            }
          ]
        }
      ],
      "chapter_rewards": {
        "key_item": "key_item_gangnam",
        "exp": 500,
        "money": 100000
      }
    }
  ]
}
```

### 7개 챕터 현황

| 챕터 ID | 제목 | 최소 레벨 | 요구 조건 | 상태 |
|--------|------|--------|---------|------|
| `ch0_prologue` | 프롤로그: 이상한 세계로 떨어지다 | — | 없음 | ✅ 완성 |
| `ch1_gangnam` | 강남권: 번영의 그림자 | 1 | — | ✅ 완성 (5개 구) |
| `ch2_northwest` | 서북권: 역사의 메아리 | 5 | key_item_gangnam | ⚠️ JSON 정의됨, 에피소드 없음 |
| `ch3_northeast` | 동북권: 자연과 도시 | 10 | key_item_northwest | ❌ districts: [] |
| `ch4_southwest` | 서남권: 새로운 가능성 | 15 | key_item_northeast | ❌ districts: [] |
| `ch5_eastwest` | 동서권: 전통의 재발견 | 20 | key_item_southwest | ❌ districts: [] |
| `ch6_final` | 최종장: 서울의 진실 | 25 | 5개 열쇠 아이템 ALL | ❌ 미작성 |

---

## 3. 지역/상인/서브퀘스트 구조

### districts.json 스키마

```json
{
  "districts": [
    {
      "district_id": "gangnam_gu",
      "district_name": "강남구",
      "chapter": "ch1_gangnam",
      "merchants": [
        {
          "merchant_id": "merchant_seoyena",
          "name": "서예나",
          "location": {
            "lat": 37.527941,
            "lng": 127.038806,
            "description": "압구정 로데오 거리"
          },
          "required_license": 0,
          "subquests": [
            "subquest_seoyena_01_dialogue",
            "subquest_seoyena_02_location",
            "subquest_seoyena_03_trading"
          ]
        }
      ]
    }
  ]
}
```

### 현재 구현된 지역 및 서브퀘스트

| 구역 | 상인 | 서브퀘스트 | GameData 파일 | 상태 |
|-----|------|-----------|-------------|------|
| 강남구 | 서예나 | 3개 (대화→배달→거래) | ✅ | ✅ 완성 |
| 서초구 | 앨리스강 | 3개 (산책→공원→간식) | ✅ | ✅ 완성 |
| 송파구 | 애니박 | 정의됨 | ⚠️ 부분 | ⚠️ 서브스토리만 |
| 강동구 | 진백호 | 정의됨 | ⚠️ 부분 | ⚠️ 서브스토리만 |
| 관악구 | 김세휘 | 정의됨 | ⚠️ 부분 | ❌ 서브스토리 없음 |
| 종로구 | 기주리 | 정의됨 | ⚠️ 부분 | ❌ 서브스토리 없음 |
| 중구 | 카타리나 최 | 정의됨 | ⚠️ 부분 | ❌ 서브스토리 없음 |
| 마포구 | 마리 | 정의됨 | ⚠️ 부분 | ❌ 서브스토리 없음 |

---

## 4. 서브퀘스트 JSON 스키마

```json
{
  "quest_id": "subquest_seoyena_01_dialogue",
  "merchant_id": "merchant_seoyena",
  "title": "서예나의 첫 번째 시험",
  "description": "서예나와 대화를 나누며 그녀의 신뢰를 얻어라.",
  "quest_type": "dialogue",
  "requirements": {
    "story_node": "sub1_064",
    "required_quests": []
  },
  "rewards": {
    "exp": 200,
    "money": 50000,
    "story_piece_ids": ["piece_seoyena_01"],
    "key_items": [],
    "relationship_change": 100
  },
  "unlock_next": "subquest_seoyena_02_location"
}
```

### 퀘스트 타입별 검증 방식

| 타입 | 검증 | 구현 상태 |
|------|------|---------|
| `dialogue` | VNNode의 `story_node_complete` 도달 | ✅ |
| `delivery` | LocationVerifier GPS 반경 체크 | ✅ |
| `trading` | GPS 반경 + ReceiptVerifier OCR | ⚠️ OCR 미완성 |

---

## 5. 메인퀘스트 JSON 스키마

```json
{
  "quest_id": "mainquest_gangnam_1_1",
  "chapter_id": "ch1_gangnam",
  "title": "로데오의 부름",
  "objectives": [
    {
      "type": "dialogue",
      "target_id": "merchant_seoyena",
      "description": "서예나와 대화 완료"
    }
  ],
  "required_episodes": ["ep_seoyena_01"],
  "required_sub_quests": [],
  "rewards": {
    "exp": 300,
    "money": 80000,
    "story_piece_ids": ["piece_gangnam_main_01"]
  }
}
```

> ⚠️ **버그**: `MainQuestDefinition.swift`에서 `required_episodes`/`required_sub_quests`가 JSON에서 디코딩되지 않고 `= []`로 초기화됨. 수정 필요.

---

## 6. PlayerProgress 저장 구조 (v4)

```swift
struct PlayerProgress: Codable {
  let version: Int = 4

  // 완료 상태
  var completedChapters:    [String]   // ["ch0_prologue", "ch1_gangnam"]
  var completedDistricts:   [String]   // ["gangnam_gu", "seocho_gu"]
  var completedSubQuests:   [String]   // ["subquest_seoyena_01_dialogue"]
  var completedMainQuests:  [String]   // ["mainquest_gangnam_1_1"]
  var completedEpisodes:    [String]
  var unlockedEpisodes:     [String]

  // 수집 아이템
  var collectedStoryPieces: [String]   // ["piece_seoyena_01"]
  var keyItems:             [String]   // ["key_item_gangnam"]
}
```

저장 경로: `Documents/player_progress.json`
자동 백업: `Documents/player_progress_backup.json`

---

## 7. 상인 관계도 시스템

```
단계 0 (초면)   : 기본 거래 가능
단계 1 (안면)   : 서브퀘스트 1 완료 후
단계 2 (친구)   : 서브퀘스트 2 완료 후
단계 3 (동료)   : 서브퀘스트 3 완료 후
단계 4 (파트너) : 히든 퀘스트 완료 후
```

단계 진행 시:
- 허가증 업그레이드 가능 (`POST /api/merchants/:id/permit/upgrade`)
- 취급 아이템 등급 확장 (common → rare → legendary)
- 특별 에피소드 해금

---

## 8. GPS 검증 (LocationVerifier)

```swift
// 기본 검증 반경
let DEFAULT_TRADE_RADIUS: Double = 100    // 100m (거래)
let DEFAULT_DELIVERY_RADIUS: Double = 50  // 50m (배달 완료 지점)

// 검증 흐름
LocationVerifier.verifyLocationWithAccuracy(
  targetLat: quest.targetLat,
  targetLng: quest.targetLng,
  radius: quest.requirements.radius
) { result in
  switch result {
  case .success:  QuestManager.completeVerification(.location)
  case .failure:  // 사용자에게 "더 가까이 이동" 안내
  }
}
```

---

## 9. 영수증 OCR 검증 (ReceiptVerifier)

```swift
// Vision framework 기반 (구현 예정)
ReceiptVerifier.verifyReceipt(
  image: capturedImage,
  merchantName: quest.requirements.merchant_name,
  minAmount: quest.requirements.min_purchase
) { result in
  // 금액 및 상호명 매칭 검증
}
```

현재 상태: 구조만 정의됨, 실제 OCR 로직 미완성.

---

## 10. 구현 우선순위

### 즉시 수정 필요
1. `MainQuestDefinition.swift` 디코딩 버그 수정
2. 강동 스토리 노드 018–063 채우기

### 단기 (다음 스프린트)
3. `GameData/Story/SubQuests/` — 애니박, 진백호, 주블수 서브퀘스트 JSON 추가
4. `StoryData/Substories/` — 서북권 4명 서브스토리 작성 시작

### 중기
5. ch2 서북권 에피소드 정의 완성
6. 영수증 OCR 구현
7. 경매 Socket.IO 이벤트 구현

### 장기
8. ch3–ch5 콘텐츠 전개
9. ch6 최종장 설계

---

**버전**: 2.0.0
**최종 업데이트**: 2026-02-12
