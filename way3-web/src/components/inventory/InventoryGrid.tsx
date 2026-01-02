
'use client';

import React, { useEffect } from 'react';
import { useUser } from '@/lib/hooks/useUser';
import { useUIStore } from '@/lib/store/uiStore';
import styles from './InventoryGrid.module.css';

// Mock Item Data (Should come from DB/API in real app)
const ITEM_DB: Record<string, { name: string; description: string; color: string }> = {
    'potion_hp_01': { name: '체력 물약', description: '체력을 50 회복시켜주는 빨간 물약입니다.', color: '#ff4d4d' },
    'sword_basic': { name: '낡은 검', description: '녹이 슬어있는 검입니다. 공격력 +1', color: '#c0c0c0' },
    'map_fragment': { name: '지도 조각', description: '강남구의 비밀이 담긴 지도 조각입니다.', color: '#e6cda7' },
};

export default function InventoryGrid() {
    const { user, fetchUser, moveItem } = useUser();
    const { setHoveredItem } = useUIStore();
    const [draggingSlot, setDraggingSlot] = React.useState<number | null>(null);

    useEffect(() => {
        fetchUser();
    }, [fetchUser]);

    const handleDragStart = (e: React.DragEvent, slotIndex: number, itemId: string) => {
        e.dataTransfer.setData('text/plain', slotIndex.toString());
        setDraggingSlot(slotIndex);

        // Show tooltip on drag
        if (ITEM_DB[itemId]) {
            setHoveredItem(ITEM_DB[itemId]);
        }
    };

    const handleDragEnd = () => {
        setDraggingSlot(null);
        setHoveredItem(null);
    };

    const handleDrop = async (e: React.DragEvent, targetSlot: number) => {
        e.preventDefault();
        const fromSlotStr = e.dataTransfer.getData('text/plain');
        if (!fromSlotStr) return;

        const fromSlot = parseInt(fromSlotStr, 10);
        if (fromSlot === targetSlot) return;

        await moveItem(fromSlot, targetSlot);
    };

    const handleDragOver = (e: React.DragEvent) => {
        e.preventDefault(); // Essential to allow dropping
    };

    const handleMouseEnter = (itemId: string) => {
        if (ITEM_DB[itemId]) {
            setHoveredItem(ITEM_DB[itemId]);
        }
    };

    const handleMouseLeave = () => {
        setHoveredItem(null);
    };

    if (!user) return <div className={styles.container}>Loading Inventory...</div>;

    const slots = Array.from({ length: user.inventorySlots || 20 }, (_, i) => i);

    return (
        <div className={styles.container}>
            <h2>내 가방</h2>
            <div className={styles.grid}>
                {slots.map((slotIndex) => {
                    const item = user.inventory.find((i) => i.slotIndex === slotIndex);
                    const itemInfo = item ? ITEM_DB[item.itemId] : null;

                    return (
                        <div
                            key={slotIndex}
                            className={styles.slot}
                            onDragOver={handleDragOver}
                            onDrop={(e) => handleDrop(e, slotIndex)}
                        >
                            {item && (
                                <div
                                    className={`${styles.item} ${draggingSlot === slotIndex ? styles.dragging : ''}`}
                                    draggable
                                    onDragStart={(e) => handleDragStart(e, slotIndex, item.itemId)}
                                    onDragEnd={handleDragEnd}
                                    onMouseEnter={() => handleMouseEnter(item.itemId)}
                                    onMouseLeave={handleMouseLeave}
                                    style={{ backgroundColor: itemInfo?.color || '#555' }}
                                >
                                    {itemInfo?.name.slice(0, 1) || '?'}
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
