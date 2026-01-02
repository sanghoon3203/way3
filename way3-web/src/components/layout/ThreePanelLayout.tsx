'use client';
import styles from './ThreePanelLayout.module.css';
import StoryPanel from './StoryPanel';
import GPSSimulator from './GPSSimulator';
import QuestPanel from './QuestPanel';
import MinigameOverlay from '../minigame/MinigameOverlay';
import ThemeToggle from '../ui/ThemeToggle';

interface ThreePanelLayoutProps {
    theme: 'light' | 'dark';
    onThemeToggle: () => void;
}

export default function ThreePanelLayout({ theme, onThemeToggle }: ThreePanelLayoutProps) {
    return (
        <div className={styles.container}>
            {/* Header with Theme Toggle */}
            <header className={styles.header}>
                <div className={styles.logo}>
                    <span className={styles.logoIcon}>🌆</span>
                    <span className={styles.logoText}>CONNECT : SEOUL</span>
                    <span className={styles.logoSubtext}>v1.0</span>
                </div>
                <div className={styles.headerControls}>
                    <ThemeToggle theme={theme} onToggle={onThemeToggle} />
                </div>
            </header>

            {/* Main Content Area */}
            <main className={styles.main}>
                {/* Left Panel - Story View (iPhone Frame) */}
                <section className={styles.storyPanel}>
                    <div className={styles.phoneFrame}>
                        <div className={styles.notch}></div>
                        <div className={styles.phoneScreen}>
                            <StoryPanel />
                        </div>
                    </div>
                </section>

                {/* Right Panels Container */}
                <div className={styles.rightPanels}>
                    {/* GPS Simulator */}
                    <section className={styles.gpsPanel}>
                        <GPSSimulator />
                    </section>

                    {/* Quest Detail */}
                    <section className={styles.questPanel}>
                        <QuestPanel />
                    </section>
                </div>
            </main>
            <MinigameOverlay />
        </div>
    );
}
