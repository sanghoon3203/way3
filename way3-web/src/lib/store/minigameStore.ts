
import { create } from 'zustand';

export type MinigameType = 'none' | 'constellation' | 'carousel' | 'roasting' | 'rhythm';

interface MinigameState {
    activeGame: MinigameType;
    isPlaying: boolean;
    score: number;
    isCompleted: boolean;

    startGame: (type: MinigameType) => void;
    endGame: (completed: boolean) => void;
    setScore: (score: number) => void;
    reset: () => void;
}

export const useMinigameStore = create<MinigameState>((set) => ({
    activeGame: 'none',
    isPlaying: false,
    score: 0,
    isCompleted: false,

    startGame: (type) => set({ activeGame: type, isPlaying: true, score: 0, isCompleted: false }),
    endGame: (completed) => set({ isPlaying: false, isCompleted: completed }),
    setScore: (score) => set({ score }),
    reset: () => set({ activeGame: 'none', isPlaying: false, score: 0, isCompleted: false }),
}));
