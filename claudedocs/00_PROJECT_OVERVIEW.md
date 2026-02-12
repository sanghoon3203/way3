# WAY3 게임 프로젝트 개요

**프로젝트명**: WAY3 (The Way Trading Game)
**플랫폼**: iOS (SwiftUI) — React Native 이식 진행 중 (`connectseoul/`)
**장르**: 위치 기반 GPS 트레이딩 RPG + Visual Novel
**배경**: 서울시 25개 구
**최종 업데이트**: 2026-02-12

---

## 게임 컨셉

WAY3는 실제 서울을 무대로 한 위치 기반 트레이딩 RPG입니다.
플레이어는 GPS로 실제 위치를 인증하며 각 구의 상인 NPC를 만나고,
거래·퀘스트·Visual Novel 형식의 스토리를 통해 서울 전역을 탐험합니다.

### 핵심 루프
```
실제 위치 이동
  → GPS 근처 상인 발견 (Mapbox 3D 맵)
  → 아이템 거래 (매입/매도)
  → 서브퀘스트 수행 (배달/거래/대화)
  → VN 스토리 진행 (에피소드 해금)
  → 보상 (돈/경험치/스토리 조각/열쇠 아이템)
  → 레벨업 → 다음 챕터 해금
```

### 핵심 특징
- **GPS 인증**: 상인 방문 및 배달 퀘스트에 실제 위치 검증 필요
- **영수증 OCR**: 거래 퀘스트에서 실제 영수증 스캔으로 거래 인증
- **Visual Novel 엔진**: 상인별 풀 시나리오 (VNNode JSON 기반)
- **오프라인 우선**: 스토리·퀘스트 데이터는 앱 번들 내 JSON으로 로컬 운영
- **사이버펑크 서울**: ChosunCentennial 폰트 + 사이버펑크 테마

---

## 세계관 요약

서울 25개 구가 각각 판타지 RPG 지역으로 재해석된 "네오 서울"이 배경.

| 권역 | 구 (5개) | 테마 |
|------|---------|------|
| 강남권 | 강남구, 서초구, 송파구, 강동구, 관악구 | 황금탑/약초/드림크리스탈/전통공예 |
| 서북권 | 종로구, 중구, 마포구, 서대문구, 용산구 | 시간의 회랑/메트로폴리스/다문화 바자회/천사 혈통/바이오테크 |
| 동북권 | 성동구, 광진구, 동대문구, 중랑구, 성북구 | 공업 크래프트/치유 산/도전 아카데미 |
| 서남권 | 영등포구, 강서구, 양천구, 구로구, 금천구 | 스팀펑크/메모리얼/아카데미/디지털 포지 |
| 동서권 | 노원구, 도봉구, 은평구, 강북구, 동작구 | 선라이즈 크래프트/히스토리 마켓/달빛 계곡 |

---

## 프로젝트 구조

```
way3/                          ← 리포지토리 루트
├── way3/                      ← iOS 앱 소스
│   ├── Core/                  ← 싱글톤 매니저 (비즈니스 로직)
│   ├── Managers/              ← 상위 오케스트레이터
│   ├── Models/                ← 데이터 구조체 + 서버 DTO
│   ├── ViewModels/            ← 화면별 뷰모델
│   ├── Views/                 ← SwiftUI 화면
│   ├── Components/            ← 사이버펑크 디자인 시스템
│   ├── Utils/                 ← 디자인 상수, 이미지 매니저
│   ├── Extensions/            ← Swift 확장
│   ├── Security/              ← Keychain 래퍼
│   ├── GameData/              ← 로컬 JSON (권위 데이터)
│   │   ├── Districts/         ← districts.json
│   │   ├── Quests/            ← main_quests.json
│   │   └── Story/             ← story_main_chapters.json + SubQuests/
│   ├── StoryData/             ← VNNode JSON (노드 단위 스토리)
│   │   ├── Prologue/          ← 74개 노드
│   │   ├── Gangnam/           ← 52개 노드
│   │   ├── Seocho/            ← 77개 노드
│   │   ├── Songpa/            ← 82개 노드
│   │   ├── Gangdong/          ← 42개 노드 (갭 존재)
│   │   └── Substories/        ← 상인별 서브스토리
│   │       ├── Seoyena/       ← 152개 (가장 완성)
│   │       ├── Alicegang/     ← 59개
│   │       ├── Anipark/       ← 66개
│   │       ├── Jinbaekho/     ← 26개
│   │       └── Jubulsu/       ← 20개
│   └── Resources/
│       ├── Merchant/          ← 상인별 이미지/JSON/영상
│       ├── images/            ← 배경 이미지
│       ├── Sound/             ← BGM/SFX
│       └── ChosunCentennial_otf.otf
│
├── claudedocs/                ← 기획/설계 문서
├── Story/                     ← 내러티브 기획 원본
│   ├── 설정집/Main.md          ← 25개 구 세계관 설정집
│   ├── CharacterStory/        ← 권역별 캐릭터 바이블
│   └── mushoku_style_notes.md ← 문체 가이드
├── connectseoul/              ← React Native 이식 프로젝트 (진행 중)
├── way3.xcodeproj
└── [Python 스크립트]           ← 스토리 데이터 빌드 도구
```

---

## 주요 시스템

### 1. 플레이어 시스템
- **레벨**: 1–100
- **스탯**: 힘/지능/매력/행운 (각 10–100)
- **스킬**: 거래/협상/감정 (각 1–10)
- **라이선스**: 초보상인(0) → 전문상인(1) → 거상(2) → 전설의 상인(3) → 마스터(4)
- **인벤토리**: 기본 5칸 (라이선스 상승 시 확장)
- **창고**: 50칸

### 2. 거래 시스템
- 상인으로부터 아이템 매입/매도
- 라이선스 요구사항 체크
- 협상 스킬에 따른 가격 조정
- 거래 기록 서버 저장

### 3. 퀘스트 시스템

**서브퀘스트 타입:**
| 타입 | 검증 방식 | 설명 |
|------|---------|------|
| `dialogue` | VNNode 완료 | 스토리 특정 노드까지 진행 |
| `delivery` | GPS 위치 도달 | 실제 장소까지 이동 |
| `trading` | GPS + 영수증 OCR | 해당 상인 방문 + 실제 구매 영수증 |

**서브퀘스트 언락 체인:**
```
서예나:  01_dialogue → 02_location → 03_trading
앨리스강: 01_walk → 02_park → 03_treats
```

**메인퀘스트:** 에피소드 완료 시 `StoryFlowManager`가 자동 생성

### 4. Visual Novel 엔진 (VNNode)

```json
{
  "node_id": "prologue_001",
  "background_image": "bg_player_room_morning",
  "character_id": "플레이어",
  "dialogue_text": "...",
  "next_node_id": "prologue_002"
}
```

노드 타입:
- `dialogue` — 대화 텍스트 + 배경 이미지
- `decision` — 선택지 분기
- `conditional` — 조건 분기 (아이템/퀘스트 상태)
- `quest_gate` — 퀘스트 게이팅

### 5. 챕터/스토리 해금 구조

```
ch0_prologue (항상 해금)
  → ch1_gangnam (레벨 1+)
    → ch2_northwest (key_item_gangnam + 레벨 5+)
      → ch3_northeast (key_item_northwest + 레벨 10+)
        → ch4_southwest (key_item_northeast + 레벨 15+)
          → ch5_eastwest (key_item_southwest + 레벨 20+)
            → ch6_final (5개 열쇠 아이템 ALL + 레벨 25+)
```

### 6. 상인 관계도 시스템

- 단계 0→4: 3→3→5→5개 서브퀘스트 클리어로 진행
- 관계도 상승 시 허가증 업그레이드 가능
- 거래 가능 아이템 등급이 라이선스에 따라 확장

---

## 상인 현황 (9명 구현됨)

| 상인 | 구역 | GPS 좌표 | 리소스 | 서브스토리 JSON |
|------|------|---------|--------|--------------|
| 서예나 (Seoyena) | 강남구 — 압구정 로데오 | 37.5279, 127.0388 | ✅ | ✅ 152노드 |
| 앨리스강 (Alicegang) | 서초구 — 서래마을 | 37.4914, 127.0032 | ✅ | ✅ 59노드 |
| 애니박 (Anipark) | 송파구 — 잠실 롯데월드 | 37.5111, 127.0982 | ✅ | ✅ 66노드 |
| 진백호 (Jinbaekho) | 강동구 — 천호동 | 37.5402, 127.1236 | ✅ | ⚠️ 26노드 |
| 주블수 (Jubulsu) | 강동구 — 천호동 | 37.5407, 127.1241 | ✅ | ⚠️ 20노드 |
| 김세휘 (Kimsehwui) | 관악구 — 서울대 | 37.4603, 126.9517 | ✅ | ❌ 미작성 |
| 기주리 (Kijuri) | 종로구 — 경복궁 | 37.5759, 126.9768 | ✅ | ❌ 미작성 |
| 카타리나 최 (Catarinachoi) | 중구 — 명동성당 | 37.5636, 126.9868 | ✅ | ❌ 미작성 |
| 마리 (Mari) | 마포구 — 홍대 | 37.5487, 126.9220 | ✅ | ❌ 미작성 |

---

## 서버 아키텍처

**기술 스택**: Node.js 18+ / Express.js / SQLite3 / JWT / Socket.IO
**배포**: Railway.app (`https://way3-production.up.railway.app`)

### 주요 API 엔드포인트

```
/api/auth
  POST /login          — 로그인 (JWT 발급)
  POST /register       — 회원가입
  POST /refresh        — 토큰 갱신
  POST /logout         — 로그아웃
  POST /password/reset/request  — 비밀번호 재설정 요청
  POST /password/reset/verify   — 비밀번호 재설정 완료

/api/player
  GET  /profile        — 플레이어 프로필 조회
  POST /create-profile — 프로필 최초 생성
  PUT  /profile        — 프로필 수정
  PUT  /location       — 위치 업데이트

/api/merchants
  GET  /               — 전체 상인 목록
  GET  /:id            — 상인 상세
  GET  /nearby         — 근처 상인 (lat, lng, radius)
  POST /:id/relationship/progress — 서브퀘 완료 → 관계도 진행
  POST /:id/permit/upgrade        — 허가증 업그레이드
  GET  /:id/story                 — 상인 스토리 노드
  POST /:id/story/progress        — 스토리 진행 기록

/api/trade
  POST /execute        — 거래 실행
  GET  /history        — 거래 기록
  GET  /market-prices  — 시장 시세

/api/quests
  GET  /               — 퀘스트 목록
  POST /:id/start      — 퀘스트 시작
  POST /:id/complete   — 퀘스트 완료

/api/skills
  GET  /               — 스킬 목록
  POST /:id/upgrade    — 스킬 업그레이드

/api/personal-items
  GET  /               — 아이템 목록
  POST /use            — 아이템 사용
  POST /equip          — 장착
  GET  /effects        — 활성 효과 조회
```

### 데이터베이스 스키마 (SQLite)

```sql
-- 사용자
users: id, email, password_hash, created_at, is_active

-- 플레이어
players: id, user_id, name, money, level, experience,
         strength, intelligence, charisma, luck,
         trading_skill, negotiation_skill, appraisal_skill,
         current_license, max_inventory_size,
         current_lat, current_lng, total_trades, total_profit

-- 상인
merchants: id, name, title, merchant_type, personality,
           district, lat, lng, required_license, price_modifier

-- 아이템 템플릿
item_templates: id, name, category, grade, required_license,
                base_price, weight, description

-- 플레이어 아이템
player_items: id, player_id, item_template_id, quantity,
              storage_type, purchase_price, purchase_date

-- 거래 기록
trade_records: id, player_id, merchant_id, item_template_id,
               trade_type, quantity, unit_price, total_price,
               profit, experience_gained, created_at

-- 상인 관계도
merchant_relationships: id, player_id, merchant_id,
                        friendship_points, trust_level,
                        stage_progress, total_trades, total_spent

-- 관계도 퀘스트 로그
merchant_relationship_quest_log: id, player_id, merchant_id,
                                  quest_id, stage, completed_at
```

---

## 보안

### iOS 클라이언트
- `SecureStorage` (iOS Keychain): Access Token, Refresh Token, 유저 ID 저장
- HTTPS 강제 (TLS 1.2+)
- 자동 토큰 갱신 (Refresh Token 기반)

### 서버
- bcrypt (salt rounds: 10) 비밀번호 해싱
- JWT: Access Token 15분 / Refresh Token 7일
- Rate Limiting: 15분 내 100회 요청 제한 (IP 기반)
- CORS, Helmet 보안 헤더

---

## 개발 환경 설정

### iOS 클라이언트
```bash
# 요구사항
- macOS + Xcode 15+
- iOS 17.0+ SDK
- Swift 5.9+

# 실행
open way3.xcodeproj
# Team 설정 후 Cmd+R
```

### 서버
```bash
cd WAY-SERVER (또는 theway_server/)
npm install
cp .env.example .env  # 환경변수 설정

npm run migrate  # DB 테이블 생성
npm run seed     # 초기 데이터 삽입
npm run dev      # 개발 서버 (nodemon)
npm start        # 프로덕션
```

---

## 개발 현황 및 로드맵

### 완료 ✅
- 인증 시스템 (로그인, 회원가입, JWT)
- 플레이어 프로필 시스템
- Cyberpunk 테마 UI 시스템
- Mapbox 3D 맵 (상인 핀, 플레이어 Puck3D)
- 거래 시스템 (매입/매도)
- 인벤토리 + 창고 관리
- Visual Novel 엔진 (TypewriterEngine, 4가지 노드 타입)
- 스토리 데이터: 프롤로그 + 강남권 4개 구 완성 (~327 메인 노드)
- 서브스토리: 서예나 완성 (152노드), 앨리스강/애니박 부분 완성
- 9명 상인 리소스 (이미지, 배경, 대화 영상)
- 오프라인 우선 진행도 관리 (ProgressManager)
- 서버 REST API + Socket.IO 기반 구조

### 진행 중 ⏳
- 강동 스토리 노드 gap 채우기 (018–063 번호 누락)
- 퀘스트 시스템 GameData 연동 완성
- React Native 이식 (`connectseoul/`)

### 계획 📋
- 서북권 서브스토리 JSON 작성 (기주리, 카타리나 최, 마리, 김세휘)
- ch3 동북권 이후 콘텐츠 전개
- 영수증 OCR 인증 구현 (Vision framework)
- 경매 시스템 (Socket.IO 이벤트 구현)
- MainQuestDefinition 디코딩 버그 수정

### 알려진 버그 🐛
- `MainQuestDefinition.swift`: `requiredEpisodes`/`requiredSubQuests` 필드가 JSON에서 읽히지 않고 `= []`로 고정됨 — 실제 요구 조건이 무시되는 이슈
- 경매 관련 Socket.IO 이벤트(`get_auctions`, `create_auction`, `cancel_bid`) 미구현

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| `DOCUMENT_INDEX.md` | 전체 문서 네비게이션 가이드 |
| `WAY3_PROJECT_FIELD_GUIDE.md` | 런타임 아키텍처 + 코드 레벨 가이드 |
| `Game_System_Restructure_Plan.md` | GameData/StoryData 스키마 설계 |
| `REACT_NATIVE_MIGRATION_PLAN.md` | RN 이식 전략 및 진행 계획 |
| `Merchant_GPS_Coordinates.md` | 상인별 GPS 좌표 레퍼런스 |
| `Seoyena_Full_Script.md` | 서예나 풀 시나리오 |
| `status/STORY_STATUS.md` | 스토리 데이터 완성도 현황 |
| `status/QUEST_STATUS.md` | 퀘스트 데이터 현황 |

---

**버전**: 2.0.0
**최종 업데이트**: 2026-02-12
**개발자**: 김상훈
