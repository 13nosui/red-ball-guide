import React, { Suspense } from 'react';
import { Canvas } from '@react-three/fiber';
import {
    PerspectiveCamera,
    OrbitControls,
} from '@react-three/drei';
import { Physics } from '@react-three/rapier';
import { create } from 'zustand';
import { RotateCw, Play, Square, RotateCcw, MousePointer2 } from 'lucide-react';
import { Experience } from './components/Experience'; // Experienceコンポーネントのパスに合わせてください

/**
 * 1. GAME STATE (変更なし)
 */
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

/**
 * 2. UI COMPONENTS (変更なし)
 */
function GameUI() {
    const { isPlaying, togglePlay, reset, rotateCursor, placeSlope } = useStore();

    const containerStyle: React.CSSProperties = {
        position: 'absolute',
        bottom: '40px',
        left: '50%',
        transform: 'translateX(-50%)',
        display: 'flex',
        gap: '20px',
        pointerEvents: 'auto',
    };

    const buttonBaseStyle: React.CSSProperties = {
        width: '60px',
        height: '60px',
        backgroundColor: '#111',
        color: '#fff',
        border: '1px solid #444',
        borderRadius: '8px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        outline: 'none',
    };

    const playButtonStyle: React.CSSProperties = {
        ...buttonBaseStyle,
        borderColor: isPlaying ? '#4ade80' : '#f87171',
        color: isPlaying ? '#4ade80' : '#f87171',
    };

    return (
        <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
            <div style={{ position: 'absolute', top: '24px', left: '24px', opacity: 0.5 }}>
                <h1 style={{ color: '#fff', margin: 0, fontSize: '14px', letterSpacing: '4px', fontWeight: 900 }}>RB_GUIDE_3D</h1>
            </div>

            <div style={containerStyle}>
                <button style={buttonBaseStyle} onClick={rotateCursor} title="Rotate Orientation">
                    <RotateCw size={24} />
                </button>
                <button style={buttonBaseStyle} onClick={placeSlope} title="Set Position">
                    <MousePointer2 size={24} />
                </button>
                <button style={playButtonStyle} onClick={togglePlay}>
                    {isPlaying ? <Square size={24} fill="currentColor" /> : <Play size={24} fill="currentColor" />}
                </button>
                <button style={buttonBaseStyle} onClick={reset} title="Reset Game">
                    <RotateCcw size={24} />
                </button>
            </div>
        </div>
    );
}

/**
 * 3. MAIN EXPORT (カメラ位置を修正)
 */
export default function App() {
    const isHoveringFloor = useStore((state) => state.isHoveringFloor);

    return (
        <div style={{ width: '100vw', height: '100vh', backgroundColor: '#000', overflow: 'hidden', position: 'relative' }}>
            <Canvas shadows gl={{ antialias: false, pixelRatio: 1 }}>

                {/* ▼▼▼ カメラ設定の変更箇所 ▼▼▼ */}
                <PerspectiveCamera
                    makeDefault
                    // x=0(正面), y=12(高さ), z=12(手前) に設定
                    position={[0, 12, 12]}
                    // 視野角を広げてパース（遠近感）を強める
                    fov={60}
                />
                <OrbitControls
                    makeDefault
                    enabled={!isHoveringFloor}
                    enableZoom={true}
                    enablePan={false}
                    // カメラの回転を制限して「正面」から大きく外れないようにする（お好みで調整可）
                    minAzimuthAngle={-Math.PI / 4}
                    maxAzimuthAngle={Math.PI / 4}
                    minPolarAngle={Math.PI / 6}
                    maxPolarAngle={Math.PI / 2.5}
                />
                {/* ▲▲▲ 変更ここまで ▲▲▲ */}

                <Suspense fallback={null}>
                    <Physics gravity={[0, -9.81, 0]}>
                        <Experience />
                    </Physics>
                </Suspense>
            </Canvas>
            <GameUI />
        </div>
    );
}