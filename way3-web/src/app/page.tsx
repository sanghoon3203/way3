'use client';
import { useState } from 'react';
import ThreePanelLayout from '@/components/layout/ThreePanelLayout';

export default function Home() {
    const [theme, setTheme] = useState<'light' | 'dark'>('light');

    const toggleTheme = () => {
        const newTheme = theme === 'light' ? 'dark' : 'light';
        setTheme(newTheme);
        document.documentElement.setAttribute('data-theme', newTheme);
    };

    return (
        <ThreePanelLayout theme={theme} onThemeToggle={toggleTheme} />
    );
}
