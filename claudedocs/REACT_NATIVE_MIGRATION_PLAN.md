# WAY3 Swift → React Native 마이그레이션 계획

**최종 업데이트**: 2025-02-10

---

## 1. 현재 구조 요약

| 영역 | Swift 경로 | 역할 |
|------|------------|------|
| **Core** | `way3/Core/*.swift` | AuthManager, NetworkManager, LocationManager, QuestManager, TradeManager, SocketManager 등 |
| **Models** | `way3/Models/*.swift` | Player, Merchant, TradeItem, Quest, GameEnums 등 |
| **Managers** | `way3/Managers/*.swift` | GameManager, StoryFlowManager, StoryHubDataProvider |
| **Views** | `way3/Views/**/*.swift` | Auth, Map, Merchant, Quest, Story, Profile, Inventory 등 |
| **Components** | `way3/Components/*.swift` | Cyberpunk* 컴포넌트, 공통 UI |
| **Data** | `way3/GameData/`, `way3/StoryData/` | JSON (챕터, 퀘스트, 스토리 노드) |
| **Resources** | `way3/Resources/`, `way3/Assets.xcassets` | 이미지, 폰트, 3D GLB, 배경 영상 |

---

## 2. RN 추천 스택 & Swift 대응

| Swift | React Native |
|-------|--------------|
| SwiftUI + Combine | React Native + TypeScript |
| `@StateObject` / `@Published` | Zustand / Jotai / Redux Toolkit |
| `NetworkManager` | TanStack Query + axios/fetch wrapper |
| `SecureStorage` (Keychain) | `react-native-keychain` / `expo-secure-store` |
| `LocationManager` (CoreLocation) | `expo-location` / `react-native-geolocation-service` |
| MapboxMaps 3D | `@rnmapbox/maps` |
| Socket.IO | `socket.io-client` |
| JSON 로컬 캐시 | Metro asset + `react-native-fs` / `expo-file-system` |
| ChosunCentennial 폰트 | `.ttf` 변환 후 RN에 번들 |

---

## 3. 마이그레이션 단계

### Phase 0: 준비 (1–2주)

1. **RN 프로젝트 생성**  
   - Expo Router 또는 RN CLI 사용  
   - TypeScript, Hermes 기본 설정

2. **데이터 계약 정의**  
   - Swift 모델 → TypeScript 타입 정의  
   - `Models/`, `GameData/`, `StoryData/` JSON 스키마 기반  
   - `claudedocs/way3_function_specifications.md` 참고

3. **API 문서 정리**  
   - NetworkManager 엔드포인트 → API 레퍼런스 문서  
   - 요청/응답 DTO 타입 정의

---

### Phase 1: 인프라 & 서비스 (2–3주)

| 순서 | Swift 소스 | RN 목표 | 비고 |
|------|------------|---------|------|
| 1 | `NetworkManager` | `api/client.ts`, `api/endpoints.ts` | JWT, baseURL, 에러 처리 |
| 2 | `SecureStorage` | `storage/secureStorage.ts` | 토큰 저장/조회 |
| 3 | `AuthManager` | `stores/authStore.ts` | 로그인/회원가입/토큰 갱신 |
| 4 | `LocationManager` | `services/locationService.ts` | 권한 요청, 위치 업데이트 스트림 |

목표: 인증 + 위치 기능만 RN에서 동작하도록 맞추기.

---

### Phase 2: UI 테마 & 공통 컴포넌트 (1–2주)

| 순서 | Swift 소스 | RN 목표 | 비고 |
|------|------------|---------|------|
| 1 | `Color+GameColors`, `CyberpunkDesignSystem` | `theme/colors.ts`, `theme/typography.ts` | 사이버펑크 색상/타이포 |
| 2 | `CyberpunkComponents`, `Cyberpunk*Components` | `components/cyberpunk/*` | 카드, 버튼, 탭 바 |
| 3 | `ChosunCentennial` 폰트 | `.ttf` 변환 후 RN에 연동 | `expo-font` 또는 `react-native-asset` |

목표: 공통 테마와 컴포넌트로 기존 UI 느낌 유지.

---

### Phase 3: 핵심 화면 (3–4주)

| 순서 | Swift 소스 | RN 목표 | 비고 |
|------|------------|---------|------|
| 1 | `LoginView`, `RegisterView`, `StartView` | `app/(auth)/login.tsx` 등 | 인증 플로우 |
| 2 | `MainTabView` | `app/(tabs)/_layout.tsx` | 탭 네비게이션 |
| 3 | `MapView` | `app/(tabs)/map.tsx` | Mapbox RN, 상인 핀 |
| 4 | `MerchantDetailView` | `app/merchant/[id].tsx` | 대화/거래/스토리 탭 |
| 5 | `StoryView` (VN 엔진) | `components/story/StoryPlayer.tsx` | 노드 읽기, 선택지, 분기 |

목표: 맵 → 상인 → 스토리/거래까지 한 경로가 RN에서 동작.

---

### Phase 4: 게임 로직 & 데이터 (2–3주)

| 순서 | Swift 소스 | RN 목표 | 비고 |
|------|------------|---------|------|
| 1 | `GameManager`, `ProgressManager` | `stores/gameStore.ts`, `stores/progressStore.ts` | Zustand 등 상태 관리 |
| 2 | `QuestManager`, `StoryFlowManager` | `services/questService.ts`, `services/storyFlowService.ts` | 퀘스트/스토리 진행 처리 |
| 3 | `GameData/`, `StoryData/` | `assets/data/` 또는 Metro 번들 | JSON 그대로 이식 |
| 4 | `StoryHubTabView`, `QuestView` | `app/(tabs)/story.tsx`, `quest.tsx` | 스토리 허브, 퀘스트 목록 |

목표: 메인/서브 퀘스트와 스토리 진행 로직이 RN에서 동작.

---

### Phase 5: 거래 & 부가 기능 (2주)

| 순서 | Swift 소스 | RN 목표 | 비고 |
|------|------------|---------|------|
| 1 | `TradeManager`, `CartManager` | `stores/tradeStore.ts`, `components/cart/` | 장바구니, 매입/매도 |
| 2 | `InventoryView`, `ProfileView` | `app/(tabs)/inventory.tsx`, `profile.tsx` | 인벤토리, 프로필 |
| 3 | `SocketManager` | `services/socketService.ts` | 실시간 가격/근처 플레이어 |

목표: 거래, 인벤토리, 프로필, 실시간 기능까지 RN에서 구현.

---

### Phase 6: 검증 & 튜닝 (1–2주)

- Jest + React Testing Library로 스토어/서비스 테스트
- Detox 또는 Maestro로 E2E (로그인 → 맵 → 상인 → 스토리)
- iOS/Android 권한 플로우 문서화
- 성능/번들 크기 점검

---

## 4. 폴더 구조 제안 (RN)

```
connectseoul/
├── app/                    # Expo Router 기반
│   ├── (auth)/             # 로그인, 회원가입
│   ├── (tabs)/             # 맵, 퀘스트, 스토리, 인벤토리, 프로필
│   └── merchant/[id].tsx   # 상인 상세
├── components/
│   ├── cyberpunk/          # 테마 컴포넌트
│   └── story/              # VN 플레이어
├── stores/                 # Zustand
│   ├── authStore.ts
│   ├── gameStore.ts
│   └── progressStore.ts
├── services/
│   ├── api/
│   ├── locationService.ts
│   ├── socketService.ts
│   └── questService.ts
├── types/                  # Swift 모델 → TS
├── assets/
│   ├── data/               # GameData, StoryData JSON
│   ├── fonts/
│   └── images/
└── theme/
```

---

## 5. 공유·재사용 자산

| 분류 | 경로 | RN 이식 방식 |
|------|------|---------------|
| JSON | `way3/GameData/`, `way3/StoryData/` | `assets/data/` 또는 번들 |
| 상인 이미지 | `way3/Resources/Merchant/` | `assets/images/merchant/` |
| 배경 영상 | `way3/Resources/Bgmv/` | CDN 또는 로컬 (용량 체크) |
| 3D GLB | `way3/Resources/3D_Models/` | Mapbox 3D 또는 Lottie 대체 검토 |
| 폰트 | `ChosunCentennial_otf.otf` | `.ttf` 변환 후 RN에 포함 |

---

## 6. 난이도가 높은 부분

1. **Mapbox 3D 플레이어 모델**: Swift `Puck3D` → RN에서 `@rnmapbox/maps` 3D 지원 범위 확인 필요
2. **Visual Novel 엔진**: `StoryView`의 노드 트리, 게이트, 선택지 로직을 RN 컴포넌트 구조로 재구성
3. **영수증 OCR**: `ReceiptVerifier` → RN에서 네이티브 모듈 또는 서버 OCR API 검토
4. **대용량 에셋**: 영상/3D는 CDN 또는 Lazy 로딩 전략 필요

---

## 7. MVP 우선순위 (빠른 시연용)

1. **RN 프로젝트 + Auth (로그인/회원가입)**
2. **맵 탭**: Mapbox RN 기본 맵 + 상인 핀
3. **상인 상세**: 대화/거래 UI만 (스토리/퀘스트는 후순위)
4. **토큰/보안 저장소**: 기존 서버 API와 동일한 인증 흐름

---

## 8. 참고 문서

- `claudedocs/00_PROJECT_OVERVIEW.md` - 게임 개요
- `claudedocs/WAY3_PROJECT_FIELD_GUIDE.md` - 구조 및 R.N 마이그레이션 Radar
- `way3/way3/Core/NetworkManager.swift` - API 엔드포인트 참조
