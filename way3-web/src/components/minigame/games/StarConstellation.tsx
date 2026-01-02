
'use client';

import { useState, useEffect } from 'react';
import { useMinigameStore } from '@/lib/store/minigameStore';
import { useGPSStore } from '@/lib/store/gpsStore';
import styles from './StarConstellation.module.css';

// Coordinates for "Cassiopeia" (Mock relative coords for now)
const TARGET_POINTS = [
    { id: 1, x: 20, y: 80, label: 'Start' },
    { id: 2, x: 35, y: 50, label: 'Seg 2' },
    { id: 3, x: 50, y: 60, label: 'Seg 3' },
    { id: 4, x: 65, y: 30, label: 'Seg 4' },
    { id: 5, x: 80, y: 70, label: 'End' },
];

export default function StarConstellation() {
    const { endGame } = useMinigameStore();
    const { userLat, userLng } = useGPSStore();

    const [visitedPoints, setVisitedPoints] = useState<number[]>([1]); // Start with point 1 visited
    const [currentDistance, setCurrentDistance] = useState(100); // Mock distance to next

    // Mock Progress Simulation (In real app, calculate GPS distance)
    // Here, we'll just use a slider to simulate "Walking" for testing
    const [simWalkProgress, setSimWalkProgress] = useState(0);

    useEffect(() => {
        // Check if reached next point
        if (simWalkProgress >= 100) {
            const lastVisited = visitedPoints[visitedPoints.length - 1];
            if (lastVisited < 5) {
                setVisitedPoints(prev => [...prev, lastVisited + 1]);
                setSimWalkProgress(0); // Reset for next segment
            } else {
                // Finished
                setTimeout(() => endGame(true), 1500);
            }
        }
    }, [simWalkProgress, visitedPoints, endGame]);

    const handleSimWalk = () => {
        setSimWalkProgress(prev => Math.min(100, prev + 5));
    };

    return (
        <div className={styles.container}>
            <h2>✨ Pilgrim of Stars</h2>
            <p>Walk to connect the stars! ({visitedPoints.length} / {TARGET_POINTS.length})</p>

            {/* Star Map Visualization */}
            <div className={styles.starMap}>
                <svg width="100%" height="100%" viewBox="0 0 100 100">
                    {/* Lines */}
                    <polyline
                        points={TARGET_POINTS
                            .filter(p => visitedPoints.includes(p.id))
                            .map(p => `${p.x},${p.y}`)
                            .join(' ')}
                        fill="none"
                        stroke="#ffd700"
                        strokeWidth="2"
                        strokeDasharray="4"
                        className={styles.lineAnim}
                    />

                    {/* Points */}
                    {TARGET_POINTS.map((p) => {
                        const isVisited = visitedPoints.includes(p.id);
                        const isNext = !isVisited && p.id === visitedPoints[visitedPoints.length - 1] + 1;

                        return (
                            <g key={p.id}>
                                <circle
                                    cx={p.x}
                                    cy={p.y}
                                    r={isVisited ? 3 : 2}
                                    fill={isVisited ? '#ffd700' : '#444'}
                                    className={isNext ? styles.pulse : ''}
                                />
                                {isNext && (
                                    <text x={p.x} y={p.y - 5} fontSize="4" fill="#fff" textAnchor="middle">
                                        Go Here!
                                    </text>
                                )}
                            </g>
                        );
                    })}
                </svg>
            </div>

            {/* Simulation Controls */}
            <div className={styles.controls}>
                <div className={styles.gpsInfo}>
                    Distance to Star #{visitedPoints.length < 5 ? visitedPoints.length + 1 : 'Done'}:
                    {Math.max(0, 100 - simWalkProgress)}m
                </div>

                <button
                    className={styles.walkBtn}
                    onClick={handleSimWalk}
                    disabled={visitedPoints.length >= 5}
                >
                    🏃 Simulate Walking (+5m)
                </button>
            </div>
        </div>
    );
}
