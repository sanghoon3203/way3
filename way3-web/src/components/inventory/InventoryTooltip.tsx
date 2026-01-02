
'use client';

import { useUIStore } from '@/lib/store/uiStore';
import { motion, AnimatePresence } from 'framer-motion';

export default function InventoryTooltip() {
    const { hoveredItem } = useUIStore();

    return (
        <AnimatePresence>
            {hoveredItem && (
                <motion.div
                    initial={{ opacity: 0, x: -20, scale: 0.9 }}
                    animate={{ opacity: 1, x: 0, scale: 1 }}
                    exit={{ opacity: 0, width: 0, padding: 0 }}
                    style={{
                        position: 'absolute',
                        top: '80px', // Below character face area?
                        left: '20px',
                        right: '20px', // Full width minus padding
                        // Or "Left of the phone" -> maybe this component should be placed OUTSIDE the phone frame?
                        // User said "Phone section left side".
                        // If the user meant "Left Panel" (StoryPanel), then inside here is fine.
                        backgroundColor: 'rgba(30, 30, 35, 0.95)',
                        border: '2px solid #ffffff',
                        borderRadius: '12px',
                        padding: '16px',
                        zIndex: 100,
                        boxShadow: '0 4px 15px rgba(0,0,0,0.5)',
                        pointerEvents: 'none',
                    }}
                >
                    {/* Tail for speech bubble effect (optional) */}
                    <div style={{
                        position: 'absolute',
                        top: '20px',
                        left: '-8px',
                        width: '16px',
                        height: '16px',
                        backgroundColor: 'inherit',
                        borderLeft: '2px solid #ffffff',
                        borderBottom: '2px solid #ffffff',
                        transform: 'rotate(45deg)',
                    }} />

                    <h3 style={{ margin: '0 0 8px 0', color: hoveredItem.color || '#fff' }}>
                        {hoveredItem.name}
                    </h3>
                    <p style={{ margin: 0, fontSize: '0.9rem', lineHeight: '1.4', color: '#ccc' }}>
                        {hoveredItem.description}
                    </p>
                </motion.div>
            )}
        </AnimatePresence>
    );
}
