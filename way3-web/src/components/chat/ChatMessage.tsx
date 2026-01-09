'use client';
import styles from './ChatMessage.module.css';
import type { ChatMessage as ChatMessageType } from '@/lib/store/chatStore';

interface ChatMessageProps {
    message: ChatMessageType;
}

export default function ChatMessage({ message }: ChatMessageProps) {
    const isNarration = !message.characterId || message.characterId === 'System';

    if (isNarration) {
        return (
            <div className={styles.narrationContainer}>
                <div className={styles.narration}>
                    {message.text}
                </div>
            </div>
        );
    }

    return (
        <div className={`${styles.messageContainer} ${message.isPlayer ? styles.player : styles.character}`}>
            {!message.isPlayer && (
                <img
                    src={message.avatar || '/images/default_avatar.png'}
                    alt={message.characterName}
                    className={styles.avatar}
                    onError={(e) => {
                        (e.target as HTMLImageElement).src = '/images/default_avatar.png';
                    }}
                />
            )}
            <div className={styles.messageContent}>
                {!message.isPlayer && (
                    <span className={styles.characterName}>{message.characterName}</span>
                )}
                <div className={styles.bubble}>
                    {message.text}
                </div>
            </div>
        </div>
    );
}
