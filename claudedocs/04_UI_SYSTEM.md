# 조선사이버펑크 UI 시스템

connect:seoul의 UI 테마 레퍼런스. 모든 새 컴포넌트는 이 가이드를 따릅니다.

**최종 업데이트**: 2026-02-20

---

## 1. 테마 개요

**조선사이버펑크(朝鮮Cyberpunk)** — 전통 한국 오방색(五方色)을 네온 사이버펑크 팔레트로 재해석.
단청(丹靑) 문양, 교서(敎書) 스타일 대화창, 도장 씰(印章) 모티프를 디지털 UI에 결합.

---

## 2. 오방색 네온 팔레트

| 상수 | 색상명 | 역할 | RGB 값 |
|------|--------|------|--------|
| `.joseonCheong` | 청(靑) 네온 | 상인 말풍선 테두리, 타이핑 인디케이터, 포커스 링 | `#00E5CC` |
| `.joseonJeok` | 적(赤) 네온 | 위험/경고, 언락 배너 액센트, 도장 씰 | `#FF2D55` |
| `.joseonHwang` | 황(黃) 금색 | 플레이어 말풍선, 선택된 탭 인디케이터, 강조 버튼 | `#FFB800` |
| `.joseonBaek` | 백(白) 아이보리 | 일반 텍스트, 상인 말풍선 글자 | `#E8E0D5` |
| `.joseonHeuk` | 흑(黑) 딥 블랙 | 앱 기본 배경 | `#0A0A0F` |
| `.joseonPanel` | 패널 다크 | 카드/패널 배경 | 정의 참조 |
| `.joseonCard` | 카드 배경 | 입력창/카드 배경 | 정의 참조 |
| `.joseonBorderDim` | 흐린 테두리 | 비활성 테두리 | 정의 참조 |

> **주의**: `Color(hex:)` 사용 금지 (Color 확장 내 스코프 충돌 발생).
> 반드시 `Color(red:green:blue:)` 또는 위 상수(`Color+GameColors.swift`)를 사용할 것.

---

## 3. 폰트 시스템

### ChosunCentennial (타이틀/헤딩/버튼 전용)

| 상수 | 크기 | 용도 |
|------|------|------|
| `.chosunTitle` | 28pt bold | 화면 메인 타이틀 |
| `.chosunH1` | 24pt bold | 섹션 헤더 1 |
| `.chosunH2` | 20pt bold | 섹션 헤더 2 |
| `.chosunH3` | 18pt semibold | 서브 헤더 |
| `.chosunButton` | 16pt medium | 버튼 레이블 |
| `.chosunBody` | 16pt | 본문 (한글 우선) |
| `.chosunCaption` | 14pt | 캡션 |
| `.chosunSmall` | 12pt | 보조 텍스트 |

### Pretendard (바디/캡션/기술 텍스트)

| 함수 | 기본 크기 | 용도 |
|------|----------|------|
| `.cyberpunkTitle(size:)` | 가변 | ChosunCentennial bold |
| `.cyberpunkHeading(size:)` | 가변 | ChosunCentennial semibold |
| `.cyberpunkBody(size:)` | 가변 | Pretendard-Regular |
| `.cyberpunkCaption(size:)` | 가변 | Pretendard-Medium |
| `.cyberpunkTechnical(size:)` | 가변 | Pretendard-SemiBold |
| `.cyberpunkButton(size:)` | 가변 | ChosunCentennial medium |

> **규칙**: `.title2`, `.body`, `.caption` 등 시스템 폰트 직접 사용 금지.

### 폰트 파일 위치
```
Resources/font/
  ChosunCentennial_otf.otf
  Pretendard-Black.otf
  Pretendard-Bold.otf
  Pretendard-ExtraBold.otf
  Pretendard-ExtraLight.otf
  Pretendard-Light.otf
  Pretendard-Medium.otf
  Pretendard-Regular.otf
  Pretendard-SemiBold.otf
  Pretendard-Thin.otf
```

---

## 4. 핵심 컴포넌트

### DancheongBar
단청 패턴 좌측 액센트 바. 퀘스트 카드, 언락 배너에 사용.

```swift
// 적→황 그라디언트 (3pt 폭)
LinearGradient(colors: [.joseonJeok, .joseonHwang], ...)
    .frame(width: 3)
```

### JoseonSealBadge
도장(印章) 씰 컴포넌트. 교서 대화창 및 언락 배너에 사용.

```swift
ZStack {
    Circle().fill(Color.joseonJeok)  // 적색 원형
    Text("開").font(.custom("ChosunCentennial", size: 16))
}
// onAppear: 좌우 흔들림 애니메이션 (-3° ↔ +3°)
```

### MerchantTabSelector
에피소드 / 대화하기 탭 선택기. `matchedGeometryEffect`로 황금 슬라이딩 인디케이터.

### CyberpunkChatComponents (AI 채팅 전용)
`Components/CyberpunkChatComponents.swift` 참조.

---

## 5. 대화창 스타일 (교서 敎書)

- **레이아웃**: 좌측 단청 바(3pt) + 도장 씰 + 한국어 발화자 레이블
- **배경**: `joseonPanel` (반투명 흑)
- **텍스트**: `joseonBaek`, `cyberpunkBody(size: 15)`
- **테두리**: `joseonCheong` 0.35 opacity

---

## 6. 퀘스트 카드 스타일

- 좌측 액센트 바: 퀘스트 타입별 오방색
  - dialogue → joseonCheong
  - delivery → joseonHwang
  - trading → joseonJeok
- 한국어 타입 레이블: JoseonSealBadge 사용

---

## 7. 프로필 스탯 패널 (CyberpunkStatsPanel)

힘(力) · 지능(智) · 매력(魅) · 행운(幸) — 각 스탯 오방색 바

| 스탯 | 색상 |
|------|------|
| 힘(力) | joseonJeok |
| 지능(智) | joseonCheong |
| 매력(魅) | joseonHwang |
| 행운(幸) | joseonBaek |

---

## 8. SourceKit 경고 주의사항

cross-file symbol resolution 오류(`Cannot find type in scope`)가 에디터에 표시될 수 있음.
이는 SourceKit false positive이며 **Xcode 빌드 시 정상 해소**됨. 별도 조치 불필요.
