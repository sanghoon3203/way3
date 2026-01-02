'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import styles from '../login/LoginPage.module.css';

type TabType = 'id' | 'password';

export default function RecoverPage() {
    const router = useRouter();
    const [activeTab, setActiveTab] = useState<TabType>('id');

    // 아이디 찾기
    const [findIdEmail, setFindIdEmail] = useState('');
    const [foundUsername, setFoundUsername] = useState('');

    // 비밀번호 찾기
    const [findPwUsername, setFindPwUsername] = useState('');
    const [findPwEmail, setFindPwEmail] = useState('');
    const [resetMessage, setResetMessage] = useState('');

    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleFindId = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setFoundUsername('');

        try {
            const res = await fetch('/api/auth/find-id', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: findIdEmail }),
            });

            const data = await res.json();

            if (res.ok) {
                setFoundUsername(data.username);
            } else {
                setError(data.error || '아이디를 찾을 수 없습니다.');
            }
        } catch (err) {
            setError('서버 오류가 발생했습니다.');
        } finally {
            setLoading(false);
        }
    };

    const handleFindPassword = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setResetMessage('');

        try {
            const res = await fetch('/api/auth/find-password', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    username: findPwUsername,
                    email: findPwEmail
                }),
            });

            const data = await res.json();

            if (res.ok) {
                setResetMessage(data.message);
            } else {
                setError(data.error || '비밀번호를 재설정할 수 없습니다.');
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
                    <span className={styles.logoIcon}>🔍</span>
                    <h1>계정 찾기</h1>
                </div>

                {/* 탭 전환 */}
                <div style={{
                    display: 'flex',
                    gap: '1rem',
                    marginBottom: '1.5rem',
                    borderBottom: '1px solid rgba(255,255,255,0.1)'
                }}>
                    <button
                        type="button"
                        onClick={() => {
                            setActiveTab('id');
                            setError('');
                            setFoundUsername('');
                            setResetMessage('');
                        }}
                        style={{
                            flex: 1,
                            padding: '0.75rem',
                            background: 'none',
                            border: 'none',
                            color: activeTab === 'id' ? '#00d4ff' : 'rgba(255,255,255,0.5)',
                            borderBottom: activeTab === 'id' ? '2px solid #00d4ff' : 'none',
                            cursor: 'pointer',
                            fontSize: '1rem',
                            fontWeight: 600,
                            transition: 'all 0.3s ease'
                        }}
                    >
                        아이디 찾기
                    </button>
                    <button
                        type="button"
                        onClick={() => {
                            setActiveTab('password');
                            setError('');
                            setFoundUsername('');
                            setResetMessage('');
                        }}
                        style={{
                            flex: 1,
                            padding: '0.75rem',
                            background: 'none',
                            border: 'none',
                            color: activeTab === 'password' ? '#00d4ff' : 'rgba(255,255,255,0.5)',
                            borderBottom: activeTab === 'password' ? '2px solid #00d4ff' : 'none',
                            cursor: 'pointer',
                            fontSize: '1rem',
                            fontWeight: 600,
                            transition: 'all 0.3s ease'
                        }}
                    >
                        비밀번호 찾기
                    </button>
                </div>

                {/* 아이디 찾기 폼 */}
                {activeTab === 'id' && (
                    <form onSubmit={handleFindId} className={styles.form}>
                        <div className={styles.inputGroup}>
                            <label>이메일</label>
                            <input
                                type="email"
                                value={findIdEmail}
                                onChange={(e) => setFindIdEmail(e.target.value)}
                                placeholder="가입 시 사용한 이메일"
                                required
                            />
                        </div>

                        {foundUsername && (
                            <div style={{
                                padding: '1rem',
                                background: 'rgba(0, 212, 255, 0.1)',
                                border: '1px solid rgba(0, 212, 255, 0.3)',
                                borderRadius: '8px',
                                color: '#00d4ff',
                                textAlign: 'center',
                                marginBottom: '1rem'
                            }}>
                                회원님의 아이디는 <strong>{foundUsername}</strong> 입니다.
                            </div>
                        )}

                        {error && <div className={styles.error}>{error}</div>}

                        <button type="submit" disabled={loading} className={styles.loginBtn}>
                            {loading ? '검색 중...' : '아이디 찾기'}
                        </button>
                    </form>
                )}

                {/* 비밀번호 찾기 폼 */}
                {activeTab === 'password' && (
                    <form onSubmit={handleFindPassword} className={styles.form}>
                        <div className={styles.inputGroup}>
                            <label>아이디</label>
                            <input
                                type="text"
                                value={findPwUsername}
                                onChange={(e) => setFindPwUsername(e.target.value)}
                                placeholder="아이디를 입력하세요"
                                required
                            />
                        </div>

                        <div className={styles.inputGroup}>
                            <label>이메일</label>
                            <input
                                type="email"
                                value={findPwEmail}
                                onChange={(e) => setFindPwEmail(e.target.value)}
                                placeholder="가입 시 사용한 이메일"
                                required
                            />
                        </div>

                        {resetMessage && (
                            <div style={{
                                padding: '1rem',
                                background: 'rgba(0, 212, 255, 0.1)',
                                border: '1px solid rgba(0, 212, 255, 0.3)',
                                borderRadius: '8px',
                                color: '#00d4ff',
                                textAlign: 'center',
                                marginBottom: '1rem',
                                fontSize: '0.9rem'
                            }}>
                                {resetMessage}
                            </div>
                        )}

                        {error && <div className={styles.error}>{error}</div>}

                        <button type="submit" disabled={loading} className={styles.loginBtn}>
                            {loading ? '처리 중...' : '비밀번호 재설정'}
                        </button>
                    </form>
                )}

                <div className={styles.footer}>
                    <a href="/login" className={styles.link}>로그인으로 돌아가기</a>
                    <span className={styles.divider}>|</span>
                    <a href="/register" className={styles.link}>회원가입</a>
                </div>
            </div>
        </div>
    );
}
