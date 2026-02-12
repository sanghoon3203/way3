# WAY3 문서 인덱스

WAY3 리포지토리의 모든 기획/설계 문서 네비게이션 가이드.
새 대화/세션 시작 시 이 파일을 먼저 확인하세요.

> 실제 게임 데이터는 `way3/GameData/`, `way3/StoryData/` JSON 기준으로 동작합니다.
> 여기 문서들은 기획 원본 / 레퍼런스 용도입니다.

---

## 1. 핵심 개요 문서 (항상 최신 유지)

| 문서 | 설명 | 최근 업데이트 |
|------|------|------------|
| `00_PROJECT_OVERVIEW.md` | 전체 게임 컨셉, 시스템 개요, API, 상인 현황, 로드맵 | 2026-02-12 |
| `WAY3_PROJECT_FIELD_GUIDE.md` | iOS 코드 구조, 매니저 목록, 데이터 흐름, TODO 목록 | 2026-02-12 |
| `Game_System_Restructure_Plan.md` | GameData/StoryData JSON 스키마, 퀘스트 구조 설계 | 2026-02-12 |
| `REACT_NATIVE_MIGRATION_PLAN.md` | React Native 이식 전략 (`connectseoul/` 프로젝트) | 2026-02-12 |
| `DOCUMENT_INDEX.md` | 이 파일 — 전체 문서 네비게이션 | 2026-02-12 |

---

## 2. 현황 추적 문서 (작업 중 수시 업데이트)

| 문서 | 설명 |
|------|------|
| `status/STORY_STATUS.md` | 스토리 노드 완성도, 배경 이미지 현황 |
| `status/QUEST_STATUS.md` | 퀘스트 GameData 현황, 버그 목록 |

---

## 3. 스토리/캐릭터 레퍼런스

### 스크립트 원본
| 문서 | 설명 |
|------|------|
| `Seoyena_Full_Script.md` | 서예나 3개 서브퀘스트 풀 시나리오 |
| `Gangnam/Gangnam.md` | 강남 챕터 개요 |
| `Gangnam/SeoYena.md` | 서예나 캐릭터 심층 자료 |
| `Gangdong/01_Intro.md`, `02_Subquests.md`, `03_Climax.md` | 강동 챕터 3막 구성 |
| `Seocho/01_Intro.md`, `02_chapter.md`, `03_Climax.md` | 서초 챕터 3막 구성 |
| `Songpa/01_Intro.md`, `02_chapter2.md`, `03_Climax.md` | 송파 챕터 3막 구성 |

### 캐릭터 설정집 (리포 루트의 Story/ 폴더)
| 문서 | 설명 |
|------|------|
| `Story/설정집/Main.md` | 25개 구 세계관 설정 (네오 서울 세계관) |
| `Story/CharacterStory/강남권_캐릭터들_v2.md` | 강남권 5명 캐릭터 바이블 (서예나, 앨리스강, 애니박, 진백호, 주블수) |
| `Story/CharacterStory/서북권_캐릭터들_v2.md` | 서북권 4명 캐릭터 바이블 (기주리, 카타리나 최, 마리, 김세휘) |
| `Story/mushoku_style_notes.md` | 문체 가이드 (무직전생 스타일 분석) |

### GPS 레퍼런스
| 문서 | 설명 |
|------|------|
| `Merchant_GPS_Coordinates.md` | 9명 상인 실제 GPS 좌표 |

---

## 4. 확장 아이디어 (미구현)

| 문서 | 설명 |
|------|------|
| `TempSubExpansion/Alice/01.md` | 앨리스강 서브퀘 확장 아이디어 |
| `TempSubExpansion/Anipark/01.md` | 애니박 서브퀘 확장 아이디어 |
| `TempSubExpansion/Jinbaekho/01.md` | 진백호 서브퀘 확장 아이디어 |
| `TempSubExpansion/Jubulsu/01.md` | 주블수 서브퀘 확장 아이디어 |
| `prologue copy.md` | 프롤로그 텍스트 백업 (빈 파일) |

---

## 5. 서버 관련 문서

| 문서 | 설명 |
|------|------|
| `way3_way-server_workflow.md` | 클라이언트-서버 상호작용 플로우 |
| `way-server_controllers_routes.md` | 서버 라우트/컨트롤러 전체 레퍼런스 |

---

## 6. 도구 및 스크립트 (리포 루트)

| 스크립트 | 용도 |
|---------|------|
| `build_story_data.py` | StoryData/ JSON 통합 빌드 |
| `generate_gangdong_jsons.py` | 강동 스토리 JSON 생성 |
| `restructure_gangdong.py` | 강동 데이터 재구조화 |
| `split_gangdong_json.py` | 강동 JSON 분할 |
| `convert_gangnam_to_md.py` | 강남 JSON → 마크다운 변환 |
| `extract_seoyena_sub.py` | 서예나 서브스토리 추출 |

---

## 빠른 온보딩 가이드

### 처음 프로젝트를 보는 경우
1. `00_PROJECT_OVERVIEW.md` — 게임 컨셉과 전체 구조 파악
2. `WAY3_PROJECT_FIELD_GUIDE.md` — iOS 코드 구조와 데이터 흐름
3. `status/STORY_STATUS.md` — 현재 어디까지 만들어졌는지 확인
4. `status/QUEST_STATUS.md` — 퀘스트 현황 및 버그 확인

### 스토리 작업을 하는 경우
1. `Story/설정집/Main.md` — 세계관 확인
2. 해당 권역 캐릭터 바이블 확인
3. `Story/mushoku_style_notes.md` — 문체 확인
4. `StoryData/STORY_DATA_GUIDE.md` — JSON 작성 방법 확인
5. `status/STORY_STATUS.md` — 어느 노드부터 이어서 쓸지 확인

### 퀘스트/게임 로직 작업을 하는 경우
1. `Game_System_Restructure_Plan.md` — JSON 스키마 확인
2. `status/QUEST_STATUS.md` — 현황 및 버그 확인
3. `WAY3_PROJECT_FIELD_GUIDE.md` — 관련 Swift 파일 위치 확인

### React Native 이식 작업을 하는 경우
1. `REACT_NATIVE_MIGRATION_PLAN.md` — 이식 전략 및 진행 현황
2. `WAY3_PROJECT_FIELD_GUIDE.md` — Swift 구조 → RN 매핑 참고
3. `connectseoul/` 디렉토리 — 현재 RN 프로젝트 상태 확인

---

**최종 업데이트**: 2026-02-12
