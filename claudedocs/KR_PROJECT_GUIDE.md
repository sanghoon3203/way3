# Way3 한국어 프로젝트 가이드

## 1. 프로젝트 한눈에 보기
- **Way3** 는 현실 서울을 기반으로 한 위치 연동 상인 거래 RPG입니다.
- 플레이어는 `커넥트:서울` 앱을 통해 네오서울로 소환되고, 25개 자치구의 상인과 교류하며 균형을 되찾습니다.
- 핵심 경험: `현실 위치 이동` + `실시간 거래` + `스토리 기반 진행` + `사이버펑크 감성`.
- 클라이언트: SwiftUI(MVVM), 서버: Node.js/Express + Socket.IO + SQLite. 로컬 우선 저장 후 서버 동기화.

## 2. 팀별 핵심 체크포인트
### 개발자
- iOS: `GameManager`가 전역 상태를, `Player`는 5개 컴포넌트(Core/Stats/Inventory/Relationships/Achievements)를 묶어 관리합니다.
- 진행도는 `ProgressManager`가 UserDefaults에 저장하고, 필요 시 `/api/player/progress`로 서버에 동기화합니다.
- 거래는 `NetworkManager.executeTrade()` → `POST /api/trade/execute` 순차 호출. 실패 시 바로 롤백하도록 구성되어 있음.
- 실시간 요소(근처 플레이어, 거래 이벤트)는 Socket.IO 핸들러(`src/socket/handlers`)로 분리돼 있으며 JWT 토큰 인증을 거칩니다.

### 디자이너
- 테마: 네온 컬러와 각진 요소가 강조된 **사이버펑크 + JRPG** 혼합.
- 폰트: 본문은 `ChosunCentennial`, 버튼/수치 등은 모노스페이스 계열 커스텀 폰트를 사용합니다.
- 컴포넌트는 `CyperpunkComponents`, `EnhancedFontSystem` 등 재사용 가능 구조가 있으므로 가이드에 맞춰 변형합니다.
- 스토리 장면은 `StoryView`를 통해 전신 일러스트 + 대화 UI 형태로 재생됩니다. 배경/캐릭터 에셋은 `Resources/Merchant`, `StoryData` 참고.

### 기획자
- 6개 챕터 구조 (5개 권역 + 최종장), 각 챕터는 5개 구역과 2~3개 서브퀘스트로 구성.
- 모든 스토리 데이터는 JSON/Markdown로 분리돼 있어, 시나리오는 `Story/` 디렉터리에서 작성 후 변환합니다.
- 거래/퀘스트 밸런스는 SQLite 기반 데이터를 수정하거나 `claudedocs/Trade_API_Communication_Flow.md` 가이드를 활용합니다.
- 튜토리얼과 초반 경제 밸런스는 1장 `박 부장` 히든 퀘스트를 기준으로 설계되어 있으며, 신규 플로우 추가 시 프롤로그 톤 유지 필요.

## 3. 세계관 & 감정선 요약
- 네오서울은 **균형을 잃어가고 있는 서울의 또 다른 층위**로, 각 자치구가 상징하는 감정과 과잉 요소를 가진 판타지화된 공간입니다.
- 권역별 테마  
  - 강남권: 번영과 탐욕의 균형 (`서예나`, `앨리스`, `애니박`, `진백호/주블수`)  
  - 서북권: 시간/신앙/과학이 교차하는 긴장 (`기주리`, `카타리나 최`, `마리`, `김세휘`)  
  - 이후 권역도 동일한 패턴으로 확장 (Story/CharacterStory 참고).
- 메인 테마는 “평범함의 힘으로 균형을 회복한다”이며, 플레이어는 거래와 관계 맺기를 통해 각 권역의 문제를 해결합니다.

## 4. 플레이 흐름 요약
1. **소환 & 튜토리얼**: 프롤로그에서 `기주리`를 만나 임시 상인 허가증과 초반 자본(골드코인 10,000)을 얻습니다.  
2. **첫 거래 & 히든 퀘스트**: `시간 크리스탈 보관함`을 5,000에 구입 → 박 부장 퀘스트로 50만 골드코인 마련이 시나리오 목표.  
3. **챕터 진행**: `GameData/Chapters/chapters.json`에 정의된 권역 순서대로 메인 스토리 노드를 활성화합니다.  
4. **거래/호감도/능력치 성장**:  
   - 거래 성공 → 돈/경험치 증가, `PlayerStats`/`PlayerRelationships` 업데이트  
   - 라이선스/평판 조건 충족 시 더 높은 등급 상인 접근  
   - `QuestManager`로 서브퀘스트 달성 → `ProgressManager`에 상태 저장  
5. **실시간 상호작용**: 위치 기반으로 주변 플레이어 알림, 경매/마켓 정보 갱신.  
6. **최종장**: 5개의 권역 증표(`key_item_*`)를 모으면 `ch6_final`이 열리고 엔딩 시퀀스 진행.

## 5. 시스템 구조 이해하기
```
SwiftUI View
  ↓ (StateObject / EnvironmentObject)
ViewModel & Manager (GameManager, ProgressManager, QuestManager)
  ↓
Core Managers (NetworkManager, TradeManager, DataManager, LocationManager)
  ↓
Player Modular Components (Core/Stats/Inventory/Relationships/Achievements)
  ↓
REST API (Express) + Socket.IO (실시간)
  ↓
SQLite (players, merchants, quests, story_progress …)
```
- **클라이언트 구조**  
  - `GameManager`: 게임 루프, 알림, 캐시 로드.  
  - `NetworkManager`: 토큰 발급, 공통 API 호출, 에러 메시지 한국어화.  
  - `ProgressManager`: 로컬 진행 상황 저장, `chapters.json`과 연동.  
  - `StoryCore` + `StoryView`: JSON 기반 스토리 노드를 로드하고 완료 콜백 실행.  
  - `LocationManager`: GPS 허용 상태/좌표를 업데이트, `DistrictManager`가 구역 판정.  

- **서버 구조**  
  - `src/app.js`: 보안 헤더, CORS, Rate limit, 세션 정리.  
  - `DatabaseManager`: 테이블 생성 + Admin 확장, `AdminExtensions`로 admin/quest 스키마 관리.  
  - REST 라우트: `/api/auth`, `/api/player`, `/api/merchants`, `/api/trade`, `/api/quests`, ...  
  - Socket: `socketAuth`로 JWT 검증 → 위치/거래/채팅 핸들러 분리.  
  - 데이터는 `database/migrations`의 SQL 스크립트로 버전 관리, 업로드 자산은 `/uploads` 경로 노출.

## 6. 데이터 & 네트워크 핵심
- **Player 데이터 구성** (`Models/Player/`)  
  | 컴포넌트 | 주요 책임 | 비고 |  
  | --- | --- | --- |  
  | `PlayerCore` | 신원, 돈, 레벨, 라이선스 | 경험치 계산/레벨업 포함 |  
  | `PlayerStats` | 능력치·스킬 | 힘 → 인벤토리 확장 등 파생 값 |  
  | `PlayerInventory` | 아이템 슬롯, 장비 | 용량 체크/정렬/보상 반영 |  
  | `PlayerRelationships` | 친구, 상인 신뢰도 | 거래 할인, 호감도 시나리오 연결 |  
  | `PlayerAchievements` | 업적, 통계 | 로컬 저장 + UI 배지 |  

- **거래 흐름** (`claudedocs/Trade_API_Communication_Flow.md` 참고)  
  1. `MerchantDetailView.executeTradeForCart()`가 장바구니 아이템을 순차 API 호출  
  2. `NetworkManager.makeRequest()` → `POST /api/trade/execute`  
  3. 서버에서 라이선스/평판/재고 확인 후 SQLite 트랜잭션 처리  
  4. 성공 시 플레이어 데이터를 새로고침, 실패 시 메시지 한국어로 표시  
  5. 자주 발생하는 오류(`403 라이선스`, `재고 부족`, `자금 부족`)는 클라이언트에서 가이드 메시지 제공  

- **실시간 요소**  
  - 위치 업데이트: `socket.emit('location:update')` → 지역 룸에 브로드캐스트 → 주변 플레이어 리스트 반영.  
  - 거래 피드: 성공 거래 시 `trade:activity` 이벤트로 50건까지 저장.  
  - 경매/가격 변동: `/api/merchants`와 병행해 Socket 이벤트 수신.  
  - 권역별 룸(`district:<id>`)로 구분해 네트워크 트래픽을 줄임.

## 7. 스토리 & 챕터 설계
- **로컬 우선 구조**: `GameData/Chapters` + `GameData/Districts` + `StoryData` JSON이 앱 번들에 포함. 오프라인에서도 진행 가능.  
- `StoryView`는 시작 노드 ID와 완료 콜백을 전달받아, JSON 내 `next_node_id`를 따라가며 재생합니다.  
- 모노가타리 스타일 문체 분석(`Story/설정집/모노가타리_스타일_분석.md`)을 기반으로, 내적 독백 + 대화 리듬을 유지합니다.  
- 캐릭터별 설정(`Story/CharacterStory/`)은 톤/말투/주요 아이템이 정리되어 있으므로, 신규 시나리오 작성 시 참고합니다.  
- 진행도 저장은 `ProgressManager.collectStoryPiece()` 등 전용 메서드 사용. 최종장은 5개 증표 보유 여부로 언락합니다.

## 8. 디자인 & 연출 가이드
- **색상 팔레트** (자세한 값은 `05_UI_DESIGN_SYSTEM.md`)  
  - 포인트: `cyberpunkYellow` (#FFD900), `cyberpunkCyan` (#00E5E5), `cyberpunkGreen` (#00FF4D)  
  - 배경: `cyberpunkDarkBg`, `cyberpunkPanelBg`, `cyberpunkCardBg`  
  - 텍스트: 기본 화이트, 보조 회색, 강조 시 시안/옐로우.  
- **타이포그래피**  
  - `Font.cyberpunkTitle/Heading/Body/Caption` 계층을 유지.  
  - 버튼/숫자는 대문자 + 모노스페이스 느낌 유지.  
- **레이아웃**  
  - 각진 모서리(기본 radius 4), 네온 글로우, 그리드 기준 spacing 12.  
  - 정보량이 많은 화면은 패널화/분리선으로 가독성 확보.  
- **애니메이션**  
  - 허용: 짧고 반복 주기가 긴 글로우/펄스, 정지 상태에서도 시선이 흐르도록 subtle motion.  
  - 금지: 과도한 모션, 프레임 드랍을 유발하는 복잡한 효과.  
- **리소스 관리**  
  - 상인 일러스트/배경은 `Resources/Merchant`, 배경 BGM은 `Resources/Sound`. 추가 자산 투입 시 naming 규칙 준수.  
  - Midjourney 등 외부 생성을 위한 프롬프트 참고는 `Midjourney_Background_Prompts.md` (필요 시 추가).

## 9. 운영 & 협업 팁
- **개발 환경**  
  - iOS: Xcode 15+, SwiftUI. `NetworkConfiguration`에서 Base URL/토큰 설정.  
  - 서버: Node 18+, `npm install` 후 `npm run migrate`, `npm start`. Railway 배포 설정은 `railway.toml`.  
  - 로컬에서 iOS + 서버 동시에 실행 시 CORS/Socket 포트(`:3000`) 유지.  
- **테스트**  
  - iOS: `way3Tests`(AuthManager, SecureStorage 등), `way3UITests`(런치 및 핵심 플로).  
  - 서버: Postman/VS Code `http` 파일로 엔드포인트 검증, `/logs`에 Winston 로그 확인.  
  - 실시간 기능은 시뮬레이터 2대 혹은 디바이스+시뮬레이터 조합으로 검증.  
- **문서 업데이트 규칙**  
  - 핵심 구조 변경 시 `00~09` 문서를 우선 수정, 팀별로 README에 링크 추가.  
  - 스토리 추가 시 `Story/` 내 Markdown → JSON 변환 스크립트 업데이트 필요.  
  - 밸런스 조정/테이블 스키마 변경 시 `database/migrations`에 새 SQL 작성 후 버전 기록.

## 10. 용어 & 참고 문서
- **커넥트:서울**: 플레이어가 사용하는 게임 내 앱.  
- **골드코인**: 네오서울 공통 화폐.  
- **증표(Key Item)**: 권역 완료 보상, 최종장 입장 조건.  
- **균형(Balance)**: 스토리 핵심 테마. 탐욕/단절/조급함 등의 과잉 상태를 중화하는 것이 목표.

### 필수 참고 자료
- 전체 구조: `00_PROJECT_OVERVIEW.md`, `01_ARCHITECTURE.md`
- 플레이어 시스템: `02_PLAYER_SYSTEM.md`
- 게임플레이 & 경제: `03_GAME_FEATURES.md`, `Trade_API_Communication_Flow.md`
- 네트워크/실시간: `04_NETWORK_REALTIME.md`, `08_SERVER_ARCHITECTURE.md`
- 디자인: `05_UI_DESIGN_SYSTEM.md`, `StoryView_Usage_Guide.md`
- 스토리/세계관: `Story/설정집/Main.md`, `Story/CharacterStory/*`, `story-system-design.md`

---
_최종 업데이트: 2025-10-07 · 작성: KR 통합 가이드 v1.0_
