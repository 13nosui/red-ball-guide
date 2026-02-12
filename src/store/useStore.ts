import { create } from 'zustand';

interface GameState {
    isPlaying: boolean;
    slopePos: [number, number, number];
    slopeRot: number;
    togglePlay: () => void;
    reset: () => void;
    moveSlope: (x: number) => void;
    rotateSlope: () => void;
}

export const useStore = create<GameState>((set) => ({
    isPlaying: false,
    slopePos: [0, -2, 0],
    slopeRot: 0,
    togglePlay: () => set((state) => ({ isPlaying: !state.isPlaying })),
    reset: () => set({ isPlaying: false, slopePos: [0, -2, 0], slopeRot: 0 }),
    moveSlope: (dir) => set((state) => ({
        slopePos: [state.slopePos[0] + dir * 2, state.slopePos[1], state.slopePos[2]]
    })),
    rotateSlope: () => set((state) => ({
        slopeRot: state.slopeRot + Math.PI / 2
    })),
}));
