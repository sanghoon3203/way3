# Trade 403 Error 진단 및 해결 가이드

## 🔴 문제 상황
`POST /api/trade/execute` 호출 시 **403 Forbidden** 에러 발생

---

## 🔍 원인 분석

서버 코드 `/Users/kimsanghoon/Documents/GitHub/way-server/src/routes/api/trade.js` 분석 결과:

### 403 에러가 발생하는 2가지 경우

#### 1️⃣ **라이센스 레벨 부족** (58-63번 줄)

```javascript
if (player.current_license < merchant.required_license) {
    return res.status(403).json({
        success: false,
        error: '라이센스 레벨이 부족합니다'
    });
}
```

**조건**:
- 플레이어의 `current_license` < 상인의 `required_license`

**예시**:
- 플레이어 라이센스: 0 (Beginner)
- 상인 요구 라이센스: 1 (Intermediate)
- → **403 에러 발생**

---

#### 2️⃣ **평판 부족** (65-70번 줄)

```javascript
if (player.reputation < merchant.reputation_requirement) {
    return res.status(403).json({
        success: false,
        error: '평판이 부족합니다'
    });
}
```

**조건**:
- 플레이어의 `reputation` < 상인의 `reputation_requirement`

**예시**:
- 플레이어 평판: 0
- 상인 요구 평판: 50
- → **403 에러 발생**

---

## 🛠️ 해결 방법

### 방법 1: 플레이어 데이터 확인 및 수정 (추천)

#### 1-1. 현재 플레이어 데이터 확인

**SQL 쿼리**:
```sql
SELECT
    id,
    name,
    current_license,
    reputation,
    money
FROM players
WHERE id = 'YOUR_PLAYER_ID';
```

**예상 결과**:
```
id                | name  | current_license | reputation | money
------------------|-------|-----------------|------------|-------
player_12345...   | 김상훈 | 0               | 0          | 10000
```

#### 1-2. 상인 요구사항 확인

**SQL 쿼리**:
```sql
SELECT
    id,
    name,
    required_license,
    reputation_requirement
FROM merchants
WHERE id = 'merchant_seoyena';
```

**예상 결과**:
```
id              | name   | required_license | reputation_requirement
----------------|--------|------------------|----------------------
merchant_seoyena| 서예나 | 0                | 0
```

#### 1-3. 문제 해결: 플레이어 데이터 업데이트

**시나리오 A: 상인 요구사항이 너무 높음**
```sql
-- 상인 요구사항 낮추기 (초기 테스트용)
UPDATE merchants
SET required_license = 0, reputation_requirement = 0
WHERE id = 'merchant_seoyena';
```

**시나리오 B: 플레이어 레벨/평판 올리기**
```sql
-- 플레이어 라이센스 & 평판 올리기
UPDATE players
SET current_license = 1, reputation = 100
WHERE id = 'YOUR_PLAYER_ID';
```

---

### 방법 2: 초기 플레이어 설정 확인

#### 신규 플레이어 생성 시 기본값 확인

**위치**: `way-server/src/routes/api/auth.js` (회원가입 부분)

```javascript
// 플레이어 생성 시 기본값
const player = {
    current_license: 0,      // ← 초보 라이센스
    reputation: 0,           // ← 평판 0
    money: 10000,            // ← 초기 자금
    // ...
};
```

**권장 초기값** (테스트용):
```javascript
const player = {
    current_license: 1,      // Intermediate 라이센스
    reputation: 100,         // 기본 평판
    money: 100000,           // 넉넉한 초기 자금
    // ...
};
```

---

### 방법 3: 서버 로직 임시 비활성화 (디버깅용)

**⚠️ 주의: 프로덕션에서는 사용하지 마세요!**

`trade.js:58-70` 주석 처리:

```javascript
// 거래 권한 확인 (임시 비활성화)
/*
if (player.current_license < merchant.required_license) {
    return res.status(403).json({
        success: false,
        error: '라이센스 레벨이 부족합니다'
    });
}

if (player.reputation < merchant.reputation_requirement) {
    return res.status(403).json({
        success: false,
        error: '평판이 부족합니다'
    });
}
*/
```

---

## 📋 디버깅 체크리스트

### 1. 서버 로그 확인

서버 콘솔에서 다음 로그 확인:

```
✅ 정상: 거래 완료: { playerId, merchantId, ... }
❌ 에러: 거래 실행 실패: <error>
```

### 2. 클라이언트 에러 응답 확인

iOS 앱 Xcode Console에서:

```swift
// 403 에러 시 응답 예시
{
    "success": false,
    "error": "라이센스 레벨이 부족합니다"
}
```

### 3. curl로 직접 테스트

```bash
# 1. 로그인해서 토큰 받기
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}' \
  | jq -r '.data.token')

# 2. 플레이어 정보 확인
curl -X GET http://localhost:3000/api/player/profile \
  -H "Authorization: Bearer $TOKEN"

# 3. 거래 API 호출
curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "merchantId": "merchant_seoyena",
    "itemTemplateId": "item_kimchi_01",
    "tradeType": "buy",
    "quantity": 1,
    "proposedPrice": 5000
  }'
```

---

## 🔧 데이터베이스 직접 수정 (SQLite)

### 방법 A: SQLite CLI 사용

```bash
# 1. 서버 디렉토리로 이동
cd /Users/kimsanghoon/Documents/GitHub/way-server

# 2. SQLite 데이터베이스 열기
sqlite3 game.db

# 3. 플레이어 정보 확인
SELECT id, name, current_license, reputation FROM players;

# 4. 플레이어 업데이트
UPDATE players
SET current_license = 2, reputation = 200, money = 500000
WHERE id = 'YOUR_PLAYER_ID';

# 5. 상인 요구사항 확인
SELECT id, name, required_license, reputation_requirement FROM merchants;

# 6. 상인 요구사항 낮추기 (필요 시)
UPDATE merchants SET required_license = 0, reputation_requirement = 0;

# 7. 종료
.exit
```

### 방법 B: DB Browser for SQLite (GUI)

1. **DB Browser for SQLite** 다운로드 (무료)
   - https://sqlitebrowser.org/

2. `game.db` 파일 열기
   - `/Users/kimsanghoon/Documents/GitHub/way-server/game.db`

3. **Browse Data** 탭에서:
   - `players` 테이블 → 플레이어 데이터 수정
   - `merchants` 테이블 → 상인 요구사항 수정

4. **Write Changes** 클릭

---

## 💡 장기 해결책

### 1. 게임 밸런스 조정

**초기 상인 설정**:
```javascript
// 초보자용 상인 (라이센스 0, 평판 0)
{
    id: 'merchant_seoyena',
    required_license: 0,
    reputation_requirement: 0
}

// 중급 상인 (라이센스 1, 평판 50)
{
    id: 'merchant_advanced',
    required_license: 1,
    reputation_requirement: 50
}
```

### 2. 튜토리얼 시스템 구현

```javascript
// 신규 플레이어에게 초기 부스트
const NEW_PLAYER_BONUS = {
    current_license: 1,
    reputation: 50,
    money: 50000
};
```

### 3. 명확한 에러 메시지 클라이언트 표시

**iOS 앱에서**:
```swift
if let error = response.error {
    if error.contains("라이센스") {
        showAlert(
            title: "라이센스 부족",
            message: "이 상인과 거래하려면 라이센스 레벨 \(requiredLevel)이 필요합니다."
        )
    } else if error.contains("평판") {
        showAlert(
            title: "평판 부족",
            message: "이 상인과 거래하려면 평판 \(requiredRep) 이상이 필요합니다."
        )
    }
}
```

---

## 🎯 빠른 해결 (권장)

**초기 개발/테스트 단계라면**:

### 옵션 1: 모든 상인 요구사항 제거

```sql
UPDATE merchants SET required_license = 0, reputation_requirement = 0;
```

### 옵션 2: 플레이어에게 최고 레벨 부여

```sql
UPDATE players SET current_license = 10, reputation = 1000, money = 10000000;
```

### 옵션 3: 서버 코드 수정 (임시)

```javascript
// trade.js:58-70 주석 처리
// 모든 거래 권한 체크 비활성화
```

---

## 📊 예상 데이터 구조

### players 테이블
```
id              | name  | current_license | reputation | money  | ...
----------------|-------|-----------------|------------|--------|----
player_abc123  | 테스터 | 0               | 0          | 10000  | ...
```

### merchants 테이블
```
id              | name   | required_license | reputation_requirement | ...
----------------|--------|------------------|------------------------|----
merchant_seoyena| 서예나  | 0                | 0                      | ...
merchant_pro    | 프로상점| 3                | 200                    | ...
```

---

## ✅ 해결 확인

다음 중 하나의 응답이 나오면 성공:

**성공 응답**:
```json
{
  "success": true,
  "message": "거래가 완료되었습니다",
  "data": {
    "tradeId": "...",
    "finalPrice": 15000,
    "experienceGained": 50
  }
}
```

**실패 응답 (다른 이유)**:
```json
{
  "success": false,
  "error": "돈이 부족합니다"  // ← 403이 아닌 400 에러
}
```

---

**작성일**: 2025-01-09
**문제**: 403 Forbidden - 라이센스/평판 부족
**상태**: 진단 완료
