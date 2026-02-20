# connect:seoul 문서 인덱스

connect:seoul 리포지토리의 모든 기획/설계 문서 네비게이션 가이드.
새 대화/세션 시작 시 이 파일을 먼저 확인하세요.

> 실제 게임 데이터는 `way3/StoryData/` JSON 기준으로 동작합니다.
> 여기 문서들은 기획 원본 / 레퍼런스 용도입니다.

---

## 핵심 문서 (항상 최신 유지)

| 파일 | 설명 | 최근 업데이트 |
|------|------|------------|
| `01_PROJECT_OVERVIEW.md` | 전체 게임 컨셉, 시스템 개요, API, 상인 현황, 로드맵 | 2026-02-20 |
| `02_FIELD_GUIDE.md` | iOS 코드 구조, 매니저 목록, 데이터 흐름, TODO 목록 | 2026-02-20 |
| `03_GAME_SYSTEM.md` | StoryData JSON 스키마, 퀘스트 구조 설계 | 2026-02-12 |
| `04_UI_SYSTEM.md` | 조선사이버펑크 디자인 시스템 (오방색, 폰트, 컴포넌트) | 2026-02-20 |
| `05_AI_CHAT_SYSTEM.md` | AI 상인 채팅 시스템 (Gemini, 언락 트리거) | 2026-02-20 |
| `06_WORKFLOW.md` | 전체 워크플로우 상세 — 앱 진입·게임 루프·스토리·거래·AI채팅·퀘스트·데이터 레이어 | 2026-02-20 |

---

## 현황 추적 문서 (작업 중 수시 업데이트)

| 파일 | 설명 |
|------|------|
| `status/STORY_STATUS.md` | 스토리 노드 완성도, 배경 이미지 현황 |
| `status/QUEST_STATUS.md` | 퀘스트 GameData 현황, 버그 목록 |

---

## 설계 문서 (docs/plans/)

| 파일 | 설명 |
|------|------|
| `docs/plans/2026-02-17-joseon-cyberpunk-ui.md` | 조선사이버펑크 UI 전면 재설계 계획 (완료) |
| `docs/plans/2026-02-20-ai-merchant-chat-design.md` | AI 상인 채팅 시스템 설계 문서 |

---

## 캐릭터 설정집 (리포 루트의 Story/ 폴더)

| 경로 | 설명 |
|------|------|
| `Story/설정집/Main.md` | 25개 구 세계관 설정 (네오 서울 세계관) |
| `Story/CharacterStory/강남권_캐릭터들_v2.md` | 강남권 5명 캐릭터 바이블 (서예나, 앨리스강, 애니박, 진백호, 주블수) |
| `Story/CharacterStory/서북권_캐릭터들_v2.md` | 서북권 4명 캐릭터 바이블 (기주리, 카타리나 최, 마리, 김세휘) |
| `Story/mushoku_style_notes.md` | 문체 가이드 (무직전생 스타일 분석) |

---

## 빠른 온보딩 가이드

### 처음 프로젝트를 보는 경우
1. `01_PROJECT_OVERVIEW.md` — 게임 컨셉과 전체 구조 파악
2. `02_FIELD_GUIDE.md` — iOS 코드 구조와 데이터 흐름
3. `04_UI_SYSTEM.md` — 조선사이버펑크 디자인 시스템
4. `status/STORY_STATUS.md` — 현재 어디까지 만들어졌는지 확인

### UI/컴포넌트 작업을 하는 경우
1. `04_UI_SYSTEM.md` — 색상/폰트/컴포넌트 규칙 확인
2. `02_FIELD_GUIDE.md` — 관련 Swift 파일 위치 확인
3. SourceKit 오류는 false positive — Xcode 빌드 시 해소

### AI 채팅 시스템 작업을 하는 경우
1. `05_AI_CHAT_SYSTEM.md` — 전체 아키텍처 확인
2. `docs/plans/2026-02-20-ai-merchant-chat-design.md` — 설계 원본
3. `way-server/src/constants/merchantPersonas.js` — 상인 인격 정의
4. `GEMINI_API_KEY` 환경 변수 설정 확인

### 스토리 작업을 하는 경우
1. `Story/설정집/Main.md` — 세계관 확인
2. 해당 권역 캐릭터 바이블 확인
3. `Story/mushoku_style_notes.md` — 문체 확인
4. `status/STORY_STATUS.md` — 어느 노드부터 이어서 쓸지 확인

### 퀘스트/게임 로직 작업을 하는 경우
1. `03_GAME_SYSTEM.md` — JSON 스키마 확인
2. `status/QUEST_STATUS.md` — 현황 및 버그 확인
3. `02_FIELD_GUIDE.md` — 관련 Swift 파일 위치 확인

---

**최종 업데이트**: 2026-02-20
