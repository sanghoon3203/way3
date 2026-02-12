# WAY3 퀘스트 데이터 현황

최종 업데이트: 2026-02-12

---

## 서브퀘스트 (SubQuest) 현황

### 강남구 — 서예나 (merchant_seoyena)

| 퀘스트 ID | 타입 | 목표 | GameData | 서브스토리 | 상태 |
|----------|------|------|---------|-----------|------|
| `subquest_seoyena_01_dialogue` | dialogue | sub1_064 도달 | ✅ | ✅ 64노드 | ✅ 완성 |
| `subquest_seoyena_02_location` | delivery | GPS 위치 도달 | ✅ | ✅ 63노드 | ✅ 완성 |
| `subquest_seoyena_03_trading` | trading | GPS + OCR | ✅ | ✅ 25노드 | ⚠️ OCR 미구현 |

**파일 경로**: `GameData/Story/SubQuests/Seoyena/`

---

### 서초구 — 앨리스강 (merchant_alicegang)

| 퀘스트 ID | 타입 | 목표 | GameData | 서브스토리 | 상태 |
|----------|------|------|---------|-----------|------|
| `subquest_alice_01_walk` | delivery | 서래마을 산책로 | ✅ | ⚠️ | ⚠️ GameData만 |
| `subquest_alice_02_park` | delivery | 서래공원 | ✅ | ⚠️ | ⚠️ GameData만 |
| `subquest_alice_03_treats` | trading | 특산 허브 구매 | ✅ | ⚠️ | ⚠️ OCR 미구현 |

**파일 경로**: `GameData/Story/SubQuests/Alicegang/`

---

### 송파구 — 애니박 (merchant_anipark)

| 퀘스트 ID | 타입 | GameData | 서브스토리 | 상태 |
|----------|------|---------|-----------|------|
| 3개 예정 | — | ❌ 없음 | ⚠️ 66노드 존재 | ❌ GameData 미작성 |

---

### 강동구 — 진백호 (merchant_jinbaekho)

| 퀘스트 ID | 타입 | GameData | 서브스토리 | 상태 |
|----------|------|---------|-----------|------|
| 3개 예정 | — | ❌ 없음 | ⚠️ 26노드 존재 | ❌ GameData 미작성 |

---

### 강동구 — 주블수 (merchant_jubulsu)

| 퀘스트 ID | 타입 | GameData | 서브스토리 | 상태 |
|----------|------|---------|-----------|------|
| 3개 예정 | — | ❌ 없음 | ⚠️ 20노드 존재 | ❌ GameData 미작성 |

---

### 관악구 — 김세휘 (merchant_kimsehwui)

| 퀘스트 ID | 타입 | GameData | 서브스토리 | 상태 |
|----------|------|---------|-----------|------|
| 3개 예정 | — | ❌ 없음 | ❌ 없음 | ❌ 미작성 |

---

### 서북권 (종로, 중구, 마포, 서대문, 용산)

| 상인 | GameData | 서브스토리 | 상태 |
|------|---------|-----------|------|
| 기주리 (Kijuri) | ❌ | ❌ | ❌ 미작성 |
| 카타리나 최 (Catarinachoi) | ❌ | ❌ | ❌ 미작성 |
| 마리 (Mari) | ❌ | ❌ | ❌ 미작성 |
| 서대문/용산 상인 | ❌ | ❌ | ❌ 미기획 |

---

## 메인퀘스트 (MainQuest) 현황

### Ch1 강남권

| 퀘스트 ID | 제목 | 목표 타입 | GPS 좌표 | 상태 |
|----------|------|---------|---------|------|
| `mainquest_gangnam_1_1` | 강남권 메인 1 | dialogue | 서예나 위치 | ✅ |
| `mainquest_gangnam_1_2` | 강남권 메인 2 | — | — | ✅ |
| `mainquest_gangnam_1_3` | 강남권 메인 3 | — | — | ✅ |

**파일**: `GameData/Quests/main_quests.json`

---

### Ch2 서북권 (JSON 정의됨, 실제 에피소드 없음)

| 구역 | 퀘스트 수 | GPS 좌표 포함 | 상태 |
|------|---------|------------|------|
| 종로구 | 3개 | ✅ 경복궁 주변 | ⚠️ JSON 정의됨 |
| 중구 | 3개 | ✅ 명동성당 주변 | ⚠️ JSON 정의됨 |
| 마포구 | 3개 | ✅ 홍대 주변 | ⚠️ JSON 정의됨 |
| 서대문구 | 3개 | ✅ | ⚠️ JSON 정의됨 |
| 용산구 | 3개 | ✅ | ⚠️ JSON 정의됨 |

---

### Ch3~Ch6

| 챕터 | 상태 |
|------|------|
| Ch3 동북권 | ❌ `districts: []` — 미작성 |
| Ch4 서남권 | ❌ `districts: []` — 미작성 |
| Ch5 동서권 | ❌ `districts: []` — 미작성 |
| Ch6 최종장 | ❌ 설계 미완성 |

---

## 알려진 버그

### MainQuestDefinition 디코딩 버그
- **파일**: `way3/Models/MainQuestDefinition.swift`
- **증상**: `requiredEpisodes`와 `requiredSubQuests` 필드가 `= []`로 하드코딩되어 있어, JSON의 실제 요구 조건이 무시됨
- **영향**: 메인퀘스트 선행 조건 없이 모든 메인퀘스트가 항상 활성화될 수 있음
- **우선순위**: 🔴 높음 — 수정 필요

---

## 퀘스트 언락 체인 (하드코딩)

```
// QuestManager.swift에 하드코딩된 체인
서예나: subquest_seoyena_01_dialogue
          → subquest_seoyena_02_location
          → subquest_seoyena_03_trading

앨리스강: subquest_alice_01_walk
           → subquest_alice_02_park
           → subquest_alice_03_treats
```

나머지 상인의 체인은 미정의 상태.

---

## 퀘스트 보상 구조

```json
"rewards": {
  "exp": 200,
  "money": 50000,
  "story_piece_ids": ["piece_seoyena_01"],
  "key_items": [],
  "relationship_change": 100
}
```

- **exp**: 경험치
- **money**: 게임 내 통화
- **story_piece_ids**: 스토리 조각 (컬렉션)
- **key_items**: 열쇠 아이템 (챕터 해금 조건)
- **relationship_change**: 상인 친밀도 변화량

---

## 다음 작업 우선순위

1. **[긴급]** `MainQuestDefinition.swift` 디코딩 버그 수정
2. **[단기]** 애니박, 진백호, 주블수 `GameData/Story/SubQuests/` JSON 추가
3. **[단기]** 영수증 OCR (ReceiptVerifier) 실제 구현
4. **[중기]** 서북권 4명 서브퀘스트 GameData JSON 작성
5. **[중기]** Ch2 서북권 에피소드 스토리 노드 연동
6. **[장기]** Ch3~Ch5 퀘스트 설계 및 구현
