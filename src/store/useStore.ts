import { create } from 'zustand';

type GameStatus = 'ready' | 'playing' | 'cleared';

interface GameState {
    gameStatus: GameStatus;
    isPlaying: boolean;
    slopePos: [number, number, number];
    slopeRot: number;

    togglePlay: () => void;
    reset: () => void;
    setGameStatus: (status: GameStatus) => void;

    // ▼ スロープ操作用の関数 ▼
    moveSlope: (dx: number, dz: number) => void;
    rotateSlope: () => void;
}

export const useStore = create<GameState>((set) => ({
    gameStatus: 'ready',
    isPlaying: false,
    slopePos: [2, -4.9, 0],
    slopeRot: 0,

    togglePlay: () => set((state) => ({
        isPlaying: !state.isPlaying,
        gameStatus: !state.isPlaying ? 'playing' : 'ready'
    })),

    reset: () => set({
        isPlaying: false,
        gameStatus: 'ready',
        slopePos: [2, -4.9, 0],
        slopeRot: 0
    }),

    setGameStatus: (status) => set({ gameStatus: status }),

    // ▼ 十字キーで呼び出される移動関数（再生中は動かせない） ▼
    moveSlope: (dx, dz) => set((state) => {
        if (state.isPlaying) return state;
        return {
            slopePos: [state.slopePos[0] + dx, state.slopePos[1], state.slopePos[2] + dz]
        };
    }),

    rotateSlope: () => set((state) => {
        if (state.isPlaying) return state;
        return { slopeRot: state.slopeRot + Math.PI / 2 };
    }),
}));