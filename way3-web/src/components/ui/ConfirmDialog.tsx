'use client';
import styles from './ConfirmDialog.module.css';

interface ConfirmDialogProps {
    isOpen: boolean;
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    onConfirm: () => void;
    onCancel: () => void;
}

export default function ConfirmDialog({
    isOpen,
    title,
    message,
    confirmText = '확인',
    cancelText = '취소',
    onConfirm,
    onCancel,
}: ConfirmDialogProps) {
    if (!isOpen) return null;

    return (
        <div className={styles.overlay} onClick={onCancel}>
            <div className={styles.dialog} onClick={(e) => e.stopPropagation()}>
                <div className={styles.header}>
                    <span className={styles.icon}>📖</span>
                    <h3 className={styles.title}>{title}</h3>
                </div>

                <p className={styles.message}>{message}</p>

                <div className={styles.buttonGroup}>
                    <button
                        className={styles.cancelButton}
                        onClick={onCancel}
                    >
                        {cancelText}
                    </button>
                    <button
                        className={styles.confirmButton}
                        onClick={onConfirm}
                    >
                        {confirmText}
                    </button>
                </div>
            </div>
        </div>
    );
}
