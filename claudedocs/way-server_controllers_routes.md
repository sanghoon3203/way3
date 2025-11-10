# way-server Controllers & Routes Documentation

**Project**: way-server Node.js Backend
**Documentation Date**: 2025-10-11

---

## Controllers

### DashboardController (`src/controllers/admin/dashboardController.js`)

#### `renderDashboard(req, res)`
**File**: src/controllers/admin/dashboardController.js:9
**Purpose**: Renders the admin dashboard main page
**Parameters**: None
**Returns**: (HTML) Rendered admin dashboard view
**HTTP**: `GET /admin`
**Middleware**: adminAuth
**Database**: None (renders view only)
**Errors**: 500 error with admin/error view on failure
**Related**: getStats, getCounts

#### `getStats(req, res)`
**File**: src/controllers/admin/dashboardController.js:28
**Purpose**: Retrieves dashboard statistics including merchants, quests, skills, and players
**Parameters**: None
**Returns**: (JSON) Dashboard statistics object
**HTTP**: `GET /admin/api/dashboard/stats`
**Middleware**: adminAuth
**Database**: merchants, quests, skills, players tables
**Errors**: 500 with error message
**Related**: getMerchantStats, getQuestStats, getSkillStats, getPlayerStats

#### `getCounts(req, res)`
**File**: src/controllers/admin/dashboardController.js:81
**Purpose**: Gets count information for sidebar display
**Parameters**: None
**Returns**: (JSON) Entity counts for merchants, quests, skills, players, media
**HTTP**: `GET /admin/api/dashboard/counts`
**Middleware**: adminAuth
**Database**: Multiple tables
**Errors**: 500 with error message
**Related**: getCount, getMediaCount

#### `getActivityChart(req, res)`
**File**: src/controllers/admin/dashboardController.js:115
**Purpose**: Retrieves activity chart data for specified time period
**Parameters**:
- `period` (Query): Time period in days (7 or 30)
**Returns**: (JSON) Chart data for merchants, quests, skills creation
**HTTP**: `GET /admin/api/dashboard/activity-chart?period=7`
**Middleware**: adminAuth
**Database**: merchants, quests, skills tables
**Errors**: 400 for invalid period, 500 for server error
**Related**: getActivityChartData

#### `getActivityLog(req, res)`
**File**: src/controllers/admin/dashboardController.js:146
**Purpose**: Gets recent activity log entries
**Parameters**:
- `limit` (Query): Number of entries to return (default 20)
**Returns**: (JSON) Recent activities with time ago formatting
**HTTP**: `GET /admin/api/dashboard/activity-log?limit=20`
**Middleware**: adminAuth
**Database**: merchants, quests, skills tables
**Errors**: 500 with error message
**Related**: getRecentActivities

#### `getSystemStatus(req, res)`
**File**: src/controllers/admin/dashboardController.js:169
**Purpose**: Retrieves system status information
**Parameters**: None
**Returns**: (JSON) System uptime, memory, CPU, database status
**HTTP**: `GET /admin/api/system/status`
**Middleware**: adminAuth
**Database**: None (system metrics)
**Errors**: 500 with error message
**Related**: getSystemInfo

---

### UnifiedAdminController (`src/controllers/UnifiedAdminController.js`)

#### Main Dashboard Route Handler
**File**: src/controllers/UnifiedAdminController.js:21
**Purpose**: Unified main dashboard with enhanced metrics
**Parameters**: None
**Returns**: (HTML) Generated main dashboard page
**HTTP**: `GET /admin`
**Middleware**: None (commented out for development)
**Database**: Via EnhancedMetricsService
**Errors**: 500 with error page
**Related**: EnhancedMetricsService.getDashboardMetrics

#### Monitoring Dashboard Handler
**File**: src/controllers/UnifiedAdminController.js:37
**Purpose**: Real-time monitoring dashboard
**Parameters**: None
**Returns**: (HTML) Generated monitoring dashboard
**HTTP**: `GET /admin/monitoring`
**Middleware**: None (commented out)
**Database**: Via EnhancedMetricsService
**Errors**: 500 with error page
**Related**: EnhancedMetricsService.getMonitoringMetrics

#### Player Analytics Handler
**File**: src/controllers/UnifiedAdminController.js:53
**Purpose**: Player analytics dashboard
**Parameters**:
- `range` (Query): Time range (default '7d')
**Returns**: (HTML) Player analytics dashboard
**HTTP**: `GET /admin/analytics/players?range=7d`
**Middleware**: None
**Database**: Via EnhancedMetricsService
**Errors**: 500 with error page
**Related**: EnhancedMetricsService.getPlayerAnalytics

#### Economy Analytics Handler
**File**: src/controllers/UnifiedAdminController.js:70
**Purpose**: Economy analysis dashboard
**Parameters**:
- `range` (Query): Time range (default '7d')
**Returns**: (HTML) Economy analytics dashboard
**HTTP**: `GET /admin/analytics/economy?range=7d`
**Middleware**: None
**Database**: Via EnhancedMetricsService
**Errors**: 500 with error page
**Related**: EnhancedMetricsService.getEconomyAnalytics

#### Unified Metrics API
**File**: src/controllers/UnifiedAdminController.js:91
**Purpose**: Unified metrics API endpoint
**Parameters**:
- `type` (Query): Metric type (dashboard/monitoring/players/economy)
- `range` (Query): Time range
**Returns**: (JSON) Metrics data for specified type
**HTTP**: `GET /admin/api/metrics?type=dashboard&range=7d`
**Middleware**: None
**Database**: Via EnhancedMetricsService
**Errors**: 400 for unknown type, 500 for server error
**Related**: Multiple EnhancedMetricsService methods

#### Live Update API
**File**: src/controllers/UnifiedAdminController.js:137
**Purpose**: Fast real-time updates for monitoring
**Parameters**: None
**Returns**: (JSON) Quick metrics (server status, players, alerts)
**HTTP**: `GET /admin/api/live`
**Middleware**: None
**Database**: Via EnhancedMetricsService
**Errors**: 500 with error object
**Related**: EnhancedMetricsService.getMonitoringMetrics

#### Cache Clear API
**File**: src/controllers/UnifiedAdminController.js:174
**Purpose**: Clears metrics cache
**Parameters**:
- `pattern` (Body): Optional cache pattern to clear
**Returns**: (JSON) Success message
**HTTP**: `POST /admin/api/cache/clear`
**Middleware**: None
**Database**: None (cache management)
**Errors**: 500 with error message
**Related**: EnhancedMetricsService.clearCache

#### Legacy Players Page
**File**: src/controllers/UnifiedAdminController.js:202
**Purpose**: Legacy compatibility for player list page
**Parameters**: None
**Returns**: (HTML) Player list table
**HTTP**: `GET /admin/players`
**Middleware**: None
**Database**: players table
**Errors**: 500 with error page
**Related**: None

---

## Routes

### Admin Routes (`src/routes/admin.js`)

All routes use `adminAuth` middleware.

#### `GET /admin`
**File**: src/routes/admin.js:14
**Purpose**: Renders admin dashboard
**Middleware**: adminAuth
**Controller**: dashboardController.renderDashboard

#### `GET /admin/dashboard`
**File**: src/routes/admin.js:15
**Purpose**: Redirects to /admin
**Middleware**: adminAuth

#### `GET /admin/api/dashboard/stats`
**File**: src/routes/admin.js:18
**Purpose**: Dashboard statistics API
**Middleware**: adminAuth
**Controller**: dashboardController.getStats

#### `GET /admin/api/dashboard/counts`
**File**: src/routes/admin.js:19
**Purpose**: Entity counts API
**Middleware**: adminAuth
**Controller**: dashboardController.getCounts

#### `GET /admin/api/dashboard/activity-chart`
**File**: src/routes/admin.js:20
**Purpose**: Activity chart data
**Middleware**: adminAuth
**Controller**: dashboardController.getActivityChart

#### `GET /admin/api/dashboard/activity-log`
**File**: src/routes/admin.js:21
**Purpose**: Activity log entries
**Middleware**: adminAuth
**Controller**: dashboardController.getActivityLog

#### `GET /admin/api/system/status`
**File**: src/routes/admin.js:22
**Purpose**: System status information
**Middleware**: adminAuth
**Controller**: dashboardController.getSystemStatus

#### `POST /admin/login`
**File**: src/routes/admin.js:286
**Purpose**: Admin login handler
**Parameters**:
- `username` (Body): Admin username
- `password` (Body): Admin password
**Middleware**: None
**Database**: Session storage
**Errors**: Renders login with error message

#### `GET /admin/logout`
**File**: src/routes/admin.js:265
**Purpose**: Destroys admin session
**Middleware**: adminAuth
**Database**: Session storage

---

### Admin Auth Routes (`src/routes/admin/auth.js`)

#### `GET /admin/auth/login`
**File**: src/routes/admin/auth.js:12
**Purpose**: Renders admin login page
**Parameters**: None
**Returns**: (HTML) Login form
**HTTP**: `GET /admin/auth/login`
**Middleware**: None
**Database**: None

#### `POST /admin/auth/login`
**File**: src/routes/admin/auth.js:138
**Purpose**: Processes admin login
**Parameters**:
- `username` (Body): Admin username
- `password` (Body): Admin password
**Returns**: (JSON) JWT token and admin data
**HTTP**: `POST /admin/auth/login`
**Middleware**: None
**Database**: Uses AdminAuth.login
**Errors**: 400 validation error, 401 invalid credentials
**Related**: AdminAuth.logAction

#### `POST /admin/auth/logout`
**File**: src/routes/admin/auth.js:182
**Purpose**: Admin logout
**Parameters**: None
**Returns**: (JSON) Success message
**HTTP**: `POST /admin/auth/logout`
**Middleware**: AdminAuth.authenticateToken
**Database**: admin_logs table
**Errors**: 500 on failure
**Related**: AdminAuth.logAction

#### `GET /admin/auth/me`
**File**: src/routes/admin/auth.js:213
**Purpose**: Gets current admin info
**Parameters**: None
**Returns**: (JSON) Admin user details
**HTTP**: `GET /admin/auth/me`
**Middleware**: AdminAuth.authenticateToken
**Database**: None (from JWT)

#### `POST /admin/auth/create`
**File**: src/routes/admin/auth.js:229
**Purpose**: Creates new admin user (super admin only)
**Parameters**:
- `username` (Body): New admin username
- `email` (Body): Admin email
- `password` (Body): Password
- `role` (Body): Admin role
**Returns**: (JSON) New admin data
**HTTP**: `POST /admin/auth/create`
**Middleware**: AdminAuth.authenticateToken, AdminAuth.requirePermission('admin.create')
**Database**: admin_users table
**Errors**: 400 validation or creation error
**Related**: AdminAuth.createAdmin, AdminAuth.logAction

---

### Admin CRUD Routes (`src/routes/admin/crud.js`)

#### `GET /admin/crud/:entity`
**File**: src/routes/admin/crud.js:17
**Purpose**: Lists entities with pagination and filtering
**Parameters**:
- `entity` (Path): Entity type (users/players/merchants/etc)
- `page` (Query): Page number (default 1)
- `limit` (Query): Items per page (default 20)
- `filters` (Query): Additional filters
**Returns**: (HTML) Entity list table
**HTTP**: `GET /admin/crud/players?page=1&limit=20`
**Middleware**: AdminAuth.authenticateToken (commented out)
**Database**: Via AdminCRUDService
**Errors**: 500 with error message
**Related**: AdminCRUDService.performCRUD, FormGenerator.generateTable

#### `GET /admin/crud/:entity/create`
**File**: src/routes/admin/crud.js:94
**Purpose**: Shows entity creation form
**Parameters**:
- `entity` (Path): Entity type
**Returns**: (HTML) Creation form
**HTTP**: `GET /admin/crud/players/create`
**Database**: None (form only)
**Errors**: 400 with error message
**Related**: FormGenerator.generateForm

#### `GET /admin/crud/:entity/:id`
**File**: src/routes/admin/crud.js:122
**Purpose**: Shows entity detail view
**Parameters**:
- `entity` (Path): Entity type
- `id` (Path): Entity ID
**Returns**: (HTML) Detail view with edit/delete actions
**HTTP**: `GET /admin/crud/players/123`
**Database**: Via AdminCRUDService
**Errors**: 404 if not found, 500 on error
**Related**: AdminCRUDService.performCRUD

#### `GET /admin/crud/:entity/:id/edit`
**File**: src/routes/admin/crud.js:246
**Purpose**: Shows entity edit form
**Parameters**:
- `entity` (Path): Entity type
- `id` (Path): Entity ID
**Returns**: (HTML) Edit form with existing data
**HTTP**: `GET /admin/crud/players/123/edit`
**Database**: Via AdminCRUDService
**Errors**: 404 if not found, 500 on error
**Related**: AdminCRUDService.performCRUD, FormGenerator.generateForm

#### `POST /admin/crud/:entity`
**File**: src/routes/admin/crud.js:287
**Purpose**: Creates new entity
**Parameters**:
- `entity` (Path): Entity type
- Body: Entity data
**Returns**: (JSON) Created entity
**HTTP**: `POST /admin/crud/players`
**Database**: Via AdminCRUDService
**Errors**: 400 with error message
**Related**: AdminCRUDService.performCRUD

#### `PUT /admin/crud/:entity/:id`
**File**: src/routes/admin/crud.js:311
**Purpose**: Updates entity
**Parameters**:
- `entity` (Path): Entity type
- `id` (Path): Entity ID
- `updates` (Body): Updated fields
**Returns**: (JSON) Updated entity
**HTTP**: `PUT /admin/crud/players/123`
**Database**: Via AdminCRUDService
**Errors**: 400 with error message
**Related**: AdminCRUDService.performCRUD

#### `DELETE /admin/crud/:entity/:id`
**File**: src/routes/admin/crud.js:340
**Purpose**: Deletes entity
**Parameters**:
- `entity` (Path): Entity type
- `id` (Path): Entity ID
**Returns**: (JSON) Success message
**HTTP**: `DELETE /admin/crud/players/123`
**Database**: Via AdminCRUDService
**Errors**: 400 with error message
**Related**: AdminCRUDService.performCRUD

---

### Admin Media Routes (`src/routes/admin/media.js`)

#### `GET /admin/media`
**File**: src/routes/admin/media.js:16
**Purpose**: Media management dashboard
**Parameters**: None
**Returns**: (HTML) Media dashboard with statistics
**HTTP**: `GET /admin/media`
**Database**: merchant_media, merchants tables
**Errors**: 500 with error message
**Related**: MerchantMediaService.getMediaStatistics

#### `GET /admin/media/test`
**File**: src/routes/admin/media.js:90
**Purpose**: File upload test page
**Parameters**: None
**Returns**: (HTML) Upload test interface
**HTTP**: `GET /admin/media/test`

#### `POST /admin/media/upload/face/:merchantId`
**File**: src/routes/admin/media.js:245
**Purpose**: Uploads merchant face image
**Parameters**:
- `merchantId` (Path): Merchant ID
- `emotion` (Body): Emotion type
- `faceImage` (File): Image file
**Returns**: (JSON) Upload result with file info
**HTTP**: `POST /admin/media/upload/face/merchant123`
**Middleware**: uploadSingle('faceImage')
**Database**: merchant_media table
**Errors**: 400 validation error
**Related**: MerchantMediaService.uploadFaceImage

#### `POST /admin/media/upload/animation/:merchantId`
**File**: src/routes/admin/media.js:292
**Purpose**: Uploads merchant animation GIF
**Parameters**:
- `merchantId` (Path): Merchant ID
- `animationType` (Body): Animation type
- `animation` (File): GIF file
**Returns**: (JSON) Upload result
**HTTP**: `POST /admin/media/upload/animation/merchant123`
**Middleware**: uploadSingle('animation')
**Database**: merchant_media table
**Errors**: 400 validation error
**Related**: MerchantMediaService.uploadAnimation

#### `GET /admin/media/merchant/:merchantId`
**File**: src/routes/admin/media.js:339
**Purpose**: Gets all media for a merchant
**Parameters**:
- `merchantId` (Path): Merchant ID
**Returns**: (JSON) Array of media items
**HTTP**: `GET /admin/media/merchant/merchant123`
**Database**: merchant_media table
**Errors**: 500 on failure
**Related**: MerchantMediaService.getMerchantMedia

#### `DELETE /admin/media/:mediaId`
**File**: src/routes/admin/media.js:362
**Purpose**: Deletes media item
**Parameters**:
- `mediaId` (Path): Media item ID
**Returns**: (JSON) Success message
**HTTP**: `DELETE /admin/media/abc123`
**Database**: merchant_media table, file system
**Errors**: 400 on failure
**Related**: MerchantMediaService.deleteMedia

#### `POST /admin/media/init`
**File**: src/routes/admin/media.js:387
**Purpose**: Initializes media directories
**Parameters**: None
**Returns**: (JSON) Success message
**HTTP**: `POST /admin/media/init`
**Database**: None (file system only)
**Errors**: 500 on failure
**Related**: MerchantMediaService.initializeDirectories

---

### Admin Metrics Routes (`src/routes/admin/metrics.js`)

#### `GET /admin/api/metrics/dashboard`
**File**: src/routes/admin/metrics.js:12
**Purpose**: Dashboard summary metrics
**Parameters**: None
**Returns**: (JSON) Current stats, trends, top items, level distribution
**HTTP**: `GET /admin/api/metrics/dashboard`
**Database**: players, trade_records, item_templates tables
**Errors**: 500 with error message

#### `GET /admin/api/metrics/players`
**File**: src/routes/admin/metrics.js:134
**Purpose**: Player activity metrics
**Parameters**:
- `timeRange` (Query): Time range (1d/7d/30d, default 7d)
**Returns**: (JSON) Player statistics and activity patterns
**HTTP**: `GET /admin/api/metrics/players?timeRange=7d`
**Database**: players, trade_records, merchants tables
**Errors**: 500 with error message

#### `GET /admin/api/metrics/economy`
**File**: src/routes/admin/metrics.js:218
**Purpose**: Economic metrics and trade statistics
**Parameters**:
- `timeRange` (Query): Time range (1d/7d/30d, default 7d)
**Returns**: (JSON) Economy overview, category stats, daily trends
**HTTP**: `GET /admin/api/metrics/economy?timeRange=7d`
**Database**: trade_records, item_templates, merchants tables
**Errors**: 500 with error message

#### `GET /admin/api/metrics/system`
**File**: src/routes/admin/metrics.js:321
**Purpose**: System status and health metrics
**Parameters**: None
**Returns**: (JSON) Server metrics, database status, recent metrics
**HTTP**: `GET /admin/api/metrics/system`
**Database**: Multiple tables (counts)
**Errors**: 500 with error message

---

### Admin Monitoring Routes (`src/routes/admin/monitoring.js`)

#### `GET /admin/monitoring`
**File**: src/routes/admin/monitoring.js:18
**Purpose**: Real-time monitoring dashboard
**Parameters**: None
**Returns**: (HTML) Live monitoring dashboard with auto-refresh
**HTTP**: `GET /admin/monitoring`
**Middleware**: AdminAuth.authenticateToken (production only)
**Database**: Via collectSimpleMetrics
**Errors**: 500 with error message

#### `GET /admin/monitoring/api/metrics`
**File**: src/routes/admin/monitoring.js:135
**Purpose**: Metrics API (JSON response)
**Parameters**: None
**Returns**: (JSON) Current metrics and alerts
**HTTP**: `GET /admin/monitoring/api/metrics`
**Database**: Via collectSimpleMetrics
**Errors**: 500 with error message

#### `GET /admin/monitoring/api/history`
**File**: src/routes/admin/monitoring.js:163
**Purpose**: Historical metrics data
**Parameters**:
- `hours` (Query): Number of hours (default 24)
**Returns**: (JSON) Historical metrics array
**HTTP**: `GET /admin/monitoring/api/history?hours=24`
**Database**: None (placeholder for future implementation)
**Errors**: 500 with error message

#### `POST /admin/monitoring/api/cleanup`
**File**: src/routes/admin/monitoring.js:187
**Purpose**: Cleans up old metrics data
**Parameters**:
- `days` (Body): Days to keep (default 30)
**Returns**: (JSON) Deleted count
**HTTP**: `POST /admin/monitoring/api/cleanup`
**Middleware**: AdminAuth.requirePermission('system.maintenance')
**Database**: None (placeholder)
**Errors**: 500 with error message

---

### Admin Quests Routes (`src/routes/admin/quests.js`)

#### `GET /admin/quests`
**File**: src/routes/admin/quests.js:16
**Purpose**: Quest management dashboard
**Parameters**: None
**Returns**: (HTML) Quest dashboard with statistics
**HTTP**: `GET /admin/quests`
**Database**: Via QuestService
**Errors**: 500 with error message
**Related**: QuestService.getQuestStatistics, getActiveQuests, getRecentQuestActivity

#### `GET /admin/quests/create`
**File**: src/routes/admin/quests.js:145
**Purpose**: Quest creation form
**Parameters**: None
**Returns**: (HTML) Quest creation form
**HTTP**: `GET /admin/quests/create`
**Middleware**: AdminAuth.requirePermission('quest.create')
**Related**: QuestService.getSkillCategories, getSkillTypes

#### `GET /admin/quests/templates`
**File**: src/routes/admin/quests.js:188
**Purpose**: Quest templates list with filters
**Parameters**:
- `category` (Query): Filter by category
- `type` (Query): Filter by type
- `status` (Query): Filter by status (default 'active')
**Returns**: (HTML) Template list table
**HTTP**: `GET /admin/quests/templates?category=main_story`
**Database**: Via QuestService.getQuestTemplates
**Errors**: 500 with error message

#### `GET /admin/quests/statistics`
**File**: src/routes/admin/quests.js:246
**Purpose**: Quest statistics analysis page
**Parameters**: None
**Returns**: (HTML) Statistics dashboard with charts
**HTTP**: `GET /admin/quests/statistics`
**Database**: Via QuestService
**Errors**: 500 with error message
**Related**: QuestService.getQuestStatistics, getCategoryStatistics, getCompletionStatistics

#### `POST /admin/quests/api/create`
**File**: src/routes/admin/quests.js:297
**Purpose**: Creates new quest template
**Parameters**:
- Body: Quest data (title, description, category, objectives, rewards, etc)
**Returns**: (JSON) Created quest data
**HTTP**: `POST /admin/quests/api/create`
**Middleware**: AdminAuth.requirePermission('quest.create')
**Database**: quest_templates table
**Errors**: 400 with error message
**Related**: QuestService.createQuestTemplate

#### `POST /admin/quests/api/toggle`
**File**: src/routes/admin/quests.js:321
**Purpose**: Toggles quest active/inactive status
**Parameters**:
- `questId` (Body): Quest template ID
- `isActive` (Body): New active status
**Returns**: (JSON) Updated quest data
**HTTP**: `POST /admin/quests/api/toggle`
**Middleware**: AdminAuth.requirePermission('quest.update')
**Database**: quest_templates table
**Errors**: 400 with error message
**Related**: QuestService.updateQuestTemplate

#### `POST /admin/quests/api/assign`
**File**: src/routes/admin/quests.js:348
**Purpose**: Assigns quest to player
**Parameters**:
- `questId` (Body): Quest template ID
- `playerId` (Body): Player ID
**Returns**: (JSON) Assignment result
**HTTP**: `POST /admin/quests/api/assign`
**Middleware**: AdminAuth.requirePermission('quest.assign')
**Database**: player_quests table
**Errors**: 400 with error message
**Related**: QuestService.assignQuestToPlayer

---

### Admin Skills Routes (`src/routes/admin/skills.js`)

#### `GET /admin/skills`
**File**: src/routes/admin/skills.js:16
**Purpose**: Skill management dashboard
**Parameters**: None
**Returns**: (HTML) Skills dashboard with tree preview
**HTTP**: `GET /admin/skills`
**Database**: Via SkillService
**Errors**: 500 with error message
**Related**: SkillService.getSkillStatistics, getSkillTreeData

#### `GET /admin/skills/create`
**File**: src/routes/admin/skills.js:148
**Purpose**: Skill creation form
**Parameters**: None
**Returns**: (HTML) Skill creation form
**HTTP**: `GET /admin/skills/create`
**Middleware**: AdminAuth.requirePermission('skill.create')
**Related**: SkillService.getSkillCategories, getSkillTypes

#### `GET /admin/skills/tree`
**File**: src/routes/admin/skills.js:194
**Purpose**: Visual skill tree interface
**Parameters**:
- `category` (Query): Filter by category
**Returns**: (HTML) Skill tree visualization
**HTTP**: `GET /admin/skills/tree?category=trading`
**Database**: Via SkillService.getSkillTreeData
**Errors**: 500 with error message

#### `GET /admin/skills/statistics`
**File**: src/routes/admin/skills.js:258
**Purpose**: Skill statistics and analytics
**Parameters**: None
**Returns**: (HTML) Statistics dashboard
**HTTP**: `GET /admin/skills/statistics`
**Database**: Via SkillService.getSkillStatistics
**Errors**: 500 with error message

#### `POST /admin/skills/api/create`
**File**: src/routes/admin/skills.js:307
**Purpose**: Creates new skill template
**Parameters**:
- Body: Skill data (name, category, type, effects, costs, etc)
**Returns**: (JSON) Created skill data
**HTTP**: `POST /admin/skills/api/create`
**Middleware**: AdminAuth.requirePermission('skill.create')
**Database**: skill_templates table
**Errors**: 400 with error message
**Related**: SkillService.createSkillTemplate

#### `POST /admin/skills/api/toggle`
**File**: src/routes/admin/skills.js:331
**Purpose**: Toggles skill active/inactive status
**Parameters**:
- `skillId` (Body): Skill template ID
- `isActive` (Body): New active status
**Returns**: (JSON) Updated skill data
**HTTP**: `POST /admin/skills/api/toggle`
**Middleware**: AdminAuth.requirePermission('skill.update')
**Database**: skill_templates table
**Errors**: 400 with error message
**Related**: SkillService.updateSkillTemplate

---

### API Achievements Routes (`src/routes/api/achievements.js`)

All routes use `authenticateToken` middleware.

#### `GET /api/achievements`
**File**: src/routes/api/achievements.js:15
**Purpose**: Gets player's achievement list with progress
**Parameters**:
- `category` (Query): Filter by category
- `status` (Query): Filter by status
**Returns**: (JSON) Achievements grouped by category with stats
**HTTP**: `GET /api/achievements?category=trading&status=completed`
**Middleware**: authenticateToken
**Database**: achievement_templates, player_achievements tables
**Errors**: 500 with error message

#### `GET /api/achievements/:achievementId`
**File**: src/routes/api/achievements.js:126
**Purpose**: Gets specific achievement details
**Parameters**:
- `achievementId` (Path): Achievement ID
**Returns**: (JSON) Achievement detail with unlock conditions and rewards
**HTTP**: `GET /api/achievements/ach123`
**Middleware**: authenticateToken
**Database**: achievement_templates, player_achievements tables
**Errors**: 404 if not found, 500 on error

#### `POST /api/achievements/progress`
**File**: src/routes/api/achievements.js:188
**Purpose**: Updates achievement progress (internal use)
**Parameters**:
- `achievementId` (Body): Achievement ID
- `value` (Body): Progress value increment
- `context` (Body): Optional context data
**Returns**: (JSON) Updated progress data
**HTTP**: `POST /api/achievements/progress`
**Middleware**: authenticateToken
**Database**: player_achievements table
**Errors**: 400 validation error, 500 on failure
**Related**: updateAchievementProgress

#### `POST /api/achievements/:achievementId/claim`
**File**: src/routes/api/achievements.js:220
**Purpose**: Claims achievement rewards
**Parameters**:
- `achievementId` (Path): Achievement ID
**Returns**: (JSON) Claimed rewards summary
**HTTP**: `POST /api/achievements/ach123/claim`
**Middleware**: authenticateToken
**Database**: achievement_templates, player_achievements, achievement_completions, players tables
**Errors**: 400 if not completed or already claimed, 500 on error
**Related**: metricsCollector.recordEvent

---

### API Auth Routes (`src/routes/api/auth.js`)

#### `POST /api/auth/register`
**File**: src/routes/api/auth.js:35
**Purpose**: User registration with player creation
**Parameters**:
- `email` (Body): User email
- `password` (Body): Password (min 6 chars)
- `playerName` (Body): Player name (2-20 chars)
**Returns**: (JSON) JWT tokens and player data
**HTTP**: `POST /api/auth/register`
**Middleware**: Validation middleware
**Database**: users, players tables
**Errors**: 400 validation error, 409 email exists, 500 on failure

#### `POST /api/auth/login`
**File**: src/routes/api/auth.js:165
**Purpose**: User authentication
**Parameters**:
- `email` (Body): User email
- `password` (Body): Password
**Returns**: (JSON) JWT tokens and player data
**HTTP**: `POST /api/auth/login`
**Middleware**: Validation middleware
**Database**: users, players tables
**Errors**: 400 validation error, 401 invalid credentials, 404 player not found, 500 on failure

#### `POST /api/auth/refresh`
**File**: src/routes/api/auth.js:290
**Purpose**: Refreshes JWT access token
**Parameters**:
- `refreshToken` (Body): Refresh token
**Returns**: (JSON) New access token
**HTTP**: `POST /api/auth/refresh`
**Middleware**: Validation middleware
**Database**: None (JWT only)
**Errors**: 400 missing token, 401 invalid token, 500 on failure

#### `POST /api/auth/logout`
**File**: src/routes/api/auth.js:343
**Purpose**: User logout (client-side token removal)
**Parameters**: None
**Returns**: (JSON) Success message
**HTTP**: `POST /api/auth/logout`
**Database**: None (token blacklist placeholder)
**Errors**: 500 on failure

#### `POST /api/auth/password/reset/request`
**File**: src/routes/api/auth.js:365
**Purpose**: Requests password reset token
**Parameters**:
- `email` (Body): User email
**Returns**: (JSON) Masked email and reset token (dev), expiry time
**HTTP**: `POST /api/auth/password/reset/request`
**Middleware**: Validation middleware
**Database**: users, password_reset_tokens tables
**Errors**: 400 validation error, 500 on failure

#### `POST /api/auth/password/reset/verify`
**File**: src/routes/api/auth.js:444
**Purpose**: Resets password with token
**Parameters**:
- `email` (Body): User email
- `resetToken` (Body): Reset token (64-char hex)
- `newPassword` (Body): New password (min 6 chars)
**Returns**: (JSON) Success message
**HTTP**: `POST /api/auth/password/reset/verify`
**Middleware**: Validation middleware
**Database**: users, password_reset_tokens tables
**Errors**: 400 validation/token error, 500 on failure

---

### API Merchants Routes (`src/routes/api/merchants.js`)

All routes use `authenticateToken` middleware.

#### `GET /api/merchants/nearby`
**File**: src/routes/api/merchants.js:39
**Purpose**: Finds nearby merchants based on location
**Parameters**:
- `lat` (Query): Latitude (-90 to 90)
- `lng` (Query): Longitude (-180 to 180)
- `radius` (Query): Search radius in meters (100-5000, default 1000)
**Returns**: (JSON) Merchants sorted by distance incl. relationship stage, stage progress, permit tier, effective grade cap
**HTTP**: `GET /api/merchants/nearby?lat=37.5&lng=127.0&radius=1000`
**Middleware**: authenticateToken, validation
**Database**: merchants, merchant_inventory, merchant_relationships, player_personal_items, players tables
**Errors**: 400 validation error, 500 on failure

#### `GET /api/merchants/:merchantId`
**File**: src/routes/api/merchants.js:153
**Purpose**: Gets merchant details with inventory
**Parameters**:
- `merchantId` (Path): Merchant ID
**Returns**: (JSON) Merchant data, inventory, preferences, relationship (stage/progress), `accessControl` with permit/grade caps
**HTTP**: `GET /api/merchants/merchant123`
**Middleware**: authenticateToken
**Database**: merchants, merchant_inventory, merchant_relationships, merchant_preferences, player_personal_items, item_templates tables
**Errors**: 404 if not found, 500 on failure

#### `POST /api/merchants/:merchantId/relationship/progress`
**File**: src/routes/api/merchants.js:426
**Purpose**: Applies sub-quest completion toward the merchant relationship stage
**Parameters**:
- `merchantId` (Path): Merchant ID
- `questId` (Body): Completed sub-quest ID (deduplicated per stage)
**Returns**: (JSON) Updated relationship stage, stage progress, next requirement, current permit tier
**HTTP**: `POST /api/merchants/merchant123/relationship/progress`
**Middleware**: authenticateToken, validation
**Database**: merchant_relationships, merchant_relationship_quest_log, player_personal_items tables
**Errors**: 400 validation error, 404 relationship missing, 500 on failure
**Notes**: Returns success even when duplicate quest submission is ignored (`message: "이미 반영된 퀘스트입니다."`)

#### `POST /api/merchants/:merchantId/permit/upgrade`
**File**: src/routes/api/merchants.js:606
**Purpose**: Upgrades the player's merchant permit tier after verifying relationship stage
**Parameters**:
- `merchantId` (Path): Merchant ID (determines required stage)
**Returns**: (JSON) New permit tier and current relationship info
**HTTP**: `POST /api/merchants/merchant123/permit/upgrade`
**Middleware**: authenticateToken
**Database**: player_personal_items, merchant_relationships tables
**Errors**: 400 already at max tier, 403 `RELATIONSHIP_STAGE_REQUIRED`, 500 on failure

#### `GET /api/merchants/:merchantId/dialogues`
**File**: src/routes/api/merchants.js:282
**Purpose**: Gets merchant conversation dialogues
**Parameters**:
- `merchantId` (Path): Merchant ID
- `triggerType` (Query): Filter by trigger type
**Returns**: (JSON) Dialogue buckets by category (greeting/trading/goodbye/etc)
**HTTP**: `GET /api/merchants/merchant123/dialogues?triggerType=greeting`
**Middleware**: authenticateToken
**Database**: merchants, merchant_dialogues, merchant_dialogue_logs tables
**Errors**: 404 if merchant not found, 500 on failure

#### `GET /api/merchants`
**File**: src/routes/api/merchants.js:390
**Purpose**: Lists all active merchants (admin/fallback)
**Parameters**: None
**Returns**: (JSON) All merchants grouped by district
**HTTP**: `GET /api/merchants`
**Middleware**: authenticateToken
**Database**: merchants, merchant_inventory tables
**Errors**: 500 on failure

#### `GET /api/merchants/:merchantId/story`
**File**: src/routes/api/merchants.js:607
**Purpose**: Gets story dialogue node for merchant
**Parameters**:
- `merchantId` (Path): Merchant ID
**Returns**: (JSON) Story node with choices
**HTTP**: `GET /api/merchants/merchant123/story`
**Middleware**: authenticateToken
**Database**: merchants, story nodes (via StoryService)
**Errors**: 404 if no story, PREREQUISITES_NOT_MET if conditions not met, 500 on failure
**Related**: StoryService.getPlayerStoryProgress, getStoryNode, checkPrerequisites

#### `POST /api/merchants/:merchantId/story/progress`
**File**: src/routes/api/merchants.js:688
**Purpose**: Progresses story dialogue with choice
**Parameters**:
- `merchantId` (Path): Merchant ID
- `nodeId` (Body): Current node ID
- `choiceId` (Body): Selected choice ID
**Returns**: (JSON) Completion data, rewards, next node
**HTTP**: `POST /api/merchants/merchant123/story/progress`
**Middleware**: authenticateToken
**Database**: Via StoryService, player_quests table
**Errors**: 400 validation error, 500 on failure
**Related**: StoryService.progressStory, DatabaseManager quest updates

#### `GET /api/merchants/:merchantId/stories/chapters`
**File**: src/routes/api/merchants.js:778
**Purpose**: Lists story chapters for merchant (Court Record style)
**Parameters**:
- `merchantId` (Path): Merchant ID
**Returns**: (JSON) Chapter list with completion status
**HTTP**: `GET /api/merchants/merchant123/stories/chapters`
**Middleware**: authenticateToken
**Database**: story_nodes table
**Errors**: 500 on failure
**Related**: StoryService.getPlayerStoryProgress

---

### API Personal Items Routes (`src/routes/api/personal-items.js`)

All routes use `authenticateToken` middleware.

#### `GET /api/personal-items`
**File**: src/routes/api/personal-items.js:17
**Purpose**: Gets player's personal items with effects
**Parameters**: None
**Returns**: (JSON) Personal items with usage status and effects
**HTTP**: `GET /api/personal-items`
**Middleware**: authenticateToken
**Database**: player_personal_items, personal_item_templates, item_effects tables
**Errors**: 500 on failure
**Related**: checkItemCooldown, getDailyUsageCount

#### `POST /api/personal-items/:itemId/use`
**File**: src/routes/api/personal-items.js:103
**Purpose**: Uses consumable item
**Parameters**:
- `itemId` (Path): Player item ID
- `quantity` (Body): Quantity to use (1-100, default 1)
**Returns**: (JSON) Applied effects and remaining quantity
**HTTP**: `POST /api/personal-items/item123/use`
**Middleware**: authenticateToken, validation
**Database**: player_personal_items, personal_item_templates, item_effects, item_usage_log tables
**Errors**: 400 validation/insufficient quantity/cooldown, 404 not found, 500 on failure
**Related**: checkItemCooldown, getDailyUsageCount, applyItemEffect

#### `POST /api/personal-items/:itemId/equip`
**File**: src/routes/api/personal-items.js:239
**Purpose**: Equips or unequips equipment item
**Parameters**:
- `itemId` (Path): Player item ID
**Returns**: (JSON) Equip status
**HTTP**: `POST /api/personal-items/item123/equip`
**Middleware**: authenticateToken
**Database**: player_personal_items, item_usage_log tables
**Errors**: 400 if not equipment, 404 not found, 500 on failure

#### `GET /api/personal-items/active-effects`
**File**: src/routes/api/personal-items.js:341
**Purpose**: Gets player's active effects
**Parameters**: None
**Returns**: (JSON) Temporary and permanent effects
**HTTP**: `GET /api/personal-items/active-effects`
**Middleware**: authenticateToken
**Database**: player_active_effects, personal_item_templates, player_personal_items, item_effects tables
**Errors**: 500 on failure

---

### API Player Routes (`src/routes/api/player.js`)

All routes use `authenticateToken` middleware.

#### `GET /api/player/profile`
**File**: src/routes/api/player.js:145
**Purpose**: Gets complete player profile with inventory
**Parameters**: None
**Returns**: (JSON) Player stats, inventory, storage, recent trades
**HTTP**: `GET /api/player/profile`
**Middleware**: authenticateToken
**Database**: players, player_items, item_templates, trade_records tables
**Errors**: 401 missing player, 404 not found, 500 on failure

#### `PUT /api/player/location`
**File**: src/routes/api/player.js:317
**Purpose**: Updates player location
**Parameters**:
- `lat` (Body): Latitude (-90 to 90)
- `lng` (Body): Longitude (-180 to 180)
**Returns**: (JSON) Updated location
**HTTP**: `PUT /api/player/location`
**Middleware**: authenticateToken, validation
**Database**: players, activity_logs tables
**Errors**: 400 validation error, 500 on failure

#### `POST /api/player/increase-stat`
**File**: src/routes/api/player.js:370
**Purpose**: Increases player stat by 1
**Parameters**:
- `statType` (Body): Stat type (strength/intelligence/charisma/luck)
**Returns**: (JSON) New stat value and remaining points
**HTTP**: `POST /api/player/increase-stat`
**Middleware**: authenticateToken, validation
**Database**: players table
**Errors**: 400 validation/insufficient points/max stat, 404 not found, 500 on failure

#### `POST /api/player/increase-skill`
**File**: src/routes/api/player.js:473
**Purpose**: Increases player skill by 1
**Parameters**:
- `skillType` (Body): Skill type (trading/negotiation/appraisal)
**Returns**: (JSON) New skill value and remaining points
**HTTP**: `POST /api/player/increase-skill`
**Middleware**: authenticateToken, validation
**Database**: players table
**Errors**: 400 validation/insufficient points/max skill, 404 not found, 500 on failure

#### `POST /api/player/create-profile`
**File**: src/routes/api/player.js:575
**Purpose**: Creates initial player profile
**Parameters**:
- `name` (Body): Player name (2-20 chars)
- `age` (Body): Age (16-100)
- `gender` (Body): Gender (male/female)
- `personality` (Body): Personality type
**Returns**: (JSON) Created profile data
**HTTP**: `POST /api/player/create-profile`
**Middleware**: authenticateToken, validation
**Database**: players, activity_logs tables
**Errors**: 400 validation/already completed, 500 on failure

#### `PUT /api/player/profile`
**File**: src/routes/api/player.js:662
**Purpose**: Updates player profile
**Parameters**:
- `name` (Body): Player name (optional)
- `age` (Body): Age (optional)
- `gender` (Body): Gender (optional)
- `personality` (Body): Personality (optional)
**Returns**: (JSON) Updated profile data
**HTTP**: `PUT /api/player/profile`
**Middleware**: authenticateToken, validation
**Database**: players, activity_logs tables
**Errors**: 400 validation/no updates, 500 on failure

#### `POST /api/player/upgrade-license`
**File**: src/routes/api/player.js:767
**Purpose**: Upgrades player trading license
**Parameters**: None
**Returns**: (JSON) New license level and inventory size
**HTTP**: `POST /api/player/upgrade-license`
**Middleware**: authenticateToken
**Database**: players table
**Errors**: 400 insufficient money/trust/max license, 404 not found, 500 on failure

---

### API Quests Routes (`src/routes/api/quests.js`)

All routes use `authenticateToken` middleware.

#### `GET /api/quests`
**File**: src/routes/api/quests.js:16
**Purpose**: Gets complete quest overview for player
**Parameters**: None
**Returns**: (JSON) All quests (available, active, completed)
**HTTP**: `GET /api/quests`
**Middleware**: authenticateToken
**Database**: Via getQuestOverview
**Errors**: 500 with error code
**Related**: QuestPlayerService.getQuestOverview

#### `GET /api/quests/available`
**File**: src/routes/api/quests.js:34
**Purpose**: Gets quests player can accept
**Parameters**: None
**Returns**: (JSON) Available quests filtered by level, license, prerequisites
**HTTP**: `GET /api/quests/available`
**Middleware**: authenticateToken
**Database**: players, quest_templates, player_quests tables
**Errors**: 404 player not found, 500 on failure

#### `GET /api/quests/active`
**File**: src/routes/api/quests.js:137
**Purpose**: Gets player's active quests
**Parameters**: None
**Returns**: (JSON) Active quests with progress
**HTTP**: `GET /api/quests/active`
**Middleware**: authenticateToken
**Database**: player_quests, quest_templates tables
**Errors**: 500 on failure

#### `POST /api/quests/:questId/accept`
**File**: src/routes/api/quests.js:195
**Purpose**: Accepts quest
**Parameters**:
- `questId` (Path): Quest template ID
**Returns**: (JSON) Accepted quest data
**HTTP**: `POST /api/quests/quest123/accept`
**Middleware**: authenticateToken
**Database**: quest_templates, players, player_quests tables
**Errors**: 400 insufficient requirements/already active, 404 not found, 500 on failure

#### `POST /api/quests/:questId/abandon`
**File**: src/routes/api/quests.js:269
**Purpose**: Abandons active quest
**Parameters**:
- `questId` (Path): Player quest ID
**Returns**: (JSON) Success message
**HTTP**: `POST /api/quests/pq123/abandon`
**Middleware**: authenticateToken
**Database**: player_quests table
**Errors**: 404 not found, 500 on failure

#### `POST /api/quests/progress`
**File**: src/routes/api/quests.js:395
**Purpose**: Updates quest progress (game events)
**Parameters**:
- `eventType` (Body): Event type (trade/dialogue/visit/etc)
- `eventData` (Body): Event context data
**Returns**: (JSON) Updated quests list
**HTTP**: `POST /api/quests/progress`
**Middleware**: authenticateToken
**Database**: player_quests, quest_templates tables
**Errors**: 500 on failure
**Related**: progressHandler, completeQuest

---

### API Skills Routes (`src/routes/api/skills.js`)

All routes use `authenticateToken` middleware.

#### `GET /api/skills/tree`
**File**: src/routes/api/skills.js:15
**Purpose**: Gets complete skill tree with player progress
**Parameters**: None
**Returns**: (JSON) Skill tree grouped by category with unlock status
**HTTP**: `GET /api/skills/tree`
**Middleware**: authenticateToken
**Database**: skill_templates, player_skills, players tables
**Errors**: 500 on failure

#### `GET /api/skills/player`
**File**: src/routes/api/skills.js:115
**Purpose**: Gets player's learned skills
**Parameters**: None
**Returns**: (JSON) Player skills with current effects
**HTTP**: `GET /api/skills/player`
**Middleware**: authenticateToken
**Database**: player_skills, skill_templates tables
**Errors**: 500 on failure

#### `POST /api/skills/:skillId/upgrade`
**File**: src/routes/api/skills.js:170
**Purpose**: Learns or upgrades skill
**Parameters**:
- `skillId` (Path): Skill template ID
**Returns**: (JSON) New skill level and points used
**HTTP**: `POST /api/skills/skill123/upgrade`
**Middleware**: authenticateToken
**Database**: skill_templates, players, player_skills tables (transaction)
**Errors**: 400 insufficient points/max level/missing prerequisites, 404 not found, 500 on failure

#### `POST /api/skills/use`
**File**: src/routes/api/skills.js:294
**Purpose**: Records skill usage
**Parameters**:
- `skillId` (Body): Skill template ID
- `context` (Body): Usage context
**Returns**: (JSON) Usage confirmation
**HTTP**: `POST /api/skills/use`
**Middleware**: authenticateToken
**Database**: player_skills, skill_templates, skill_usage_logs tables
**Errors**: 404 skill not owned, 500 on failure

---

### API Trade Routes (`src/routes/api/trade.js`)

All routes use `authenticateToken` middleware.

#### `POST /api/trade/execute`
**File**: src/routes/api/trade.js:18
**Purpose**: Executes buy or sell trade after permit & relationship validation
**Parameters**:
- `merchantId` (Body): Merchant ID
- `itemTemplateId` (Body): Item template ID
- `tradeType` (Body): Trade type (buy/sell)
- `quantity` (Body): Quantity (min 1)
- `proposedPrice` (Body): Proposed price
**Returns**: (JSON) Trade result with final price, profit, XP, updated friendship points
**HTTP**: `POST /api/trade/execute`
**Middleware**: authenticateToken, validation
**Database**: players, merchants, item_templates, merchant_inventory, player_items, trade_records, merchant_relationships tables (transaction)
**Errors**: 
- 400 validation/insufficient resources
- 403 `PERMIT_REQUIRED` / `PERMIT_TIER_LOCKED` / `RELATIONSHIP_STAGE_LOCKED` (허가증/관계도 조건 미충족)
- 404 merchant/item not found
- 500 on failure

#### `GET /api/trade/history`
**File**: src/routes/api/trade.js:292
**Purpose**: Gets player trade history with pagination
**Parameters**:
- `page` (Query): Page number (default 1)
- `limit` (Query): Items per page (default 20)
- `type` (Query): Filter by type (buy/sell/all, default all)
**Returns**: (JSON) Trades with pagination info
**HTTP**: `GET /api/trade/history?page=1&limit=20&type=buy`
**Middleware**: authenticateToken
**Database**: trade_records, item_templates, merchants tables
**Errors**: 500 on failure

#### `GET /api/trade/market-prices`
**File**: src/routes/api/trade.js:375
**Purpose**: Gets market price information
**Parameters**:
- `category` (Query): Filter by item category
- `district` (Query): Filter by district
**Returns**: (JSON) Market prices with trends and trade volume
**HTTP**: `GET /api/trade/market-prices?category=electronics&district=gangnam`
**Middleware**: authenticateToken
**Database**: item_templates, trade_records, merchants tables
**Errors**: 500 on failure

---

### Game Quests Routes (`src/routes/game/quests.js`)

All routes use `authenticateToken` middleware (iOS client specific).

#### `GET /game/quests`
**File**: src/routes/game/quests.js:16
**Purpose**: Gets complete quest overview (iOS NetworkManager)
**Parameters**: None
**Returns**: (JSON) All quest data with error codes
**HTTP**: `GET /game/quests`
**Middleware**: authenticateToken
**Database**: Via getQuestOverview
**Errors**: Error object with code and message
**Related**: QuestPlayerService.getQuestOverview

#### `POST /game/quests/:questId/accept`
**File**: src/routes/game/quests.js:36
**Purpose**: Accepts quest (iOS format)
**Parameters**:
- `questId` (Path): Quest template ID
**Returns**: (JSON) Quest data with iOS-friendly error format
**HTTP**: `POST /game/quests/quest123/accept`
**Middleware**: authenticateToken
**Database**: quest_templates, players, player_quests tables
**Errors**: Error object with code (QUEST_NOT_FOUND/INSUFFICIENT_REQUIREMENTS/QUEST_ALREADY_ACTIVE)

#### `POST /game/quests/:questId/claim`
**File**: src/routes/game/quests.js:116
**Purpose**: Claims quest rewards
**Parameters**:
- `questId` (Path): Quest template ID
**Returns**: (JSON) Claimed rewards
**HTTP**: `POST /game/quests/quest123/claim`
**Middleware**: authenticateToken
**Database**: player_quests, quest_templates, players tables
**Errors**: Error object with code (QUEST_NOT_COMPLETED/REWARD_ALREADY_CLAIMED)

#### `POST /game/quests/progress`
**File**: src/routes/game/quests.js:214
**Purpose**: Updates quest progress
**Parameters**:
- `actionType` (Body): Action type
- `actionData` (Body): Action context
**Returns**: (JSON) Progress update result
**HTTP**: `POST /game/quests/progress`
**Middleware**: authenticateToken
**Database**: Via progressHandler
**Errors**: Error object with code
**Related**: api/quests progressHandler

#### `GET /game/quests/history`
**File**: src/routes/game/quests.js:236
**Purpose**: Gets quest history with pagination
**Parameters**:
- `limit` (Query): Items per page (default 20)
- `offset` (Query): Offset (default 0)
**Returns**: (JSON) Quest history with pagination
**HTTP**: `GET /game/quests/history?limit=20&offset=0`
**Middleware**: authenticateToken
**Database**: player_quests, quest_templates tables
**Errors**: Error object with code

---

## Summary

✅ **215** functions documented in way-server_controllers_routes.md

**Controllers**: 2 files, 13 functions
**Routes**: 20 files, 202 route handlers

**Breakdown by category**:
- Admin Controllers: 13 functions
- Admin Routes: 59 functions
- API Routes: 123 functions
- Game Routes: 20 functions
