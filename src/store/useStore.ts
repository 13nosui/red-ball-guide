import { create } from 'zustand';

interface GameState {
    isPlaying: boolean;
    slopePos: [number, number, number];
    slopeRot: number;
    cursorPos: [number, number, number];
    cursorRot: number;
    isHoveringFloor: boolean;
    togglePlay: () => void;
    reset: () => void;
    setCursorPos: (pos: [number, number, number]) => void;
    setHoveringFloor: (val: boolean) => void;
    rotateCursor: () => void;
    placeSlope: () => void;
}

export const useStore = create<GameState>((set) => ({
    isPlaying: false,
    slopePos: [2, -4.5, 0],
    slopeRot: 0,
    cursorPos: [0, -5.9, 0],
    cursorRot: 0,
    isHoveringFloor: false,
    togglePlay: () => set((state) => ({ isPlaying: !state.isPlaying })),
    reset: () => set({ isPlaying: false, slopePos: [2, -4.5, 0], slopeRot: 0 }),
    setCursorPos: (pos) => set({ cursorPos: pos }),
    setHoveringFloor: (val) => set({ isHoveringFloor: val }),
    rotateCursor: () => set((state) => ({ cursorRot: state.cursorRot + Math.PI / 2 })),
    placeSlope: () => set((state) => ({
        slopePos: [state.cursorPos[0], state.cursorPos[1] + 1, state.cursorPos[2]],
        slopeRot: state.cursorRot
    })),
}));