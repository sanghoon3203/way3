# 🎨 Views Architecture Analysis

**작성일:** 2025-12-03
**분석 대상:** `way3/Views`

## 1. 🌟 Overview
`Views` 레이어는 SwiftUI를 기반으로 하며, `CyberpunkDesignSystem`을 적극 활용하여 독특한 비주얼 아이덴티티를 구축하고 있습니다. 특히 `StoryView`와 `MerchantDetailView`는 단순한 UI를 넘어 자체적인 상태 머신과 애니메이션 엔진을 내장한 복합 컴포넌트입니다.

## 2. 🔑 Key Components

### A. StoryView (`Story/StoryView.swift`)
*   **Visual Novel Engine:** `VNLoader`를 통해 JSON 노드를 로드하고, `TypewriterEngine`으로 텍스트를 출력하며, `SFXManager`로 사운드를 제어하는 등 **완전한 비주얼 노벨 엔진**이 뷰 내부에 통합되어 있습니다.
*   **Layered Rendering:** `ZStack`을 사용하여 배경 -> 캐릭터 -> 대화창 순으로 레이어를 쌓는 방식이 깔끔합니다.
*   **Interactive Elements:** 선택지(`DecisionChoiceList`)와 퀘스트 게이트(`handleQuestGateNode`) 처리가 뷰 내부에서 유기적으로 이루어집니다.

### B. MerchantDetailView (`Merchant/MerchantDetailView.swift`)
*   **All-in-One Controller:** 상인과의 대화, 거래(구매/판매), 스토리 진행, 퀘스트 수락 등 **모든 상호작용의 진입점**입니다.
*   **Tab Interface:** `Dialogue`, `Trade`, `Story` 3개의 탭으로 기능을 분리하여 복잡도를 낮추려 시도했습니다.
*   **TV Animation:** 탭 전환 시 `TVChannelSwitchTransition` 효과를 넣어 사이버펑크 감성을 살린 점이 인상적입니다.

### C. MainTabView (`Game/MainTabView.swift`)
*   **Custom Navigation:** 기본 `TabView`를 커스텀 래퍼(`CyberpunkEnhancedTabView`)로 감싸서 하단 바 스타일링을 통일했습니다.
*   **Integrated Hub:** 상점 탭(`ShopView` 대신 `StoryHubTabView`)에서 스토리와 쇼핑을 통합 제공하는 구조로 변경된 흔적이 보입니다.

## 3. ⚠️ Critical Findings & Recommendations

### 1. Massive View (거대 뷰 문제)
*   **문제:** `MerchantDetailView.swift` 파일이 너무 큽니다(2500+ 라인 추정). `MerchantInventoryView`, `PlayerInventoryView`, `FullScreenTradeView`, `StoryArchiveView` 등 독립적인 컴포넌트들이 하나의 파일에 정의되어 있어 가독성이 떨어지고 재사용이 어렵습니다.
*   **제안:** `Views/Merchant/Components/` 폴더를 만들고, 내부 컴포넌트들을 별도 파일로 분리(Extract Subview)해야 합니다.

### 2. Hardcoded Strings & Assets
*   **문제:** `ItemDetailView` 등에서 폰트 이름("ChosunCentennial")이 하드코딩되어 있습니다.
*   **제안:** `Font+ChosunSystem.swift`와 같은 디자인 시스템 확장을 일관되게 사용하도록 리팩토링해야 합니다.

### 3. Mixed Architecture
*   **문제:** 어떤 뷰는 `ViewModel`(`StoryViewModel`)을 사용하고, 어떤 뷰(`StoryChapterDetailView`)는 `EnvironmentObject`(`ProgressManager`)에 직접 의존합니다. 패턴이 혼재되어 데이터 흐름 추적이 어려울 수 있습니다.
*   **제안:** 복잡한 비즈니스 로직이 있는 뷰는 반드시 `ViewModel`을 경유하도록 통일하는 것이 좋습니다.

## 4. ✅ Conclusion
UI의 비주얼 퀄리티와 인터랙션(애니메이션, 타자기 효과 등)은 매우 우수합니다. 다만, `MerchantDetailView`와 같은 핵심 파일의 비대화 문제를 해결하고, 컴포넌트 분리 원칙을 더 철저히 지킨다면 유지보수성이 크게 향상될 것입니다.
