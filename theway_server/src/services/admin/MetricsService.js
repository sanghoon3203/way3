// 📁 src/services/admin/MetricsService.js - 시스템 메트릭 수집 서비스
const DatabaseManager = require('../../database/DatabaseManager');
const logger = require('../../config/logger');
const os = require('os');
const { performance } = require('perf_hooks');

class MetricsService {
    
    // 종합 시스템 메트릭 수집
    static async collectSystemMetrics() {
        try {
            const startTime = performance.now();
            
            const [
                serverMetrics,
                gameMetrics,
                databaseMetrics,
                playerMetrics
            ] = await Promise.all([
                this.getServerMetrics(),
                this.getGameMetrics(),
                this.getDatabaseMetrics(),
                this.getPlayerMetrics()
            ]);

            const collectionTime = Math.round(performance.now() - startTime);
            
            const metrics = {
                timestamp: new Date().toISOString(),
                collectionTime: `${collectionTime}ms`,
                server: serverMetrics,
                game: gameMetrics,
                database: databaseMetrics,
                players: playerMetrics
            };

            // 메트릭을 데이터베이스에 저장
            await this.saveMetrics(metrics);
            
            return metrics;
        } catch (error) {
            logger.error('메트릭 수집 실패:', error);
            throw error;
        }
    }

    // 서버 시스템 메트릭
    static async getServerMetrics() {
        const memoryUsage = process.memoryUsage();
        const cpuUsage = process.cpuUsage();
        
        return {
            uptime: {
                seconds: Math.floor(process.uptime()),
                formatted: this.formatUptime(process.uptime())
            },
            memory: {
                used: Math.round(memoryUsage.heapUsed / 1024 / 1024), // MB
                total: Math.round(memoryUsage.heapTotal / 1024 / 1024), // MB
                external: Math.round(memoryUsage.external / 1024 / 1024), // MB
                systemTotal: Math.round(os.totalmem() / 1024 / 1024), // MB
                systemFree: Math.round(os.freemem() / 1024 / 1024), // MB
                usage: Math.round((memoryUsage.heapUsed / memoryUsage.heapTotal) * 100) // %
            },
            cpu: {
                model: os.cpus()[0].model,
                cores: os.cpus().length,
                load: os.loadavg(),
                usage: this.calculateCPUUsage(cpuUsage)
            },
            system: {
                platform: os.platform(),
                arch: os.arch(),
                nodeVersion: process.version,
                pid: process.pid
            }
        };
    }

    // 게임 관련 메트릭
    static async getGameMetrics() {
        const now = new Date();
        const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const weekStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

        const [
            totalPlayers,
            activePlayers,
            todayTrades,
            weeklyTrades,
            totalTrades,
            activeMerchants,
            totalQuests,
            activeQuests,
            totalSkills
        ] = await Promise.all([
            DatabaseManager.get('SELECT COUNT(*) as count FROM players'),
            DatabaseManager.get(`
                SELECT COUNT(*) as count FROM players 
                WHERE last_active > datetime('now', '-1 hour')
            `),
            DatabaseManager.get(`
                SELECT COUNT(*) as count, COALESCE(SUM(total_price), 0) as volume
                FROM trade_records 
                WHERE created_at >= ?
            `, [todayStart.toISOString()]),
            DatabaseManager.get(`
                SELECT COUNT(*) as count, COALESCE(SUM(total_price), 0) as volume
                FROM trade_records 
                WHERE created_at >= ?
            `, [weekStart.toISOString()]),
            DatabaseManager.get('SELECT COUNT(*) as count FROM trade_records'),
            DatabaseManager.get('SELECT COUNT(*) as count FROM merchants WHERE is_active = 1'),
            DatabaseManager.get('SELECT COUNT(*) as count FROM quest_templates'),
            DatabaseManager.get('SELECT COUNT(*) as count FROM quest_templates WHERE is_active = 1'),
            DatabaseManager.get('SELECT COUNT(*) as count FROM skill_templates WHERE is_active = 1')
        ]);

        return {
            players: {
                total: totalPlayers.count,
                active: activePlayers.count,
                onlineRate: totalPlayers.count > 0 ? 
                    Math.round((activePlayers.count / totalPlayers.count) * 100) : 0
            },
            trades: {
                today: {
                    count: todayTrades.count,
                    volume: todayTrades.volume || 0
                },
                weekly: {
                    count: weeklyTrades.count,
                    volume: weeklyTrades.volume || 0
                },
                total: totalTrades.count,
                avgPerDay: weeklyTrades.count > 0 ? Math.round(weeklyTrades.count / 7) : 0
            },
            merchants: {
                active: activeMerchants.count
            },
            content: {
                quests: {
                    total: totalQuests.count,
                    active: activeQuests.count
                },
                skills: {
                    total: totalSkills.count
                }
            }
        };
    }

    // 데이터베이스 메트릭
    static async getDatabaseMetrics() {
        const dbPath = process.env.DB_PATH || './data/way_game.sqlite';
        
        try {
            const fs = require('fs');
            const stats = fs.statSync(dbPath);
            
            // 테이블별 레코드 수
            const [
                usersCount,
                playersCount,
                merchantsCount,
                itemsCount,
                tradesCount,
                questsCount,
                skillsCount
            ] = await Promise.all([
                DatabaseManager.get('SELECT COUNT(*) as count FROM users'),
                DatabaseManager.get('SELECT COUNT(*) as count FROM players'),
                DatabaseManager.get('SELECT COUNT(*) as count FROM merchants'),
                DatabaseManager.get('SELECT COUNT(*) as count FROM item_templates'),
                DatabaseManager.get('SELECT COUNT(*) as count FROM trade_records'),
                DatabaseManager.get('SELECT COUNT(*) as count FROM quest_templates'),
                DatabaseManager.get('SELECT COUNT(*) as count FROM skill_templates')
            ]);

            return {
                file: {
                    size: Math.round(stats.size / 1024 / 1024 * 100) / 100, // MB
                    modified: stats.mtime.toISOString()
                },
                tables: {
                    users: usersCount.count,
                    players: playersCount.count,
                    merchants: merchantsCount.count,
                    items: itemsCount.count,
                    trades: tradesCount.count,
                    quests: questsCount.count,
                    skills: skillsCount.count
                },
                performance: {
                    // 간단한 쿼리 성능 테스트
                    queryTime: await this.testQueryPerformance()
                }
            };
        } catch (error) {
            logger.error('데이터베이스 메트릭 수집 실패:', error);
            return {
                error: 'Unable to collect database metrics',
                message: error.message
            };
        }
    }

    // 플레이어 활동 메트릭
    static async getPlayerMetrics() {
        const [
            levelDistribution,
            recentActivity,
            topPlayers,
            locationDistribution
        ] = await Promise.all([
            DatabaseManager.all(`
                SELECT 
                    CASE 
                        WHEN level BETWEEN 1 AND 10 THEN '1-10'
                        WHEN level BETWEEN 11 AND 20 THEN '11-20'
                        WHEN level BETWEEN 21 AND 50 THEN '21-50'
                        ELSE '50+' 
                    END as level_range,
                    COUNT(*) as count
                FROM players 
                GROUP BY level_range
            `),
            DatabaseManager.get(`
                SELECT COUNT(*) as count
                FROM players 
                WHERE last_active > datetime('now', '-24 hours')
            `),
            DatabaseManager.all(`
                SELECT name, level, money, total_trades, reputation
                FROM players 
                ORDER BY level DESC, total_trades DESC 
                LIMIT 5
            `),
            DatabaseManager.all(`
                SELECT 
                    CASE 
                        WHEN last_known_lat IS NOT NULL AND last_known_lng IS NOT NULL 
                        THEN 'Seoul' 
                        ELSE 'Unknown' 
                    END as location,
                    COUNT(*) as count
                FROM players
                GROUP BY location
            `)
        ]);

        return {
            activity: {
                recent24h: recentActivity.count
            },
            levels: levelDistribution,
            topPlayers: topPlayers,
            locations: locationDistribution
        };
    }

    // 메트릭 히스토리 조회
    static async getMetricsHistory(hours = 24) {
        const sinceTime = new Date(Date.now() - hours * 60 * 60 * 1000).toISOString();
        
        const history = await DatabaseManager.all(`
            SELECT 
                datetime(recorded_at) as time,
                metric_name,
                metric_value,
                metric_unit
            FROM server_metrics 
            WHERE recorded_at > ? 
            ORDER BY recorded_at DESC
        `, [sinceTime]);

        // 메트릭별로 그룹핑
        const groupedMetrics = {};
        history.forEach(metric => {
            if (!groupedMetrics[metric.metric_name]) {
                groupedMetrics[metric.metric_name] = [];
            }
            groupedMetrics[metric.metric_name].push({
                time: metric.time,
                value: metric.metric_value,
                unit: metric.metric_unit
            });
        });

        return groupedMetrics;
    }

    // 알람 조건 검사
    static async checkAlerts(metrics) {
        const alerts = [];

        // 메모리 사용량 경고 (80% 이상)
        if (metrics.server.memory.usage > 80) {
            alerts.push({
                level: 'warning',
                type: 'memory',
                message: `메모리 사용량이 ${metrics.server.memory.usage}%입니다`,
                value: metrics.server.memory.usage,
                threshold: 80
            });
        }

        // 활성 플레이어 급감 경고
        const previousMetrics = await this.getPreviousMetrics();
        if (previousMetrics && metrics.players.active < previousMetrics.players.active * 0.5) {
            alerts.push({
                level: 'critical',
                type: 'player_drop',
                message: '활성 플레이어 수가 급격히 감소했습니다',
                current: metrics.players.active,
                previous: previousMetrics.players.active
            });
        }

        // 데이터베이스 크기 경고 (1GB 이상)
        if (metrics.database.file && metrics.database.file.size > 1024) {
            alerts.push({
                level: 'info',
                type: 'database_size',
                message: `데이터베이스 크기가 ${metrics.database.file.size}MB입니다`,
                value: metrics.database.file.size
            });
        }

        return alerts;
    }

    // 헬퍼 메서드들
    static formatUptime(seconds) {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        
        return `${days}일 ${hours}시간 ${minutes}분`;
    }

    static calculateCPUUsage(cpuUsage) {
        // 간단한 CPU 사용률 계산 (정확하지 않을 수 있음)
        const total = cpuUsage.user + cpuUsage.system;
        return Math.round(total / 1000); // 마이크로초를 밀리초로
    }

    static async testQueryPerformance() {
        const start = performance.now();
        await DatabaseManager.get('SELECT COUNT(*) FROM players');
        return Math.round(performance.now() - start);
    }

    static async saveMetrics(metrics) {
        const metricsToSave = [
            { name: 'memory_usage', value: metrics.server.memory.usage || 0, unit: 'percent' },
            { name: 'memory_used', value: metrics.server.memory.used || 0, unit: 'mb' },
            { name: 'active_players', value: metrics.players?.active || 0, unit: 'count' },
            { name: 'total_players', value: metrics.players?.total || 0, unit: 'count' },
            { name: 'daily_trades', value: metrics.game?.trades?.today?.count || 0, unit: 'count' },
            { name: 'db_size', value: metrics.database?.file?.size || 0, unit: 'mb' },
            { name: 'query_time', value: metrics.database?.performance?.queryTime || 0, unit: 'ms' }
        ];

        for (const metric of metricsToSave) {
            await DatabaseManager.run(`
                INSERT INTO server_metrics (id, metric_name, metric_value, metric_unit)
                VALUES (?, ?, ?, ?)
            `, [
                require('crypto').randomUUID(),
                metric.name,
                metric.value,
                metric.unit
            ]);
        }
    }

    static async getPreviousMetrics() {
        try {
            const previous = await DatabaseManager.get(`
                SELECT metric_value as active_players
                FROM server_metrics
                WHERE metric_name = 'active_players'
                ORDER BY recorded_at DESC
                LIMIT 1 OFFSET 1
            `);
            
            return previous ? { players: { active: previous.active_players } } : null;
        } catch (error) {
            return null;
        }
    }

    // 정리 작업 - 오래된 메트릭 삭제
    static async cleanupOldMetrics(daysToKeep = 30) {
        const cutoffDate = new Date(Date.now() - daysToKeep * 24 * 60 * 60 * 1000).toISOString();
        
        const result = await DatabaseManager.run(`
            DELETE FROM server_metrics 
            WHERE recorded_at < ?
        `, [cutoffDate]);

        logger.info(`오래된 메트릭 정리 완료: ${result.changes}개 레코드 삭제`);
        return result.changes;
    }
}

module.exports = MetricsService;