# connect:seoul (구 WAY3)

> **네오 서울을 무대로 한 GPS 기반 위치 인증 트레이딩 RPG + Visual Novel**
> iOS SwiftUI · Swift 5.9 · iOS 17+

---

## 프로젝트 개요

connect:seoul은 실제 서울시 25개 구를 무대로 플레이어가 직접 현장에 방문하여 상인 NPC와 거래·퀘스트·스토리를 즐기는 게임입니다. 조선사이버펑크 세계관("네오 서울")을 배경으로, Visual Novel 형식의 서브스토리와 AI 자유대화(Gemini 기반)를 결합한 독자적인 경험을 제공합니다.

### 핵심 루프
```
실제 위치 이동 → GPS 인증 → 상인 발견 → 아이템 거래
 → 서브퀘스트 → VN 스토리 진행 → AI 자유대화 → 보상 → 레벨업
```

---

## 요구 사항

| 항목 | 버전 |
|------|------|
| macOS | 14 Sonoma 이상 |
| Xcode | 15.0 이상 |
| iOS 타깃 | 17.0 이상 |
| Swift | 5.9 |
| Node.js (서버) | 18.0 이상 |
| Docker | 선택 사항 (서버 컨테이너 실행 시) |

---

## 빠른 시작

### 1. iOS 앱 실행
```bash
open way3.xcodeproj
# Xcode → iPhone 15 시뮬레이터 → Cmd+R
```

CLI 빌드:
```bash
xcodebuild -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### 2. 서버 실행 (Docker)

서버는 별도 저장소 `way-server`에 있습니다.

```bash
cd /path/to/way-server

# .env 설정 (최초 1회)
cp .env.example .env   # 없으면 직접 생성
# GEMINI_API_KEY, JWT_SECRET 등 필수값 입력

# 빌드 및 실행
docker compose up --build -d

# 상태 확인
docker compose ps
curl http://localhost:3000/health
```

### 3. iOS 앱 ↔ 서버 연결

로컬 서버 사용 시 `way3/Info.plist`에서:
```xml
<key>API_BASE_URL</key>
<string>http://localhost:3000</string>
```

> 실기기 테스트 시 Mac의 로컬 IP 주소로 변경 (예: `http://192.168.1.x:3000`)

---

## 디렉터리 구조

```
way3/                          ← iOS 앱 소스
├── way3App.swift              — 앱 진입점 / 환경 객체 등록
├── ContentView.swift          — 인증 상태 라우팅
├── Core/                      — 핵심 싱글톤 매니저
│   ├── AuthManager.swift          JWT 인증 / 회원가입
│   ├── NetworkManager.swift       REST 클라이언트 / 토큰 재발급
│   ├── ProgressManager.swift      오프라인 진행도 (챕터/퀘스트)
│   ├── QuestManager.swift         퀘스트 실행 엔진
│   ├── StoryCore.swift            VN 엔진 (VNNode, TypewriterEngine)
│   ├── TradeManager.swift         거래 로직
│   └── LocationVerifier.swift     GPS 위치 검증
├── Managers/                  — 상위 오케스트레이터
│   ├── GameManager.swift          중앙 게임 상태 허브
│   └── StoryFlowManager.swift     에피소드 완료 파이프라인
├── Models/                    — 데이터 구조체 + 서버 DTO
├── ViewModels/                — View ↔ Core 상태 바인딩
├── Views/                     — SwiftUI 화면
│   ├── Auth/                      로그인·회원가입·비밀번호 재설정
│   ├── Game/MainTabView.swift     메인 탭 네비게이션 (5탭)
│   ├── Map/                       Mapbox 3D 지도
│   ├── Merchant/                  상인 상세 / AI 채팅
│   ├── Story/                     스토리 허브 / 챕터 상세
│   ├── Quest/                     퀘스트 목록 / 상세
│   ├── Profile/                   플레이어 프로필
│   ├── Shop/                      상점 (stub — 구현 예정)
│   └── Components/                공통 UI 컴포넌트
├── Components/                — 조선사이버펑크 디자인 시스템
├── Utils/CyberpunkDesignSystem.swift — 색상·타이포 상수
├── GameData/                  — 로컬 JSON (권위 데이터)
│   ├── districts.json             25개 구 정보
│   ├── main_quests.json           메인 퀘스트
│   └── story_main_chapters.json   챕터 구조
├── StoryData/                 — VNNode JSON (329개 파일)
│   ├── prologue.json / gangnam.json / seocho.json ...
│   └── Substories/                상인별 서브스토리
└── Resources/                 — 폰트·이미지·영상·사운드

claudedocs/                    ← 기술 문서
Story/                         ← 시나리오 원본 (기획용)
way3Tests/                     ← 단위 테스트
way3UITests/                   ← UI 테스트
```

---

## 아키텍처

```
View ──→ ViewModel ──→ Manager/Core ──→ JSON / REST API
 ↑                          │
 └──── @Published ──────────┘
         (Combine)
```

- **오프라인 우선**: 스토리·퀘스트·지역 데이터는 앱 번들 JSON으로 로컬 운영
- **MVVM + Combine**: `@Published` / `ObservableObject` 패턴
- **싱글톤 매니저**: 루트(`way3App`)에서 `@StateObject`로 전체 주입
- **보안**: `SecureStorage` (Keychain) — Access/Refresh Token, User ID

---

## 디자인 시스템 — 조선사이버펑크

### 오방색 네온 팔레트
| 상수 | 의미 | 용도 |
|------|------|------|
| `.joseonCheong` | 청(靑) | 정보·상태 |
| `.joseonJeok` | 적(赤) | 위험·강조 |
| `.joseonHwang` | 황(黃) | 보상·골드 |
| `.joseonBaek` | 백(白) | 텍스트 |
| `.joseonHeuk` | 흑(黑) | 배경 |

> `Color(hex:)` 사용 금지 → `Color(red:green:blue:)` 또는 정의된 상수 사용

### 폰트 규칙
| 용도 | 폰트 | 상수 |
|------|------|------|
| 타이틀·헤딩·버튼 | ChosunCentennial | `.chosunH1~H3`, `.chosunTitle`, `.chosunButton` |
| 바디·캡션·기술 | Pretendard | `.cyberpunkBody()`, `.cyberpunkCaption()`, `.cyberpunkTechnical()` |

시스템 폰트(`.title2`, `.body` 등) 직접 사용 금지.

---

## 스토리 데이터 현황

| 챕터 | 상태 |
|------|------|
| 프롤로그 | ✅ 완성 |
| 강남 | ✅ 완성 |
| 서초 | ✅ 완성 |
| 송파 | ✅ 완성 |
| 강동 | ⚠️ 일부 노드 누락 |
| 서북권 이후 | ❌ 미구현 |

**서브스토리**: 서예나(152) · 앨리스강(59) · 애니박(66) · 진백호(26) · 주블수(20)

---

## 상인 9명

| 상인 | 구역 | 서브스토리 |
|------|------|-----------|
| 서예나 | 강남구 압구정 | ✅ |
| 앨리스강 | 서초구 서래마을 | ✅ |
| 애니박 | 송파구 잠실 | ✅ |
| 진백호 | 강동구 천호동 | ⚠️ 부분 |
| 주블수 | 강동구 천호동 | ⚠️ 부분 |
| 김세휘 | 관악구 서울대 | ❌ |
| 기주리 | 종로구 경복궁 | ❌ |
| 카타리나 최 | 중구 명동성당 | ❌ |
| 마리 | 마포구 홍대 | ❌ |

---

## 알려진 버그 및 미구현

| 우선순위 | 위치 | 내용 |
|---------|------|------|
| 🔴 | `Info.plist` | `API_BASE_URL`이 비활성 Railway URL → 네트워크 전체 실패 (로컬로 변경 필요) |
| 🔴 | `Models/MainQuestDefinition.swift` | `requiredEpisodes`·`requiredSubQuests` 항상 `[]` 고정 |
| 🟡 | `Views/Shop/ShopView.swift` | stub 상태 — 구현 예정 |
| 🟡 | `Core/TradeManager.swift` | 서버 미연결 시 임시 시뮬레이션 코드 |
| 🟡 | `StoryData/gangdong.json` | 일부 노드 번호 누락 |

---

## 서버 API 엔드포인트

| 엔드포인트 | 용도 |
|-----------|------|
| `GET /health` | 서버 상태 확인 |
| `POST /api/auth/login` | JWT 로그인 |
| `POST /api/auth/register` | 회원가입 |
| `POST /api/auth/refresh` | 토큰 갱신 |
| `GET /api/player/profile` | 플레이어 정보 |
| `PUT /api/player/location` | GPS 위치 업데이트 |
| `GET /api/merchants` | 주변 상인 조회 |
| `POST /api/trade/buy` / `sell` | 거래 |
| `GET /api/quests` | 퀘스트 목록 |

---

## 테스트

```bash
xcodebuild test -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 문서

| 파일 | 내용 |
|------|------|
| `CLAUDE.md` | AI 에이전트용 프로젝트 레퍼런스 |
| `AGENTS.md` | 코드베이스 구조 가이드 |
| `claudedocs/01_PROJECT_OVERVIEW.md` | 게임 컨셉·API·DB 스키마 |
| `claudedocs/02_FIELD_GUIDE.md` | iOS 코드 구조·데이터 흐름 |
| `claudedocs/04_UI_SYSTEM.md` | 조선사이버펑크 디자인 시스템 |
| `claudedocs/05_AI_CHAT_SYSTEM.md` | AI 상인 채팅 시스템 |

---

*connect:seoul — 서울의 모든 골목이 던전이다*
