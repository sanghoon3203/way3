# 조선사이버펑크 UI 리디자인 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** connect:seoul 게임의 "제네릭 사이버펑크" UI를 오방색 네온 팔레트·ChosunCentennial 전면 확장·교서 스타일 대화창·단청 장식 요소를 핵심으로 하는 "조선사이버펑크(朝鮮 Cyberpunk)" 정체성으로 전환한다.

**Architecture:** 기존 `cyberpunk*` 네이밍 체계와 API 시그니처를 100% 유지한 채 내부 색상·폰트·레이아웃 값만 교체하여 기존 뷰 코드를 건드리지 않는다. 신규 컴포넌트(`DancheongBar`, `JoseonSealBadge`)를 추가하고, `CyberpunkDialogueBox`만 헤더 영역을 부분 재설계한다.

**Tech Stack:** Swift 5.9, SwiftUI, ChosunCentennial(번들 내 OTF), SF Mono(시스템 모노스페이스 대체용)

---

## Task 1: 프로젝트명 및 컨셉 문서 업데이트

**Files:**
- Modify: `claudedocs/UI_CONCEPT_PROPOSAL.html` — "WAY3" → "connect:seoul"
- Modify: `CLAUDE.md` — 프로젝트명 반영

**Step 1: HTML 문서 내 WAY3 → connect:seoul 치환**

`UI_CONCEPT_PROPOSAL.html` 에서 아래 문자열 전체 치환:
- `<title>WAY3 UI 리디자인 컨셉 — 조선사이버펑크</title>` → `<title>connect:seoul UI 리디자인 컨셉 — 조선사이버펑크</title>`
- `UI REDESIGN PROPOSAL — WAY3` → `UI REDESIGN PROPOSAL — connect:seoul`
- `WAY3 — 조선사이버펑크` (footer) → `connect:seoul — 조선사이버펑크`
- `WAY3 UI 리디자인 컨셉 — 조선사이버펑크` (h1) → `connect:seoul UI 리디자인 컨셉 — 조선사이버펑크`

**Step 2: CLAUDE.md 프로젝트명 업데이트**

`CLAUDE.md` 첫 번째 줄 이름 항목:
```
- **이름**: WAY3 (The Way Trading Game)
```
→
```
- **이름**: connect:seoul (구 WAY3)
```

**Step 3: 브라우저 새로고침 확인 후 커밋**

```bash
git add claudedocs/UI_CONCEPT_PROPOSAL.html CLAUDE.md
git commit -m "docs: rename WAY3 → connect:seoul in UI concept and CLAUDE.md"
```

---

## Task 2: 오방색 네온 팔레트 추가 (CyberpunkDesignSystem.swift)

**Files:**
- Modify: `way3/Utils/CyberpunkDesignSystem.swift`

**변경 전략:** 기존 색상 변수는 삭제하지 않고, 오방색 별칭을 추가한 뒤 기존 변수가 새 값을 참조하도록 재배선한다. 이 방식으로 기존 `cyberpunkYellow` 등을 사용하는 뷰 코드를 전혀 수정하지 않아도 된다.

**Step 1: 오방색 팔레트 상수 블록 추가**

`// MARK: - Cyberpunk Color Palette` 다음, 기존 색상들 위에 아래 블록 삽입:

```swift
// MARK: - 오방색 네온 팔레트 (五方色 Neon — 조선사이버펑크)
extension Color {
    // 청(靑) — 동쪽·나무·탐색/이동
    static let joseonCheong   = Color(hex: "00E5CC")
    // 적(赤) — 남쪽·불·도장·긴급
    static let joseonJeok     = Color(hex: "FF2D55")
    // 황(黃) — 중앙·흙·거래·보상
    static let joseonHwang    = Color(hex: "FFB800")
    // 백(白) — 서쪽·금·한지 크림
    static let joseonBaek     = Color(hex: "E8E0D5")
    // 흑(黑) — 북쪽·물·딥 잉크 배경
    static let joseonHeuk     = Color(hex: "0A0A0F")

    // 패널/카드 배경 (한지 노이즈 느낌 위한 미세 따뜻함)
    static let joseonPanel    = Color(hex: "111118")
    static let joseonCard     = Color(hex: "16161F")

    // 보더
    static let joseonBorderDim  = Color.joseonBaek.opacity(0.12)
    static let joseonBorderGlow = Color.joseonCheong.opacity(0.35)
}
```

**Step 2: 기존 cyberpunk 색상 값을 오방색으로 재배선**

`extension Color` 블록에서 기존 값들 교체:

```swift
// 기존 코드 — 전부 교체
static let cyberpunkYellow     = Color(red: 1.0, green: 0.85, blue: 0.0)
static let cyberpunkGold       = Color(red: 1.0, green: 0.75, blue: 0.0)
static let cyberpunkCyan       = Color(red: 0.0, green: 0.9, blue: 0.9)
static let cyberpunkGreen      = Color(red: 0.0, green: 1.0, blue: 0.3)
static let cyberpunkDarkBg     = Color(red: 0.05, green: 0.05, blue: 0.08)
static let cyberpunkPanelBg    = Color(red: 0.1, green: 0.12, blue: 0.15)
static let cyberpunkCardBg     = Color(red: 0.15, green: 0.18, blue: 0.22)

// 교체 후 — 오방색 참조
static let cyberpunkYellow     = Color.joseonHwang        // 황(黃)
static let cyberpunkGold       = Color.joseonHwang.opacity(0.85)
static let cyberpunkCyan       = Color.joseonCheong       // 청(靑)
static let cyberpunkGreen      = Color(hex: "00FF66")     // 유지 (성공 상태용)
static let cyberpunkDarkBg     = Color.joseonHeuk
static let cyberpunkPanelBg    = Color.joseonPanel
static let cyberpunkCardBg     = Color.joseonCard
```

**Step 3: 단청 장식 바 컴포넌트 추가 (파일 끝에 추가)**

```swift
// MARK: - 단청 장식 바 (DancheongBar)
/// 단청(丹靑) 패턴을 모방한 색동 수평 바.
/// 대화창 상단, 화면 진입 트랜지션에 사용.
struct DancheongBar: View {
    var height: CGFloat = 4

    private let segments: [(Color, CGFloat)] = [
        (.joseonHwang, 1), (.joseonJeok, 1), (.joseonCheong, 1),
        (.joseonJeok, 1),  (.joseonHwang, 1)
    ]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(0..<segments.count, id: \.self) { i in
                    Rectangle()
                        .fill(segments[i].0)
                        .frame(width: geo.size.width / CGFloat(segments.count))
                }
            }
        }
        .frame(height: height)
    }
}
```

**Step 4: 도장 씰 배지 컴포넌트 추가 (파일 끝에 추가)**

```swift
// MARK: - 도장 씰 배지 (JoseonSealBadge)
/// 조선 관아 도장(圖章) 스타일. 상인 이니셜 한 글자를 적(赤) 테두리 사각형에 표시.
struct JoseonSealBadge: View {
    let character: String
    var size: CGFloat = 36
    var color: Color = .joseonJeok

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(0.12))
                .frame(width: size, height: size)
                .overlay(
                    Rectangle()
                        .stroke(color, lineWidth: 1.5)
                )
                .overlay(
                    Rectangle()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                        .padding(4)
                )

            Text(character)
                .font(.custom("ChosunCentennial", size: size * 0.5))
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .shadow(color: color.opacity(0.3), radius: 6)
    }
}
```

**Step 5: CyberpunkCornerDecoration 단청 색으로 업데이트**

```swift
// 기존
Rectangle().fill(Color.cyberpunkYellow)
// → 변경 없음 (cyberpunkYellow가 이미 joseonHwang을 가리키므로 자동 반영)
```

**Step 6: 빌드 확인**

```bash
xcodebuild -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|warning:|BUILD"
```
Expected: `BUILD SUCCEEDED`

**Step 7: 커밋**

```bash
git add way3/Utils/CyberpunkDesignSystem.swift
git commit -m "feat(ui): add 오방색 neon palette and Joseon UI primitives (DancheongBar, JoseonSealBadge)"
```

---

## Task 3: ChosunCentennial 폰트 전면 확장 (CyberpunkDesignSystem.swift)

**Files:**
- Modify: `way3/Utils/CyberpunkDesignSystem.swift` — `extension Font` 블록

**핵심 원칙:**
- `cyberpunkTitle`, `cyberpunkHeading` → ChosunCentennial (디스플레이 역할)
- `cyberpunkBody` → 시스템 기본 (한글 본문 가독성 유지)
- `cyberpunkCaption`, `cyberpunkTechnical` → 시스템 모노스페이스 유지 (기술 데이터 전용)

**Step 1: `extension Font` 블록 내 함수 교체**

```swift
// 기존 — 전부 system monospaced
static func cyberpunkTitle(size: CGFloat = 24) -> Font {
    return .system(size: size, weight: .bold, design: .monospaced)
}
static func cyberpunkHeading(size: CGFloat = 18) -> Font {
    return .system(size: size, weight: .semibold, design: .monospaced)
}
static func cyberpunkBody(size: CGFloat = 14) -> Font {
    return .system(size: size, weight: .medium, design: .default)
}
static func cyberpunkButton(size: CGFloat = 16) -> Font {
    return .system(size: size, weight: .semibold, design: .default)
}

// 교체 후
static func cyberpunkTitle(size: CGFloat = 24) -> Font {
    return Font.custom("ChosunCentennial", size: size).weight(.bold)
}
static func cyberpunkHeading(size: CGFloat = 18) -> Font {
    return Font.custom("ChosunCentennial", size: size).weight(.semibold)
}
static func cyberpunkBody(size: CGFloat = 14) -> Font {
    return .system(size: size, weight: .regular)   // 본문 가독성
}
static func cyberpunkButton(size: CGFloat = 16) -> Font {
    return Font.custom("ChosunCentennial", size: size).weight(.medium)
}
// cyberpunkCaption, cyberpunkTechnical은 모노스페이스 유지
```

**Step 2: 빌드 + 시뮬레이터 실행으로 폰트 적용 육안 확인**

```bash
xcodebuild -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"
```

**Step 3: 커밋**

```bash
git add way3/Utils/CyberpunkDesignSystem.swift
git commit -m "feat(ui): promote ChosunCentennial as display font for title/heading/button roles"
```

---

## Task 4: 교서 스타일 대화창 재설계 (CyberpunkComponents.swift)

**Files:**
- Modify: `way3/Components/CyberpunkComponents.swift` — `CyberpunkDialogueBox` 구조체

**변경 범위:** 헤더 영역만 재설계. body/footer 구조·프로퍼티는 그대로 유지하여 기존 `StoryView` 등의 호출 코드를 건드리지 않는다.

**Step 1: `CyberpunkDialogueBox` 헤더 영역 교체**

`CyberpunkDialogueBox.body` 의 첫 번째 VStack 내부, `// Technical Header` 주석 블록 전체를 아래로 교체:

```swift
// 기존 Technical Header (삭제)
// HStack {
//     Text("COMM_LINK") ...
//     Text(merchantName.uppercased()) ...
//     HStack { Circle()... Text("CONNECTED") }
// }

// 교체 후 — 교서(敎書) 스타일 헤더
VStack(spacing: 0) {
    // 단청 바
    DancheongBar(height: 4)

    HStack(spacing: 10) {
        // 도장 씰 — 상인 이름 첫 글자
        JoseonSealBadge(
            character: String(merchantName.prefix(1)),
            size: 34
        )

        // 상인 정보
        VStack(alignment: .leading, spacing: 2) {
            Text(merchantName)
                .font(.cyberpunkHeading(size: 15))
                .foregroundColor(.joseonHwang)

            Text("접속중")
                .font(.cyberpunkTechnical())
                .foregroundColor(.joseonCheong)
        }

        Spacer()

        // 연결 상태 펄스
        HStack(spacing: 4) {
            Circle()
                .fill(Color.joseonCheong)
                .frame(width: 5, height: 5)
                .shadow(color: .joseonCheong, radius: 3)

            Text("연결됨")
                .font(.cyberpunkTechnical())
                .foregroundColor(.joseonCheong)
        }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(Color.cyberpunkDarkBg)
    .overlay(
        Rectangle()
            .fill(Color.joseonBorderDim)
            .frame(height: 1),
        alignment: .bottom
    )
}
```

**Step 2: footer "CONTINUE" → 한국어**

```swift
// 기존
Text("CONTINUE")
    .font(.cyberpunkTechnical())
    .foregroundColor(.cyberpunkYellow)
Text(">")
    ...

// 교체 후
Text("계속")
    .font(.cyberpunkCaption())
    .foregroundColor(.joseonHwang)
Text("▶")
    .font(.system(size: 10))
    .foregroundColor(.joseonHwang)
```

**Step 3: 선택지 메뉴 헤더 한국어화 (CyberpunkChoiceMenu)**

```swift
// 기존
Text("ACTION_MENU") ...
Text("[SELECT]") ...

// 교체 후
Text("선택")
    .font(.cyberpunkTechnical())
    .foregroundColor(.cyberpunkTextSecondary)
Text("▼")
    .font(.cyberpunkTechnical())
    .foregroundColor(.joseonHwang)
```

**Step 4: DATA_TRANSFER 텍스트 한국어화**

```swift
// 기존
Text("DATA_TRANSFER")
// 교체 후
Text("전송 중")
```

**Step 5: 빌드 확인**

```bash
xcodebuild -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"
```

**Step 6: 커밋**

```bash
git add way3/Components/CyberpunkComponents.swift
git commit -m "feat(ui): redesign dialogue box with 교서 style — dancheong bar, seal badge, Korean labels"
```

---

## Task 5: 퀘스트 카드 조선사이버펑크화 (CyberpunkQuestComponents.swift)

**Files:**
- Modify: `way3/Components/CyberpunkQuestComponents.swift`

**Step 1: Quest 제목 폰트 교체 + 영문 uppercase 라벨 한국어화**

```swift
// 기존
Text(quest.title.uppercased())
    .font(.cyberpunkHeading(size: 16))

// 교체 후 — ChosunCentennial 자동 적용 (Task 3 덕분)
Text(quest.title)  // uppercased() 제거
    .font(.cyberpunkHeading(size: 16))
    .foregroundColor(.cyberpunkTextPrimary)
```

```swift
// 기존
Text("CATEGORY: \(quest.category.uppercased())")
// 교체 후
Text("분류 · \(quest.category)")
    .font(.cyberpunkTechnical())
    .foregroundColor(.cyberpunkTextSecondary)
```

```swift
// 기존
Text("PROGRESS")
// 교체 후
Text("진행도")
```

```swift
// 기존
Text("REWARD_PACKAGE:")
// 교체 후
Text("보상 :")
```

**Step 2: 퀘스트 카드 좌측 타입 색상 바 추가**

`VStack(alignment: .leading, spacing: 16)` 의 body를 `HStack`으로 감싸 좌측에 4pt 색상 바 추가:

```swift
HStack(spacing: 0) {
    // 퀘스트 타입 색상 바
    Rectangle()
        .fill(questTypeColor(quest.category))
        .frame(width: 4)

    // 기존 VStack 내용 (패딩 좌측 12→16)
    VStack(alignment: .leading, spacing: 16) {
        // ... (기존 내용 유지)
    }
    .padding(.leading, 12)
}
```

```swift
// 퀘스트 타입 색상 헬퍼 (파일 내 private func 추가)
private func questTypeColor(_ category: String) -> Color {
    switch category.lowercased() {
    case "dialogue", "대화": return .joseonCheong
    case "delivery", "배달": return .joseonJeok
    case "trading", "거래":  return .joseonHwang
    default: return .cyberpunkBorder
    }
}
```

**Step 3: 빌드 + 커밋**

```bash
xcodebuild -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"

git add way3/Components/CyberpunkQuestComponents.swift
git commit -m "feat(ui): joseon-style quest cards — Korean labels, type color accent bar"
```

---

## Task 6: 프로필 스탯 바 오방색화 (CyberpunkProfileComponents.swift)

**Files:**
- Modify: `way3/Components/CyberpunkProfileComponents.swift`

**Step 1: 프로필 헤더 영문 라벨 한국어화**

```swift
// 기존
CyberpunkSectionHeader(
    title: "OPERATIVE_PROFILE",
    subtitle: "BIOMETRIC_ACCESS_GRANTED"
)
// 교체 후
CyberpunkSectionHeader(
    title: "상인 프로필",
    subtitle: "신원 인증 완료"
)
```

```swift
// 기존
Text("TRADER_ID:")
    .font(.cyberpunkTechnical())
    .foregroundColor(.cyberpunkTextSecondary)
// 교체 후
Text("상인 ID :")
    .font(.cyberpunkTechnical())
    .foregroundColor(.cyberpunkTextSecondary)
```

```swift
// 기존 — 이름 uppercase
Text(profile.core.name.uppercased())
// 교체 후 — 원본 이름
Text(profile.core.name)
    .font(.cyberpunkHeading())  // 이미 ChosunCentennial
```

**Step 2: 스탯 라벨 한자 포함 형식 추가 (스탯 바 컴포넌트 탐색 필요)**

스탯 표시 부분에서 "STR", "INT", "CHA", "LCK" 등의 라벨을 찾아:

```swift
// 기존 패턴
Text("STR")
Text("INT")
Text("CHA")
Text("LCK")

// 교체 후
Text("힘 (力)")
Text("지능 (智)")
Text("매력 (魅)")
Text("행운 (幸)")
```

**Step 3: 스탯 바 오방색 매핑**

스탯별 색상을 `CyberpunkProgressBar` 에 전달하는 부분 수정:

```swift
// 스탯 → 오방색 매핑
// 힘(力)   → joseonJeok  (赤·불·강렬함)
// 지능(智) → joseonCheong (靑·물·냉철함)
// 매력(魅) → Color(hex: "FF88BB") (분홍 — 별도)
// 행운(幸) → joseonHwang (黃·흙·풍요)

CyberpunkProgressBar(progress: strProgress,  color: .joseonJeok,  height: 3)
CyberpunkProgressBar(progress: intProgress,  color: .joseonCheong, height: 3)
CyberpunkProgressBar(progress: chaProgress,  color: Color(hex: "FF88BB"), height: 3)
CyberpunkProgressBar(progress: lckProgress,  color: .joseonHwang, height: 3)
```

**Step 4: 빌드 + 커밋**

```bash
xcodebuild -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"

git add way3/Components/CyberpunkProfileComponents.swift
git commit -m "feat(ui): Korean labels and 오방색 stat bars in profile components"
```

---

## Task 7: 내비게이션 상태 바 한국어화 (CyberpunkNavigationComponents.swift)

**Files:**
- Modify: `way3/Components/CyberpunkNavigationComponents.swift`

**Step 1: 영문 시스템 상태 라벨 한국어화**

```swift
// 기존
Text("SYSTEM_STATUS:")
Text("ONLINE")

// 교체 후
Text("시스템 :")
    .font(.cyberpunkTechnical())
    .foregroundColor(.cyberpunkTextSecondary)
Text("온라인")
    .font(.cyberpunkTechnical())
    .foregroundColor(.cyberpunkGreen)
```

```swift
// 기존 리소스 인디케이터 라벨
CyberpunkResourceIndicator(label: "CREDITS", ...)
CyberpunkResourceIndicator(label: "LVL", ...)
CyberpunkResourceIndicator(label: "SYNC", ...)

// 교체 후
CyberpunkResourceIndicator(label: "자금", ...)
CyberpunkResourceIndicator(label: "레벨", ...)
CyberpunkResourceIndicator(label: "동기화", ...)
```

**Step 2: 탭 바 레이블 확인 (MainTabView.swift)**

`Views/Game/MainTabView.swift` 를 읽고 탭 라벨이 이미 한국어인지 확인. 영문이면 동일 패턴으로 교체.

**Step 3: 빌드 + 커밋**

```bash
xcodebuild -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"

git add way3/Components/CyberpunkNavigationComponents.swift
git commit -m "feat(ui): Korean navigation labels and system status indicators"
```

---

## Task 8: 섹션 헤더 영문 라벨 전체 한국어화 (CyberpunkComponents.swift)

**Files:**
- Modify: `way3/Components/CyberpunkComponents.swift` — `CyberpunkSectionHeader`

**Step 1: 섹션 헤더 컴포넌트에서 uppercased() 제거**

```swift
// 기존 — CyberpunkSectionHeader.body
Text(title.uppercased())
    .font(.cyberpunkTitle())

// 교체 후
Text(title)  // ChosunCentennial + uppercased 제거
    .font(.cyberpunkTitle())
```

**Step 2: `cyberpunkStatusBar` View modifier 한국어화**

```swift
// 기존
Text(title.uppercased())
    .font(.cyberpunkTechnical())
Text(status)
    .font(.cyberpunkTechnical())
    .foregroundColor(.cyberpunkGreen)

// 교체 후
Text(title)
    .font(.cyberpunkTechnical())
// status는 호출자가 이미 한국어 전달 (변경 없음)
```

**Step 3: 빌드 + 커밋**

```bash
xcodebuild -scheme way3 \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD"

git add way3/Components/CyberpunkComponents.swift
git commit -m "feat(ui): remove uppercase on section headers, Korean labels throughout"
```

---

## Task 9: Memory 업데이트 및 최종 검증

**Files:**
- Modify: `/Users/kimsanghoon/.claude/projects/.../memory/MEMORY.md`

**Step 1: MEMORY.md 프로젝트명 업데이트**

```
프로젝트명: WAY3 → connect:seoul (2026-02-17 리브랜딩)
```

**Step 2: 시뮬레이터에서 전체 UI 흐름 확인**

수동으로 확인할 화면 체크리스트:
- [ ] 로그인 → StartView 화면: ChosunCentennial 타이틀 적용 확인
- [ ] 메인 맵 탭: 오방색 배경 확인
- [ ] 상인 탭 → 대화창: 단청 바, 도장 씰, 한국어 라벨 확인
- [ ] 퀘스트 탭: 타입 색상 바, 한국어 라벨 확인
- [ ] 프로필 탭: 오방색 스탯 바, 한자 포함 라벨 확인

**Step 3: 최종 커밋 + 태그**

```bash
git add .
git commit -m "feat(ui): connect:seoul 조선사이버펑크 UI 리디자인 P1 완료"
git tag v0.9.0-joseon-ui
```

---

## 요약 — 파일별 변경 범위

| 파일 | 변경 규모 | 위험도 |
|------|---------|--------|
| `Utils/CyberpunkDesignSystem.swift` | 색상 재배선 + 신규 컴포넌트 2개 추가 | 낮음 |
| `Extensions/Font+ChosunSystem.swift` | 변경 없음 (이미 잘 구성됨) | — |
| `Components/CyberpunkComponents.swift` | 대화창 헤더만 교체, 섹션 헤더 uppercase 제거 | 낮음 |
| `Components/CyberpunkQuestComponents.swift` | 라벨 한국어화 + 좌측 color bar 추가 | 낮음 |
| `Components/CyberpunkProfileComponents.swift` | 라벨 한국어화 + 스탯 오방색 | 낮음 |
| `Components/CyberpunkNavigationComponents.swift` | 라벨 한국어화 | 낮음 |
| `claudedocs/UI_CONCEPT_PROPOSAL.html` | 이름 치환 | 최소 |
| `CLAUDE.md` | 이름 치환 | 최소 |

**API 시그니처 변경 없음** — 기존 뷰 코드(StoryView, MerchantDetailView 등) 수정 불필요.
