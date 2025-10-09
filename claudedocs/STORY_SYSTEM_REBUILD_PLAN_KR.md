# Way3 메인 스토리 시스템 재설계 메모

## 1. 배경 및 목표
- **현재 상황**  
  - `chapters.json`·`districts.json` 등 데이터는 존재하지만, 챕터/구역/스토리 진행이 단일 흐름으로 연결되어 있지 않음.  
  - 스토리 재생 → 퀘스트 연결 → 상인 서브 퀘스트 요구 아이템 구조가 미완성 상태.
- **최종 목표**  
  - 챕터 선택 후 5개 구역을 자유롭게 탐색하며 스토리 에피소드를 순차 진행.  
  - 각 에피소드 완료 시 자동으로 해당 메인 퀘스트가 생성되고, 필요한 경우 상인 서브 퀘스트·아이템 요구 조건과 연동.  
  - 서브 퀘스트 보상 아이템을 인벤토리에 지급하고, 메인 퀘스트 요구사항에 사용 가능.  
  - 진행도/보상/아이템/영수증 검증을 서버와 동기화하여 다중 디바이스에서도 일관된 경험 제공.

## 2. 새로운 사용자 플로우 요약
1. **스토리 탭** → 챕터 선택 (예: 강남권).  
2. 챕터 화면에서 5개 구역이 모두 활성화(Active) 상태로 표시.  
3. 구역 선택 시, 해당 구역의 메인 스토리 에피소드 리스트 표시.  
   - 에피소드 순서대로 잠금/언락 처리 (1편 완료 시 2편 언락).  
4. 에피소드 선택 → `StoryView` 재생 → 종료 시 자동으로 `ProgressManager`와 연동.  
5. 스토리 완료 콜백에서 관련 메인 퀘스트를 `QuestManager`에 등록, 퀘스트 탭에서 수행 가능.  
6. 퀘스트 요구조건에 따라 상인 서브 퀘스트, 특정 아이템, 스토리 진행 상황 등을 검사.  
7. 서브 퀘스트 완료 시 아이템 · 돈 · 경험치 · 신뢰도 · 스토리 조각 등 복합 보상을 지급.  
8. 챕터 내 5개 구역을 모두 완료하면 증표 아이템 획득 → 최종장 언락.

## 3. 데이터 구조 재설계
### 3.1 신규 파일
- `GameData/Story/story_main_chapters.json`  
  ```json
  {
    "chapters": [
      {
        "chapter_id": "ch1_gangnam",
        "title": "강남권: 번영의 그림자",
        "order": 1,
        "districts": [
          {
            "district_id": "gangnam_gu",
            "episodes": [
              {
                "episode_id": "gangnam_1_1",
                "title": "서예나 - 프롤로그",
                "story_node_id": "gangnam_1_1_start",
                "order": 1,
                "unlock_conditions": [],
                "post_quest_id": "mainquest_gangnam_1_1"
              },
              {
                "episode_id": "gangnam_1_2",
                "title": "서예나 - 첫 거래",
                "story_node_id": "gangnam_1_2_start",
                "order": 2,
                "unlock_conditions": ["episode:gangnam_1_1"],
                "post_quest_id": "mainquest_gangnam_1_2"
              }
            ]
          }
        ]
      }
    ]
  }
  ```

- `GameData/Quests/main_quests.json`  
  ```json
  {
    "quests": [
      {
        "quest_id": "mainquest_gangnam_1_1",
        "title": "서예나의 의뢰 1",
        "type": "story_main",
        "description": "...",
        "requirements": {
          "required_story_ids": ["gangnam_1_1"],
          "required_items": [],
          "required_level": 1
        },
        "objectives": [
          {
            "type": "delivery",
            "target_location": { "latitude": ..., "longitude": ..., "radius": 50 }
          }
        ],
        "rewards": {
          "money": 15000,
          "exp": 200,
          "inventory_items": ["questitem_receipt_scanner"],
          "story_piece_ids": ["story_piece_seoyena_01"]
        }
      }
    ]
  }
  ```

### 3.2 기존 파일 정리
- `districts.json`은 **상인 + 서브 퀘스트 + 상점 메타**에 집중.  
  - `merchant` 안에 실제 상점 정보(`store_id`, `store_name`) 추가.  
  - 서브 퀘스트 보상에 `inventory_items`를 포함하여 메인 퀘스트에서 요구 가능하도록 조정.
- `chapters.json`은 최종장 증표 조건 등 최소 정보만 유지하거나 폐기 후 `story_main_chapters.json`에 통합.

## 4. 진행 상태 모델 확장
- `PlayerProgress` 변경 사항  
  ```swift
  struct PlayerProgress: Codable {
      var completedEpisodes: Set<String>
      var unlockedEpisodes: Set<String>
      var completedMainQuests: Set<String>
      var completedSubQuests: Set<String>
      // 기존 필드: completedChapters, completedDistricts, keyItems 등도 유지
      var version: Int
  }
  ```
- 초기화 시 기존 데이터 버전을 확인하고, 없으면 마이그레이션 수행.
- `completeEpisode(_:)`, `unlockNextEpisodes(for:)`, `completeMainQuest(_:)` 등 새 메서드 추가.

## 5. 클라이언트 로직/구조 개선
1. **스토리 네비게이터 뷰모델 (신규)**  
   - 챕터 → 구역 → 에피소드 데이터를 로드해 UI에 제공.  
   - 에피소드 잠금/언락 상태 판단에 `ProgressManager` 사용.  
   - 에피소드 선택 이벤트를 관리하고 `StoryView` 호출 파이프라인 구성.

2. **StoryView 완료 콜백 통합**  
   - 현재: 콜백에서 간단한 로직 수행.  
   - 변경: `StoryFlowController.finishEpisode(episode)` 호출 → `ProgressManager.completeEpisode` + `QuestSpawner.createMainQuestIfNeeded`.

3. **QuestManager 리팩터링** (`Documents/GitHub/way3/way3/Core/QuestManager.swift`)  
   - `QuestRequirements` 구조 확장 (`required_story_ids`, `required_items`, `required_level`, `required_sub_quests` 등).  
   - `QuestRewards`를 세분화하고 `PlayerInventory`, `PlayerRelationships`, `PlayerAchievements`와 연동.  
   - `canStartQuest`/`execute*Quest`에서 새 조건 및 보상 적용.

4. **보상 처리 유틸리티 (신규)**  
   - `RewardProcessor.apply(rewards: QuestRewards, to player: Player)` 형태로 보상 로직을 단일화.  
   - 돈/경험치/스토리 조각/아이템/증표/신뢰도 변경 모두 여기서 처리.

5. **UI/UX 업데이트**  
   - 스토리 탭: 에피소드 리스트에 `진행중`, `진행 가능`, `잠금` 상태 뱃지.  
   - 퀘스트 탭: “메인 스토리” 섹션과 “상인 서브” 섹션 분리, 요구 조건/보상 명시.  
   - 퀘스트 상세 화면에 필요한 아이템/스토리/레벨 정보를 시각적으로 표현.

## 6. 상점·영수증 검증 강화
- `QuestRequirements.location`에 `store_id`, `store_name` 추가.  
- `ReceiptVerifier.verifyReceipt`에서 상호명/고유 식별자를 비교.  
- 영수증 해시 중복 체크 + 상점별 검증 로직을 강화, 필요 시 사용자 수동 확인 단계 추가.

## 7. 서버 연동 계획
1. **진행도 동기화**  
   - `player_progress` 테이블(episodes, quests, items, key_items, last_synced_at 등).  
   - `/api/progress/sync` 엔드포인트에서 클라이언트 상태 업로드/다운로드.  
   - 서버에서 요구 조건 검사(에피소드 완료 여부, 아이템 보유 여부) 지원.

2. **퀘스트 API 확장**  
   - 메인 퀘스트 CRUD 및 상태 업데이트 라우트 추가 (`/api/quests/main`).  
   - 상인 서브 퀘스트 관련 아이템 보상/요구사항도 서버에서 검증하도록 설계.

3. **영수증 검증 API**  
   - 영수증 OCR 결과를 서버에 업로드하고, 서버가 최종 검증/저장을 수행.  
   - 중복 제출, 상점 불일치 등 서버 측에서도 차단.

4. **안전장치**  
   - 클라이언트 보상 지급 전에 서버 확인을 필요로 하는 퀘스트(중요 아이템/증표 등)는 서버 승인 후 지급 프로세스로 전환.

## 8. 단계별 구현 로드맵
1. **데이터 스키마 작성**  
   - 신규 JSON 설계 & 샘플 데이터 작성 → 기존 데이터 마이그레이션 스크립트/문서화.  
2. **ProgressManager 확장 및 마이그레이션 코드 구현**  
   - 저장 버전 관리, 기존 사용자 데이터 변환.  
3. **스토리 네비게이터 & StoryFlowController 구축**  
   - UI/로직 통합, 스토리 재생 → 에피소드 완료 콜백 파이프라인 확립.  
4. **QuestManager/Rewards 리팩터링**  
   - 요구조건/보상 구조 변경, RewardProcessor 도입.  
5. **UI 업데이트 & QA**  
   - 스토리/퀘스트 탭 시각화, 잠금 처리, 진행 상태 표시.  
6. **서버 API 확장**  
   - 진행도/퀘스트/영수증 관련 엔드포인트 구현 및 클라이언트 연동.  
7. **통합 테스트**  
   - 단일 디바이스에서 프롤로그 → 강남 에피소드 체인 → 서브 퀘스트 → 아이템 필요 메인 퀘스트 진행 검증.  
   - 멀티 디바이스 동기화/재로그인 시 상태 일관성 확인.  
8. **문서화 & 인수인계**  
   - `claudedocs`에 스토리 시스템/데이터 스키마/서버 API 변경 사항 반영.  
   - 기획·디자인 팀을 위한 에피소드 제작 가이드 업데이트.

## 9. 남은 결정 사항 / 리스크
- **데이터 분리 여부**: 스토리·퀘스트 데이터를 한 JSON에 둘지, 여러 파일로 분리할지 확정 필요.  
- **서버 연동 방식**: 영수증 및 퀘스트 검증을 어느 단계에서 서버 승인으로 전환할지 결정.  
- **기존 사용자 진행도 처리**: 신규 시스템 도입 시 최초 세션에서 어떤 방식으로 자동 변환/튜토리얼을 제공할지 정해야 함.  
- **실상점 데이터 확보**: 상점별 좌표·상호명·store_id 관리 방법(별도 DB? JSON?)을 확정하고 유지 계획 필요.

---
이 문서는 Way3 메인 스토리 시스템을 “챕터 → 구역 → 에피소드 → 퀘스트” 구조로 재편하는 전체 그림을 요약한 것입니다.  
향후 작업 시 단계별 실행 항목과 의존 관계를 확인하는 기준 문서로 사용하세요.  
_작성일: 2025-10-07 · 작성자: Codex (슈퍼 띵크 모드)_ 
