# Way3 게임 시스템 재구조화 계획서

## 📋 목표

**핵심**: 6개 챕터 기반 스토리 중심 게임으로 재구조화
- 5개 지역 챕터 + 1개 최종 챕터
- 25개 구역 (지역당 5개) × 1개 상인 × 2-3개 서브퀘스트
- 실제 위치 연동 (GPS 인증, 영수증 OCR)
- **로컬 우선** 아키텍처 (서버 의존 최소화)

---

## 🔍 현재 시스템 분석

### 문제점
1. **Quest 시스템**: 기존 daily_quests 테이블은 일일 퀘스트용 → 스토리 퀘스트와 구조가 맞지 않음
2. **진행 추적**: 챕터/구역/스토리 조각 진행 상태 추적 불가
3. **상인-퀘스트 연결**: 상인별 서브퀘스트 매핑 없음
4. **실제 위치 연동**: GPS 인증, 영수증 OCR 시스템 미구현
5. **데이터 분산**: 스토리(JSON) + 퀘스트(서버) + 진행상태(로컬) 분리되어 관리 어려움

### 보존할 것
- Player 모듈 시스템 (Core, Stats, Inventory, Relationships, Achievements)
- VNNode 기반 스토리 시스템 (StoryCore.swift)
- Merchant/Item 기본 구조
- 위치 기반 상인 발견 (LocationManager + Mapbox)

---

## 🎯 새로운 데이터 구조 설계

### 1. 챕터 시스템 (Local JSON)

**파일**: `way3/GameData/Chapters/chapters.json`

```json
{
  "chapters": [
    {
      "chapter_id": "ch1_gangnam",
      "title": "강남권: 번영의 그림자",
      "region": "gangnam",
      "order": 1,
      "districts": ["gangnam_gu", "seocho_gu", "songpa_gu", "gangdong_gu", "gwanak_gu"],
      "entry_requirements": {
        "min_level": 1,
        "required_items": []
      },
      "completion_reward": {
        "item_id": "key_item_gangnam",
        "item_name": "강남의 증표",
        "money": 50000,
        "exp": 1000
      },
      "main_story_entry": "ch1_intro_01",
      "unlock_condition": "always"
    },
    {
      "chapter_id": "ch2_northwest",
      "title": "서북권: 역사의 메아리",
      "region": "northwest",
      "order": 2,
      "districts": ["jongno_gu", "jung_gu", "seodaemun_gu", "mapo_gu", "yongsan_gu"],
      "entry_requirements": {
        "min_level": 5,
        "required_items": []
      },
      "completion_reward": {
        "item_id": "key_item_northwest",
        "item_name": "서북의 증표",
        "money": 75000,
        "exp": 1500
      },
      "main_story_entry": "ch2_intro_01",
      "unlock_condition": "parallel"
    },
    // ... ch3_northeast, ch4_southwest, ch5_eastwest
    {
      "chapter_id": "ch6_final",
      "title": "최종장: 서울의 진실",
      "region": "final",
      "order": 6,
      "districts": [],
      "entry_requirements": {
        "min_level": 20,
        "required_items": [
          "key_item_gangnam",
          "key_item_northwest",
          "key_item_northeast",
          "key_item_southwest",
          "key_item_eastwest"
        ]
      },
      "completion_reward": {
        "item_id": "final_key",
        "item_name": "서울의 열쇠",
        "money": 500000,
        "exp": 10000
      },
      "main_story_entry": "ch6_final_01",
      "unlock_condition": "all_five_keys"
    }
  ]
}
```

---

### 2. 구역/상인 시스템 (Local JSON)

**파일**: `way3/GameData/Districts/districts.json`

```json
{
  "districts": [
    {
      "district_id": "gangnam_gu",
      "chapter_id": "ch1_gangnam",
      "name": "강남구",
      "merchant": {
        "merchant_id": "merchant_seoyena",
        "name": "서예나",
        "location": {
          "latitude": 37.5172,
          "longitude": 127.0473,
          "radius": 500
        },
        "main_story_id": "gangnam_seoyena_main",
        "sub_quests": [
          {
            "quest_id": "seoyena_sub_01",
            "title": "서예나의 첫 거래",
            "type": "trading",
            "verification": "receipt_ocr",
            "requirements": {
              "location": {"latitude": 37.5172, "longitude": 127.0473, "radius": 100},
              "min_purchase": 5000
            },
            "rewards": {
              "money": 10000,
              "exp": 100,
              "item_id": "story_piece_seoyena_01"
            }
          },
          {
            "quest_id": "seoyena_sub_02",
            "title": "강남의 비밀 장소",
            "type": "delivery",
            "verification": "gps_location",
            "requirements": {
              "target_location": {"latitude": 37.5200, "longitude": 127.0500, "radius": 50},
              "time_limit": 3600
            },
            "rewards": {
              "money": 15000,
              "exp": 150,
              "item_id": "story_piece_seoyena_02"
            }
          },
          {
            "quest_id": "seoyena_sub_03",
            "title": "서예나와의 대화",
            "type": "dialogue",
            "verification": "story_completion",
            "requirements": {
              "story_node_complete": "seoyena_dialogue_end"
            },
            "rewards": {
              "money": 20000,
              "exp": 200,
              "item_id": "story_piece_seoyena_03",
              "relationship_change": {"merchant_id": "merchant_seoyena", "trust": 10}
            }
          }
        ]
      },
      "unlock_condition": "story_tab_always_visible"
    }
    // ... 24 more districts
  ]
}
```

#### 🤝 상인 관계도 & 거래 허가증 흐름
- **관계도 단계**: 0~4단계. `merchant_relationships` 테이블에 `stage_progress`(누적)와 `trust_level`(단계)을 저장하며, 단계별 요구치는 **3 → 3 → 5 → 5** 서브퀘스트 클리어.
- **단계 상승**: 서브퀘스트 완료 시 `POST /api/merchants/:merchantId/relationship/progress`를 호출하여 서버가 진행도를 1 증가시키고, 요구치를 달성하면 다음 단계로 승급.
  - 중복 제출 방지를 위해 `merchant_relationship_quest_log`에 `(player_id, merchant_id, quest_id)`를 기록.
  - 최종 단계(4단계)에서는 더 이상 진행도를 쌓지 않고 성공 메시지만 반환.
- **거래 허가증**: `Merchantpermit_1`~`Merchantpermit_4` 네 종류로 Seed 데이터에 추가. 각 허가증은 **일반 → 중급 → 고급 → 희귀/전설** 등급까지 거래 허용.
- **거래 검증**: 서버 `/api/trade/execute`는 허가증 등급과 관계도 단계가 모두 충족될 때만 거래 허용(둘 중 하나라도 부족하면 403).
- **허가증 업그레이드**: `POST /api/merchants/:merchantId/permit/upgrade` 호출 시
  1. 현재 보유 허가증을 모두 제거하고,
  2. 목표 단계 허가증으로 교체하며,
  3. 최소 관계도 단계를 만족하지 못하면 403 반환.
- **클라이언트 UI**: `MerchantDetailView` 상단에 관계도 카드 노출 → 현재 단계, 진행도, 허가증 레벨, 업그레이드 버튼을 즉시 확인 가능.
- **클라이언트 동기화 흐름**:
  1. `ProgressManager.completeSubQuest` → `MerchantDataManager.recordRelationshipProgress` 호출
  2. 서버가 진행도/단계를 반환하면 `cachedRelationships` 갱신 → `MerchantDetailViewModel` 재로딩
  3. 허가증 업그레이드 시 `MerchantDataManager.upgradePermit` → `GameManager.loadPersonalItemsData()`로 인벤토리 동기화

> 📌 구현 레퍼런스  
> - 서버: `way-server/src/routes/api/merchants.js`, `way-server/src/routes/api/trade.js`, `src/database/migrations/006_relationship_progress.sql`  
> - 클라이언트: `way3/Core/MerchantDataManager.swift`, `way3/Core/ProgressManager.swift`, `way3/Views/Merchant/MerchantDetailView.swift`, `way3/ViewModels/MerchantDetailViewModel.swift`

---

### 3. 퀘스트 진행 상태 (Local Storage + Minimal Server Sync)

**로컬 저장**: `UserDefaults` 또는 `Codable` JSON

```swift
// way3/Core/ProgressManager.swift
struct PlayerProgress: Codable {
    var completedChapters: [String] = []
    var completedDistricts: [String] = []
    var completedQuests: [String] = []
    var collectedStoryPieces: [String] = []
    var keyItems: [String] = []
    var currentChapterID: String?
    var lastSyncedAt: Date?
}
```

**서버 동기화** (선택적, 진행 백업용):
```javascript
// way-server/src/routes/api/progress.js
POST /api/progress/sync
{
  "completed_chapters": ["ch1_gangnam"],
  "completed_quests": ["seoyena_sub_01", "seoyena_sub_02"],
  "key_items": ["key_item_gangnam"],
  "last_synced_at": "2025-01-09T12:00:00Z"
}
```

---

### 4. 실제 위치 인증 시스템

#### GPS 인증 (Delivery Quests)
```swift
// way3/Core/LocationVerifier.swift
class LocationVerifier {
    func verifyLocation(
        userLocation: CLLocationCoordinate2D,
        targetLocation: CLLocationCoordinate2D,
        radius: Double
    ) -> Bool {
        let distance = userLocation.distance(to: targetLocation)
        return distance <= radius
    }

    func startLocationTracking(questID: String, targetLocation: CLLocationCoordinate2D) {
        // GPS 모니터링 + 도착 시 자동 검증
    }
}
```

#### 영수증 OCR 인증 (Trading Quests)
```swift
// way3/Core/ReceiptVerifier.swift
import Vision

class ReceiptVerifier {
    func verifyReceipt(
        image: UIImage,
        minPurchase: Int,
        requiredLocation: CLLocationCoordinate2D?
    ) async throws -> ReceiptVerificationResult {
        // 1. Vision OCR로 영수증 텍스트 추출
        let text = try await extractText(from: image)

        // 2. 금액 파싱 (정규식)
        let amount = parseAmount(from: text)

        // 3. 위치 정보 확인 (Optional: 영수증의 주소 vs GPS)
        if let location = requiredLocation {
            let isNearby = verifyLocationFromReceipt(text: text, target: location)
            guard isNearby else { throw VerificationError.locationMismatch }
        }

        // 4. 최소 금액 검증
        guard amount >= minPurchase else {
            throw VerificationError.insufficientAmount
        }

        return ReceiptVerificationResult(
            verified: true,
            amount: amount,
            timestamp: Date()
        )
    }
}
```

---

## 🏗️ 로컬 우선 아키텍처

### 데이터 계층 구조

```
┌─────────────────────────────────────┐
│   Local JSON Files (GameData/)      │
│  - chapters.json                    │
│  - districts.json                   │
│  - story_nodes/*.json               │
│  (읽기 전용, 앱 번들에 포함)          │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   ProgressManager (Local Storage)   │
│  - UserDefaults / Codable           │
│  - 퀘스트 완료 상태                  │
│  - 스토리 조각 수집                  │
│  - 챕터 진행도                       │
│  (읽기/쓰기, 기기 로컬 저장)          │
└─────────────────────────────────────┘
              ↓ (선택적 동기화)
┌─────────────────────────────────────┐
│   Server API (way-server)           │
│  - /api/progress/sync (백업)        │
│  - /api/trade/execute (거래만)      │
│  - /api/auth (인증만)               │
│  (최소 의존, 백업/멀티디바이스용)     │
└─────────────────────────────────────┘
```

### 동작 원리
1. **앱 시작**: Local JSON 로드 → ProgressManager 초기화
2. **퀘스트 완료**: Local 상태 업데이트 → UI 즉시 반영 → (optional) 서버 백업
3. **거래 실행**: 서버 API 호출 필수 (경제 검증)
4. **스토리 재생**: Local JSON 읽기 → VNLoader → StoryView
5. **진행 복구**: 새 기기 → 서버에서 Progress 복원 → Local 적용

---

## 📊 데이터베이스 변경사항

### 서버 DB (SQLite) - 최소한만 유지

**제거할 테이블**:
```sql
-- 기존 daily_quests 테이블 삭제 (스토리 퀘스트와 무관)
DROP TABLE IF EXISTS daily_quests;
```

**새로 추가할 테이블**:
```sql
-- 플레이어 진행 상태 백업용 (동기화 전용)
CREATE TABLE player_progress (
    player_id TEXT PRIMARY KEY,
    completed_chapters TEXT,  -- JSON array: ["ch1_gangnam", "ch2_northwest"]
    completed_quests TEXT,    -- JSON array: ["seoyena_sub_01", ...]
    key_items TEXT,           -- JSON array: ["key_item_gangnam", ...]
    last_synced_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id)
);

-- 영수증 인증 기록 (사기 방지)
CREATE TABLE receipt_verifications (
    id TEXT PRIMARY KEY,
    player_id TEXT NOT NULL,
    quest_id TEXT NOT NULL,
    image_hash TEXT NOT NULL,  -- 중복 방지
    amount INTEGER NOT NULL,
    verified_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id)
);
```

**기존 테이블 수정**:
```sql
-- merchants 테이블: 위치 정보 추가
ALTER TABLE merchants ADD COLUMN latitude REAL;
ALTER TABLE merchants ADD COLUMN longitude REAL;
ALTER TABLE merchants ADD COLUMN radius INTEGER DEFAULT 500;
```

---

## 🛠️ 구현 단계

### Phase 1: 데이터 구조 구축 (1-2일)
**Todo**:
1. ✅ `GameData/` 폴더 생성
2. ✅ `chapters.json` 작성 (6개 챕터 정의)
3. ✅ `districts.json` 작성 (25개 구역 × 상인 × 퀘스트)
4. ✅ `ProgressManager.swift` 구현
5. ✅ 서버 DB 마이그레이션 스크립트

**검증**:
- JSON 파싱 테스트
- ProgressManager 로드/저장 테스트

---

### Phase 2: 위치 인증 시스템 (2-3일)
**Todo**:
1. ✅ `LocationVerifier.swift` 구현 (GPS 인증)
2. ✅ `ReceiptVerifier.swift` 구현 (OCR 인증)
3. ✅ 카메라 권한 + Vision 프레임워크 통합
4. ✅ 테스트용 영수증 이미지로 OCR 검증

**검증**:
- GPS 반경 내 도착 → 퀘스트 완료
- 영수증 업로드 → 금액 파싱 → 검증 성공

---

### Phase 3: Quest UI 재구성 (2-3일)
**Todo**:
1. ✅ `ChapterListView.swift` (6개 챕터 선택)
2. ✅ `DistrictListView.swift` (챕터별 5개 구역)
3. ✅ `MerchantQuestView.swift` (상인 + 서브퀘스트 3개)
4. ✅ `QuestDetailView.swift` (퀘스트 상세 + 인증 버튼)
5. ✅ 기존 `DailyQuestView.swift` 제거

**검증**:
- 챕터 → 구역 → 상인 → 퀘스트 네비게이션
- GPS/영수증 인증 버튼 동작
- 완료 시 스토리 조각 획득

---

### Phase 4: 스토리 통합 (2일)
**Todo**:
1. ✅ 메인 스토리 JSON 노드 작성 (챕터별)
2. ✅ 서브퀘스트 대화 스토리 노드 작성
3. ✅ `StoryView` 호출 연결:
   - 챕터 시작 → `StoryView(startNodeID: "ch1_intro_01")`
   - 서브퀘스트 대화 → `StoryView(startNodeID: "seoyena_dialogue_01")`
4. ✅ 완료 콜백으로 진행 상태 업데이트

**검증**:
- 챕터 시작 → 인트로 스토리 재생
- 대화 퀘스트 → 스토리 재생 → 완료 처리

---

### Phase 5: 서버 동기화 (1-2일)
**Todo**:
1. ✅ `POST /api/progress/sync` 엔드포인트 구현
2. ✅ `ProgressManager`에 자동 동기화 로직
3. ✅ 네트워크 오프라인 시 로컬 우선 동작
4. ✅ 다중 기기 진행 복구 테스트

**검증**:
- 오프라인에서 퀘스트 완료 → 로컬 저장
- 온라인 복귀 → 자동 동기화
- 다른 기기 → 진행 복구

---

### Phase 6: 최종 챕터 + 보상 (1일)
**Todo**:
1. ✅ 5개 증표 아이템 체크 로직
2. ✅ 최종 챕터 잠금 해제 UI
3. ✅ 엔딩 스토리 JSON
4. ✅ 게임 완료 처리 + 크레딧

**검증**:
- 5개 증표 수집 → 최종 챕터 활성화
- 최종 챕터 완료 → 엔딩 재생

---

## 📁 파일 구조 (예상)

```
way3/
├── GameData/                    # 새로 추가
│   ├── Chapters/
│   │   └── chapters.json
│   ├── Districts/
│   │   └── districts.json
│   └── StoryData/
│       ├── ch1_intro_01.json
│       ├── ch2_intro_01.json
│       └── ... (스토리 노드들)
│
├── Core/
│   ├── ProgressManager.swift    # 새로 추가
│   ├── LocationVerifier.swift   # 새로 추가
│   ├── ReceiptVerifier.swift    # 새로 추가
│   └── StoryCore.swift          # 기존
│
├── Views/
│   ├── Story/
│   │   ├── ChapterListView.swift      # 새로 추가
│   │   ├── DistrictListView.swift     # 새로 추가
│   │   ├── MerchantQuestView.swift    # 새로 추가
│   │   ├── QuestDetailView.swift      # 새로 추가
│   │   └── StoryView.swift            # 기존 (수정 완료)
│   │
│   └── Quest/
│       └── DailyQuestView.swift       # 삭제 예정
│
└── Models/
    ├── Chapter.swift            # 새로 추가
    ├── District.swift           # 새로 추가
    └── Quest.swift              # 새로 추가
```

---

## 🎮 사용자 플로우 예시

### 챕터 1 시작
1. **스토리 탭** → "강남권: 번영의 그림자" 선택
2. **인트로 스토리** → `StoryView(startNodeID: "ch1_intro_01")` 재생
3. **구역 선택** → 강남구 (서예나 상인 표시)
4. **서브퀘스트 1** → "서예나의 첫 거래"
   - GPS 위치 이동 (강남역 반경 100m)
   - 영수증 촬영 → OCR → 5000원 이상 확인
   - 완료 → 스토리 조각 획득
5. **서브퀘스트 2** → "강남의 비밀 장소"
   - GPS 목표 지점 이동
   - 도착 → 자동 완료
6. **서브퀘스트 3** → "서예나와의 대화"
   - 대화 스토리 재생 → 완료
7. **5개 구역 완료** → "강남의 증표" 획득
8. **챕터 1 완료** → 다음 챕터 진행 가능

---

## ⚠️ 주요 결정 사항

### 1. 서버 의존 최소화
- **로컬 우선**: 모든 퀘스트/스토리 데이터는 앱 번들 JSON
- **서버 역할**: 거래 검증 + 진행 백업 + 멀티디바이스 동기화
- **오프라인 동작**: 거래 제외한 모든 기능 오프라인 가능

### 2. 퀘스트 타입
- **trading**: 영수증 OCR + (선택) GPS 위치
- **delivery**: GPS 위치 + 반경 도달
- **dialogue**: 스토리 노드 완료 (`StoryView`)

### 3. 게이팅 전략
- **챕터 게이팅**: 레벨/아이템 요구사항 (병렬 진행 가능)
- **최종 챕터**: 5개 증표 필수 (순차 강제)
- **구역 잠금**: 없음 (스토리 탭에서 모두 접근 가능)

### 4. 보상 체계
- **서브퀘스트**: 돈 + 경험치 + 스토리 조각
- **챕터 완료**: 증표 아이템 + 큰 보상
- **최종 챕터**: 엔딩 + 크레딧 + 특별 아이템

---

## 📝 다음 단계

1. ✅ **이 계획서 리뷰**: 사용자 확인 및 피드백
2. ⏭️ **JSON 스키마 구현**: `chapters.json`, `districts.json` 실제 작성
3. ⏭️ **Core 클래스 구현**: `ProgressManager`, `LocationVerifier`, `ReceiptVerifier`
4. ⏭️ **UI 재구성**: 챕터/구역/퀘스트 뷰 생성
5. ⏭️ **테스트 및 검증**: 각 Phase별 검증 항목 완료

---

**작성일**: 2025-01-09
**버전**: Way3 v2.0 Restructure Plan
**상태**: 계획 완료, 구현 대기
