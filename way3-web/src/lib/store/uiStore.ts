
import { create } from 'zustand';

interface ItemInfo {
    name: string;
    description: string;
    image?: string;
    color?: string;
}

interface UIState {
    hoveredItem: ItemInfo | null;
    setHoveredItem: (item: ItemInfo | null) => void;
}

export const useUIStore = create<UIState>((set) => ({
    hoveredItem: null,
    setHoveredItem: (item) => set({ hoveredItem: item }),
}));
