# WAY3 프로젝트 문서

이 디렉토리는 WAY3 게임 프로젝트의 공식 문서를 포함하고 있습니다.

## 📚 문서 목록

### 주요 문서
- **[00_PROJECT_OVERVIEW.md](./00_PROJECT_OVERVIEW.md)** - 프로젝트 전체 개요
  - 게임 컨셉 및 핵심 특징
  - 프로젝트 구조 (클라이언트 + 서버)
  - 주요 게임 시스템 설명
  - 데이터베이스 스키마
  - 보안 및 배포 환경
  - 개발 로드맵

- **[Game_System_Restructure_Plan.md](./Game_System_Restructure_Plan.md)** - 게임 시스템 재구조화 계획
  - 로컬 우선 아키텍처 설계
  - 챕터 기반 스토리 시스템
  - 퀘스트 및 진행도 관리
  - 위치 인증 시스템 (GPS, OCR)
  - 구현 단계별 계획

---

## 🚀 빠른 시작

### 클라이언트 (iOS)
```bash
# Xcode에서 프로젝트 열기
open way3.xcodeproj

# 또는
1. Xcode 실행
2. way3.xcodeproj 열기
3. Cmd+R로 빌드 및 실행
```

### 서버 (Node.js)
```bash
cd WAY-SERVER
npm install
npm run migrate  # DB 초기화
npm run seed     # 초기 데이터
npm start        # 서버 시작
```

---

## 📖 문서 읽는 순서

프로젝트를 처음 접하는 경우 다음 순서로 문서를 읽는 것을 권장합니다:

1. **00_PROJECT_OVERVIEW.md** (필수)
   - 프로젝트 전체 구조 파악
   - 게임 시스템 이해
   - 기술 스택 확인

2. **Game_System_Restructure_Plan.md** (선택)
   - 향후 구현 계획 확인
   - 로컬 우선 아키텍처 이해
   - Phase별 개발 로드맵

---

## 🏗 프로젝트 구조

```
프로젝트 루트/
├── WAY3/              # iOS 클라이언트
│   ├── way3/          # SwiftUI 소스 코드
│   └── claudedocs/    # 📍 이 디렉토리
│
└── WAY-SERVER/        # Node.js 서버
    └── src/           # 서버 소스 코드
```

---

## 🎮 게임 개요

**WAY3 (The Way Trading Game)**는 서울시를 무대로 한 위치 기반 거래 시뮬레이션 게임입니다.

### 핵심 특징
- 🗺 **위치 기반 게임플레이**: GPS를 활용한 상인 발견
- 📖 **스토리 중심**: 6개 챕터의 메인 스토리
- 💰 **거래 시뮬레이션**: 아이템 매입/매도로 수익 창출
- 🎭 **Visual Novel**: 텍스트 기반 대화 및 선택지
- 📈 **캐릭터 성장**: 레벨, 스킬, 라이선스 시스템

### 게임 플로우
```
로그인 → 프로필 생성 → 맵에서 상인 발견 → 거래 →
퀘스트 완료 → 경험치 획득 → 레벨업 → 새 지역 언락
```

---

## 🛠 기술 스택

### 클라이언트 (iOS)
- **언어**: Swift 5.9+
- **프레임워크**: SwiftUI
- **최소 버전**: iOS 17.0+
- **주요 기능**: GPS, Keychain, UserDefaults

### 서버 (Node.js)
- **런타임**: Node.js 18+
- **프레임워크**: Express.js 4.18+
- **데이터베이스**: SQLite3 5.1+
- **실시간 통신**: Socket.IO 4.7+
- **인증**: JWT (Access + Refresh Token)

---

## 📊 주요 시스템

### 1. 플레이어 시스템
- 레벨, 경험치, 돈, 스탯
- 스킬 (거래, 협상, 감정)
- 라이선스 (초보상인 → 전설의 상인)
- 인벤토리 (5칸) + 창고 (50칸)

### 2. 거래 시스템
- 매입: 상인으로부터 아이템 구매
- 매도: 보유 아이템 판매
- 동적 가격 변동
- 협상 시스템 (스킬 기반)

### 3. 스토리 시스템
- Visual Novel 형식
- JSON 기반 스토리 노드
- 선택지 및 분기
- 챕터 진행 (6개 챕터)

### 4. 위치 시스템
- GPS 기반 실시간 추적
- 서울시 25개 구역
- 상인 발견 (반경 500m)
- Haversine 거리 계산

### 5. 퀘스트 시스템
- 거래 퀘스트 (영수증 OCR)
- 배달 퀘스트 (GPS 인증)
- 대화 퀘스트 (스토리 완료)

---

## 🔒 보안

### 클라이언트
- iOS Keychain (토큰 저장)
- SecureStorage 클래스
- HTTPS 통신

### 서버
- bcrypt 비밀번호 해싱
- JWT 토큰 (Access 15분, Refresh 7일)
- Rate Limiting (15분/100회)
- CORS 설정
- Helmet 보안 헤더

---

## 🚀 배포

### 개발 환경
- **클라이언트**: Xcode Simulator
- **서버**: localhost:3000

### 프로덕션
- **클라이언트**: App Store (예정)
- **서버**: Railway.app
  - URL: https://way3-production.up.railway.app
  - DB: SQLite (영구 볼륨)

---

## 📝 개발 로드맵

### Phase 1: 기본 시스템 ✅
- 인증, 프로필, UI/UX
- 위치 기반 상인 발견
- 거래 시스템
- 인벤토리 관리

### Phase 2: 스토리 시스템 ⏳
- Visual Novel 엔진
- 챕터 시스템
- 퀘스트 시스템
- 위치 인증 (GPS, OCR)

### Phase 3: 게임 콘텐츠 📋
- 25개 구역 상인 데이터
- 메인 스토리 (챕터 1-6)
- 서브퀘스트 (상인별 2-3개)
- Personal Items
- 업적 시스템

### Phase 4: 소셜 기능 🔮
- 채팅
- 거래소
- 길드
- 랭킹

---

## 👥 기여 및 연락처

- **프로젝트 리드**: 김상훈
- **개발**: iOS (SwiftUI) + Node.js (Express)
- **스토리**: 메인 및 서브 스토리 기획
- **디자인**: Cyberpunk/JRPG 테마

---

## 📌 중요 링크

- [WAY3 GitHub Repository](https://github.com/yourusername/WAY3)
- [WAY-SERVER GitHub Repository](https://github.com/yourusername/WAY-SERVER)
- [Railway 배포 서버](https://way3-production.up.railway.app)

---

**문서 버전**: 1.0.0
**최종 업데이트**: 2025-01-09
**작성자**: Claude Code
**라이선스**: MIT
