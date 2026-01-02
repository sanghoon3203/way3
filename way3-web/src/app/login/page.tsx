
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import styles from './LoginPage.module.css';

export default function LoginPage() {
    const router = useRouter();
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    // Auto-fill for testing
    const fillTestUser = () => {
        setUsername('login_test_user');
        setPassword('password123');
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const res = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password }),
            });

            const data = await res.json();

            if (res.ok) {
                // Success
                router.push('/'); // Redirect to main game
                router.refresh(); // Refresh router cache
            } else {
                setError(data.error || '로그인에 실패했습니다.');
            }
        } catch (err) {
            setError('서버 오류가 발생했습니다.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className={styles.container}>
            <div className={styles.card}>
                <div className={styles.logo}>
                    <span className={styles.logoIcon}>🌌</span>
                    <h1>CONNECT : SEOUL</h1>
                </div>

                <form onSubmit={handleSubmit} className={styles.form}>
                    <div className={styles.inputGroup}>
                        <label>아이디</label>
                        <input
                            type="text"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            placeholder="Username"
                            required
                        />
                    </div>

                    <div className={styles.inputGroup}>
                        <label>비밀번호</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="Password"
                            required
                        />
                    </div>

                    {error && <div className={styles.error}>{error}</div>}

                    <button type="submit" disabled={loading} className={styles.loginBtn}>
                        {loading ? '접속 중...' : '접속하기'}
                    </button>
                </form>

                <div className={styles.footer}>
                    <button onClick={fillTestUser} className={styles.testBtn}>
                        (Test) Create/Fill User
                    </button>
                    <a href="/register" className={styles.link}>회원가입</a>
                    <span className={styles.divider}>|</span>
                    <a href="/recover" className={styles.link}>아이디/비밀번호 찾기</a>
                </div>
            </div>
        </div>
    );
}
