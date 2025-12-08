# 🏗️ Models Architecture Analysis

**작성일:** 2025-12-03
**분석 대상:** `way3/Models`

## 1. 🌟 Overview
`Models` 레이어는 앱의 데이터 구조와 비즈니스 로직의 기초를 담당합니다. `Codable` 프로토콜을 적극 활용하여 서버 통신 및 로컬 저장소와의 호환성을 확보하고 있으며, `Player` 모델을 중심으로 컴포넌트 기반 설계를 채택하여 유지보수성을 높였습니다.

## 2. 🔑 Key Components

### A. Player (`Player.swift`)
*   **Component Pattern:** `PlayerCore`, `PlayerStats`, `PlayerInventory`, `PlayerRelationships`, `PlayerAchievements` 등 기능별로 클래스를 분리하고, 메인 `Player` 클래스에서 이를 조합(Composition)하여 관리합니다. 이는 단일 책임 원칙(SRP)을 잘 준수한 사례입니다.
*   **ObservableObject:** `@Published` 프로퍼티 래퍼를 사용하여 데이터 변경 시 UI가 자동으로 업데이트되도록 설계되었습니다.
*   **Legacy Support:** 기존 코드와의 호환성을 위해 `extension`으로 편의 프로퍼티(`name`, `money` 등)를 제공하고 있어 점진적인 리팩토링이 가능합니다.

### B. Merchant (`Merchant.swift`)
*   **Server-Client Mapping:** `ServerMerchantResponse` 구조체를 통해 서버의 JSON 응답을 안전하게 파싱하고, `init(from:)` 생성자에서 로컬 `Merchant` 모델로 변환합니다.
*   **Flexible Attributes:** `personality`, `type`, `storyRole` 등 다양한 속성을 `Enum`으로 관리하여 상인의 개성을 데이터 주도적으로 정의할 수 있습니다.
*   **Logic Encapsulation:** `canTrade`, `getFinalPrice` 등의 메서드를 모델 내부에 포함시켜 비즈니스 로직이 뷰나 컨트롤러로 유출되는 것을 방지했습니다.

### C. Story Structure (`StoryChapterDefinition.swift`)
*   **Hierarchical Data:** `Chapter` -> `District` -> `Episode`로 이어지는 계층 구조를 명확히 정의했습니다.
*   **Unlock Condition System:** `StoryUnlockCondition`을 통해 퀘스트, 아이템, 에피소드 완료 등 다양한 해금 조건을 유연하게 처리합니다. `isSatisfied(by:)` 메서드를 통해 조건을 검사하는 로직이 깔끔합니다.
*   **Repository Pattern:** `StoryChapterRepository`를 통해 정적 JSON 데이터를 로딩하는 로직을 캡슐화했습니다.

### D. Quest System (`QuestModels.swift`)
*   **Rich Metadata:** `QuestData`, `SubQuest` 등의 모델이 퀘스트의 상태, 보상, 요구 조건을 상세하게 정의하고 있습니다.
*   **Hashable & Identifiable:** `SwiftUI` 리스트 렌더링에 최적화되어 있습니다.

## 3. ⚠️ Critical Findings & Recommendations

### 1. Data Consistency (데이터 일관성)
*   **문제:** `Player` 클래스의 `init(from decoder:)`에서 런타임 데이터(`sessionStartTime`)를 초기화하지만, `isOnline`과 같은 상태값은 저장된 값을 불러옵니다. 앱이 비정상 종료된 후 재시작할 때 `isOnline`이 `true`로 남아있을 수 있습니다.
*   **제안:** `decoder` 초기화 시 일부 런타임 상태값은 항상 기본값(`false` 등)으로 강제 초기화하는 것이 안전합니다.

### 2. Enum Hardcoding (열거형 하드코딩)
*   **문제:** `MerchantType`과 `ItemCategory`의 `iconName`이나 `color`가 코드 내에 하드코딩되어 있습니다. 테마 변경이나 디자인 시스템 업데이트 시 유지보수가 어려울 수 있습니다.
*   **제안:** 별도의 `DesignSystem`이나 `ThemeManager`를 통해 색상과 아이콘을 관리하고, Enum은 시맨틱한 키값만 반환하도록 리팩토링하는 것이 좋습니다.

### 3. Hardcoded Strings in Repository
*   **문제:** `StoryChapterRepository`에서 파일명 `"story_main_chapters"`가 코드에 박혀 있습니다.
*   **제안:** `Constants` 구조체나 설정 파일로 분리하여 관리하세요.

## 4. ✅ Conclusion
전반적으로 데이터 모델링이 매우 견고하며, 특히 `Player` 모델의 컴포넌트화와 `StoryChapterDefinition`의 유연한 구조는 확장성이 뛰어납니다. 몇 가지 사소한 하드코딩 이슈만 해결하면 엔터프라이즈급 프로젝트로 손색이 없습니다.
