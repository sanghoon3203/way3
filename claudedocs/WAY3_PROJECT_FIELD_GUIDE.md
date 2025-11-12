# WAY3 Project Field Guide

서울 전역을 무대로 한 위치 기반 트레이딩 RPG **WAY3**의 현재 상태를 빠르게 파악하고, 다음 모델/개발자가 즉시 투입될 수 있도록 정리한 해설 문서입니다. SwiftUI 클라이언트를 React Native로 이식할 때 거쳐야 할 체크포인트도 함께 포함되어 있습니다.

---

## 1. Game Identity & Pillars
- **장르**: GPS + 실시간 트레이딩 RPG. 포켓몬고식 맵 위에서 상인과 교역하고, 스토리·퀘스트·경매를 진행.
- **핵심 루프**: 위치 인증 → 상인 탐색/거래 → 재화/호감도/스토리 진척 → 메인/서브 퀘스트 완료 → 보상/인벤토리 관리.
- **콘텐츠 소스**: 로컬 JSON(`GameData/`, `StoryData/`) 선로드 후 서버(`API_BASE_URL`, Socket.IO) 동기화. 오프라인 우선 구조.
- **미학**: 사이버펑크 + 서울. `Components/` 폴더의 커스텀 UI와 `Resources/Background`, `Sound` 자산이 톤앤매너를 정의.

---

## 2. Quick Facts
- **클라이언트 스택**: Swift 5.9, SwiftUI, Combine, MapboxMaps (3D puck), Socket.IO, CoreLocation, SecureStorage.
- **상태 관리**: `@StateObject` + 싱글톤 매니저(`GameManager`, `AuthManager`, `ProgressManager`, 등).
- **로컬 저장소**: `PlayerDataManager`가 JSON 캐시/백업, `SecureStorage`가 토큰·ID 보관.
- **서버 기대치**: Node.js 18+ 기반 `way-server`(또는 `theway_server/`)를 `start_server.sh`로 기동, REST + Socket.IO 제공.

---

## 3. Repository Layout

| Path | 설명 |
| --- | --- |
| `way3/way3App.swift`, `ContentView.swift` | 앱 엔트리. 환경 객체 등록 및 생명주기 저장/로드. |
| `way3/Core/` | 인증/네트워크/스토리/거래/경매 등 핵심 로직 매니저 (`AuthManager`, `NetworkManager`, `QuestManager`, `AuctionManager`, `SocketManager`, etc.). |
| `way3/Managers/` | 상위 오케스트레이터 (`GameManager`, `StoryFlowManager`, `StoryRewardService`). |
| `way3/Models/` | Player, Merchant, TradeItem, Quest, PersonalItem 등 게임 데이터 구조 + 서버 응답 매핑. |
| `way3/ViewModels/` | 현재는 `StoryViewModel`, `MerchantDetailViewModel` 등 일부 화면-로직 바인딩. |
| `way3/Views/` | 탭별 SwiftUI 화면 (Map, Inventory, Quest, Story, Profile, Auth, Auction, Trade 등). |
| `way3/Components/`, `Utils/`, `Extensions/` | 사이버펑크 UI 컴포넌트, 공통 디자인 시스템, 폰트/이미지 관리. |
| `way3/GameData/`, `StoryData/` | 챕터/퀘스트/스토리 JSON 및 지역별 시나리오 노드. 오프라인 우선 컨텐츠. |
| `way3/Resources/`, `Assets.xcassets/` | 3D GLB, 배경, 폰트(`ChosunCentennial`), 사운드, 상인 이미지, 로고. |
| `way3Tests/`, `way3UITests/` | XCTest 타깃. 현재 샘플/스텁 형태, but CI 대비 구조 유지. |
| `Story/` | 내러티브 기획 원본 문서. |
| `claudedocs/` | 기능별 심화 문서 (전체 개요, 함수 스펙, GPS 좌표, 구현 보고서 등). |
| `start_server.sh` | 루트에서 서버 (`theway_server/`)를 부팅하는 스크립트. **주의**: 현재 리포에 서버 폴더가 없으므로 외부 동기화 필요. |

---

## 4. Runtime Architecture Snapshot

### 4.1 App Entry & Environment
- `way3App`가 `NetworkManager.shared`, `LocationManager.shared`, `GameManager.shared`, `AuthManager.shared`, `ProgressManager.shared`, `QuestManager.shared`를 `environmentObject`로 주입.
- `ContentView`는 `StartView → LoginView → MainTabView` 순으로 전환하며, `PlayerDataManager`를 통해 로컬 세이브를 자동 복원/저장.
- `ScenePhase` 감시로 백그라운드 전환 시 저장, 폰트 로딩 검증(`FontSystemManager.validateChosunFont()`).

### 4.2 Manager Layer (주요 싱글톤)
- `AuthManager`: SecureStorage + UserDefaults 하이브리드. JWT 로그인/회원가입/패스워드 리셋, `NetworkManager`에 토큰 주입.
- `NetworkManager`: API Base URL 결정, 토큰 관리, 공통 요청/재시도/캐싱, `NetworkError` → 사용자 메시지 매핑.
- `GameManager`: 중앙 상태 허브. 플레이어, 탭, 알림, 인벤토리/프로필 뷰 상태, 타이머 루프, 위치 업데이트.
- `LocationManager`: CoreLocation delegate, 10m 필터, `GameLogger`로 상태 로깅.
- `ProgressManager`: JSON 기반 챕터/에피소드/퀘스트 잠금 해제 관리.
- `QuestManager`: 메인/서브 퀘스트 큐 관리, 완료 처리, 보상 지급.
- `StoryFlowManager`: 에피소드 완료 → 다음 에피소드 언락, 메인 퀘스트 생성, 챕터 보상 `RewardProcessor` 호출.
- `TradeManager`, `AuctionManager`, `MerchantDataManager`, `DialogueDataManager`: 각각 거래/경매/상인/스토리 대화 데이터 로더.
- `SocketManager`: Socket.IO 연결, 재접속, 근처 플레이어/가격 변동/트레이드 오퍼 스트림 관리.
- `PlayerDataManager`: 플레이어 JSON 저장, 자동 백업, 버전링.
- `GameLogger`: os.Logger 기반 카테고리 로깅(`.system`, `.gameplay`, `.authentication`, `.socket`...).

### 4.3 Data / Security
- 모델 폴더는 Swift struct + 서버 응답 매퍼(`ServerMerchantResponse` 등). `LicenseLevel`, `ItemGrade`, `MerchantType` 등 enum이 뷰 색상/아이콘 결정.
- `SecureStorage` (Security.framework + Keychain)로 토큰, 유저/플레이어 ID 저장. 폴백으로 UserDefaults 사용.
- `Info.plist`의 `API_BASE_URL` + 환경변수 → `NetworkConfiguration.baseURL`.

### 4.4 UI Layer
- `Views/Game/MainTabView.swift`: `CyberpunkEnhancedTabView` wrapping `TabView`. 탭 순서 = Map / Inventory / Quest / Story / Profile.
- Map 탭은 `MapboxMaps`의 `Map` + `Puck3D`, 상인 어노테이션 (`OptimizedMerchantPinView`), `MerchantDetailView` 풀스크린 커버.
- 나머지 탭은 각 `Views/*` 폴더 (예: `Views/Quest/QuestCenterView.swift`, `Views/Story/StoryHubTabView.swift`)와 `Components/`의 사이버펑크 카드/버튼/오버레이 조합.
- `ViewModels`는 복잡한 화면만 별도로 보유 (`MerchantDetailViewModel`, `StoryViewModel`).

---

## 5. Gameplay System Notes

### 5.1 인증 & 플레이어 라이프사이클
- 로그인 성공 시 `AuthData` → SecureStorage. `AuthManager`가 `NetworkManager.applyAuthTokens` 호출.
- `ContentView`는 인증 상태를 감시하여 `Player.load()`로 로컬 코어 데이터를 복구하고 `Player.startAutoSave()` 호출.
- `Player` struct는 `core`, `stats`, `inventory`, `relationships`, `achievements`, 위치/진행도 등 세분화된 서브-struct로 구성.

### 5.2 위치 + 맵
- `LocationManager`가 실시간 위치 업데이트 → `GameManager.currentLocation`.
- `MapView`는 서울 중심 좌표를 기본으로 하고, 위치 변화 시 Mapbox Viewport를 애니메이션으로 갱신. 10km 이상 이동 시 서버에 상인 재요청.
- 상인 정보는 `NetworkManager.getNearbyMerchants` + `MerchantDataManager` 로컬 캐시 조합. 거래 가능 여부(`withinTradeDistance`, `meetsRequirements`) 표시.

### 5.3 상인 & 거래
- `Merchant` 모델은 라이선스 요구, 선호/비선호 아이템, 평판, 거래 거리, 스토리 연동 필드(`storyRole`, `initialStoryNode`)까지 포함.
- `TradeManager`가 아이템 가격, 흥정 성공 여부, 재고 업데이트를 담당. `MerchantDetailView`에선 `MerchantDetailViewModel`로 상호작용.

### 5.4 인벤토리 & 개인 아이템
- `GameManager`가 `personalItems`, `activeEffects`, `permanentEffects` 상태를 보유하며, `loadPersonalItemsData()`로 서버/로컬 동기화.
- `Components/CyberpunkInventoryComponents.swift`가 UI/필터/정렬 제공. 아이템 상세는 `ItemDetailView`.

### 5.5 퀘스트 & 스토리
- `GameData/Chapters/chapters.json` + `StoryData/<region>/<episode>.json`이 메인 스토리 구조를 정의.
- `StoryFlowManager` + `ProgressManager` + `QuestManager`가 에피소드 완료 시 다음 에피소드 언락 → 메인 퀘스트 생성 → 보상 지급.
- `StoryHubTabView`는 `StoryViewModel`을 사용해 진행도, 보상, 서브스토리 등을 보여줌.

### 5.6 경매 & 실시간 요소
- `AuctionManager`와 `SocketManager`가 Socket.IO 이벤트를 구독. 현재 `get_auctions`, `create_auction`, `cancel_bid`는 TODO 상태.
- `SocketManager`는 근처 플레이어, 실시간 거래 활동, 가격 변동, 트레이드 오퍼를 `@Published`로 송출. Map/Trade/Story UI에서 소비 가능.

### 5.7 오디오/3D/연출
- `Resources/3D_Models`의 GLB가 Map 3D 플레이어 모델을 정의. 배경 영상/사운드 (`Resources/Bgmv`, `Sound`)를 각 뷰에서 활용.
- 커스텀 폰트(`ChosunCentennial_otf.otf`)는 `defaultChosunFont()`로 글로벌 적용.

---

## 6. Content & Data Sources
- **GameData**: `Chapters/`, `Districts/`, `Quests/`, `Story/`. JSON 스키마는 `claudedocs/Game_System_Restructure_Plan.md` 참고.
- **StoryData**: 지역/챕터별 JSON 노드 (`Prologue`, `Gangnam`, `Seocho`, etc.) + `Substories/`.
- **Resources**:
  - `3D_Models/` + `3D_Models_Guide.md`
  - `Background/`, `Bgmv/`, `Sound/`, `Merchant/` 이미지
  - `Story/` 폴더에 시나리오 원고
- **문서**: `claudedocs/00_PROJECT_OVERVIEW.md`, `way3_function_specifications.md`, 각 시스템 구현 보고서.

---

## 7. Build / Run / Test Flow
1. **필수 도구**: macOS + Xcode 15+, iOS 17 시뮬레이터, Node.js 18+ (서버).
2. **클라이언트 실행**: `open way3.xcodeproj` 혹은 `xed .` → Scheme `way3` → `Cmd+R`. CLI 빌드 시 `xcodebuild -scheme way3 -destination 'platform=iOS Simulator,name=iPhone 15' build`.
3. **서버**: `start_server.sh`는 `theway_server/` 내 `npm install`, `.env` 체크, `npm run dev` 호출. 현재 리포엔 서버 폴더가 없으므로 별도 복제 필요.
4. **테스트**: `Cmd+U` 또는 `xcodebuild test -scheme way3 -destination 'platform=iOS Simulator,name=iPhone 15'`. 테스트는 대부분 목/스텁 구조이므로 새로운 기능 시 케이스 추가 필수.
5. **데이터 리프레시**: `GameData/`·`StoryData/` JSON 수정 후 앱 재실행. `ProgressManager`가 캐시를 다시 읽음.

---

## 8. Known Gaps & TODO Radar
- `theway_server/` 소스가 현재 리포에 없음 → 서버 변경 시 별도 저장소/브랜치 확인 필요.
- `AuctionManager`와 `SocketManager` 사이의 `get_auctions`, `create_auction`, `cancel_bid` 이벤트 미구현.
- `Story`/`Quest` 일부 뷰는 모형 데이터 사용 (`MockQuestData`) → 실제 API 연동 시 DTO 정리 필요.
- `Story` 에셋(영상/사운드)은 용량 큼. Git LFS/외부 스토리지 전략 필요.
- `MapboxMaps`가 `@_spi(Experimental)` import 사용 → SDK 업데이트 시 빌드 이슈 가능.
- `PlayerDataManager` 백업 경로/암호화 전략 점검 (현재는 FileManager 로컬 디렉터리 기반).

---

## 9. React Native Migration Radar

### 9.1 추천 스택 & 매핑
- **언어/런타임**: React Native (TypeScript, Hermes), Expo Router or RN CLI.
- **상태 관리**: Zustand/Recoil/Redux Toolkit → `GameManager`, `AuthManager`, `ProgressManager` 싱글톤을 RN store로 매핑.
- **네트워크**: `react-query`(TanStack Query) + custom fetch wrapper → `NetworkManager`.
- **보안 스토리지**: `react-native-keychain` or `expo-secure-store` → `SecureStorage`.
- **위치/GPS**: `react-native-geolocation-service` + `react-native-permissions`, 혹은 Expo Location → `LocationManager`.
- **지도**: `@rnmapbox/maps` (Mapbox GL RN)로 3D puck/경로 구현. 대안으로 `react-native-maps` + 커스텀 3D는 난이도 ↑.
- **소켓**: `socket.io-client` (TS) → `SocketManager`.
- **로컬 데이터**: JSON은 Metro asset bundle에 포함 → `expo-file-system`/`react-native-fs`로 캐시. 대규모 데이터는 SQLite/WatermelonDB 고려.
- **UI**: RN Animated/Reanimated + Tailwind(Dripsy) or Styled Components로 `Components/Cyberpunk*` 스타일 재현. 폰트(`ChosunCentennial`)는 `.ttf` 변환 필요.
- **3D/효과**: Mapbox 3D puck, Lottie, 혹은 Expo GL + three.js로 GLB 로딩 검토.

### 9.2 제안 마이그레이션 순서
1. **데이터 계약 확정**: Swift 모델 ↔ TypeScript type 정의. `claudedocs/way3_function_specifications.md`와 JSON 스키마 기반으로 DTO 문서화.
2. **서비스 계층 포팅**: RN 프로젝트에서 `api/`, `storage/`, `sockets/`, `location/` 모듈 작성. Swift 매니저 메서드를 1:1 대응시키면 이후 UI 작업이 단순화.
3. **상태/스토어 구성**: `useGameStore`, `useAuthStore`, `useQuestStore` 등 훅 정의 → Swift `@Published` 필드와 동일한 shape 유지.
4. **공통 UI/테마 이식**: 사이버펑크 컬러, 카드, 탭을 RN 컴포넌트로 재현. RN에서 Map 탭, Quest/Story 탭 등을 Skeleton 상태로 우선 구축.
5. **플랫폼 기능 래핑**: 위치 권한, 맵, 소켓, Secure Storage를 RN Native Module/패키지와 연결. iOS/Android 권한 flow 문서화.
6. **콘텐츠 자산 포팅**: JSON, 이미지, 사운드, GLB를 `/assets`에 배치하고 Metro에 등록. 용량 큰 파일은 CDN/Cloud Storage 고려.
7. **테스트 & 품질**: Jest + React Testing Library로 로직/뷰 테스트, Detox/E2E로 지도/스토리 플로우 검증.

### 9.3 빠른 포트폴리오용 액션 아이템
1. Swift 모델 → TS 타입 생성 스크립트 작성.
2. RN Map 탭(기본 맵 + 상인 핀)과 Auth/Login 화면을 MVP로 선구현.
3. Socket mock 서버(또는 Swift 서버 응답 JSON)로 RN에서 실시간 피드 데모.

---

## 10. Reference Checklist
- **필수 문서**: `README.md`, `claudedocs/00_PROJECT_OVERVIEW.md`, `claudedocs/way3_function_specifications.md`, 각 구현 보고서.
- **데이터 편집 시**: `GameData/`·`StoryData/` JSON → 앱 재실행, 필요 시 캐시 삭제.
- **서버 연동**: `.env` 업데이트 시 `Info.plist`의 `API_BASE_URL`도 동기화.
- **자산 관리**: GLB/영상은 Git LFS 또는 외부 스토리지, Chosun 폰트는 iOS/Android 모두에 번들.

이 문서를 최신 상태로 유지하면, 새로운 에이전트/개발자가 Swift → React Native 이식 작업을 즉시 이어서 진행할 수 있습니다. 추가 정보가 필요하면 `claudedocs/` 하위 문서와 각 Swift 파일 상단 주석(기능 설명)을 참고하세요.
