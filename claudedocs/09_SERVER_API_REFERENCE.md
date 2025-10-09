# Way3 Server API Reference

Complete API documentation for the Way3 backend server.

## 🌐 Base URL

```
Development: http://localhost:3000
Production: https://way3_production.railway.app
```

## 🔐 Authentication

### JWT Authentication (Mobile App)

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Token Refresh Flow**:
1. Access token expires (15min)
2. Use refresh token to get new access token
3. Update stored tokens

### Session Authentication (Admin Panel)

**Cookies**: Automatic session cookie management
**Duration**: 24 hours

## 📋 Response Format

### Success Response
```json
{
  "success": true,
  "data": { /* response data */ },
  "message": "Operation successful",
  "timestamp": "2025-10-05T12:00:00.000Z"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error type",
  "message": "Detailed error message",
  "timestamp": "2025-10-05T12:00:00.000Z"
}
```

## 🔑 Authentication Endpoints

### POST /api/auth/register

Register new user account.

**Request**:
```json
{
  "email": "player@example.com",
  "password": "SecurePassword123!",
  "name": "플레이어이름"
}
```

**Response** (201):
```json
{
  "success": true,
  "data": {
    "userId": "uuid-here",
    "email": "player@example.com",
    "accessToken": "jwt-access-token",
    "refreshToken": "jwt-refresh-token"
  }
}
```

**Errors**:
- `400` - Invalid email or password format
- `409` - Email already registered

### POST /api/auth/login

Login to existing account.

**Request**:
```json
{
  "email": "player@example.com",
  "password": "SecurePassword123!"
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "userId": "uuid-here",
    "email": "player@example.com",
    "accessToken": "jwt-access-token",
    "refreshToken": "jwt-refresh-token",
    "player": {
      "id": "player-uuid",
      "name": "플레이어이름",
      "level": 5,
      "money": 125000
    }
  }
}
```

**Errors**:
- `401` - Invalid credentials
- `404` - User not found

### POST /api/auth/refresh

Refresh access token using refresh token.

**Request**:
```json
{
  "refreshToken": "jwt-refresh-token"
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "accessToken": "new-jwt-access-token"
  }
}
```

**Errors**:
- `401` - Invalid or expired refresh token

## 👤 Player Endpoints

### GET /api/player

Get current player data.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "player-uuid",
    "userId": "user-uuid",
    "name": "플레이어이름",
    "money": 125000,
    "level": 5,
    "experience": 450,
    "currentLicense": 1,
    "stats": {
      "strength": 15,
      "intelligence": 12,
      "charisma": 18,
      "luck": 10
    },
    "skills": {
      "tradingSkill": 25,
      "negotiationSkill": 30,
      "appraisalSkill": 18
    },
    "inventory": [
      {
        "id": "item-uuid",
        "name": "고급 도자기",
        "quantity": 2,
        "basePrice": 50000
      }
    ]
  }
}
```

### PUT /api/player

Update player data.

**Auth**: Required

**Request**:
```json
{
  "money": 130000,
  "experience": 500,
  "stats": {
    "strength": 16
  }
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "updated": true,
    "player": { /* updated player data */ }
  }
}
```

### POST /api/player/level-up

Process player level up.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "newLevel": 6,
    "statPointsGained": 3,
    "skillPointsGained": 1,
    "rewards": {
      "money": 5000,
      "inventorySlots": 1
    }
  }
}
```

## 🏪 Merchant Endpoints

### GET /api/merchants

Get all merchants or filter by district.

**Query Parameters**:
- `district` (optional): Filter by Seoul district
- `license` (optional): Filter by required license level

**Response** (200):
```json
{
  "success": true,
  "data": [
    {
      "id": "merchant-uuid",
      "name": "서예나",
      "type": "specialty",
      "district": "강남구",
      "location": {
        "lat": 37.4979,
        "lng": 127.0276
      },
      "requiredLicense": 1,
      "imageFilename": "Seoyena.png",
      "gifFilename": "Seoyena.gif",
      "description": "전통 공예품 전문 상인",
      "inventory": [
        "item-uuid-1",
        "item-uuid-2"
      ]
    }
  ]
}
```

### GET /api/merchants/:id

Get specific merchant details.

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "merchant-uuid",
    "name": "서예나",
    "type": "specialty",
    "district": "강남구",
    "location": { "lat": 37.4979, "lng": 127.0276 },
    "requiredLicense": 1,
    "imageUrl": "/uploads/merchants/Seoyena.png",
    "gifUrl": "/uploads/merchants/Seoyena.gif",
    "description": "전통 공예품 전문 상인",
    "dialogueData": {
      "greeting": "어서오세요!",
      "trade": "좋은 물건을 가져오셨군요",
      "goodbye": "또 오세요!"
    },
    "inventory": [
      {
        "id": "item-uuid",
        "name": "청자 꽃병",
        "category": "공예품",
        "grade": 2,
        "basePrice": 80000,
        "currentPrice": 85000,
        "description": "고려시대 양식의 청자 꽃병"
      }
    ]
  }
}
```

## 💰 Trade Endpoints

### POST /api/trade/buy

Purchase item from merchant.

**Auth**: Required

**Request**:
```json
{
  "playerId": "player-uuid",
  "merchantId": "merchant-uuid",
  "itemId": "item-uuid",
  "quantity": 1,
  "agreedPrice": 85000
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "transactionId": "trade-uuid",
    "type": "buy",
    "itemName": "청자 꽃병",
    "quantity": 1,
    "totalPrice": 85000,
    "playerMoneyBefore": 125000,
    "playerMoneyAfter": 40000,
    "experienceGained": 850,
    "skillImprovement": {
      "tradingSkill": 26,
      "negotiationSkill": 31
    },
    "timestamp": "2025-10-05T12:00:00.000Z"
  }
}
```

**Errors**:
- `400` - Insufficient funds, inventory full
- `404` - Item or merchant not found
- `403` - License requirement not met

### POST /api/trade/sell

Sell item to merchant.

**Auth**: Required

**Request**:
```json
{
  "playerId": "player-uuid",
  "merchantId": "merchant-uuid",
  "itemId": "item-uuid-in-inventory",
  "quantity": 1,
  "agreedPrice": 90000
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "transactionId": "trade-uuid",
    "type": "sell",
    "itemName": "청자 꽃병",
    "quantity": 1,
    "totalPrice": 90000,
    "profit": 5000,
    "profitPercentage": 5.88,
    "playerMoneyAfter": 130000,
    "experienceGained": 900
  }
}
```

### GET /api/trade/history

Get player's trade history.

**Auth**: Required

**Query Parameters**:
- `limit` (optional): Number of records (default: 50)
- `offset` (optional): Pagination offset

**Response** (200):
```json
{
  "success": true,
  "data": {
    "trades": [
      {
        "id": "trade-uuid",
        "type": "buy",
        "merchantName": "서예나",
        "itemName": "청자 꽃병",
        "price": 85000,
        "timestamp": "2025-10-05T12:00:00.000Z"
      }
    ],
    "total": 150,
    "hasMore": true
  }
}
```

## 🎯 Quest Endpoints

### GET /api/quests

Get all available quests.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": [
    {
      "id": "quest-uuid",
      "title": "첫 거래",
      "description": "상인과 첫 거래를 완료하세요",
      "type": "tutorial",
      "requiredLevel": 1,
      "objectives": [
        {
          "type": "trade",
          "target": "any",
          "count": 1,
          "current": 0
        }
      ],
      "rewards": {
        "experience": 100,
        "money": 5000,
        "items": []
      },
      "status": "available"
    }
  ]
}
```

### GET /api/quests/:id

Get specific quest details.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "quest-uuid",
    "title": "첫 거래",
    "description": "상인과 첫 거래를 완료하세요",
    "longDescription": "거래의 세계에 첫 발을 내딛는 중요한 순간입니다...",
    "type": "tutorial",
    "requiredLevel": 1,
    "objectives": [
      {
        "id": "obj-1",
        "type": "trade",
        "description": "아무 상인과 거래",
        "target": "any",
        "requiredCount": 1,
        "currentCount": 0,
        "completed": false
      }
    ],
    "rewards": {
      "experience": 100,
      "money": 5000,
      "items": [],
      "title": "초보 상인"
    },
    "playerProgress": {
      "status": "in_progress",
      "startedAt": "2025-10-05T10:00:00.000Z",
      "completionPercentage": 0
    }
  }
}
```

### POST /api/quests/:id/start

Start a quest.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "questId": "quest-uuid",
    "status": "in_progress",
    "startedAt": "2025-10-05T12:00:00.000Z"
  }
}
```

### POST /api/quests/:id/complete

Complete a quest and claim rewards.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "questId": "quest-uuid",
    "status": "completed",
    "completedAt": "2025-10-05T12:30:00.000Z",
    "rewards": {
      "experience": 100,
      "money": 5000,
      "items": [],
      "title": "초보 상인"
    },
    "playerUpdates": {
      "experience": 550,
      "money": 135000,
      "newLevel": null
    }
  }
}
```

## 🏆 Achievement Endpoints

### GET /api/achievements

Get all achievements and player progress.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "achievements": [
      {
        "id": "ach-uuid",
        "name": "백 번의 거래",
        "description": "100번의 거래를 완료하세요",
        "category": "trading",
        "iconName": "trophy.fill",
        "requirement": 100,
        "rewardPoints": 500,
        "playerProgress": {
          "unlocked": false,
          "progress": 45,
          "percentage": 45.0
        }
      }
    ],
    "totalAchievements": 50,
    "unlockedCount": 12,
    "totalPoints": 2400
  }
}
```

### POST /api/achievements/:id/unlock

Unlock achievement (triggered by game logic).

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "achievementId": "ach-uuid",
    "name": "백 번의 거래",
    "unlockedAt": "2025-10-05T12:00:00.000Z",
    "rewards": {
      "points": 500,
      "title": "거래왕"
    }
  }
}
```

## 💼 Personal Items Endpoints

### GET /api/personal-items

Get player's inventory items.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "inv-item-uuid",
        "itemId": "item-uuid",
        "name": "청자 꽃병",
        "category": "공예품",
        "grade": 2,
        "quantity": 2,
        "purchasePrice": 85000,
        "purchaseDate": "2025-10-05T12:00:00.000Z",
        "currentMarketPrice": 90000,
        "potentialProfit": 5000
      }
    ],
    "totalItems": 15,
    "maxInventorySize": 25,
    "totalValue": 850000
  }
}
```

### POST /api/personal-items

Add item to inventory (used after trade).

**Auth**: Required

**Request**:
```json
{
  "itemId": "item-uuid",
  "quantity": 1,
  "purchasePrice": 85000
}
```

**Response** (201):
```json
{
  "success": true,
  "data": {
    "id": "inv-item-uuid",
    "itemId": "item-uuid",
    "quantity": 1,
    "addedAt": "2025-10-05T12:00:00.000Z"
  }
}
```

### DELETE /api/personal-items/:id

Remove item from inventory.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "removed": true,
    "itemId": "inv-item-uuid"
  }
}
```

## 🎮 Skills Endpoints

### GET /api/skills

Get all skills and player levels.

**Auth**: Required

**Response** (200):
```json
{
  "success": true,
  "data": {
    "skills": [
      {
        "id": "skill-trading",
        "name": "거래 기술",
        "description": "일반 거래 숙련도",
        "category": "trading",
        "maxLevel": 100,
        "playerLevel": 25,
        "experience": 12500,
        "nextLevelExp": 13000,
        "benefits": "거래 성공률 +25%, 수수료 -5%"
      },
      {
        "id": "skill-negotiation",
        "name": "협상 기술",
        "description": "가격 협상 능력",
        "category": "social",
        "maxLevel": 100,
        "playerLevel": 30,
        "experience": 15000,
        "nextLevelExp": 15500,
        "benefits": "가격 할인 +15%"
      }
    ]
  }
}
```

### POST /api/skills/:id/improve

Improve skill (costs skill points).

**Auth**: Required

**Request**:
```json
{
  "pointsToSpend": 1
}
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "skillId": "skill-trading",
    "newLevel": 30,
    "skillPointsRemaining": 2,
    "improvements": "+5% trade success rate"
  }
}
```

## 📊 Health & Monitoring

### GET /health

Server health check (no auth required).

**Response** (200):
```json
{
  "status": "healthy",
  "timestamp": "2025-10-05T12:00:00.000Z",
  "uptime": 86400,
  "memory": {
    "rss": 52428800,
    "heapTotal": 18874368,
    "heapUsed": 12345678
  },
  "version": "v18.0.0"
}
```

## 🔌 WebSocket Events

### Client → Server

**updateLocation**
```json
{
  "playerId": "player-uuid",
  "lat": 37.4979,
  "lng": 127.0276
}
```

**joinLocationGroup**
```json
{
  "district": "강남구"
}
```

**sendTradeOffer**
```json
{
  "toPlayerId": "other-player-uuid",
  "itemsOffered": ["item-uuid-1"],
  "itemsRequested": ["item-uuid-2"],
  "message": "좋은 거래 제안입니다!"
}
```

### Server → Client

**nearbyPlayersUpdate**
```json
{
  "players": [
    {
      "id": "player-uuid",
      "name": "플레이어1",
      "level": 5,
      "distance": 250
    }
  ]
}
```

**tradeActivity**
```json
{
  "playerId": "player-uuid",
  "playerName": "플레이어1",
  "merchantName": "서예나",
  "itemName": "청자 꽃병",
  "tradeType": "sell",
  "isProfit": true,
  "timestamp": "2025-10-05T12:00:00.000Z"
}
```

**marketPriceUpdate**
```json
{
  "itemName": "청자 꽃병",
  "oldPrice": 85000,
  "newPrice": 90000,
  "district": "강남구",
  "changePercent": 5.88
}
```

## ⚠️ Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions/license |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

## 📝 Rate Limits

**Default**: 100 requests per 15 minutes per IP
**WebSocket**: No rate limit (connection-based)

**Headers**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1696516800
```

---

**Version**: 1.0.0
**Last Updated**: 2025-10-05
