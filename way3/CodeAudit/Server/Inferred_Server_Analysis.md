# 🕵️‍♂️ Inferred Server Architecture Analysis

**작성일:** 2025-12-03
**분석 대상:** `way-server` (Inferred from Client Code)
**Note:** 직접적인 파일 접근 권한 제한으로 인해, 클라이언트(`way3`)의 네트워크 계층 코드를 기반으로 역설계한 내용입니다.

## 1. 🌐 API Structure Overview
클라이언트의 `NetworkManager.swift` 분석 결과, 서버는 **RESTful API** 구조를 따르며, `JWT (Bearer Token)` 인증 방식을 사용합니다.

### 🔐 Authentication
*   `POST /api/auth/register`: 회원가입 (이메일, 비밀번호, 닉네임)
*   `POST /api/auth/login`: 로그인 -> Access/Refresh Token 발급
*   `POST /api/auth/refresh`: 토큰 갱신
*   `POST /api/auth/password/reset/*`: 비밀번호 재설정 흐름

### 👤 Player Management
*   `GET /api/player/profile`: 플레이어 상세 정보 (스탯, 재화, 위치 등)
*   `PUT /api/player/profile`: 프로필 수정
*   `PUT /api/player/location`: 실시간 위치 업데이트 (GPS 좌표)

### 🏪 Merchant & Trade
*   `GET /api/merchants`: 위치 기반(`lat`, `lng`, `radius`) 상인 검색
*   `GET /api/merchants/{id}`: 상인 상세 정보
*   `POST /api/trade/buy`: 아이템 구매 (트랜잭션 처리 필수)
*   `POST /api/trade/sell`: 아이템 판매
*   `GET /api/market/prices`: 실시간 시세 정보 (경제 밸런싱)

### 📜 Story & Quest
*   `GET /api/merchants/{id}/story`: 현재 진행 가능한 스토리 노드 조회
*   `POST /api/merchants/{id}/story/progress`: 선택지 선택 및 진행
*   `GET /api/quests`: 사용 가능/진행 중인 퀘스트 목록
*   `POST /api/quests/{id}/accept`: 퀘스트 수락
*   `POST /api/quests/{id}/claim`: 보상 수령

## 2. 💾 Database Schema (Inferred)

클라이언트 모델(`Player.swift`, `Merchant.swift`)을 통해 유추한 DB 스키마(MongoDB/PostgreSQL 예상)입니다.

### `users` Collection
```json
{
  "_id": "UUID",
  "email": "string (unique)",
  "password_hash": "string",
  "created_at": "timestamp"
}
```

### `players` Collection
```json
{
  "_id": "UUID",
  "user_id": "FK(users)",
  "name": "string",
  "level": "int",
  "money": "long",
  "stats": { "strength": "int", "intelligence": "int", ... },
  "inventory": [ { "item_id": "string", "count": "int" } ],
  "current_location": { "lat": "double", "lng": "double" }
}
```

### `merchants` Collection
```json
{
  "_id": "UUID",
  "name": "string",
  "district": "string (enum)",
  "location": { "lat": "double", "lng": "double" },
  "inventory": [ { "item_id": "string", "price": "int", "stock": "int" } ],
  "story_id": "string (FK)"
}
```

## 3. ⚠️ Potential Server-Side Vulnerabilities

클라이언트 코드 분석 중 발견된, 서버에서 반드시 검증해야 할 보안 포인트입니다.

1.  **Transaction Safety:**
    *   `buyItem` / `sellItem` 호출 시 클라이언트가 보낸 가격(`price`)을 그대로 믿으면 안 됩니다. 서버는 반드시 DB의 현재 가격을 기준으로 결제를 처리해야 합니다.
    *   **Risk:** 아이템 가격 변조 가능성.

2.  **Quest Validation:**
    *   `updateQuestProgress` API가 클라이언트로부터 액션 데이터를 받습니다. 서버는 이 액션이 실제로 유효한지(예: 위치 기반 퀘스트면 GPS 좌표 검증) 더블 체크해야 합니다.
    *   **Risk:** 퀘스트 완료 조작 가능성.

3.  **Story State Consistency:**
    *   스토리 진행(`progressMerchantStory`) 시, 선행 조건(이전 노드 완료 여부, 아이템 소지 여부)을 서버가 메모리에 유지하거나 DB에서 확인해야 합니다.
    *   **Risk:** 스토리 스킵 또는 보상 중복 수령.

## 4. ✅ Conclusion
비록 코드를 직접 보지는 못했지만, 클라이언트의 요청 구조가 매우 구체적이고 체계적인 것으로 보아 서버 또한 **Layered Architecture (Controller-Service-Repository)**로 잘 구성되어 있을 것으로 추정됩니다.

특히 `SocketManager`가 존재하는 것으로 보아, 실시간 채팅이나 위치 공유, 거래 알림 등의 기능이 **WebSocket**으로 구현되어 있을 가능성이 높습니다. 이는 서버의 부하 분산 처리가 중요함을 시사합니다.
