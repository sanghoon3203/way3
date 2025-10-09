# Way3 Server Architecture - Backend System

## 📡 Overview

The Way3 server is a **Node.js/Express** backend with **Socket.IO** for real-time communication and **SQLite** for data persistence. It provides RESTful APIs for game data and WebSocket connections for real-time multiplayer features.

**Repository**: `way-server/`
**Language**: JavaScript (Node.js 18+)
**Framework**: Express.js + Socket.IO
**Database**: SQLite3

## 🏗️ System Architecture

```
┌──────────────────────────────────────────────────────────┐
│                   iOS Client (way3)                       │
└────────────────┬────────────────┬────────────────────────┘
                 │                │
            HTTP REST          WebSocket
                 │                │
    ┌────────────▼────────────────▼───────────────┐
    │         Node.js Server (way-server)         │
    ├─────────────────────────────────────────────┤
    │  Express.js API        Socket.IO Server     │
    ├─────────────────────────────────────────────┤
    │  Middleware Layer (Auth, CORS, Rate Limit)  │
    ├─────────────────────────────────────────────┤
    │  Controllers & Services                     │
    ├─────────────────────────────────────────────┤
    │  Database Layer (SQLite Manager)            │
    └──────────────────┬──────────────────────────┘
                       │
                ┌──────▼──────┐
                │   SQLite    │
                │  Database   │
                └─────────────┘
```

## 📦 Project Structure

```
way-server/
├── src/
│   ├── app.js                    # Express application setup
│   ├── server.js                 # Server entry point
│   │
│   ├── config/
│   │   └── logger.js            # Winston logging configuration
│   │
│   ├── database/
│   │   ├── DatabaseManager.js    # SQLite connection & table management
│   │   ├── AdminExtensions.js    # Admin-specific table extensions
│   │   ├── migrate.js           # Database migration runner
│   │   ├── seed.js              # Database seeding
│   │   ├── initAdmin.js         # Admin user initialization
│   │   ├── migrations/          # SQL migration files
│   │   │   ├── 001_initial_schema.sql
│   │   │   ├── 002_merchants_schema.sql
│   │   │   ├── 003_merchant_media_tables.sql
│   │   │   ├── 004_add_image_filename_to_merchants.sql
│   │   │   ├── 005_story_system_schema.sql
│   │   │   └── personal_items_schema.sql
│   │   └── merchant_data/       # Merchant character data & images
│   │       ├── Seoyena/
│   │       ├── Mari/
│   │       └── ...
│   │
│   ├── middleware/
│   │   ├── auth.js              # JWT authentication middleware
│   │   ├── adminAuth.js         # Admin session authentication
│   │   ├── errorHandler.js      # Error handling & responses
│   │   └── uploadMiddleware.js  # File upload processing (multer/sharp)
│   │
│   ├── routes/
│   │   ├── api/                 # RESTful API routes
│   │   │   ├── auth.js          # Authentication endpoints
│   │   │   ├── player.js        # Player data CRUD
│   │   │   ├── merchants.js     # Merchant data
│   │   │   ├── trade.js         # Trading operations
│   │   │   ├── quests.js        # Quest system API
│   │   │   ├── achievements.js  # Achievement tracking
│   │   │   ├── skills.js        # Skill system
│   │   │   └── personal-items.js # Player inventory items
│   │   │
│   │   ├── game/                # Game-specific routes
│   │   │   └── quests.js        # Quest gameplay endpoints
│   │   │
│   │   └── admin/               # Admin panel routes
│   │       ├── index.js         # Admin router aggregation
│   │       ├── auth.js          # Admin login/logout
│   │       ├── crud.js          # Generic CRUD operations
│   │       ├── media.js         # Merchant media management
│   │       ├── metrics.js       # System metrics API
│   │       ├── monitoring.js    # Server monitoring
│   │       ├── quests.js        # Quest admin management
│   │       └── skills.js        # Skill admin management
│   │
│   ├── controllers/
│   │   ├── UnifiedAdminController.js  # Main admin controller
│   │   └── admin/
│   │       └── dashboardController.js  # Dashboard metrics
│   │
│   ├── services/
│   │   ├── admin/
│   │   │   ├── CRUDService.js          # Generic CRUD operations
│   │   │   ├── EnhancedMetricsService.js # Real-time metrics
│   │   │   ├── FormGenerator.js        # Dynamic form generation
│   │   │   ├── MerchantMediaService.js # Media file handling
│   │   │   ├── QuestService.js         # Quest management
│   │   │   └── SkillService.js         # Skill system service
│   │   │
│   │   └── game/
│   │       ├── QuestPlayerService.js   # Player quest progress
│   │       └── StoryService.js         # Story system logic
│   │
│   ├── socket/
│   │   └── handlers/
│   │       ├── index.js         # Socket event router
│   │       ├── chatHandler.js   # Real-time chat
│   │       ├── locationHandler.js # Player location updates
│   │       └── tradeHandler.js  # Real-time trading events
│   │
│   ├── utils/
│   │   ├── MetricsCollector.js  # Performance monitoring
│   │   └── StandardResponse.js  # Consistent API responses
│   │
│   ├── errors/
│   │   └── CustomErrors.js      # Custom error classes
│   │
│   ├── constants/
│   │   └── merchantDialogues.js # NPC dialogue data
│   │
│   └── views/                   # EJS templates for admin panel
│       └── admin/
│           ├── layouts/
│           ├── partials/
│           ├── auth/
│           └── dashboard.ejs
│
├── public/                      # Static assets
│   └── admin/
│       ├── css/
│       └── js/
│
├── uploads/                     # User-uploaded files (merchants, items)
├── data/                        # SQLite database files
├── scripts/                     # Utility scripts
├── package.json
├── .env
└── railway.toml                # Railway deployment config
```

## 🔑 Core Components

### 1. Server Entry Point (`server.js`)

**Responsibilities**:
- HTTP server creation
- Socket.IO initialization
- Database connection
- Migration & seeding
- Graceful shutdown handling

**Key Features**:
```javascript
// CORS for mobile apps (iOS/Android)
const localNetworkPattern = /^http:\/\/(192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+):3000$/;

// Socket.IO configuration
const io = new Server(server, {
    cors: { /* mobile-friendly */ },
    pingTimeout: 60000,
    pingInterval: 25000,
    allowEIO3: true,
    transports: ['websocket', 'polling']
});

// Startup sequence
async function startServer() {
    await DatabaseManager.initialize();
    await runMigrations({ reuseConnection: true });
    await seedDatabase({ reuseConnection: true });
    server.listen(PORT);
    metricsCollector.start();
}
```

### 2. Express Application (`app.js`)

**Middleware Stack**:
1. **Helmet** - Security headers
2. **CORS** - Cross-origin resource sharing (mobile + local network)
3. **Rate Limiting** - API abuse prevention (100 req/15min)
4. **Session** - Admin authentication (24h cookie)
5. **JSON/URL Parsing** - Body parsing (10MB limit)
6. **Static Files** - Public assets, uploads, admin panel
7. **Request Logging** - Winston logger integration
8. **Error Handling** - Custom error middleware

**Route Organization**:
```javascript
// API routes (mobile client)
app.use('/api/auth', require('./routes/api/auth'));
app.use('/api/player', require('./routes/api/player'));
app.use('/api/merchants', require('./routes/api/merchants'));
app.use('/api/trade', require('./routes/api/trade'));
app.use('/api/quests', require('./routes/api/quests'));
app.use('/api/achievements', require('./routes/api/achievements'));
app.use('/api/skills', require('./routes/api/skills'));
app.use('/api/personal-items', require('./routes/api/personal-items'));

// Game client routes
app.use('/game/quests', require('./routes/game/quests'));

// Admin panel
app.use('/admin', require('./routes/admin'));
```

### 3. Database Manager (`DatabaseManager.js`)

**Singleton Pattern** for SQLite connection management

**Responsibilities**:
- Connection pooling
- Table creation & migration
- Index management
- Transaction support
- Query execution helpers

**Table Schema** (Core):
- `users` - Authentication (email/password)
- `players` - Player profiles & stats
- `merchants` - NPC merchant data
- `items` - Trade items catalog
- `player_inventory` - Player-owned items
- `trade_history` - Transaction records
- `achievements` - Achievement definitions
- `player_achievements` - Player progress
- `quests` - Quest definitions
- `player_quests` - Quest progress
- `skills` - Skill system data
- `story_nodes` - Story/dialogue system

**Helper Methods**:
```javascript
// Promised-based query execution
run(sql, params) // INSERT/UPDATE/DELETE
get(sql, params) // SELECT single row
all(sql, params) // SELECT multiple rows
```

### 4. Authentication System

**Two Auth Mechanisms**:

**A. JWT Authentication** (`middleware/auth.js`)
- For mobile app API access
- Access token (15min) + Refresh token (7 days)
- Bearer token in Authorization header

```javascript
// Token generation
const accessToken = jwt.sign({ userId, email }, JWT_SECRET, { expiresIn: '15m' });
const refreshToken = jwt.sign({ userId }, JWT_REFRESH_SECRET, { expiresIn: '7d' });

// Middleware
function authenticateToken(req, res, next) {
    const token = req.headers.authorization?.split(' ')[1];
    // Verify JWT...
}
```

**B. Session Authentication** (`middleware/adminAuth.js`)
- For admin web panel
- Express session with secure cookies
- 24-hour session duration

```javascript
function requireAdminAuth(req, res, next) {
    if (!req.session.adminId) {
        return res.redirect('/admin/login');
    }
    next();
}
```

## 🔌 Socket.IO Real-Time Features

### Event Handlers

**Location Handler** (`socket/handlers/locationHandler.js`)
```javascript
socket.on('updateLocation', ({ playerId, lat, lng }) => {
    // Update player location in DB
    // Broadcast to nearby players
    io.to(districtRoom).emit('nearbyPlayersUpdate', nearbyPlayers);
});

socket.on('joinLocationGroup', (district) => {
    socket.join(`district-${district}`);
});
```

**Trade Handler** (`socket/handlers/tradeHandler.js`)
```javascript
socket.on('tradeCompleted', (tradeData) => {
    // Record trade in database
    // Broadcast to district
    io.to(`district-${district}`).emit('tradeActivity', activityData);
});

socket.on('priceUpdate', (priceData) => {
    // Update market prices
    io.emit('marketPriceUpdate', updatedPrices);
});
```

**Chat Handler** (`socket/handlers/chatHandler.js`)
```javascript
socket.on('sendMessage', ({ roomId, message, playerId }) => {
    // Validate and sanitize
    io.to(roomId).emit('newMessage', messageData);
});
```

### Room System

**District Rooms**: `district-강남구`, `district-종로구`, etc.
- Players join room based on GPS location
- Receive location-specific updates (nearby players, trades, prices)

**Event Rooms**: Special event or auction rooms
- Temporary rooms for live auctions
- Quest event coordination

## 📊 Admin Panel

### Features

**Dashboard** (`/admin`)
- Real-time server metrics (CPU, memory, requests)
- Active players count
- Recent trade activity
- System health monitoring

**CRUD Management**:
- Merchants (name, type, location, inventory, media)
- Items (name, category, grade, price, description)
- Quests (objectives, rewards, requirements)
- Skills (name, description, max level)
- Achievements (criteria, rewards, icons)

**Media Management**:
- Merchant character images (PNG)
- Merchant GIFs/animations
- Item icons
- Image optimization (sharp library)

**Monitoring**:
- Request logs
- Error tracking
- Performance metrics
- Database query performance

### Technology Stack

**Frontend**: Vanilla JS + EJS templates
**CSS**: Custom admin.css (responsive design)
**Charts**: Real-time metrics visualization
**Upload**: Multer + Sharp (image processing)

## 🗄️ Database Schema

### Core Tables

**users**
```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);
```

**players**
```sql
CREATE TABLE players (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    money INTEGER DEFAULT 50000,
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0,
    current_license INTEGER DEFAULT 0,

    -- Stats
    strength INTEGER DEFAULT 10,
    intelligence INTEGER DEFAULT 10,
    charisma INTEGER DEFAULT 10,
    luck INTEGER DEFAULT 10,

    -- Skills
    trading_skill INTEGER DEFAULT 1,
    negotiation_skill INTEGER DEFAULT 1,
    appraisal_skill INTEGER DEFAULT 1,

    -- Inventory
    max_inventory_size INTEGER DEFAULT 5,
    max_storage_size INTEGER DEFAULT 50,

    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**merchants**
```sql
CREATE TABLE merchants (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    district TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    required_license INTEGER DEFAULT 0,
    image_filename TEXT,
    gif_filename TEXT,
    description TEXT,
    dialogue_data TEXT  -- JSON string
);
```

**items**
```sql
CREATE TABLE items (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    grade INTEGER DEFAULT 0,  -- 0=common, 4=legendary
    base_price INTEGER NOT NULL,
    required_license INTEGER DEFAULT 0,
    weight REAL DEFAULT 1.0,
    description TEXT
);
```

### Migration System

**Migration Files** (`database/migrations/*.sql`):
- `001_initial_schema.sql` - Core tables (users, players, items)
- `002_merchants_schema.sql` - Merchant system
- `003_merchant_media_tables.sql` - Media file tracking
- `004_add_image_filename_to_merchants.sql` - Image support
- `005_story_system_schema.sql` - Story/dialogue system
- `personal_items_schema.sql` - Player inventory extensions

**Migration Runner** (`database/migrate.js`):
```javascript
async function runMigrations({ reuseConnection }) {
    const applied = await getAppliedMigrations();
    const pending = migrationFiles.filter(f => !applied.includes(f));

    for (const file of pending) {
        const sql = await fs.readFile(path.join(migDir, file), 'utf8');
        await db.exec(sql);
        await db.run('INSERT INTO migrations (name) VALUES (?)', file);
        logger.info(`✓ Migration applied: ${file}`);
    }
}
```

## 🔐 Security Features

### Authentication
- **JWT** with access + refresh tokens
- **bcrypt** password hashing (10 rounds)
- **Session secrets** from environment variables

### Rate Limiting
```javascript
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100,                  // 100 requests per window
    message: '너무 많은 요청입니다. 잠시 후 다시 시도해주세요.'
});
app.use('/api/', limiter);
```

### Input Validation
- **express-validator** for request validation
- **SQL injection** prevention via parameterized queries
- **XSS protection** via helmet middleware

### CORS Configuration
```javascript
// Mobile app + local network support
origin: function(origin, callback) {
    if (!origin) return callback(null, true);  // Mobile apps

    const localNetworkPattern = /^http:\/\/(192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+):3000$/;

    if (allowedOrigins.includes(origin) || localNetworkPattern.test(origin)) {
        callback(null, true);
    } else {
        callback(new Error('CORS 정책에 의해 차단됨'), false);
    }
}
```

## 📈 Performance & Monitoring

### Metrics Collection (`utils/MetricsCollector.js`)

**Tracked Metrics**:
- Request rate (req/min, req/hour)
- Response times (avg, p95, p99)
- CPU usage
- Memory consumption
- Active connections (HTTP + WebSocket)
- Database query performance
- Error rates

**Real-Time Updates**:
```javascript
class MetricsCollector {
    start() {
        this.interval = setInterval(() => {
            this.collectSystemMetrics();
            this.calculateStatistics();
        }, 5000);  // Every 5 seconds
    }

    getMetrics() {
        return {
            requests: this.requestCount,
            avgResponseTime: this.calculateAverage(this.responseTimes),
            cpu: process.cpuUsage(),
            memory: process.memoryUsage(),
            activeConnections: this.connections.size
        };
    }
}
```

### Logging (`config/logger.js`)

**Winston Logger Configuration**:
```javascript
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' }),
        new winston.transports.Console({ format: winston.format.simple() })
    ]
});
```

**Log Levels**:
- `error` - Critical failures
- `warn` - Warnings and potential issues
- `info` - General information (startup, shutdown, requests)
- `debug` - Detailed debugging information

## 🚀 Deployment

### Environment Variables

```bash
# Server
NODE_ENV=production
PORT=3000

# Database
DB_PATH=./data/way_game.sqlite

# Authentication
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret
SESSION_SECRET=your-session-secret

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000  # 15 minutes
RATE_LIMIT_MAX_REQUESTS=100

# CORS
ALLOWED_ORIGINS=https://your-frontend.com,http://localhost:3000

# Admin
ADMIN_USERNAME=admin
ADMIN_PASSWORD=secure-password
```

### Railway Deployment

**railway.toml**:
```toml
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "npm start"
healthcheckPath = "/health"
healthcheckTimeout = 100
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

### Startup Scripts

**start_server.sh**:
```bash
#!/bin/bash
npm run migrate
npm start
```

---

**Next**: [09_SERVER_API_REFERENCE.md](09_SERVER_API_REFERENCE.md) - Complete API endpoint documentation
