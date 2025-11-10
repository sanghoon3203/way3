# WAY3 ↔ WAY-SERVER 워크플로우 가이드 (한국어)

SwiftUI 클라이언트(`way3`)와 Node.js 백엔드(`way-server`)가 기능별로 어떻게 협업하는지 정리했습니다. 각 항목은 **클라이언트 흐름**과 **서버 처리 흐름**을 나눠 적어, 한쪽에서 무엇을 기대하는지 빠르게 파악할 수 있습니다.

---

## 1. 전체 역할 개요
- **클라이언트 (way3)**
  - SwiftUI + Combine 기반 UI, GPS 및 입력 처리, 로컬 JSON(`GameData/`, `StoryData/`) 우선 로딩.
  - `GameManager`, `NetworkManager`, `ProgressManager`, `QuestManager` 등이 게임 상태를 제어하고, Keychain `SecureStorage`로 토큰을 관리합니다.
- **서버 (way-server)**
  - Express + SQLite로 인증, 거래 검증, 퀘스트/스토리 진행, 관리자 대시보드 제공.
  - 주요 테이블: `users`, `players`, `player_items`, `player_quests`, `merchant_inventory`, `trade_records`, `player_story_progress`, `merchant_relationships` 등.
  - 라우트/서비스 파일은 `src/routes/**`, `src/services/**`에 집중되어 있습니다.

---

## 2. 개발 & 테스트 준비 순서
### 2.1 서버 기동
1. `cd way-server`
2. `npm install`
3. `npm run migrate` → 모든 마이그레이션을 `data/way_game.sqlite`에 적용
4. `npm run seed` → 초기 상인/아이템/퀘스트/스토리 데이터 삽입
5. `.env` 설정 (JWT, `ALLOWED_ORIGINS`, `DB_PATH` 등)
6. 개발 모드 `npm run dev`, 운영 모드 `npm start`

### 2.2 클라이언트 실행
1. `open way3.xcodeproj` → Team 설정 (필요 시)
2. `way3/Info.plist`의 `API_BASE_URL`을 실행 중인 서버로 확인 (`http://localhost:3000` 권장)
3. Xcode에서 `Cmd + R`
4. 필요 시 `start_server.sh`로 서버·클라이언트를 한 번에 띄울 수 있습니다.

---

## 3. 기능별 협업 흐름

### 3.1 회원가입 & 로그인
- **클라이언트 흐름**
  - `RegisterView`·`LoginView` → `AuthManager` → `NetworkManager`가 `/api/auth/register`, `/api/auth/login` 호출.
  - 응답으로 받은 Access/Refresh 토큰을 Keychain에 저장하고, `NetworkManager.isAuthenticated` 상태를 갱신.
- **서버 처리 흐름 (`src/routes/api/auth.js`)**
  - `express-validator`로 이메일·비밀번호·닉네임 검증 후 `users` 테이블 중복 확인.
  - 회원가입 시 `users`·`players` 두 테이블에 함께 insert (초기 자금/스탯 설정) → JWT 발급.
  - 로그인 시 `bcrypt.compare`로 비밀번호 확인, `players.last_active` 업데이트, JWT/Refresh 토큰 재발급.
  - Refresh 토큰은 `/api/auth/refresh`에서 검증 후 새 Access 토큰을 반환.

### 3.2 위치 인증 & 근처 상인 탐색
- **클라이언트 흐름**
  - 앱 시작 시 `LocationVerifier`가 권한 요청 → `DistrictManager`로 구역 계산.
  - 맵 탭에서 현재 좌표를 기반으로 `/api/merchants/nearby` 호출, 오프라인 시 `GameData/Districts`로 대체.
  - 응답 데이터를 `Merchant` 모델에 매핑 후 핀/리스트에 반영.
- **서버 처리 흐름 (`src/routes/api/merchants.js`)**
  - `authenticateToken`으로 플레이어 식별 → `players`에서 허가증/평판 조회.
  - `player_personal_items`를 확인해 허가증 티어 파악, `merchant_relationships`로 관계 단계·진행도 계산.
  - 모든 활성 상인을 `merchants` + `merchant_inventory`에서 조인 후 하버사인 공식으로 거리 계산.
  - 각 상인에 대해 거래 가능 여부(`canTrade`), 필요 허가증, 관계도, 재고 수량 등을 계산해 응답.

### 3.3 거래 (구매/판매)
- **클라이언트 흐름**
  - `MerchantDetailView`에서 아이템 선택 → `CartManager`가 수량/금액 계산.
  - 확정 시 `NetworkManager`가 `/api/trade/execute` 호출. 성공하면 인벤토리·잔액 UI 갱신, 실패 시 `TradeLockAlert` 팝업.
- **서버 처리 흐름 (`src/routes/api/trade.js`)**
  - 공통: 요청 검증 후 `players`, `merchants`, `item_templates`, `merchant_relationships`, `player_personal_items`를 확인해 허가증/관계/등급 조건 체크.
  - **구매**
    - `merchant_inventory` 재고 확인, 플레이어 자금·인벤토리 슬롯 검증.
    - 가격 계산(상인 가격, 협상 확률, 제안가 반영) 후
      1) `players` 돈/경험치 차감,
      2) `merchant_inventory` 수량 감소,
      3) `player_items` 인벤토리에 새 아이템 insert.
  - **판매**
    - `player_items` 보유 수량 확인 → 판매 단가 계산(보통 구매가보다 낮음, 협상 시 상향).
    - 플레이어 돈/경험치/총수익 업데이트, `player_items` 수량 감소 또는 삭제, 상인 재고에 추가/증가.
  - 공통 후처리: `trade_records`에 거래 로그 추가, `merchant_relationships`에 호감도/거래 횟수 업데이트, 전체 작업은 `DatabaseManager.transaction`으로 원자 처리.

### 3.4 퀘스트 수락·진행·보상
- **클라이언트 흐름**
  - `QuestManager`가 `/game/quests`로 전체 목록/상태 로드 → `QuestCenterView`에서 표시.
  - 수락/진행/보상 시 각각 `/game/quests/:questId/accept`, `/game/quests/progress`, `/game/quests/:questId/claim` 호출.
  - 응답 결과를 `ProgressManager`에 반영해 로컬 JSON과 동기화.
- **서버 처리 흐름 (`src/routes/game/quests.js`, `src/services/game/QuestPlayerService.js`)**
  - 목록: `getQuestOverview(playerId)`가 `quest_templates`, `player_quests`, `player_story_progress` 등을 조인해 현재 상태 반환.
  - 수락: 템플릿 존재 여부, 플레이어 레벨·라이선스 조건, 중복 진행 여부를 점검 후 `player_quests`에 `status='active'` 행 생성.
  - 진행 업데이트: 각 objective에 맞춰 `player_quests.progress` JSON을 수정하고, 모든 목표 완료 시 상태를 `completed`로 변경.
  - 보상: 완료/미수령 조건을 검사 → 보상 JSON 파싱 후 `players` 자금·경험치·신뢰도를 업데이트, 필요 시 아이템 지급, `player_quests.reward_claimed` 플래그 설정.

### 3.5 스토리/에피소드 & 대화
- **클라이언트 흐름**
  - `StoryDialogueView` 혹은 상인 상세에서 `/api/merchants/:merchantId/story` 호출로 현재 노드/선택지를 받아 VN UI 표시.
  - 선택 후 `/api/merchants/:merchantId/story/progress` 전송 → 다음 노드를 받아 ViewModel 업데이트.
  - 챕터 보상은 `StoryHub`·`ProgressManager`가 `/api/story/chapter/reward` 호출.
- **서버 처리 흐름 (`src/routes/api/merchants.js`, `src/routes/api/story.js`, `src/services/game/StoryService.js`)**
  - `StoryService`가 `player_story_progress`를 관리: 방문 노드 배열, `story_flags`, 현재 노드 ID를 저장.
  - 스토리 노드(`story_nodes` 테이블) prerequisites 검사 후 선택지 필터링, 진행 시 방문 목록과 플래그를 갱신.
  - 진행 완료 시, 관련 퀘스트 objective(`dialogue` 타입)가 있다면 `player_quests.progress`를 즉시 갱신하고 완료 여부 체크.
  - 챕터 보상 API는 플레이어에게 돈/경험치/개인장비를 지급하고, `StoryService.setStoryFlag`로 `chapter_reward_*` 플래그를 기록해 중복 수령을 차단.

### 3.6 진행도·동기화 & 복구
- **클라이언트 흐름**
  - `ProgressManager`가 로컬 JSON 변화를 추적하고, 온라인일 때 퀘스트·스토리·거래 API 호출 결과로 로컬 상태를 갱신.
  - 앱 재시작 시 `/api/player/profile`, `/game/quests`, `/api/merchants/.../story` 등을 다시 호출해 서버 상태와 병합.
- **서버 처리 흐름**
  - 플레이어 핵심 상태는 `players`, 인벤토리는 `player_items`, 퀘스트는 `player_quests`, 스토리는 `player_story_progress`·`story_flags`에 보관.
  - 각 기능 API가 호출될 때마다 해당 테이블을 즉시 업데이트하므로, 별도의 전용 “동기화” 라우트가 없어도 재로그인 시 자동 복구가 가능합니다.
  - 추후 구조화된 배치 동기화를 위해 `/api/progress/sync`를 도입할 계획이며, 현재도 `StoryService`·`QuestPlayerService`가 변경 이력을 한 번에 반영할 수 있도록 JSON 필드를 사용합니다.

### 3.7 실시간 알림 & 상태 모니터링 (선택)
- **클라이언트 흐름**
  - 로그인 후 Socket.IO 세션을 열어 거래 알림, 관리자 방송 등을 수신 (`GameManager` 또는 관련 서비스에서 처리).
- **서버 처리 흐름 (`src/socket`)**
  - 인증 성공 시 소켓에 플레이어 ID를 매핑, 거래 완료/퀘스트 업데이트와 연동해 실시간 이벤트를 emit.
  - 중요 정보는 항상 REST API에서도 조회 가능하도록 동일한 DB 트랜잭션에서 기록합니다.

---

## 4. 데이터 소유권 & 활용 표

| 영역 | 서버 저장 위치 | 주요 갱신 API | 메모 |
| --- | --- | --- | --- |
| 계정/토큰 | `users`, JWT | `/api/auth/*` | Refresh 토큰으로 자동 연장 |
| 플레이어 스탯·자금 | `players` | `/api/trade/execute`, `/api/quests/:id/claim`, `/api/story/chapter/reward` | 경험치/돈 변화는 즉시 반영 |
| 인벤토리 | `player_items`, `player_personal_items` | 거래·스토리 보상·챕터 보상 | 수량 0이면 자동 삭제 |
| 퀘스트 상태 | `player_quests` | `/game/quests/*` | `progress` 컬럼은 JSON |
| 스토리 진행 | `player_story_progress`, `story_flags` | `/api/merchants/:id/story*`, `/api/story/chapter/reward` | 방문 노드·플래그로 재구성 |
| 상인 관계 | `merchant_relationships` | `/api/trade/execute`, 스토리 진행 | 호감도/단계/진행도 저장 |

---

## 5. 개발 & QA 팁
- **로그 확인**: 클라이언트는 `GameLogger`, 서버는 Winston 로그(`logs/`, `migrate.log`).
- **오프라인 테스트**: 서버를 내리고 플레이 → 거래만 실패하고 나머지는 로컬 JSON으로 계속 동작해야 함.
- **데이터 초기화**: `way-server/data/way_game.sqlite` 삭제 후 `npm run migrate && npm run seed`.
- **중요 시나리오 수동 점검**: 회원가입/로그인, 상인 탐색, 거래(구매·판매), 퀘스트 수락·진행·보상, 스토리 노드 진행, 오프라인→온라인 전환.
- **문서 참조**: `claudedocs/Game_System_Restructure_Plan.md`(데이터 스키마), `way-server_controllers_routes.md`(API 전체 목록), `way3_function_specifications.md`(클라이언트 함수 사양).

---

## 6. 변경 시 문서 업데이트 체크리스트
1. 새로운 엔드포인트 추가 또는 응답 스키마 변경 → 본 워크플로우 문서와 `claudedocs/way-server_controllers_routes.md` 동시 업데이트.
2. 로컬 JSON 스키마 수정 → `Game_System_Restructure_Plan.md` 반영, 앱 번들 및 서버 seed 동시 검토.
3. 대규모 밸런스 조정(가격, 경험치 등) → 거래/퀘스트 섹션의 서버 흐름 설명과 QA 시나리오 갱신.

이 문서만 열어도 기능 단위로 클라이언트와 서버가 어떤 데이터를 주고받는지, 어떤 테이블이 갱신되는지 빠르게 파악할 수 있습니다. 앞으로도 흐름이 바뀌면 여기에 먼저 기록해 주세요.
