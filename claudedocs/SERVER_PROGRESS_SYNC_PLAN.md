# Way3 진행도/퀘스트 서버 동기화 설계 초안

## 1. 목표
- 클라이언트 로컬 진행 상태(에피소드, 서브/메인 퀘스트, 증표, 스토리 조각 등)를 서버와 양방향 동기화.
- 실상점 영수증 검증 결과를 서버에서 2차 확인하고 저장해 치팅을 방지.
- 멀티 디바이스 로그인 시 일관된 진행도를 유지하며, 서버가 최종 진실 소스로 동작.

## 2. 데이터 스키마 제안 (SQLite)
### 2.1 player_progress
| 칼럼 | 타입 | 설명 |
|------|------|------|
| player_id | TEXT (PK) | 플레이어 ID |
| completed_episodes | TEXT(JSON) | 완료 에피소드 목록 |
| unlocked_episodes | TEXT(JSON) | 언락 상태 에피소드 목록 |
| completed_sub_quests | TEXT(JSON) | 완료 서브 퀘스트 ID 배열 |
| completed_main_quests | TEXT(JSON) | 완료 메인 퀘스트 ID 배열 |
| collected_story_pieces | TEXT(JSON) | 수집한 스토리 조각 ID 배열 |
| key_items | TEXT(JSON) | 보유 증표/키 아이템 ID 배열 |
| completed_chapters | TEXT(JSON) | 완료 챕터 ID 배열 |
| completed_districts | TEXT(JSON) | 완료 구역 ID 배열 |
| last_synced_at | DATETIME | 마지막 동기화 시간 |
| version | INTEGER | 진행 데이터 버전(클라이언트와 동일) |

### 2.2 quest_items (선택)
| 칼럼 | 타입 | 설명 |
|------|------|------|
| id | TEXT (PK) |
| player_id | TEXT | |
| item_id | TEXT | 보상 아이템 ID |
| source | TEXT | 획득 출처(퀘스트/챕터 등) |
| acquired_at | DATETIME | 지급 시각 |

### 2.3 receipt_verifications
| 칼럼 | 타입 | 설명 |
|------|------|------|
| id | TEXT (PK) |
| player_id | TEXT | |
| quest_id | TEXT | 연관 퀘스트 ID |
| store_id | TEXT | 실제 상점 ID |
| receipt_hash | TEXT | 영수증 해시(중복 방지) |
| amount | INTEGER | 인식된 금액 |
| merchant_name | TEXT | 인식된 상호명 |
| verified | BOOLEAN | 서버 검증 여부 |
| created_at | DATETIME | 업로드 시간 |

## 3. API 엔드포인트

### 3.1 진행도 Sync
- `GET /api/progress`
  - 요청 헤더: `Authorization: Bearer <token>`
  - 응답 데이터: `player_progress` 테이블 내용을 JSON으로 전달
- `POST /api/progress/sync`
  - 본문: 클라이언트 `PlayerProgress` 직렬화 데이터(JSON)
  - 서버 로직:
    1. 요청 데이터 버전 확인
    2. 서버 저장된 진행도와 클라이언트 데이터를 비교하여 우선순위 결정 (최근 `last_synced_at` 기준)
    3. 서버 데이터 갱신 후 최신 상태 반환

### 3.2 영수증 업로드/검증
- `POST /api/receipts/verify`
  - 본문: 
    ```json
    {
      "questId": "seoyena_sub_01",
      "image": "<base64 or multipart>",
      "storeId": "real_store_coex_001",
      "clientHash": "sha256..."
    }
    ```
  - 처리 흐름:
    1. 이미지 저장 또는 OCR (필요 시 서버 OCR 수행, 미사용 시 클라이언트 인식 데이터를 함께 전송)
    2. 상호명/금액/시간 정보 파싱 → 서버 DB와 비교
    3. 중복 영수증 여부 확인(`receipt_hash`)
    4. 검증 성공 시 `receipt_verifications`에 저장, 응답으로 금액/상호명/검증 결과 전달

### 3.3 메인 퀘스트 완료 보고 (선택)
- `POST /api/quests/main/complete`
  - 본문: `{ "questId": "mainquest_gangnam_1_1" }`
  - 서버가 진행 조건을 추가 확인하고 보상 지급/동기화 후 최종 상태 반환.

## 4. 동기화 전략
1. **앱 시작 시**: `GET /api/progress` 호출 → 서버 상태와 로컬 `PlayerProgress` 비교 → 최신 데이터로 병합 (`ProgressManager` 마이그레이션 로직 재사용).
2. **중요 이벤트 후**(에피소드 완료, 퀘스트 완료, 증표 획득 등):  
   - 로컬 반영 → `POST /api/progress/sync` 비동기 호출 → 서버와 동기화.
3. **영수증 제출 시**:  
   - 클라이언트에서 1차 OCR → 검증 성공 시 이미지/요약 데이터 서버에 업로드 → 서버 승인 후 퀘스트 완료 확정.

## 5. 보안/치팅 고려 사항
- 영수증 해시 중복 체크로 동일 이미지 재활용 방지.
- 상호명/금액/시간 범위 검증 (운영자가 제공한 실제 상점 데이터와 비교).
- 진행도 업데이트 시 서버가 유효성 검사 (예: 존재하지 않는 퀘스트/에피소드 ID 거부).
- 클라이언트는 진행도/보상 상태를 캐시하되, 서버 응답이 실패하면 재시도 로직 및 충돌 해결 전략(최신 타임스탬프 우선)을 구현.

## 6. 후속 작업 항목
1. **노드/퀘스트 메타 데이터 API 준비**  
   - 서버가 최신 메인 퀘스트 정의/스토리 락 정보를 내려줄 수 있도록 `/api/story/meta`.
2. **서버 OCR 도입 검토**  
   - 클라이언트 OCR 결과만 사용할지, 서버 측에서도 검증할지 결정.
3. **진행도 병합 전략 구현**  
   - 동일 시각에 서로 다른 기기에서 플레이한 경우 우선순위를 어떻게 둘지 정의 (Timestamp + 변경 로그 기반).
4. **단위 테스트/통합 테스트 케이스**  
   - 클라이언트 ProgressManager와 서버 API 간 통신 흐름을 자동화 테스트로 검증할 계획 수립.

---
_작성일: 2025-10-07 · 초안 · 추후 API 설계/구현 시 보완 예정_
