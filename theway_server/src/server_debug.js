// 📁 src/server_debug.js - Way Game Server 진입점 (디버그 버전)
require('dotenv').config();
const app = require('./app_debug');  // Use debug version of app
const { Server } = require('socket.io');
const http = require('http');
// const DatabaseManager = require('./database/DatabaseManager'); // Commented out for debugging
const logger = require('./config/logger');
// const metricsCollector = require('./utils/MetricsCollector'); // Commented out for debugging

const PORT = process.env.PORT || 3000;

// HTTP 서버 생성
const server = http.createServer(app);

// Socket.IO 서버 설정 (모바일 앱 지원 강화)
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || ["http://localhost:3000"];

const io = new Server(server, {
    cors: {
        origin: function(origin, callback) {
            // 모바일 앱에서는 origin이 없을 수 있음
            if (!origin) return callback(null, true);

            // 로컬 네트워크 IP 패턴 허용 (192.168.x.x, 10.x.x.x)
            const localNetworkPattern = /^http:\/\/(192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+|172\.(1[6-9]|2\d|3[01])\.\d+\.\d+):3000$/;

            if (allowedOrigins.includes(origin) || localNetworkPattern.test(origin)) {
                callback(null, true);
            } else {
                logger.warn(`CORS 차단된 origin: ${origin}`);
                callback(new Error('CORS 정책에 의해 차단됨'), false);
            }
        },
        methods: ["GET", "POST"],
        credentials: true
    },
    pingTimeout: 60000,
    pingInterval: 25000,
    // 모바일 앱 지원을 위한 추가 설정
    allowEIO3: true,
    transports: ['websocket', 'polling']
});

// Socket.IO 핸들러 등록 (임시 모크)
require('./socket/handlers_temp')(io);

// 데이터베이스 초기화 및 서버 시작
async function startServer() {
    try {
        // 데이터베이스 연결 및 테이블 생성 - COMMENTED OUT FOR DEBUGGING
        // await DatabaseManager.initialize();
        logger.info('데이터베이스 초기화 스킵됨 (디버그 모드)');

        // 서버 시작
        server.listen(PORT, () => {
            logger.info(`🚀 Way Game Server 시작됨 - 포트: ${PORT} (디버그 모드)`);
            logger.info(`📱 환경: ${process.env.NODE_ENV}`);
            logger.info(`🗄️  데이터베이스: DISABLED FOR DEBUGGING`);

            // 메트릭 수집 시작 - COMMENTED OUT
            // metricsCollector.start();
            logger.info('📊 실시간 메트릭 수집 스킵됨 (디버그 모드)');

            logger.info('='.repeat(50));
            logger.info('🐛 DEBUG MODE: Server running without database connectivity');
            logger.info('🌐 Test the server: http://localhost:3000');
            logger.info('💚 Health check: http://localhost:3000/health');
            logger.info('='.repeat(50));
        });

    } catch (error) {
        logger.error('서버 시작 실패:', error);
        process.exit(1);
    }
}

// 우아한 종료 처리
process.on('SIGTERM', async () => {
    logger.info('SIGTERM 신호 받음. 서버를 종료합니다...');

    server.close(async () => {
        // metricsCollector.stop();
        // await DatabaseManager.close();
        logger.info('서버가 정상적으로 종료되었습니다.');
        process.exit(0);
    });
});

process.on('SIGINT', async () => {
    logger.info('SIGINT 신호 받음. 서버를 종료합니다...');

    server.close(async () => {
        // metricsCollector.stop();
        // await DatabaseManager.close();
        logger.info('서버가 정상적으로 종료되었습니다.');
        process.exit(0);
    });
});

// 처리되지 않은 오류 처리
process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception:', error);
    process.exit(1);
});

// 서버 시작
startServer();