# 로컬 파일 저장 시스템 구현 계획서

## 📌 프로젝트 개요
네오-서울 트레이딩 게임의 플레이어 데이터 손실 문제를 해결하기 위한 로컬 파일 저장 시스템 구현

## 🚨 현재 문제점
- 앱 강제 종료 시 모든 게임 진행도 손실
- PlayerStats, PlayerRelationships, PlayerAchievements 등이 메모리에만 존재
- 레벨/경험치 시스템이 서버에 저장되지 않음
- 프로필 정보(age, personality, gender)가 UserDefaults에만 저장

## 🎯 목표
1. **데이터 영속성**: 앱 종료 후에도 게임 진행도 유지
2. **자동 백업**: 주기적 자동 저장으로 데이터 손실 최소화
3. **빠른 복구**: 앱 시작 시 이전 상태 즉시 복원
4. **안정성**: 저장 실패 시 백업본으로 복구

## 📋 구현 단계별 계획

### Phase 1: 기반 구조 구축 ⏱️ 1시간
#### 1.1 PlayerDataManager 클래스 생성
- **위치**: `/Models/Player/PlayerDataManager.swift`
- **기능**: 저장/로드/자동저장 관리
- **저장 위치**: Documents 디렉토리
- **파일 형태**: JSON (Player의 Codable 활용)

#### 1.2 저장 전략 설정
```swift
// 저장 트리거
- 30초마다 자동 저장
- 앱 백그라운드 전환 시
- 중요 이벤트 발생 시 (레벨업, 거래완료, 업적달성)
- 앱 종료 시

// 저장 데이터
- Player 전체 객체 (모든 컴포넌트 포함)
- 메타데이터 (저장 시간, 버전 정보)
```

### Phase 2: 핵심 기능 구현 ⏱️ 1.5시간
#### 2.1 PlayerDataManager 구현
- `savePlayer(_ player: Player)` - 플레이어 데이터 저장
- `loadPlayer() -> Player?` - 플레이어 데이터 로드
- `startAutoSave(for player: Player)` - 자동 저장 시작
- `stopAutoSave()` - 자동 저장 중지
- `createBackup()` - 백업 파일 생성

#### 2.2 에러 처리 및 백업 시스템
- 저장 실패 시 재시도 로직
- 백업 파일 관리 (최대 3개 보관)
- 데이터 무결성 검증

### Phase 3: Player 클래스 통합 ⏱️ 30분
#### 3.1 Player 클래스 수정
- 저장/로드 편의 메서드 추가
- 데이터 변경 감지 시스템
- 자동 저장 트리거 연결

```swift
extension Player {
    func save() async
    static func load() -> Player?
    func startAutoSave()
    func markAsChanged() // 데이터 변경 시 호출
}
```

### Phase 4: 앱 생명주기 연동 ⏱️ 30분
#### 4.1 ContentView 또는 App 파일 수정
- 앱 시작 시 자동 로드
- 백그라운드 전환 시 자동 저장
- 앱 종료 시 최종 저장

#### 4.2 ScenePhase 감지
```swift
.onChange(of: scenePhase) { phase in
    switch phase {
    case .background: player.save()
    case .inactive: player.save()
    default: break
    }
}
```

### Phase 5: 고급 기능 구현 ⏱️ 1시간
#### 5.1 마이그레이션 시스템
- 데이터 버전 관리
- 구조 변경 시 자동 마이그레이션
- 호환성 유지

#### 5.2 성능 최적화
- 변경된 데이터만 저장 (Delta 저장)
- 압축 저장 (대용량 데이터 처리)
- 백그라운드 스레드 저장

## 📁 파일 구조
```
Models/
  Player/
    ├── PlayerDataManager.swift        // 새로 생성
    ├── PlayerCore.swift              // 기존
    ├── PlayerStats.swift             // 기존
    ├── PlayerInventory.swift         // 기존
    ├── PlayerRelationships.swift     // 기존
    └── PlayerAchievements.swift      // 기존
```

## 🔧 기술 사양

### 저장 형식
```json
{
  "version": "1.0.0",
  "savedAt": "2024-12-26T10:30:00Z",
  "playerData": {
    "core": { ... },
    "stats": { ... },
    "inventory": { ... },
    "relationships": { ... },
    "achievements": { ... }
  }
}
```

### 파일명 규칙
- **주 파일**: `player_data.json`
- **백업파일**: `player_data_backup_1.json`, `player_data_backup_2.json`, `player_data_backup_3.json`

## 🧪 테스트 계획
1. **저장 테스트**: 다양한 게임 상태에서 저장 성공
2. **로드 테스트**: 저장된 데이터 정확히 복원
3. **자동 저장 테스트**: 30초마다 정상 저장
4. **백업 테스트**: 저장 실패 시 백업으로 복구
5. **성능 테스트**: 대용량 데이터 저장 속도

## 📊 예상 효과
- ✅ **데이터 보존율**: 99.9% (현재 0%)
- ✅ **사용자 만족도**: 대폭 향상
- ✅ **게임 연속성**: 완벽한 진행도 유지
- ✅ **안정성**: 다중 백업으로 데이터 안전

## 🚀 배포 계획
1. **개발 완료**: Phase 1-5 순차 진행
2. **내부 테스트**: 다양한 시나리오 검증
3. **베타 테스트**: 실제 사용 환경 검증
4. **정식 배포**: 안정성 확인 후 릴리즈

---
**작성일**: 2024-12-26
**예상 소요시간**: 4.5시간
**우선순위**: 🔴 최고 (게임 플레이 핵심 기능)