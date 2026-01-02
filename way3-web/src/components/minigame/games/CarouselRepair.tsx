
'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useMinigameStore } from '@/lib/store/minigameStore';
import styles from './CarouselRepair.module.css';

// 3 types of crystals: Red (Anger), Blue (Depression), Black (Fear)
export default function CarouselRepair() {
    const { endGame } = useMinigameStore();

    const [redHp, setRedHp] = useState(20);
    const [blueHold, setBlueHold] = useState(0);
    const [blackSync, setBlackSync] = useState(0);

    const [completed, setCompleted] = useState({ red: false, blue: false, black: false });

    // Check Win Condition
    useEffect(() => {
        if (completed.red && completed.blue && completed.black) {
            setTimeout(() => endGame(true), 2000); // End game after animation
        }
    }, [completed, endGame]);

    // Red Crystal: Tap mechanics
    const handleRedTap = () => {
        if (completed.red) return;
        setRedHp(prev => {
            const next = prev - 1;
            if (next <= 0) {
                setCompleted(c => ({ ...c, red: true }));
                return 0;
            }
            return next;
        });
    };

    // Blue Crystal: Hold mechanics
    const startHold = () => {
        if (completed.blue) return;
        const interval = setInterval(() => {
            setBlueHold(prev => {
                if (prev >= 100) {
                    clearInterval(interval);
                    setCompleted(c => ({ ...c, blue: true }));
                    return 100;
                }
                return prev + 2;
            });
        }, 50);
        // @ts-ignore
        window.blueInterval = interval;
    };

    const endHold = () => {
        // @ts-ignore
        if (window.blueInterval) clearInterval(window.blueInterval);
    };

    // Black Crystal: Timing mechanics (Simple version for MVP: Tap when pulsating)
    // Let's use simpler logic: Click 5 times with delay
    const handleBlackTap = () => {
        if (completed.black) return;
        setBlackSync(prev => {
            const next = prev + 20;
            if (next >= 100) {
                setCompleted(c => ({ ...c, black: true }));
                return 100;
            }
            return next;
        });
    };

    return (
        <div className={styles.container}>
            <h2>회전목마 수리</h2>
            <p>악몽의 결정을 제거하세요!</p>

            <div className={styles.gears}>
                {/* Red: Anger (Tap rapidly) */}
                {!completed.red && (
                    <motion.button
                        className={`${styles.crystal} ${styles.red}`}
                        whileTap={{ scale: 0.9 }}
                        onClick={handleRedTap}
                        initial={{ scale: 1 }}
                        animate={{ scale: [1, 1.1, 1] }}
                        transition={{ repeat: Infinity, duration: 0.5 }}
                    >
                        🔥 {redHp}
                    </motion.button>
                )}

                {/* Blue: Depression (Hold) */}
                {!completed.blue && (
                    <motion.button
                        className={`${styles.crystal} ${styles.blue}`}
                        onMouseDown={startHold}
                        onMouseUp={endHold}
                        onMouseLeave={endHold}
                        onTouchStart={startHold}
                        onTouchEnd={endHold}
                        animate={{ opacity: 1 - (blueHold / 200) }} // Fades out
                    >
                        💧 {Math.floor(blueHold)}%
                    </motion.button>
                )}

                {/* Black: Fear (Sync) - Just placeholders for now */}
                {!completed.black && (
                    <motion.button
                        className={`${styles.crystal} ${styles.black}`}
                        onClick={handleBlackTap}
                        animate={{ scale: [1, 1.2, 1] }}
                        transition={{ repeat: Infinity, duration: 2 }} // Slow pulse
                    >
                        👁️ {blackSync}%
                    </motion.button>
                )}
            </div>

            {completed.red && completed.blue && completed.black && (
                <motion.div
                    className={styles.successMessage}
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                >
                    ✨ 수리 완료! ✨
                </motion.div>
            )}
        </div>
    );
}
