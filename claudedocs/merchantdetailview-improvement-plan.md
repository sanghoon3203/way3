# MerchantDetailView 개선 계획

## 현재 문제점 분석
1. **iPhone 16 화면 크기 대응 이슈**: 좌우측이 짤리는 현상
2. **JRPG 스타일 부족**: 현재 좌우 분할 레이아웃이 아닌 하단 대화창 필요
3. **선택지 위치**: 전통적인 JRPG처럼 대화창 우상단에 위치해야 함
4. **이미지 매칭 시스템**: Asset 폴더의 상인 이름과 매칭하여 동적 로드 필요

## Phase 1: 현재 구조 분석 및 문제점 파악 (30분)

### 1.1 현재 MerchantDetailView 구조 분석
- [ ] 현재 레이아웃 구조 파악 (HStack 기반 좌우 분할)
- [ ] iPhone 16 화면 크기에서 발생하는 문제점 확인
- [ ] 현재 대화창 및 선택지 구조 분석

### 1.2 Asset 폴더 구조 확인
- [ ] Assets.xcassets/Merchant/ 폴더 내 이미지 파일 확인
- [ ] 상인 이름과 이미지 파일명 매칭 규칙 파악
- [ ] 현재 merchantImageName 로직 검토

## Phase 2: iPhone 16 대응 레이아웃 수정 (45분)

### 2.1 화면 크기 대응 시스템 구현
```swift
// 안전한 화면 크기 계산
struct ScreenSizeManager {
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    static let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero

    // iPhone 16 대응 비율 계산
    static var dialogueWidth: CGFloat {
        return screenWidth * 0.9 // 90% 사용으로 여백 확보
    }

    static var characterDisplayHeight: CGFloat {
        return screenHeight * 0.6 // 상단 60%를 캐릭터 영역으로
    }
}
```

### 2.2 반응형 레이아웃 적용
- [ ] HStack 기반 좌우 분할에서 VStack 기반 상하 분할로 변경
- [ ] 모든 하드코딩된 크기값을 상대적 비율로 변경
- [ ] SafeArea 적용하여 노치/Dynamic Island 대응

## Phase 3: JRPG 스타일 하단 대화창 구현 (60분)

### 3.1 새로운 레이아웃 구조 설계
```swift
VStack {
    // 상단: 상인 캐릭터 표시 영역 (60%)
    CharacterDisplayArea()
        .frame(height: ScreenSizeManager.characterDisplayHeight)

    Spacer()

    // 하단: JRPG 스타일 대화창 (40%)
    ZStack(alignment: .topTrailing) {
        // 메인 대화창
        JRPGDialogueBox()

        // 우상단 선택지 창
        if isTypingComplete {
            ChoiceSelectionPanel()
                .offset(x: -20, y: 20)
        }
    }
    .frame(height: ScreenSizeManager.screenHeight * 0.4)
}
```

### 3.2 JRPG 대화창 컴포넌트 구현
- [ ] 전통적인 JRPG 스타일 대화창 디자인
- [ ] 타이핑 애니메이션 효과
- [ ] 다음 화살표 표시 시스템

### 3.3 상인 캐릭터 표시 영역 최적화
- [ ] 상단 영역에 상인 캐릭터 중앙 배치
- [ ] 배경 효과 및 애니메이션 추가

## Phase 4: ZStack 기반 선택지 시스템 구현 (45분)

### 4.1 선택지 패널 디자인
```swift
struct ChoiceSelectionPanel: View {
    let choices: [DialogueChoice]
    @Binding var selectedChoice: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                ChoiceRow(
                    choice: choice,
                    isSelected: selectedChoice == index,
                    onTap: { selectedChoice = index }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gold, lineWidth: 2)
                )
        )
        .shadow(radius: 10)
    }
}
```

### 4.2 선택지 상호작용 시스템
- [ ] 선택지 호버/터치 효과
- [ ] 키보드 네비게이션 지원
- [ ] 선택 확정 애니메이션

## Phase 5: 동적 이미지 로드 시스템 구현 (45분)

### 5.1 이미지 매칭 시스템 구현
```swift
class MerchantImageManager {
    static func getImageName(for merchantName: String) -> String {
        // 1. 기본 변환: 공백 제거, 소문자
        let baseName = merchantName.replacingOccurrences(of: " ", with: "").lowercased()

        // 2. Asset에서 이미지 존재 확인
        let possibleNames = [
            baseName,
            merchantName.replacingOccurrences(of: " ", with: ""),
            "\(baseName)_merchant",
            "merchant_\(baseName)"
        ]

        for name in possibleNames {
            if UIImage(named: name) != nil {
                return name
            }
        }

        // 3. 기본 이미지 반환
        return "default_merchant"
    }
}
```

### 5.2 Asset 구조 정리
- [ ] Assets.xcassets/Merchant/ 폴더 내 이미지 정리
- [ ] 네이밍 규칙 표준화
- [ ] 기본 이미지 추가

### 5.3 동적 로드 구현
- [ ] MerchantDetailView에 동적 이미지 로드 적용
- [ ] 이미지 로드 실패 시 fallback 처리
- [ ] 이미지 캐싱 시스템 (성능 최적화)

## Phase 6: 통합 테스트 및 최적화 (30분)

### 6.1 다양한 기기에서 테스트
- [ ] iPhone 16 Pro Max에서 테스트
- [ ] iPhone 16에서 테스트
- [ ] iPad에서 테스트 (필요시)
- [ ] 가로/세로 모드 테스트

### 6.2 성능 최적화
- [ ] 레이아웃 성능 측정
- [ ] 이미지 로드 성능 확인
- [ ] 메모리 사용량 체크

### 6.3 사용자 경험 개선
- [ ] 애니메이션 타이밍 조정
- [ ] 터치 반응성 최적화
- [ ] 접근성 기능 추가

## 구현 순서

1. **Phase 1** → **Phase 2**: 기본 레이아웃 문제 해결
2. **Phase 3**: JRPG 스타일 적용
3. **Phase 4**: 선택지 시스템 완성
4. **Phase 5**: 이미지 시스템 구현
5. **Phase 6**: 전체 검증 및 최적화

## 예상 소요 시간
- **총 소요 시간**: 약 4-5시간
- **우선순위 작업** (iPhone 16 대응): 1-2시간
- **JRPG 스타일 구현**: 2-3시간
- **테스트 및 최적화**: 1시간

## 주요 고려사항

1. **화면 크기 대응**: 모든 하드코딩된 값을 상대적 비율로 변경
2. **성능**: 이미지 로드 및 애니메이션 최적화
3. **사용자 경험**: 직관적인 JRPG 스타일 인터페이스
4. **확장성**: 다양한 상인 캐릭터 및 대화 시나리오 지원

## 완료 기준

- [x] iPhone 16에서 UI가 짤리지 않음
- [x] 전통적인 JRPG 스타일 하단 대화창 구현
- [x] 대화창 우상단에 선택지 패널이 ZStack으로 구현됨
- [x] Asset 폴더의 상인 이미지가 이름으로 자동 매칭됨
- [x] 모든 기기에서 정상적으로 작동함