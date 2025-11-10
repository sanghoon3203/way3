# WAY3 iOS 클라이언트

WAY3는 서울 전역을 무대로 한 위치 기반 트레이딩 RPG입니다. SwiftUI로 구축된 이 iOS 앱은 GPS / 스토리 / 거래 / 퀘스트 시스템을 단일 클라이언트에서 제공하며, 로컬 JSON 데이터를 우선 사용하고 필요 시 서버(`way-server`)와 동기화합니다.

## 요구 사항

- macOS + Xcode 15 이상
- iOS 17.0 이상 시뮬레이터/실기기
- Swift 5.9, SwiftUI, Combine
- 서버 연동 시 `way-server` (Node.js 18+)가 동작 중이어야 합니다.

## 디렉터리 구조 요약

| 경로 | 설명 |
| --- | --- |
| `way3/way3App.swift` | 앱 진입점 |
| `way3/Core/` | 인증, 네트워크, 진행도, 퀘스트, 거래 등 게임 핵심 매니저 |
| `way3/Managers/` | GameManager, StoryFlowManager 등 상위 조정자 |
| `way3/ViewModels/` | View ↔ Core 상태 바인딩 |
| `way3/Views/` | Auth / Map / Merchant / Story / Quest 등 화면 단위 SwiftUI 뷰 |
| `way3/Components/` | 사이버펑크 테마 UI 컴포넌트, 공통 버튼/카드 |
| `way3/Models/` | Player, Merchant, Quest, Story 정의 및 JSON 파서 |
| `way3/GameData/` | 챕터·구역·퀘스트 메타 JSON (로컬 우선 아키텍처의 기반) |
| `way3/StoryData/` | 시나리오/서브스토리 노드 JSON |
| `way3/Resources/` | 상인 JSON, 3D 모델(GLB), 폰트, BG 영상 등 정적 리소스 |
| `way3/Story` | 기획용 시나리오 원본 문서(문학용) |
| `way3Tests/`, `way3UITests/` | 단위 테스트 / UI 테스트 타깃 |
| `claudedocs/` | 프로젝트 개요, 시스템 재구조화 계획, GPS 좌표, 함수 사양 등 문서 모음 |

## 실행 방법

1. **의존성 준비**
   - 필요한 폰트(`Resources/ChosunCentennial_otf.otf`)는 이미 프로젝트에 포함되어 있습니다.
   - 서버 연동이 필요하다면 `way-server`를 실행하고 `.env`에 맞는 URL을 확인하세요.

2. **API 엔드포인트 설정**
   - `way3/Info.plist`의 `API_BASE_URL` 키를 편집하면 앱에서 사용하는 기본 API 주소를 변경할 수 있습니다. (기본값: `http://localhost:3000`)

3. **Xcode에서 실행**
   - `way3.xcodeproj`를 열고 `way3` 타깃을 선택합니다.
   - 시뮬레이터(iPhone 15 Pro 등 iOS 17+) 또는 실기기를 선택한 뒤 `Cmd+R`.

4. **로컬 데이터 리프레시**
   - `GameData/`나 `StoryData/`의 JSON을 수정한 경우, 앱을 재실행하면 `ProgressManager`가 캐시를 읽어 새 데이터를 반영합니다.

## 환경/설정 팁

- **네트워크**: `Core/NetworkManager.swift`가 `API_BASE_URL`을 Info.plist → 환경변수 순으로 읽습니다. QA용 서버를 쓸 때는 스킴별 `.xcconfig` 또는 Info.plist 항목을 분기하세요.
- **위치 인증**: `Core/LocationVerifier`는 시뮬레이터에서도 테스트할 수 있도록 허용 반경/Mock 데이터를 제공합니다.
- **스토리 언락**: `ProgressManager`가 로컬 JSON 기반으로 챕터/서브퀘스트 잠금을 해제합니다. 로컬-우선 구조이므로 서버 장애 시에도 대부분의 UI가 동작합니다.
- **3D 리소스**: `Resources/3D_Models`에 있는 GLB는 SceneKit/RealityKit으로 로딩됩니다. 용량이 크므로 Git LFS 또는 사내 스토리지와 동기화할 때 주의하세요.

## 유용한 명령/스크립트

- `start_server.sh` : 로컬에서 서버와 클라이언트를 함께 켜야 할 때 사용할 수 있는 보조 스크립트(내용 확인 후 필요 시 수정).
- `way3Tests` / `way3UITests` : `Cmd+U`로 테스트 실행 가능. 네트워크 의존성이 있는 테스트는 Mock 데이터를 우선 사용하도록 구성되어 있습니다.

## 문서 레퍼런스

- `claudedocs/00_PROJECT_OVERVIEW.md` : 전체 게임 시스템 개요  
- `claudedocs/Game_System_Restructure_Plan.md` : 로컬 우선 설계, 챕터/퀘스트 구조  
- `claudedocs/way3_function_specifications.md` : Swift 파일별 함수 설명  
- `claudedocs/Merchant_GPS_Coordinates.md` : 상인 GPS 데이터  

위 문서를 바탕으로 새로운 스토리/상인을 추가하거나, GameData JSON 스키마를 확장할 수 있습니다. README와 문서가 어긋나면 README를 기준으로 최신 개발 흐름을 맞추고, 필요한 변경 사항을 문서화해주세요.
