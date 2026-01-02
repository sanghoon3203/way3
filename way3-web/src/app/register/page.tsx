'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import styles from '../login/LoginPage.module.css';

export default function RegisterPage() {
    const router = useRouter();
    const [username, setUsername] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [passwordConfirm, setPasswordConfirm] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        // 비밀번호 확인
        if (password !== passwordConfirm) {
            setError('비밀번호가 일치하지 않습니다.');
            setLoading(false);
            return;
        }

        try {
            const res = await fetch('/api/auth/register', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, email, password }),
            });

            const data = await res.json();

            if (res.ok) {
                // 회원가입 성공 - 로그인 페이지로 이동
                alert('회원가입이 완료되었습니다! 로그인해주세요.');
                router.push('/login');
            } else {
                setError(data.error || '회원가입에 실패했습니다.');
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
                    <p style={{ fontSize: '0.9rem', opacity: 0.7, marginTop: '0.5rem' }}>
                        새로운 여정을 시작하세요
                    </p>
                </div>

                <form onSubmit={handleSubmit} className={styles.form}>
                    <div className={styles.inputGroup}>
                        <label>아이디</label>
                        <input
                            type="text"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            placeholder="3글자 이상"
                            required
                            minLength={3}
                        />
                    </div>

                    <div className={styles.inputGroup}>
                        <label>이메일</label>
                        <input
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="example@email.com"
                            required
                        />
                    </div>

                    <div className={styles.inputGroup}>
                        <label>비밀번호</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="6글자 이상"
                            required
                            minLength={6}
                        />
                    </div>

                    <div className={styles.inputGroup}>
                        <label>비밀번호 확인</label>
                        <input
                            type="password"
                            value={passwordConfirm}
                            onChange={(e) => setPasswordConfirm(e.target.value)}
                            placeholder="비밀번호 재입력"
                            required
                        />
                    </div>

                    {error && <div className={styles.error}>{error}</div>}

                    <button type="submit" disabled={loading} className={styles.loginBtn}>
                        {loading ? '처리 중...' : '회원가입'}
                    </button>
                </form>

                <div className={styles.footer}>
                    <a href="/login" className={styles.link}>이미 계정이 있으신가요? 로그인</a>
                </div>
            </div>
        </div>
    );
}
