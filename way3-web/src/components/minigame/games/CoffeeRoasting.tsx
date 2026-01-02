
'use client';

import { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { useMinigameStore } from '@/lib/store/minigameStore';
import styles from './CoffeeRoasting.module.css';

export default function CoffeeRoasting() {
    const { endGame } = useMinigameStore();

    // Game State
    const [temperature, setTemperature] = useState(20); // Starts at room temp (20°C)
    const [phase, setPhase] = useState<'drying' | 'maillard' | 'development' | 'finished'>('drying');
    const [gasLevel, setGasLevel] = useState(0); // 0 to 100
    const [damperOpen, setDamperOpen] = useState(false); // False = Closed (Heat trapped), True = Open (Airflow, Temp drops)

    const [progress, setProgress] = useState(0); // 0 to 100% per phase
    const [message, setMessage] = useState('Phase 1: Drying (수분 날리기)');

    // Ref for game loop
    const requestRef = useRef<number>();
    const lastTimeRef = useRef<number>();

    // Parameters
    // Phase 1 Target: 150°C
    // Phase 2 Target: 200°C
    // Phase 3 Target: 220°C (Crack!)

    const animate = (time: number) => {
        if (lastTimeRef.current !== undefined) {
            // const deltaTime = time - lastTimeRef.current;

            setTemperature(prevTemp => {
                let change = 0;

                // Gas heats up
                change += (gasLevel / 500);

                // Damper cools down
                if (damperOpen) {
                    change -= 0.15;
                }

                // Natural cooling
                change -= 0.05;

                const newTemp = Math.max(20, prevTemp + change);

                // Phase Logic
                if (phase === 'drying') {
                    if (newTemp > 150) {
                        setPhase('maillard');
                        setMessage('Phase 2: Maillard (메일라드 반응) - 갈변 시작!');
                    }
                } else if (phase === 'maillard') {
                    if (newTemp > 200) {
                        setPhase('development');
                        setMessage('Phase 3: Development (디벨롭먼트) - 향미 발현!');
                    }
                } else if (phase === 'development') {
                    if (newTemp > 230) {
                        // Burned!
                        setMessage('Over-roasted! (잿더미가 되었습니다...)');
                        setTimeout(() => endGame(false), 2000);
                    } else if (newTemp > 215 && progress > 80) {
                        // Success condition handled in Effect
                    }
                }

                return newTemp;
            });

            // Progress Simulation
            setProgress(prev => {
                if (phase === 'finished') return 100;
                return Math.min(100, prev + 0.1);
            });
        }
        lastTimeRef.current = time;
        requestRef.current = requestAnimationFrame(animate);
    };

    useEffect(() => {
        requestRef.current = requestAnimationFrame(animate);
        return () => cancelAnimationFrame(requestRef.current!);
    }, [phase, gasLevel, damperOpen]);


    // Win Condition check
    useEffect(() => {
        if (phase === 'development' && progress >= 100) {
            if (temperature >= 210 && temperature <= 225) {
                setPhase('finished');
                setMessage('Perfect Roast! (완벽한 원두입니다!)');
                setTimeout(() => endGame(true), 3000);
            } else {
                setMessage('Under-developed... (덜 볶였습니다)');
                setTimeout(() => endGame(false), 2000);
            }
        }
    }, [progress, phase, temperature, endGame]);


    // Handlers
    const handleGasChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setGasLevel(Number(e.target.value));
    };

    const toggleDamper = () => {
        setDamperOpen(!damperOpen);
    };

    return (
        <div className={styles.container}>
            <h2>☕ Terra Roasting</h2>
            <div className={styles.statusPanel}>
                <div className={styles.tempDisplay}>
                    {Math.floor(temperature)}°C
                </div>
                <div className={styles.message}>{message}</div>
            </div>

            {/* Roaster Visual */}
            <div className={styles.roaster}>
                <motion.div
                    className={styles.drum}
                    animate={{ rotate: 360 }}
                    transition={{ repeat: Infinity, duration: 2, ease: "linear" }}
                    style={{
                        backgroundColor:
                            phase === 'drying' ? '#d4c4a8' :
                                phase === 'maillard' ? '#c2a374' :
                                    '#5e4b35'
                    }}
                >
                    🫘
                </motion.div>

                {/* Fire Visual */}
                <motion.div
                    className={styles.fire}
                    animate={{ height: gasLevel + 20, opacity: gasLevel / 100 + 0.2 }}
                />
            </div>

            {/* Controls */}
            <div className={styles.controls}>
                <div className={styles.controlGroup}>
                    <label>🔥 Gas Level</label>
                    <input
                        type="range"
                        min="0"
                        max="100"
                        value={gasLevel}
                        onChange={handleGasChange}
                        className={styles.slider}
                    />
                </div>

                <button
                    className={`${styles.damperBtn} ${damperOpen ? styles.open : ''}`}
                    onClick={toggleDamper}
                >
                    💨 Damper: {damperOpen ? 'OPEN' : 'CLOSED'}
                </button>
            </div>

            {/* Progress Bar */}
            <div className={styles.progressBar}>
                <div className={styles.progressFill} style={{ width: `${progress}%` }} />
            </div>
        </div>
    );
}
