# WAY3 게임 프로젝트 개요

**프로젝트명**: WAY3 (The Way Trading Game)
**플랫폼**: iOS (SwiftUI) + Node.js 서버
**장르**: 위치 기반 실시간 거래 시뮬레이션 RPG
**개발 상태**: 개발 진행 중
**최종 업데이트**: 2025-01-09

---

## 📖 게임 컨셉

WAY3는 서울시를 무대로 한 위치 기반 거래 시뮬레이션 게임입니다. 플레이어는 실제 GPS 위치를 기반으로 25개 구역에 분산된 상인들과 만나 거래하며, 스토리를 진행하고 캐릭터를 성장시킵니다.

### 핵심 특징
- ✅ **실제 위치 연동**: GPS 기반 상인 발견 및 거래
- ✅ **챕터 기반 스토리**: 6개 챕터(5개 지역 + 최종장)
- ✅ **Visual Novel 스타일**: 상인과의 대화 및 선택지 시스템
- ✅ **거래 시뮬레이션**: 아이템 매입/매도를 통한 수익 창출
- ✅ **캐릭터 성장**: 레벨, 스킬, 라이선스 시스템
- ✅ **로컬 우선 아키텍처**: 오프라인에서도 대부분의 기능 동작

---

## 🎯 게임 플로우

```
1. 회원가입/로그인
   ↓
2. 프로필 생성 (이름, 나이, 성별, 성격)
   ↓
3. 메인 게임 화면
   ├─ 맵 탭: 실시간 위치 기반 상인 발견
   ├─ 인벤토리 탭: 보유 아이템 관리
   ├─ 스토리 탭: 챕터 진행 및 퀘스트
   ├─ 스킬 탭: 캐릭터 능력치 관리
   └─ 프로필 탭: 플레이어 정보 및 설정
   ↓
4. 거래 및 퀘스트 완료
   ↓
5. 경험치/돈 획득 → 레벨업 → 새 지역 언락
   ↓
6. 5개 지역 완료 → 최종 챕터 진입
```

---

## 🏗 프로젝트 구조

### 클라이언트 (WAY3)
```
way3/
├── Core/                    # 핵심 시스템
│   ├── AuthManager.swift    # 인증 관리 (JWT 토큰)
│   ├── NetworkManager.swift # 서버 통신 (REST API)
│   ├── GameManager.swift    # 게임 상태 관리
│   ├── ProgressManager.swift # 진행도 관리 (로컬)
│   ├── QuestManager.swift   # 퀘스트 시스템
│   ├── DistrictManager.swift # 지역 관리
│   └── GameLogger.swift     # 로깅 시스템
│
├── Models/                  # 데이터 모델
│   ├── Player/              # 플레이어 관련
│   │   ├── PlayerCore.swift       # 기본 정보
│   │   ├── PlayerStats.swift      # 능력치
│   │   ├── PlayerInventory.swift  # 인벤토리
│   │   ├── PlayerAchievements.swift # 업적
│   │   └── PlayerDataManager.swift  # 로컬 저장
│   ├── TradeItem.swift      # 거래 아이템
│   ├── PersonalItem.swift   # 장비 아이템
│   ├── Achievement.swift    # 업적
│   └── GameEnums.swift      # 열거형
│
├── Views/                   # UI 화면
│   ├── Auth/                # 인증 (로그인, 회원가입)
│   ├── Map/                 # 맵 및 위치
│   ├── Player/              # 플레이어 (프로필, 스킬)
│   └── Components/          # 공통 컴포넌트
│
├── Components/              # 디자인 시스템
│   ├── CyberpunkComponents.swift
│   ├── Cyberpunk*Components.swift
│   ├── EnhancedFontSystem.swift
│   └── LocationTrackingButton.swift
│
├── Utils/                   # 유틸리티
│   ├── CyberpunkDesignSystem.swift
│   └── JRPGScreenManager.swift
│
├── Resources/               # 리소스 파일
│   ├── Merchant/            # 상인 데이터 (JSON)
│   ├── 3D_Models/           # 3D 모델 (GLB)
│   ├── Bgmv/                # 배경 영상
│   └── ChosunCentennial_otf.otf # 커스텀 폰트
│
├── Security/                # 보안
│   └── SecureStorage.swift  # Keychain 저장
│
└── Extensions/              # Swift 확장
    ├── Font+ChosunSystem.swift
    ├── Color+GameColors.swift
    └── CLLocationCoordinate2D+Codable.swift
```

### 서버 (WAY-SERVER)
```
WAY-SERVER/
├── src/
│   ├── app.js               # Express 앱 설정
│   ├── server.js            # 서버 진입점
│   │
│   ├── config/              # 설정
│   │   └── logger.js        # Winston 로거
│   │
│   ├── database/            # 데이터베이스
│   │   ├── DatabaseManager.js    # SQLite 관리
│   │   ├── AdminExtensions.js    # 확장 테이블
│   │   ├── migrate.js            # 마이그레이션
│   │   ├── seed.js               # 초기 데이터
│   │   ├── migrations/           # 마이그레이션 SQL
│   │   └── merchant_data/        # 상인 데이터 (JSON)
│   │
│   ├── routes/              # API 라우트
│   │   ├── api/             # 게임 API
│   │   │   ├── auth.js
│   │   │   ├── player.js
│   │   │   ├── merchants.js
│   │   │   ├── trade.js
│   │   │   ├── quests.js
│   │   │   ├── achievements.js
│   │   │   ├── skills.js
│   │   │   └── personal-items.js
│   │   ├── admin/           # 관리자 API
│   │   └── game/            # 게임 로직 API
│   │
│   ├── controllers/         # 컨트롤러
│   ├── services/            # 비즈니스 로직
│   ├── middleware/          # 미들웨어
│   ├── socket/              # Socket.IO 핸들러
│   ├── errors/              # 에러 정의
│   └── utils/               # 유틸리티
│
├── public/                  # 정적 파일
│   └── admin/               # 관리자 페이지
│
├── package.json
└── .env                     # 환경 변수
```

---

## 🎮 주요 게임 시스템

### 1. 플레이어 시스템 (`Player`)
- **기본 정보**: 이름, 레벨 (1-100), 돈, 경험치
- **스탯**: 힘, 지능, 매력, 행운 (각 10-100)
- **스킬**: 거래, 협상, 감정 (각 1-10)
- **라이선스**: 초보상인(0) → 전문상인(1) → 거상(2) → 전설의 상인(3)
- **인벤토리**: 최대 5개 (라이선스에 따라 증가)
- **창고**: 최대 50개 (별도 저장소)

### 2. 거래 시스템 (`TradeManager`)
- **매입 (Buy)**: 상인으로부터 아이템 구매
  - 라이선스 요구사항 체크
  - 자금 충분 여부 체크
  - 인벤토리 공간 체크
- **매도 (Sell)**: 보유 아이템 판매
  - 상인 매입 가격 계산
  - 수익금 즉시 지급
- **가격 변동**: 시장 상황에 따른 동적 가격
- **협상**: 플레이어 협상 스킬에 따른 가격 조정

### 3. 스토리 시스템 (`StoryView`, `VNNode`)
- **Visual Novel 형식**: 텍스트 + 선택지 + 이미지
- **VNNode 구조**: JSON 기반 스토리 노드
  - `dialogue`: 대화 (speaker, text, emotion)
  - `decision`: 선택지 (choices)
  - `quest_gate`: 퀘스트 게이팅
- **챕터 구조**:
  - 챕터 1-5: 서울 5개 지역 (강남권, 서북권, 동북권, 서남권, 동서권)
  - 챕터 6: 최종장 (5개 증표 필요)
- **서브퀘스트**: 상인별 2-3개 퀘스트
- **스토리 조각**: 퀘스트 완료 시 획득

### 4. 위치 시스템 (`LocationManager`, `DistrictManager`)
- **GPS 추적**: CoreLocation 기반 실시간 위치
- **지역 구분**: 서울시 25개 구 (각 구별 1명 상인)
  - 강남권 (5구): 강남구, 서초구, 송파구, 강동구, 관악구
  - 서북권 (5구): 종로구, 중구, 서대문구, 마포구, 용산구
  - 동북권 (5구): 성동구, 광진구, 동대문구, 중랑구, 성북구
  - 서남권 (5구): 영등포구, 강서구, 양천구, 구로구, 금천구
  - 동서권 (5구): 노원구, 도봉구, 은평구, 강북구, 동작구
- **상인 발견**: 반경 내 상인 자동 표시 (기본 500m)
- **거리 계산**: Haversine 공식 사용

### 5. 인벤토리 시스템 (`PlayerInventory`)
- **인벤토리**: 휴대 가능한 아이템 (기본 5칸)
- **창고**: 대용량 저장소 (기본 50칸)
- **아이템 등급**:
  - 일반 (Common, 0)
  - 중급 (Intermediate, 1)
  - 고급 (Advanced, 2)
  - 희귀 (Rare, 3)
  - 전설 (Legendary, 4)
- **Personal Items**: 장비 아이템 (버프 효과)
  - 소모품: 일회용 효과
  - 영구품: 영구 버프
  - 장착품: 장착 시 효과

### 6. 퀘스트 시스템 (`QuestManager`)
- **퀘스트 타입**:
  - `trading`: 영수증 OCR + GPS 위치 인증
  - `delivery`: GPS 위치 도달
  - `dialogue`: 스토리 노드 완료
- **보상**: 돈, 경험치, 스토리 조각, 관계도 상승
- **진행 상태**: 대기 → 진행 중 → 완료

---

## 🌐 서버 아키텍처

### 기술 스택
- **런타임**: Node.js 18+
- **프레임워크**: Express.js 4.18+
- **데이터베이스**: SQLite3 5.1+
- **실시간 통신**: Socket.IO 4.7+
- **인증**: JWT (jsonwebtoken 9.0+)
  - Access Token: 15분
  - Refresh Token: 7일
- **보안**:
  - bcrypt 5.1+ (비밀번호 해싱)
  - helmet 7.0+ (보안 헤더)
  - express-rate-limit 6.10+ (API 속도 제한)
- **로깅**: Winston 3.10+

### API 구조
```
/api/auth          # 인증
  POST /login      # 로그인
  POST /register   # 회원가입
  POST /refresh    # 토큰 갱신
  POST /logout     # 로그아웃
  POST /password/reset/request  # 비밀번호 재설정 요청
  POST /password/reset/verify   # 비밀번호 재설정 검증

/api/player        # 플레이어
  GET  /profile    # 프로필 조회
  POST /create-profile # 프로필 생성
  PUT  /profile    # 프로필 수정
  PUT  /location   # 위치 업데이트

/api/merchants     # 상인
  GET  /           # 상인 목록
  GET  /:id        # 상인 상세
  GET  /nearby     # 근처 상인 (쿼리: lat, lng, radius)

/api/trade         # 거래
  POST /execute    # 거래 실행
  GET  /history    # 거래 기록

/api/quests        # 퀘스트
  GET  /           # 퀘스트 목록
  POST /:id/start  # 퀘스트 시작
  POST /:id/complete # 퀘스트 완료

/api/achievements  # 업적
  GET  /           # 업적 목록
  POST /:id/claim  # 업적 보상 수령

/api/skills        # 스킬
  GET  /           # 스킬 목록
  POST /:id/upgrade # 스킬 업그레이드

/api/personal-items # Personal Items
  GET  /           # 아이템 목록
  POST /use        # 아이템 사용
  POST /equip      # 아이템 장착
  POST /unequip    # 아이템 해제
  GET  /effects    # 활성 효과 조회

/admin             # 관리자 (EJS 템플릿)
  GET  /login      # 관리자 로그인
  GET  /dashboard  # 대시보드
  POST /crud/*     # CRUD 작업
```

### Socket.IO 이벤트
```javascript
// 클라이언트 → 서버
'trade:request'      // 거래 요청
'location:update'    // 위치 업데이트
'chat:message'       // 채팅 (미구현)

// 서버 → 클라이언트
'trade:response'     // 거래 응답
'location:nearby'    // 근처 플레이어
'market:update'      // 시장 가격 업데이트
```

---

## 📊 데이터베이스 스키마

### users (사용자)
```sql
id TEXT PRIMARY KEY
email TEXT UNIQUE NOT NULL
password_hash TEXT NOT NULL
created_at DATETIME DEFAULT CURRENT_TIMESTAMP
is_active BOOLEAN DEFAULT TRUE
```

### players (플레이어)
```sql
id TEXT PRIMARY KEY
user_id TEXT NOT NULL (FK → users.id)
name TEXT NOT NULL
money INTEGER DEFAULT 50000
trust_points INTEGER DEFAULT 0
reputation INTEGER DEFAULT 0
current_license INTEGER DEFAULT 0
max_inventory_size INTEGER DEFAULT 5
level INTEGER DEFAULT 1
experience INTEGER DEFAULT 0
stat_points INTEGER DEFAULT 0
skill_points INTEGER DEFAULT 0
strength, intelligence, charisma, luck INTEGER DEFAULT 10
trading_skill, negotiation_skill, appraisal_skill INTEGER DEFAULT 1
current_lat, current_lng REAL
total_trades INTEGER DEFAULT 0
total_profit INTEGER DEFAULT 0
created_at DATETIME
last_active DATETIME
total_play_time INTEGER DEFAULT 0
```

### merchants (상인)
```sql
id TEXT PRIMARY KEY
name TEXT NOT NULL
title TEXT
merchant_type TEXT NOT NULL
personality TEXT DEFAULT 'calm'
district TEXT NOT NULL
lat, lng REAL NOT NULL
required_license INTEGER DEFAULT 0
price_modifier REAL DEFAULT 1.0
is_active BOOLEAN DEFAULT TRUE
```

### item_templates (아이템 템플릿)
```sql
id TEXT PRIMARY KEY
name TEXT NOT NULL
category TEXT NOT NULL
grade INTEGER NOT NULL
required_license INTEGER DEFAULT 0
base_price INTEGER NOT NULL
weight REAL DEFAULT 1.0
description TEXT
```

### player_items (플레이어 아이템)
```sql
id TEXT PRIMARY KEY
player_id TEXT NOT NULL (FK → players.id)
item_template_id TEXT NOT NULL (FK → item_templates.id)
quantity INTEGER DEFAULT 1
storage_type TEXT DEFAULT 'inventory'  # 'inventory' or 'storage'
purchase_price INTEGER
purchase_date DATETIME
```

### trade_records (거래 기록)
```sql
id TEXT PRIMARY KEY
player_id TEXT NOT NULL
merchant_id TEXT NOT NULL
item_template_id TEXT NOT NULL
trade_type TEXT NOT NULL  # 'buy' or 'sell'
quantity INTEGER NOT NULL
unit_price INTEGER NOT NULL
total_price INTEGER NOT NULL
profit INTEGER DEFAULT 0
experience_gained INTEGER DEFAULT 0
created_at DATETIME DEFAULT CURRENT_TIMESTAMP
```

### merchant_relationships (상인 관계도)
```sql
id TEXT PRIMARY KEY
player_id TEXT NOT NULL
merchant_id TEXT NOT NULL
friendship_points INTEGER DEFAULT 0
trust_level INTEGER DEFAULT 0
total_trades INTEGER DEFAULT 0
total_spent INTEGER DEFAULT 0
last_interaction DATETIME
UNIQUE(player_id, merchant_id)
```

---

## 🔒 보안

### 클라이언트 (iOS)
- **SecureStorage**: iOS Keychain 사용
  - 토큰 저장 (Access Token, Refresh Token)
  - 민감한 사용자 정보 저장
- **자동 토큰 갱신**: Refresh Token 기반
- **HTTPS 강제**: TLS 1.2+

### 서버 (Node.js)
- **비밀번호 해싱**: bcrypt (salt rounds: 10)
- **JWT 토큰**:
  - Access Token: 15분 유효
  - Refresh Token: 7일 유효
- **Rate Limiting**:
  - 15분 내 100회 요청 제한
  - IP 기반 제한
- **CORS**: 허용된 Origin만 접근
  - 모바일 앱 (origin 없음)
  - 로컬 네트워크 (192.168.x.x, 10.x.x.x)
- **Helmet**: 보안 헤더 자동 설정

---

## 🚀 배포 환경

### 클라이언트 (iOS)
- **개발**: Xcode Simulator (iOS 17+)
- **테스트**: TestFlight (베타)
- **프로덕션**: App Store (예정)
- **최소 버전**: iOS 17.0+
- **디바이스**: iPhone (iPad 미지원)
- **방향**: Portrait (세로 모드 고정)
- **권한**: 위치 정보 (필수), 카메라 (OCR용, 추후)

### 서버
- **플랫폼**: Railway.app
- **URL**: `https://way3-production.up.railway.app`
- **데이터베이스**: SQLite (영구 볼륨 /data)
- **환경 변수**:
  ```bash
  JWT_SECRET=your-secret-key
  JWT_REFRESH_SECRET=your-refresh-secret
  DB_PATH=./data/way_game.sqlite
  PORT=3000
  NODE_ENV=production
  ALLOWED_ORIGINS=https://example.com,http://localhost:3000
  ```

---

## 🛠 개발 환경 설정

### 클라이언트 (iOS)
```bash
# 필요 사항
- Xcode 15+
- iOS 17.0+ SDK
- Swift 5.9+

# 설정
1. Xcode에서 way3.xcodeproj 열기
2. Signing & Capabilities → Team 설정
3. Info.plist에서 API_BASE_URL 설정 (선택)
   - 기본값: http://localhost:3000 (Debug)
   - 프로덕션: https://way3-production.up.railway.app
4. Cmd+R로 빌드 및 실행
```

### 서버 (Node.js)
```bash
# 필요 사항
- Node.js 18+
- npm 9+

# 설정
cd WAY-SERVER
npm install

# 환경 변수 (.env 파일 생성)
echo "JWT_SECRET=your-secret-key" > .env
echo "JWT_REFRESH_SECRET=your-refresh-secret" >> .env
echo "DB_PATH=./data/way_game.sqlite" >> .env
echo "PORT=3000" >> .env

# 데이터베이스 초기화
npm run migrate  # 테이블 생성
npm run seed     # 초기 데이터 삽입

# 서버 시작
npm start        # 프로덕션
npm run dev      # 개발 (nodemon)
```

---

## 📝 개발 로드맵

### Phase 1: 기본 시스템 ✅ 완료
- [x] 인증 시스템 (로그인, 회원가입, 토큰 관리)
- [x] 플레이어 프로필 생성
- [x] 기본 UI/UX (Cyberpunk 테마)
- [x] 위치 기반 상인 발견
- [x] 거래 시스템 (매입/매도)
- [x] 인벤토리 관리 (인벤토리 + 창고)
- [x] 로컬 저장 시스템 (PlayerDataManager)
- [x] 서버 API 구축 (REST + Socket.IO)

### Phase 2: 스토리 시스템 ⏳ 진행 중
- [x] Visual Novel 엔진 (VNNode, StoryView)
- [x] 스토리 JSON 로더
- [x] 선택지 및 분기 시스템
- [ ] 챕터 시스템 (6개 챕터)
- [ ] 퀘스트 시스템 (서브퀘스트)
- [ ] 영수증 OCR 인증
- [ ] GPS 위치 인증
- [ ] 진행도 관리 (ProgressManager)

### Phase 3: 게임 콘텐츠 📋 계획
- [ ] 25개 구역 상인 데이터 완성
- [ ] 메인 스토리 작성 (챕터 1-6)
- [ ] 서브퀘스트 작성 (상인별 2-3개)
- [ ] Personal Items 시스템 (장비 효과)
- [ ] 업적 시스템 (50+ 업적)
- [ ] 스킬 트리 (스킬 업그레이드)

### Phase 4: 소셜 기능 🔮 미정
- [ ] 채팅 시스템 (플레이어 간 채팅)
- [ ] 거래소 (플레이어 간 거래)
- [ ] 길드 시스템 (협동 퀘스트)
- [ ] 랭킹 시스템 (레벨, 수익, 거래량)

---

## 👥 팀 및 연락처

- **프로젝트 리드**: 김상훈
- **개발**:
  - iOS 클라이언트 (SwiftUI)
  - Node.js 서버 (Express + SQLite)
- **스토리 기획**: 메인 스토리 및 서브퀘스트
- **디자인**: Cyberpunk/JRPG 테마

---

## 📚 관련 문서

| 문서 | 설명 |
|------|------|
| [01_ARCHITECTURE.md](./01_ARCHITECTURE.md) | 시스템 아키텍처 및 설계 패턴 |
| [02_PLAYER_SYSTEM.md](./02_PLAYER_SYSTEM.md) | 플레이어 모델 및 컴포넌트 |
| [03_GAME_FEATURES.md](./03_GAME_FEATURES.md) | 게임 기능 (거래, 퀘스트, 업적) |
| [04_NETWORK_REALTIME.md](./04_NETWORK_REALTIME.md) | 네트워크 및 실시간 통신 |
| [05_UI_DESIGN_SYSTEM.md](./05_UI_DESIGN_SYSTEM.md) | UI 디자인 시스템 및 컴포넌트 |
| [06_DATA_MODELS.md](./06_DATA_MODELS.md) | 데이터 모델 및 구조체 |
| [07_DEVELOPER_GUIDE.md](./07_DEVELOPER_GUIDE.md) | 개발자 가이드 및 빌드 설정 |
| [08_SERVER_ARCHITECTURE.md](./08_SERVER_ARCHITECTURE.md) | 서버 아키텍처 및 구조 |
| [09_SERVER_API_REFERENCE.md](./09_SERVER_API_REFERENCE.md) | 서버 API 레퍼런스 |
| [Game_System_Restructure_Plan.md](./Game_System_Restructure_Plan.md) | 게임 시스템 재구조화 계획 (보존) |

---

**버전**: 1.0.0
**마지막 수정**: 2025-01-09
**문서 작성**: Claude Code
**라이선스**: MIT
