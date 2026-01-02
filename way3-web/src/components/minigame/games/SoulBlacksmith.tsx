
'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useMinigameStore } from '@/lib/store/minigameStore';
import styles from './SoulBlacksmith.module.css';

export default function SoulBlacksmith() {
    const { endGame } = useMinigameStore();
    const [combo, setCombo] = useState(0);
    const [score, setScore] = useState(0); // Target: 1000?
    const [message, setMessage] = useState('Wait for the Hammer...');
    const [hammerState, setHammerState] = useState<'idle' | 'hit'>('idle');
    const [sparkVisible, setSparkVisible] = useState(false);

    // Rhythm Logic (Simulated)
    // Computer hits at T=0, Player must hit at T=500ms (Off-beat)
    // Loop every 1000ms

    const [beatPhase, setBeatPhase] = useState<'hammer' | 'player'>('hammer');
    const intervalRef = useRef<NodeJS.Timeout | undefined>(undefined);
    const startTimeRef = useRef<number>(0);

    useEffect(() => {
        // Start loop
        setMessage('Listen to the rhythm! (Hammer... YOU!)');

        const loop = () => {
            const now = Date.now();
            startTimeRef.current = now;
            setBeatPhase('hammer');
            setHammerState('hit');

            // Reset hammer animation
            setTimeout(() => setHammerState('idle'), 200);

            // Switch to player phase after 400ms
            setTimeout(() => {
                setBeatPhase('player');
            }, 400);
        };

        loop(); // First hit
        intervalRef.current = setInterval(loop, 1200); // 1.2s BPM = 50 BPM (Slow heavy pounding)

        return () => clearInterval(intervalRef.current);
    }, []);

    const handleStrike = () => {
        const now = Date.now();
        const diff = now - startTimeRef.current;
        // Ideally player hits around 600ms (halfway)
        const targetTime = 600;
        const accuracy = Math.abs(diff - targetTime);

        if (accuracy < 150) {
            // Good Hit
            setCombo(c => c + 1);
            setScore(s => s + 100 + (combo * 10));
            setMessage('PERFECT! 🔥');
            setSparkVisible(true);
            setTimeout(() => setSparkVisible(false), 200);
        } else if (accuracy < 300) {
            // Okay Hit
            setCombo(0);
            setScore(s => s + 50);
            setMessage('Good... but tighter!');
        } else {
            // Miss
            setCombo(0);
            setMessage('MISS! (Too early/late)');
        }
    };

    // Win Condition
    useEffect(() => {
        if (score >= 1500) {
            clearInterval(intervalRef.current);
            setMessage('MASTERPIECE FORGED! ⚔️');
            setTimeout(() => endGame(true), 2500);
        }
    }, [score, endGame]);

    return (
        <div className={styles.container}>
            <h2>⚔️ Soul Synchro (Rhythm)</h2>
            <div className={styles.stats}>
                <div>Score: {score}</div>
                <div>Combo: {combo}</div>
            </div>
            <div className={styles.message}>{message}</div>

            <div className={styles.forge}>
                {/* Hammer (Visual) */}
                <motion.div
                    className={styles.hammer}
                    animate={hammerState === 'hit' ? { rotate: -45, y: 10 } : { rotate: 0, y: 0 }}
                    transition={{ type: "spring", stiffness: 300, damping: 10 }}
                >
                    🔨
                </motion.div>

                {/* Anvil */}
                <div className={styles.anvil}>
                    ⬛
                    <AnimatePresence>
                        {sparkVisible && (
                            <motion.div
                                className={styles.spark}
                                initial={{ opacity: 1, scale: 0.5 }}
                                animate={{ opacity: 0, scale: 2 }}
                                exit={{ opacity: 0 }}
                            >
                                💥
                            </motion.div>
                        )}
                    </AnimatePresence>
                </div>
            </div>

            {/* Player Input Area */}
            <button
                className={`${styles.bellowsBtn} ${beatPhase === 'player' ? styles.active : ''}`}
                onMouseDown={handleStrike}
                onTouchStart={handleStrike}
            >
                PRESS SPACE / TAP!
            </button>

            {/* Visual Metronome */}
            <div className={styles.metronome}>
                <div className={`${styles.beat} ${beatPhase === 'hammer' ? styles.hammerBeat : ''}`} />
                <div className={`${styles.beat} ${beatPhase === 'player' ? styles.playerBeat : ''}`} />
            </div>
        </div>
    );
}
