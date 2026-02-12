import { create } from 'zustand';

// ゲームの状態定義
type GameStatus = 'ready' | 'playing' | 'cleared';

interface GameState {
    gameStatus: GameStatus; // 現在の状態
    isPlaying: boolean;
    slopePos: [number, number, number];
    slopeRot: number;
    cursorPos: [number, number, number];
    cursorRot: number;
    isHoveringFloor: boolean;

    togglePlay: () => void;
    reset: () => void;
    setGameStatus: (status: GameStatus) => void; // 状態を変更する関数
    setCursorPos: (pos: [number, number, number]) => void;
    setHoveringFloor: (val: boolean) => void;
    rotateCursor: () => void;
    placeSlope: () => void;
}

export const useStore = create<GameState>((set) => ({
    gameStatus: 'ready',
    isPlaying: false,
    slopePos: [2, -4.5, 0],
    slopeRot: 0,
    cursorPos: [0, -5.9, 0],
    cursorRot: 0,
    isHoveringFloor: false,

    togglePlay: () => set((state) => ({
        isPlaying: !state.isPlaying,
        // 再生中は 'playing'、停止したら 'ready' に戻す（クリア済みでなければ）
        gameStatus: !state.isPlaying ? 'playing' : 'ready'
    })),

    reset: () => set({
        isPlaying: false,
        gameStatus: 'ready', // クリア状態もリセット
        slopePos: [2, -4.5, 0],
        slopeRot: 0
    }),

    setGameStatus: (status) => set({ gameStatus: status }),
    setCursorPos: (pos) => set({ cursorPos: pos }),
    setHoveringFloor: (val) => set({ isHoveringFloor: val }),
    rotateCursor: () => set((state) => ({ cursorRot: state.cursorRot + Math.PI / 2 })),
    placeSlope: () => set((state) => ({
        slopePos: [state.cursorPos[0], state.cursorPos[1] + 1, state.cursorPos[2]],
        slopeRot: state.cursorRot
    })),
}));