
import { create } from 'zustand';

interface InventoryItem {
    id: string;
    itemId: string;
    slotIndex: number;
    quantity: number;
}

interface UserState {
    user: {
        id: string;
        username: string;
        currentChapter: string;
        inventory: InventoryItem[];
        inventorySlots: number;
        credits: number;
        unlockedDistricts: string; // JSON string
    } | null;
    isLoading: boolean;
    error: string | null;
    fetchUser: () => Promise<void>;
    moveItem: (fromSlot: number, toSlot: number) => Promise<boolean>;
}

export const useUser = create<UserState>((set, get) => ({
    user: null,
    isLoading: false,
    error: null,

    fetchUser: async () => {
        set({ isLoading: true });
        try {
            const res = await fetch('/api/user/me');
            if (res.ok) {
                const data = await res.json();
                set({ user: data.user, error: null });
            } else {
                set({ user: null, error: 'Failed to fetch user' });
            }
        } catch (error) {
            set({ user: null, error: 'Network error' });
        } finally {
            set({ isLoading: false });
        }
    },

    moveItem: async (fromSlot, toSlot) => {
        const { user } = get();
        if (!user) return false;

        // 1. Optimistic Update (Client-side swap)
        const newInventory = [...user.inventory];
        const fromItemIndex = newInventory.findIndex(i => i.slotIndex === fromSlot);
        const toItemIndex = newInventory.findIndex(i => i.slotIndex === toSlot);

        if (fromItemIndex === -1) return false; // Source empty?

        if (toItemIndex !== -1) {
            // Swap
            newInventory[fromItemIndex] = { ...newInventory[fromItemIndex], slotIndex: toSlot };
            newInventory[toItemIndex] = { ...newInventory[toItemIndex], slotIndex: fromSlot };
        } else {
            // Move
            newInventory[fromItemIndex] = { ...newInventory[fromItemIndex], slotIndex: toSlot };
        }

        set({ user: { ...user, inventory: newInventory } });

        // 2. Server API Call
        try {
            const res = await fetch('/api/inventory/move', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ fromSlot, toSlot }),
            });

            if (!res.ok) {
                throw new Error('Move failed');
            }
            return true;
        } catch (error) {
            // Revert on failure
            console.error('Move failed, reverting:', error);
            get().fetchUser(); // Refetch to sync
            return false;
        }
    },
}));
