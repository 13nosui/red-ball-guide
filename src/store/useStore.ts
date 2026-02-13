import { create } from 'zustand';

type GameStatus = 'ready' | 'playing' | 'cleared';

interface GameState {
    gameStatus: GameStatus;
    isPlaying: boolean;
    slopePos: [number, number, number];
    // ▼ 回転をXYZの配列に変更 ▼
    slopeRot: [number, number, number];

    togglePlay: () => void;
    reset: () => void;
    setGameStatus: (status: GameStatus) => void;

    moveSlope: (dx: number, dz: number) => void;
    // ▼ 引数で x, y, z を受け取るように変更 ▼
    rotateSlope: (axis: 'x' | 'y' | 'z') => void;
}

export const useStore = create<GameState>((set) => ({
    gameStatus: 'ready',
    isPlaying: false,
    slopePos: [2, -4.9, 0],
    slopeRot: [0, 0, 0], // 初期状態はすべて0度

    togglePlay: () => set((state) => ({
        isPlaying: !state.isPlaying,
        gameStatus: !state.isPlaying ? 'playing' : 'ready'
    })),

    reset: () => set({
        isPlaying: false,
        gameStatus: 'ready',
        slopePos: [2, -4.9, 0],
        slopeRot: [0, 0, 0] // リセット時も配列に戻す
    }),

    setGameStatus: (status) => set({ gameStatus: status }),

    moveSlope: (dx, dz) => set((state) => {
        if (state.isPlaying) return state;
        return {
            slopePos: [state.slopePos[0] + dx, state.slopePos[1], state.slopePos[2] + dz]
        };
    }),

    // ▼ 指定された軸だけ90度（Math.PI / 2）回転させる ▼
    rotateSlope: (axis) => set((state) => {
        if (state.isPlaying) return state;
        const newRot = [...state.slopeRot] as [number, number, number];
        if (axis === 'x') newRot[0] += Math.PI / 2;
        if (axis === 'y') newRot[1] += Math.PI / 2;
        if (axis === 'z') newRot[2] += Math.PI / 2;
        return { slopeRot: newRot };
    }),
}));