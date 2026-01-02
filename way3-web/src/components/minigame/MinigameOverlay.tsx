
'use client';

import { useMinigameStore } from '@/lib/store/minigameStore';
import { motion, AnimatePresence } from 'framer-motion';
import CarouselRepair from './games/CarouselRepair';
import CoffeeRoasting from './games/CoffeeRoasting';
import SoulBlacksmith from './games/SoulBlacksmith';
import StarConstellation from './games/StarConstellation';
import styles from './MinigameOverlay.module.css';

export default function MinigameOverlay() {
    const { activeGame, isPlaying, reset } = useMinigameStore();

    if (!isPlaying || activeGame === 'none') return null;

    return (
        <AnimatePresence>
            <motion.div
                className={styles.overlay}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
            >
                <div className={styles.modal}>
                    <button className={styles.closeButton} onClick={reset}>✕</button>

                    <div className={styles.gameContent}>
                        {activeGame === 'carousel' && <CarouselRepair />}
                        {activeGame === 'roasting' && <CoffeeRoasting />}
                        {activeGame === 'rhythm' && <SoulBlacksmith />}
                        {activeGame === 'constellation' && <StarConstellation />}
                    </div>
                </div>
            </motion.div>
        </AnimatePresence>
    );
}
