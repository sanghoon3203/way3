# 🧠 Core & Managers Architecture Analysis

**작성일:** 2025-12-03
**분석 대상:** `way3/Core`, `way3/Managers`

## 1. 🌟 Overview
`Core`와 `Managers` 레이어는 앱의 두뇌에 해당합니다. 네트워크 통신, 인증, 로깅, 상태 관리 등 앱의 핵심 인프라를 제공하며, 대부분 Singleton 패턴을 사용하여 전역적인 접근성을 확보하고 있습니다. 특히 `Concurrency`(`async/await`)와 `Actor` 모델을 적극 도입하여 스레드 안전성을 강화한 점이 돋보입니다.

## 2. 🔑 Key Components

### A. NetworkManager (`Core/NetworkManager.swift`)
*   **Robust Error Handling:** `NetworkError` 열거형을 통해 클라이언트/서버 에러를 세분화하고, `retry` 로직을 내장하여 네트워크 불안정성에 대비했습니다.
*   **Thread Safety:** `_activeRequests`와 `_requestCache` 접근 시 `DispatchQueue(barrier)`를 사용하여 동시성 문제를 해결했습니다.
*   **Configuration:** 환경 변수(`#if DEBUG`)에 따라 Base URL과 타임아웃을 동적으로 설정하는 유연함을 갖췄습니다.

### B. AuthManager (`Core/AuthManager.swift`)
*   **Secure Storage:** 민감한 토큰 정보는 `SecureStorage`(Keychain)에 저장하고, 일반 프로필 정보는 `UserDefaults`에 저장하는 **하이브리드 저장 전략**을 사용하여 보안과 성능의 균형을 맞췄습니다.
*   **Token Refresh:** 401 에러 발생 시 자동으로 토큰 갱신(`refreshAuthToken`)을 시도하고 요청을 재개하는 `Interceptor` 패턴이 구현되어 있습니다.

### C. GameLogger (`Core/GameLogger.swift`)
*   **Structured Logging:** 단순 `print`가 아닌 `OSLog`를 사용하여 시스템 콘솔에서 필터링이 가능하도록 설계되었습니다.
*   **Performance Monitoring:** `PerformanceMeasurement` 구조체를 통해 특정 작업의 소요 시간을 측정하고 경고(`warning`)를 남기는 기능은 최적화에 매우 유용합니다.

### D. Story Managers (`Managers/`)
*   **StoryFlowManager:** 스토리 진행, 퀘스트 연동, 보상 지급 등 스토리의 라이프사이클을 총괄합니다.
*   **StoryRewardService:** 챕터 보상 지급 시 서버와의 동기화를 담당하여, 오프라인 치팅을 방지합니다.

## 3. ⚠️ Critical Findings & Recommendations

### 1. Singleton Dependency Cycle
*   **문제:** `AuthManager`가 `NetworkManager`를 사용하고, `NetworkManager`가 `AuthManager`의 상태(로그아웃 등)를 변경하는 상호 의존성이 존재합니다.
*   **제안:** 인증 상태 관리를 별도의 `AuthStateObserver` 프로토콜로 분리하거나, 의존성 주입(DI) 컨테이너를 도입하여 결합도를 낮춰야 합니다.

### 2. Manual JSON Parsing
*   **문제:** `NetworkManager`의 `performRequest` 내부에서 JSON 디코딩 실패 시, 에러 원인을 찾기 위한 디버깅 코드가 산재해 있어 코드가 다소 지저분합니다.
*   **제안:** 제네릭 디코더 함수로 로직을 분리하고, 디코딩 에러 시 자동으로 JSON 구조를 덤프하는 유틸리티를 만드는 것이 좋습니다.

### 3. Hardcoded Cache Keys
*   **문제:** 캐시 키(`auth_token`, `player_data` 등)가 문자열 리터럴로 관리되고 있습니다.
*   **제안:** `Keys` 열거형이나 `Constants` 구조체로 통합 관리하여 오타로 인한 버그를 방지해야 합니다.

## 4. ✅ Conclusion
Core 레이어는 **엔터프라이즈급 앱**에서 요구되는 안정성과 확장성을 갖추고 있습니다. 특히 네트워크 모듈의 완성도가 높으며, 로깅 시스템은 상용화 수준입니다. 싱글톤 간의 의존성 문제만 해결한다면 더욱 완벽한 아키텍처가 될 것입니다.
