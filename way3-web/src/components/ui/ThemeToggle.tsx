'use client';
import styles from './ThemeToggle.module.css';

interface ThemeToggleProps {
    theme: 'light' | 'dark';
    onToggle: () => void;
}

export default function ThemeToggle({ theme, onToggle }: ThemeToggleProps) {
    return (
        <button
            className={styles.container}
            onClick={onToggle}
            aria-label={`Switch to ${theme === 'light' ? 'dark' : 'light'} mode`}
        >
            <div className={styles.track}>
                <span className={styles.iconSun}>☀️</span>
                <span className={styles.iconMoon}>🌙</span>
                <div className={`${styles.thumb} ${theme === 'dark' ? styles.dark : ''}`} />
            </div>
            <span className={styles.label}>
                {theme === 'light' ? 'Light' : 'Dark'}
            </span>
        </button>
    );
}
