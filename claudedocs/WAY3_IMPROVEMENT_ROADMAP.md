# 🛠️ Way3 프로젝트 개선 로드맵

> **작성일**: 2024년 12월 26일
> **프로젝트**: Way3 (위치기반 트레이딩 게임)
> **상태**: 포트 통일 완료 (3000포트로 통합)

## 📋 완료된 작업

### ✅ 1단계: 포트 통일 및 구조 정리
- ❌ **admin-frontend 폴더 제거** (4000포트 React 앱)
- ✅ **theway_server 어드민 시스템 활용** (3000포트 HTML 기반)
- ✅ **start_server.sh 업데이트** - 관리자 패널 접속 정보 추가

**현재 포트 구조:**
```
🎮 iOS 앱: http://localhost:3000
🎛️ 관리자 패널: http://localhost:3000/admin
🔌 Socket.IO: ws://localhost:3000
📊 API: http://localhost:3000/api/*
```

---

## 🚨 Critical Issues (즉시 수정 필요)

### 2. Socket CORS 설정 확장
**파일**: `theway_server/src/server.js:18`
**문제**: 모바일 앱 연결 시 localhost 제한
```javascript
// 현재
origin: process.env.ALLOWED_ORIGINS?.split(',') || ["http://localhost:3000"]

// 개선안
const allowedOrigins = [
    "http://localhost:3000",
    "http://192.168.*.*:3000",  // 로컬 네트워크
    "capacitor://localhost",    // Capacitor 앱
    "ionic://localhost"         // Ionic 앱
];
```

### 3. NetworkManager 환경별 설정
**파일**: `way3/Core/NetworkManager.swift:8`
**문제**: 개발/운영 환경 구분 없음
```swift
// 현재
static let baseURL = "http://localhost:3000"

// 개선안
static let baseURL: String = {
    #if DEBUG
    return ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:3000"
    #else
    return "https://your-production-server.com"
    #endif
}()
```

---

## ⚠️ Important Issues (우선 수정 권장)

### 4. Player 모델 리팩토링
**파일**: `way3/Models/Player.swift` (1000+ 라인)
**문제**: 단일 파일이 너무 비대함
```swift
// 분리 구조
PlayerCore.swift          // 기본 정보, 레벨, 경험치
PlayerStats.swift         // 스탯 시스템 (힘, 지능, 매력, 행운)
PlayerInventory.swift     // 인벤토리, 착용품, 창고
PlayerRelationships.swift // 상인 관계, 길드
PlayerAchievements.swift  // 업적, 스킬 시스템
```

### 5. Socket 재연결 시스템
**파일**: `way3/Core/SocketManager.swift`
**추가 필요**:
```swift
private var reconnectionTimer: Timer?
private var reconnectionAttempts = 0
private let maxReconnectionAttempts = 5

func handleDisconnection() {
    guard reconnectionAttempts < maxReconnectionAttempts else { return }

    reconnectionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
        if !self.isConnected {
            self.reconnectionAttempts += 1
            self.connect()
        }
    }
}
```

### 6. API 응답 표준화
**파일**: 모든 API 응답
**목표**: 통일된 응답 구조
```javascript
// 표준 응답 포맷
{
    "success": boolean,
    "data": any,
    "error": {
        "code": string,
        "message": string,
        "details": object?
    },
    "timestamp": string,
    "version": "1.0.0"
}
```

### 7. 에러 처리 체계화
**위치**: 전역
**개선사항**:
- 네트워크 타임아웃 처리
- 서버 오류 시 사용자 친화적 메시지
- 재시도 메커니즘 구현
- 오프라인 모드 지원

---

## 🔄 Performance Issues (성능 개선)

### 8. 데이터베이스 최적화
**파일**: `theway_server/src/database/`
```sql
-- 추가할 인덱스
CREATE INDEX idx_players_location ON players(latitude, longitude);
CREATE INDEX idx_trades_timestamp ON trades(created_at);
CREATE INDEX idx_merchants_active ON merchants(is_active, district);
CREATE INDEX idx_inventory_player ON inventory_items(player_id, item_id);
```

### 9. 캐싱 시스템 도입
**새 파일**: `way3/Core/CacheManager.swift`
```swift
class CacheManager {
    static let shared = CacheManager()
    private let cache = NSCache<NSString, AnyObject>()
    private let cacheExpiry: TimeInterval = 300 // 5분

    // 플레이어 데이터 캐싱
    // 상인 정보 캐싱
    // 아이템 정보 캐싱
    // 가격 정보 캐싱 (짧은 만료시간)
}
```

### 10. 메모리 관리 개선
**파일**: 모든 Manager 클래스
```swift
deinit {
    cancellables.removeAll()
    reconnectionTimer?.invalidate()
    locationTimer?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
```

---

## 🎮 User Experience Issues

### 11. 오프라인 모드 지원
**새 파일**: `way3/Core/OfflineManager.swift`
- Core Data 로컬 저장소
- 오프라인 상태 UI 표시
- 연결 복구 시 데이터 동기화
- 읽기 전용 모드 지원

### 12. 로딩 상태 개선
**새 파일**: `way3/Components/LoadingSystem.swift`
```swift
struct LoadingOverlay: View {
    @Binding var isLoading: Bool
    let message: String

    // 스켈레톤 UI
    // 프로그레스 인디케이터
    // 로딩 메시지 다국어 지원
}
```

### 13. 푸시 알림 시스템
**새 파일**: `way3/Core/NotificationManager.swift`
- APNs 연동
- 거래 완료 알림
- 근처 플레이어 알림
- 이벤트 알림
- 백그라운드 작업 처리

---

## 🔒 Security Issues

### 14. JWT 토큰 보안 강화
**파일**: `way3/Core/AuthManager.swift`
```swift
import Security

class SecureStorage {
    static let shared = SecureStorage()

    // Keychain을 사용한 안전한 토큰 저장
    func storeToken(_ token: String, forKey key: String) {
        // Keychain Services API 사용
    }

    // 자동 토큰 갱신
    func refreshTokenIfNeeded() async {
        // 만료 1시간 전 자동 갱신
    }
}
```

### 15. API 보안 강화
**파일**: `theway_server/src/middleware/`
- 엔드포인트별 레이트 리밋
- 사용자별 API 호출 제한
- 요청 크기 제한
- SQL 인젝션 방지

### 16. 입력 검증 체계화
**파일**: `way3/Utils/ValidationExtensions.swift`
```swift
extension String {
    var isValidPlayerName: Bool {
        return self.count >= 2 && self.count <= 20 &&
               !self.contains(where: { $0.isSymbol || $0.isPunctuation })
    }

    var isValidTradeAmount: Bool {
        guard let amount = Int(self) else { return false }
        return amount > 0 && amount <= 1_000_000
    }
}
```

---

## 🏗️ Architecture Issues

### 17. 의존성 주입 도입
**새 파일**: `way3/Core/DependencyContainer.swift`
```swift
protocol NetworkManagerProtocol {
    func authenticate(email: String, password: String) async throws -> AuthResponse
    func fetchPlayerData() async throws -> Player
}

class DependencyContainer {
    static let shared = DependencyContainer()

    lazy var networkManager: NetworkManagerProtocol = NetworkManager()
    lazy var authManager: AuthManagerProtocol = AuthManager()
}
```

### 18. 테스트 환경 구축
**새 폴더**: `way3Tests/`
```swift
// 단위 테스트
way3Tests/
├── Models/
│   ├── PlayerTests.swift
│   └── TradeItemTests.swift
├── Core/
│   ├── NetworkManagerTests.swift
│   └── AuthManagerTests.swift
└── Views/
    └── TradeViewTests.swift

// 통합 테스트
way3UITests/
├── LoginFlowTests.swift
├── TradingFlowTests.swift
└── MapNavigationTests.swift
```

### 19. 환경 설정 체계화
**새 파일들**:
```
way3/Config/
├── Development.xcconfig
├── Staging.xcconfig
├── Production.xcconfig
└── Base.xcconfig
```

---

## 📊 Monitoring & Analytics

### 20. 로깅 시스템 확장
**파일**: `way3/Core/Logger.swift`
```swift
import OSLog

class GameLogger {
    static let shared = GameLogger()
    private let logger = Logger(subsystem: "com.way3.game", category: "main")

    func logUserAction(_ action: String, parameters: [String: Any]) {
        // 로컬 로깅
        // 원격 로깅 (개인정보 제외)
    }
}
```

### 21. 성능 모니터링
**통합 서비스**:
- Firebase Analytics
- Crashlytics
- Performance Monitoring
- Remote Config

### 22. 게임 밸런싱 데이터
**새 시스템**: 이벤트 트래킹
```swift
enum GameEvent {
    case tradeCompleted(itemId: String, price: Int, profit: Int)
    case levelUp(newLevel: Int, timeTaken: TimeInterval)
    case skillLearned(skillId: String, playerLevel: Int)
    case merchantDiscovered(merchantId: String, district: String)
}

class AnalyticsManager {
    static let shared = AnalyticsManager()

    func track(_ event: GameEvent) {
        // 게임 밸런싱을 위한 데이터 수집
    }
}
```

---

## 🔧 Development Experience

### 23. 개발 도구 개선
**추가 도구**:
- SwiftUI Preview 최적화
- Xcode Build Phases 정리
- 빌드 시간 최적화 (모듈화)

### 24. 문서화 체계
**새 문서들**:
```
docs/
├── API_DOCUMENTATION.md      # Swagger/OpenAPI
├── GAME_DESIGN.md           # 게임 기획서
├── TECHNICAL_ARCHITECTURE.md # 기술 아키텍처
├── DEPLOYMENT_GUIDE.md      # 배포 가이드
└── TROUBLESHOOTING.md       # 문제해결 가이드
```

### 25. CI/CD 파이프라인
**새 파일**: `.github/workflows/`
- 자동 테스트 실행
- 코드 품질 검사
- 자동 배포 (Staging/Production)

---

## 🎯 우선순위별 실행 계획

### Phase 1 (즉시 - 1주) - Critical
- [ ] Socket CORS 설정 확장 (#2)
- [ ] NetworkManager 환경별 설정 (#3)
- [ ] Socket 재연결 시스템 (#5)

### Phase 2 (1-2주) - Architecture
- [ ] Player 모델 리팩토링 (#4)
- [ ] API 응답 표준화 (#6)
- [ ] 에러 처리 체계화 (#7)

### Phase 3 (2-4주) - Performance & UX
- [ ] 데이터베이스 최적화 (#8)
- [ ] 캐싱 시스템 도입 (#9)
- [ ] 오프라인 모드 지원 (#11)
- [ ] 로딩 상태 개선 (#12)

### Phase 4 (4-6주) - Security & Monitoring
- [ ] JWT 보안 강화 (#14)
- [ ] 테스트 환경 구축 (#18)
- [ ] 로깅/모니터링 시스템 (#20, #21)
- [ ] 푸시 알림 시스템 (#13)

### Phase 5 (6-8주) - Advanced Features
- [ ] 의존성 주입 도입 (#17)
- [ ] 게임 밸런싱 데이터 (#22)
- [ ] CI/CD 파이프라인 (#25)

---

## 📝 체크리스트 템플릿

각 작업 완료 시 다음을 확인:

```markdown
## 작업 완료 체크리스트

- [ ] 코드 구현 완료
- [ ] 단위 테스트 작성
- [ ] 코드 리뷰 완료
- [ ] 문서 업데이트
- [ ] 테스트 서버 검증
- [ ] 성능 테스트 (필요시)
- [ ] 보안 검토 (민감한 기능)
- [ ] 사용자 테스트 (UI 관련)
```

---

## 🔗 관련 파일 참조

### 핵심 파일들
- `way3/Core/NetworkManager.swift` - API 통신
- `way3/Core/SocketManager.swift` - 실시간 통신
- `way3/Models/Player.swift` - 플레이어 모델
- `theway_server/src/server.js` - 서버 진입점
- `theway_server/src/routes/admin/index.js` - 관리자 기능

### 환경 설정
- `theway_server/.env` - 서버 환경 변수
- `start_server.sh` - 서버 시작 스크립트

---

> 🎮 **목표**: 이 로드맵을 완료하면 Way3는 상용 출시 가능한 최고 품질의 위치기반 트레이딩 게임이 됩니다!

**마지막 업데이트**: 2024년 12월 26일