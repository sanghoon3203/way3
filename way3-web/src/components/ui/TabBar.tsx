'use client';
import styles from './TabBar.module.css';

type TabType = 'people' | 'story' | 'inventory' | 'mypage';

interface TabBarProps {
    activeTab: TabType;
    onTabChange: (tab: TabType) => void;
}

const tabs: { id: TabType; icon: string; label: string }[] = [
    { id: 'people', icon: '👥', label: '인물' },
    { id: 'story', icon: '📖', label: '스토리' },
    { id: 'inventory', icon: '🎒', label: '인벤토리' },
    { id: 'mypage', icon: '👤', label: '마이페이지' },
];

export default function TabBar({ activeTab, onTabChange }: TabBarProps) {
    return (
        <nav className={styles.container}>
            {tabs.map((tab) => (
                <button
                    key={tab.id}
                    className={`${styles.tab} ${activeTab === tab.id ? styles.active : ''}`}
                    onClick={() => onTabChange(tab.id)}
                >
                    <span className={styles.icon}>{tab.icon}</span>
                    <span className={styles.label}>{tab.label}</span>
                </button>
            ))}
        </nav>
    );
}
