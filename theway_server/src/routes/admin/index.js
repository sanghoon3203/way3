// 📁 src/routes/admin/index.js - 어드민 라우트 (기본 구조)
const express = require('express');
const DatabaseManager = require('../../database/DatabaseManager');
const logger = require('../../config/logger');

const router = express.Router();

// 어드민 인증 라우트 추가
const authRouter = require('./auth');
router.use('/auth', authRouter);

// CRUD 라우트 추가
const crudRouter = require('./crud');
router.use('/crud', crudRouter);

// 모니터링 라우트 추가
const monitoringRouter = require('./monitoring');
router.use('/monitoring', monitoringRouter);

// 퀘스트 관리 라우트 추가
const questsRouter = require('./quests');
router.use('/quests', questsRouter);

// 스킬 관리 라우트 추가
const skillsRouter = require('./skills');
router.use('/skills', skillsRouter);

// 메트릭 API 라우트 추가
const metricsRouter = require('./metrics');
router.use('/api/metrics', metricsRouter);

/**
 * 어드민 메인 대시보드
 * GET /admin
 */
router.get('/', async (req, res) => {
    try {
        // 기본 통계 조회
        const stats = await Promise.all([
            DatabaseManager.get('SELECT COUNT(*) as count FROM players'),
            DatabaseManager.get('SELECT COUNT(*) as count FROM trade_records WHERE date(created_at) = date("now")'),
            DatabaseManager.get('SELECT SUM(total_price) as total FROM trade_records WHERE date(created_at) = date("now")'),
            DatabaseManager.get('SELECT COUNT(*) as count FROM merchants WHERE is_active = 1')
        ]);

        const dashboardData = {
            totalPlayers: stats[0]?.count || 0,
            dailyTrades: stats[1]?.count || 0,
            dailyRevenue: stats[2]?.total || 0,
            activeMerchants: stats[3]?.count || 0,
            serverStatus: 'running'
        };

        // 간단한 HTML 응답 (추후 템플릿 엔진으로 교체)
        res.send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Way Game Admin</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    .stat-card { 
                        display: inline-block; 
                        margin: 10px; 
                        padding: 20px; 
                        border: 1px solid #ddd; 
                        border-radius: 8px;
                        min-width: 150px;
                        text-align: center;
                    }
                    .stat-value { font-size: 24px; font-weight: bold; color: #333; }
                    .stat-label { color: #666; margin-top: 5px; }
                </style>
            </head>
            <body>
                <h1>🎮 Way Game Admin Dashboard</h1>
                
                <div class="stats">
                    <div class="stat-card">
                        <div class="stat-value">${dashboardData.totalPlayers}</div>
                        <div class="stat-label">총 플레이어</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">${dashboardData.dailyTrades}</div>
                        <div class="stat-label">오늘 거래 횟수</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">${dashboardData.dailyRevenue.toLocaleString()}원</div>
                        <div class="stat-label">오늘 총 거래량</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">${dashboardData.activeMerchants}</div>
                        <div class="stat-label">활성 상인</div>
                    </div>
                </div>
                
                <h2>📊 관리 메뉴</h2>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; margin: 20px 0;">
                    <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; text-align: center;">
                        <h3 style="margin: 0 0 10px 0;">👥 데이터 관리</h3>
                        <a href="/admin/crud/players">플레이어</a> | 
                        <a href="/admin/crud/merchants">상인</a> | 
                        <a href="/admin/crud/items">아이템</a>
                    </div>
                    <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; text-align: center;">
                        <h3 style="margin: 0 0 10px 0;">🎯 퀘스트 관리</h3>
                        <a href="/admin/quests">퀘스트 대시보드</a><br>
                        <a href="/admin/quests/create">새 퀘스트</a> | 
                        <a href="/admin/quests/statistics">통계</a>
                    </div>
                    <div style="background: #f3e5f5; padding: 15px; border-radius: 8px; text-align: center;">
                        <h3 style="margin: 0 0 10px 0;">⚡ 스킬 관리</h3>
                        <a href="/admin/skills">스킬 대시보드</a><br>
                        <a href="/admin/skills/create">새 스킬</a> | 
                        <a href="/admin/skills/tree">스킬 트리</a>
                    </div>
                    <div style="background: #fff3e0; padding: 15px; border-radius: 8px; text-align: center;">
                        <h3 style="margin: 0 0 10px 0;">📊 시스템 모니터링</h3>
                        <a href="/admin/monitoring">실시간 모니터링</a><br>
                        <a href="/admin/monitoring/api/metrics" target="_blank">API 메트릭</a>
                    </div>
                </div>
                
                <h2>🛠️ Server Status</h2>
                <p><strong>Status:</strong> ${dashboardData.serverStatus}</p>
                <p><strong>Uptime:</strong> ${Math.round(process.uptime())} seconds</p>
                <p><strong>Memory:</strong> ${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)} MB</p>
            </body>
            </html>
        `);

    } catch (error) {
        logger.error('어드민 대시보드 로드 실패:', error);
        res.status(500).send('서버 오류가 발생했습니다');
    }
});

/**
 * 플레이어 목록
 * GET /admin/players
 */
router.get('/players', async (req, res) => {
    try {
        const players = await DatabaseManager.all(`
            SELECT 
                id, name, level, money, current_license, total_trades, 
                created_at, last_active
            FROM players 
            ORDER BY last_active DESC 
            LIMIT 50
        `);

        let tableRows = players.map(player => `
            <tr>
                <td>${player.name}</td>
                <td>${player.level}</td>
                <td>Level ${player.current_license}</td>
                <td>${player.money.toLocaleString()}원</td>
                <td>${player.total_trades}</td>
                <td>${new Date(player.last_active).toLocaleString()}</td>
            </tr>
        `).join('');

        res.send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>플레이어 관리 - Way Game Admin</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    table { border-collapse: collapse; width: 100%; }
                    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                    th { background-color: #f2f2f2; }
                    .back-link { margin-bottom: 20px; }
                </style>
            </head>
            <body>
                <div class="back-link"><a href="/admin">← 대시보드로 돌아가기</a></div>
                
                <h1>👥 플레이어 관리</h1>
                <p>총 ${players.length}명의 플레이어</p>
                
                <table>
                    <tr>
                        <th>이름</th>
                        <th>레벨</th>
                        <th>라이센스</th>
                        <th>보유금</th>
                        <th>거래횟수</th>
                        <th>최종 접속</th>
                    </tr>
                    ${tableRows}
                </table>
            </body>
            </html>
        `);

    } catch (error) {
        logger.error('플레이어 목록 조회 실패:', error);
        res.status(500).send('서버 오류가 발생했습니다');
    }
});

module.exports = router;