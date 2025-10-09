# Trade API Communication Flow

## 📱 거래 통신 흐름 전체 설명

### 1️⃣ 사용자 액션: 거래 실행 버튼 클릭

**위치**: `MerchantDetailViewExtensions.swift:555`

```swift
Task { await executeTradeForCart() }
```

사용자가 "거래 실행하기" 버튼을 누르면:
- `CartDetailView`의 거래 실행 버튼이 트리거됨
- `executeTradeForCart()` 비동기 함수 호출

---

### 2️⃣ 거래 실행 함수: `executeTradeForCart()`

**위치**: `MerchantDetailViewExtensions.swift:129-184`

```swift
private func executeTradeForCart() async {
    let merchantId = merchant.id

    // 1. 로딩 시작
    await MainActor.run { viewModel.isLoading = true }

    do {
        // 2. 장바구니의 각 아이템마다 개별 API 호출
        for cartItem in cartManager.items {
            let request = TradeExecuteRequest(
                merchantId: merchantId,
                itemTemplateId: cartItem.item.itemId,
                tradeType: cartItem.type.rawValue,  // "buy" or "sell"
                quantity: cartItem.quantity,
                proposedPrice: proposedPrice(for: cartItem)
            )

            // 3. API 호출
            let response = try await NetworkManager.shared.executeTrade(request: request)

            // 4. 실패 처리
            if !response.success {
                throw TradeExecutionError(message: response.error ?? "거래에 실패했습니다")
            }
        }

        // 5. 성공 시: 플레이어 & 상인 데이터 새로고침
        await gameManager.refreshPlayerData()
        await viewModel.refreshMerchantData()

        // 6. UI 업데이트
        await MainActor.run {
            cartManager.clearCart()
            showPurchaseConfirmation = false
            isCartPresented = false
            viewModel.isLoading = false
            selectTab(.dialogue)
            gameManager.addNotification(title: "거래 완료", ...)
        }

    } catch {
        // 7. 에러 처리
        await MainActor.run {
            viewModel.error = MerchantDataError.tradeExecutionFailed(...)
            viewModel.isLoading = false
        }
    }
}
```

**중요 포인트**:
- ✅ **장바구니의 각 아이템마다 개별 API 호출** (배치 처리 아님)
- ✅ **순차 실행**: 첫 번째 아이템 거래 → 두 번째 아이템 거래 → ...
- ✅ **실패 시 즉시 중단**: 하나라도 실패하면 전체 중단

---

### 3️⃣ NetworkManager: `executeTrade()`

**위치**: `NetworkManager.swift:749-765`

```swift
func executeTrade(request: TradeExecuteRequest) async throws -> TradeExecuteResponse {
    let body: [String: Any] = [
        "merchantId": request.merchantId,
        "itemTemplateId": request.itemTemplateId,
        "tradeType": request.tradeType,        // "buy" or "sell"
        "quantity": request.quantity,
        "proposedPrice": request.proposedPrice
    ]

    return try await makeRequest(
        endpoint: "/trade/execute",
        method: .POST,
        body: body,
        requiresAuth: true,
        responseType: TradeExecuteResponse.self
    )
}
```

**HTTP 요청 정보**:
- **Method**: `POST`
- **Endpoint**: `/trade/execute`
- **Headers**: `Authorization: Bearer <token>` (필수)
- **Body (JSON)**:
  ```json
  {
    "merchantId": "merchant_seoyena",
    "itemTemplateId": "item_kimchi_01",
    "tradeType": "buy",
    "quantity": 5,
    "proposedPrice": 15000
  }
  ```

---

### 4️⃣ 서버 응답 형식

**위치**: `NetworkManager.swift:974-991`

```swift
struct TradeExecuteResponse: Codable {
    let success: Bool
    let message: String?
    let data: TradeExecuteData?
    let error: String?
}

struct TradeExecuteData: Codable {
    let tradeId: String?
    let tradeType: String?
    let itemName: String?
    let quantity: Int?
    let finalPrice: Int?
    let profit: Int?
    let experienceGained: Int?
    let relationshipChange: TradeRelationshipChange?
    let timestamp: String?
}
```

**성공 응답 예시**:
```json
{
  "success": true,
  "message": "거래가 성공적으로 완료되었습니다",
  "data": {
    "tradeId": "trade_12345",
    "tradeType": "buy",
    "itemName": "김치",
    "quantity": 5,
    "finalPrice": 15000,
    "profit": 0,
    "experienceGained": 50,
    "relationshipChange": {
      "friendship": 5,
      "trust": 3
    },
    "timestamp": "2025-01-09T10:30:00Z"
  }
}
```

**실패 응답 예시**:
```json
{
  "success": false,
  "message": null,
  "data": null,
  "error": "플레이어의 돈이 부족합니다"
}
```

---

## 🔍 통신이 안 되는 이유 진단

### 체크리스트:

#### 1️⃣ **서버 연결 확인**
```swift
// NetworkManager.swift
private let baseURL = "YOUR_SERVER_URL"  // ← 서버 주소 확인!
```
- ❓ `baseURL`이 올바르게 설정되어 있나요?
- ❓ 서버가 실행 중인가요?

#### 2️⃣ **인증 토큰 확인**
거래 API는 `requiresAuth: true`입니다.
```swift
// NetworkManager.swift:762
requiresAuth: true
```

**토큰 확인 방법**:
1. 로그인이 성공했나요?
2. `NetworkManager.shared.authToken`에 토큰이 있나요?
3. 토큰이 만료되지 않았나요?

#### 3️⃣ **API 엔드포인트 확인**
```
POST /trade/execute
```
- ❓ 서버에 `/trade/execute` 엔드포인트가 구현되어 있나요?
- ❓ POST 메서드를 받나요?

#### 4️⃣ **요청 Body 형식 확인**
서버가 기대하는 형식:
```json
{
  "merchantId": "string",
  "itemTemplateId": "string",
  "tradeType": "buy" | "sell",
  "quantity": number,
  "proposedPrice": number
}
```

---

## 🐛 디버깅 방법

### 1. 네트워크 로그 확인

`NetworkManager.swift`의 `makeRequest` 함수에서 로그를 확인:

```swift
// 요청 로그
print("🌐 Request: \(method.rawValue) \(endpoint)")
print("📦 Body: \(String(data: bodyData, encoding: .utf8) ?? "nil")")

// 응답 로그
print("✅ Response: \(response)")
```

### 2. Xcode Console에서 확인할 것

**성공 시**:
```
🌐 Request: POST /trade/execute
📦 Body: {"merchantId":"merchant_seoyena","itemTemplateId":"item_kimchi_01","tradeType":"buy","quantity":5,"proposedPrice":15000}
✅ Response: {"success":true,"message":"거래가 성공적으로 완료되었습니다",...}
```

**실패 시 (서버 연결 실패)**:
```
❌ Network error: URLError(.cannotConnectToHost)
```

**실패 시 (인증 실패)**:
```
❌ HTTP 401 Unauthorized
```

**실패 시 (서버 에러)**:
```
✅ Response: {"success":false,"error":"플레이어의 돈이 부족합니다"}
```

### 3. 서버 엔드포인트 테스트 (curl)

터미널에서 직접 API 호출 테스트:

```bash
# 1. 로그인해서 토큰 받기
curl -X POST http://YOUR_SERVER/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}'

# 응답: {"success":true,"data":{"token":"eyJhbGc..."}}

# 2. 토큰으로 거래 API 호출
curl -X POST http://YOUR_SERVER/trade/execute \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGc..." \
  -d '{
    "merchantId": "merchant_seoyena",
    "itemTemplateId": "item_kimchi_01",
    "tradeType": "buy",
    "quantity": 5,
    "proposedPrice": 15000
  }'
```

---

## 🔧 자주 발생하는 문제와 해결

### ❌ 문제 1: "거래에 실패했습니다"
**원인**: 서버가 `success: false` 반환
**해결**: 서버 로그 확인 → 비즈니스 로직 오류 (돈 부족, 재고 없음 등)

### ❌ 문제 2: "Network error"
**원인**: 서버 연결 불가
**해결**:
1. `baseURL` 확인
2. 서버 실행 여부 확인
3. 네트워크 연결 확인

### ❌ 문제 3: "401 Unauthorized"
**원인**: 인증 토큰 없음 or 만료
**해결**:
1. 로그인 다시 하기
2. `authToken` 확인
3. 토큰 갱신 로직 구현

### ❌ 문제 4: "itemTemplateId not found"
**원인**: 서버에 해당 아이템 템플릿이 없음
**해결**:
1. `itemTemplateId` 값 확인 (`cartItem.item.itemId`)
2. 서버 DB에 해당 아이템이 있는지 확인

---

## 💡 개선 제안

### 1. 배치 거래 API 구현
현재는 아이템마다 개별 API 호출입니다. 성능 개선을 위해 배치 API 추천:

```swift
// 개선안
func executeBatchTrade(requests: [TradeExecuteRequest]) async throws -> BatchTradeResponse {
    return try await makeRequest(
        endpoint: "/trade/execute/batch",
        method: .POST,
        body: ["trades": requests],
        requiresAuth: true,
        responseType: BatchTradeResponse.self
    )
}
```

### 2. 재시도 로직
네트워크 일시적 오류 대응:

```swift
func executeTradeWithRetry(request: TradeExecuteRequest, maxRetries: Int = 3) async throws -> TradeExecuteResponse {
    for attempt in 1...maxRetries {
        do {
            return try await executeTrade(request: request)
        } catch {
            if attempt == maxRetries { throw error }
            try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
        }
    }
    fatalError("Unreachable")
}
```

### 3. 낙관적 UI 업데이트
거래 전에 UI 먼저 업데이트, 실패 시 롤백:

```swift
// 1. UI 즉시 업데이트 (낙관적)
updateUIOptimistically()

// 2. API 호출
do {
    try await executeTrade(...)
} catch {
    // 3. 실패 시 롤백
    rollbackUIChanges()
}
```

---

**작성일**: 2025-01-09
**버전**: Way3 v1.0
