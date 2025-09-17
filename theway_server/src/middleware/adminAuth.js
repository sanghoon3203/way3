// 📁 src/middleware/adminAuth.js - 어드민 인증 미들웨어
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const DatabaseManager = require('../database/DatabaseManager');
const logger = require('../config/logger');

// 어드민 권한 레벨 정의
const ADMIN_ROLES = {
    SUPER_ADMIN: 'super_admin',
    ADMIN: 'admin', 
    MODERATOR: 'moderator'
};

// 권한별 접근 가능 기능 정의
const PERMISSIONS = {
    [ADMIN_ROLES.SUPER_ADMIN]: [
        'users.create', 'users.read', 'users.update', 'users.delete',
        'players.create', 'players.read', 'players.update', 'players.delete',
        'quests.create', 'quests.read', 'quests.update', 'quests.delete',
        'skills.create', 'skills.read', 'skills.update', 'skills.delete',
        'items.create', 'items.read', 'items.update', 'items.delete',
        'merchants.create', 'merchants.read', 'merchants.update', 'merchants.delete',
        'admin.create', 'admin.read', 'admin.update', 'admin.delete',
        'system.settings', 'system.maintenance', 'analytics.all'
    ],
    [ADMIN_ROLES.ADMIN]: [
        'users.read', 'users.update',
        'players.read', 'players.update', 'players.delete',
        'quests.create', 'quests.read', 'quests.update', 'quests.delete',
        'skills.create', 'skills.read', 'skills.update', 'skills.delete',
        'items.create', 'items.read', 'items.update', 'items.delete',
        'merchants.create', 'merchants.read', 'merchants.update', 'merchants.delete',
        'analytics.read'
    ],
    [ADMIN_ROLES.MODERATOR]: [
        'users.read',
        'players.read', 'players.update',
        'quests.read', 'quests.update',
        'skills.read',
        'items.read',
        'merchants.read',
        'analytics.read'
    ]
};

class AdminAuth {
    
    // 어드민 로그인
    static async login(username, password) {
        try {
            const admin = await DatabaseManager.get(
                'SELECT * FROM admin_users WHERE username = ? AND is_active = 1',
                [username]
            );
            
            if (!admin) {
                throw new Error('존재하지 않는 사용자입니다');
            }
            
            const isValidPassword = await bcrypt.compare(password, admin.password_hash);
            if (!isValidPassword) {
                throw new Error('비밀번호가 일치하지 않습니다');
            }
            
            // 마지막 로그인 시간 업데이트
            await DatabaseManager.run(
                'UPDATE admin_users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?',
                [admin.id]
            );
            
            // JWT 토큰 생성
            const token = jwt.sign(
                { 
                    adminId: admin.id, 
                    username: admin.username,
                    role: admin.role,
                    permissions: JSON.parse(admin.permissions || '[]')
                },
                process.env.ADMIN_JWT_SECRET || 'admin_secret_key_2024',
                { expiresIn: '8h' }
            );
            
            logger.info('어드민 로그인 성공', {
                adminId: admin.id,
                username: admin.username,
                role: admin.role
            });
            
            return {
                token,
                admin: {
                    id: admin.id,
                    username: admin.username,
                    email: admin.email,
                    role: admin.role,
                    permissions: JSON.parse(admin.permissions || '[]')
                }
            };
            
        } catch (error) {
            logger.error('어드민 로그인 실패:', { username, error: error.message });
            throw error;
        }
    }
    
    // 어드민 사용자 생성
    static async createAdmin(creatorId, userData) {
        const { username, email, password, role = ADMIN_ROLES.MODERATOR } = userData;
        
        try {
            // 중복 체크
            const existing = await DatabaseManager.get(
                'SELECT id FROM admin_users WHERE username = ? OR email = ?',
                [username, email]
            );
            
            if (existing) {
                throw new Error('이미 존재하는 사용자명 또는 이메일입니다');
            }
            
            // 비밀번호 해시화
            const saltRounds = 12;
            const passwordHash = await bcrypt.hash(password, saltRounds);
            
            // 기본 권한 설정
            const permissions = PERMISSIONS[role] || PERMISSIONS[ADMIN_ROLES.MODERATOR];
            
            const adminId = require('crypto').randomUUID();
            
            await DatabaseManager.run(`
                INSERT INTO admin_users (
                    id, username, email, password_hash, role, 
                    permissions, created_by, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            `, [
                adminId, username, email, passwordHash, role,
                JSON.stringify(permissions), creatorId
            ]);
            
            logger.info('어드민 사용자 생성', {
                adminId,
                username,
                role,
                createdBy: creatorId
            });
            
            return { adminId, username, email, role, permissions };
            
        } catch (error) {
            logger.error('어드민 사용자 생성 실패:', { username, error: error.message });
            throw error;
        }
    }
    
    // JWT 토큰 검증 미들웨어
    static authenticateToken(req, res, next) {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({
                success: false,
                error: '어드민 인증 토큰이 필요합니다'
            });
        }
        
        jwt.verify(token, process.env.ADMIN_JWT_SECRET || 'admin_secret_key_2024', (err, admin) => {
            if (err) {
                return res.status(403).json({
                    success: false,
                    error: '유효하지 않은 어드민 토큰입니다'
                });
            }
            
            req.admin = admin;
            next();
        });
    }
    
    // 권한 검증 미들웨어
    static requirePermission(permission) {
        return (req, res, next) => {
            const admin = req.admin;
            
            if (!admin) {
                return res.status(401).json({
                    success: false,
                    error: '어드민 인증이 필요합니다'
                });
            }
            
            const hasPermission = admin.permissions.includes(permission) || 
                                admin.role === ADMIN_ROLES.SUPER_ADMIN;
            
            if (!hasPermission) {
                logger.warn('권한 부족한 어드민 접근 시도', {
                    adminId: admin.adminId,
                    username: admin.username,
                    requiredPermission: permission,
                    userPermissions: admin.permissions
                });
                
                return res.status(403).json({
                    success: false,
                    error: '해당 작업에 대한 권한이 없습니다',
                    required: permission
                });
            }
            
            next();
        };
    }
    
    // 액션 로그 기록
    static async logAction(adminId, actionType, targetType, targetId, oldData, newData, req) {
        try {
            const logId = require('crypto').randomUUID();
            
            await DatabaseManager.run(`
                INSERT INTO admin_action_logs (
                    id, admin_user_id, action_type, target_type, target_id,
                    old_data, new_data, ip_address, user_agent, performed_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            `, [
                logId, adminId, actionType, targetType, targetId,
                oldData ? JSON.stringify(oldData) : null,
                newData ? JSON.stringify(newData) : null,
                req.ip || req.connection.remoteAddress,
                req.get('User-Agent') || ''
            ]);
            
        } catch (error) {
            logger.error('어드민 액션 로그 기록 실패:', error);
        }
    }
    
    // 초기 슈퍼 어드민 생성 (최초 설정용)
    static async initializeSuperAdmin() {
        try {
            const existingSuperAdmin = await DatabaseManager.get(
                'SELECT id FROM admin_users WHERE role = ? LIMIT 1',
                [ADMIN_ROLES.SUPER_ADMIN]
            );
            
            if (existingSuperAdmin) {
                logger.info('슈퍼 어드민이 이미 존재합니다');
                return null;
            }
            
            const superAdminData = {
                username: 'superadmin',
                email: 'admin@waygame.com',
                password: 'WayGame2024!',
                role: ADMIN_ROLES.SUPER_ADMIN
            };
            
            const result = await this.createAdmin(null, superAdminData);
            logger.info('초기 슈퍼 어드민 생성 완료', { username: 'superadmin' });
            
            return result;
            
        } catch (error) {
            logger.error('초기 슈퍼 어드민 생성 실패:', error);
            throw error;
        }
    }
}

module.exports = {
    AdminAuth,
    ADMIN_ROLES,
    PERMISSIONS
};