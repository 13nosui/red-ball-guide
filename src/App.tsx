import React, { Suspense, useEffect } from 'react';
import { Canvas, useThree } from '@react-three/fiber';
import {
    PerspectiveCamera,
    OrbitControls,
} from '@react-three/drei';
import { Physics } from '@react-three/rapier';
import { create } from 'zustand';
import { RotateCw, Play, Square, RotateCcw, MousePointer2 } from 'lucide-react';
import { Experience } from './components/Experience';
import * as THREE from 'three';

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
 * 3. RESPONSIVE CAMERA LOGIC (修正版)
 * 画面の比率にかかわらず、常に一定の「横幅」が映るようにカメラ距離を自動計算する
 */
function ResponsiveCamera() {
    const { camera, size } = useThree();

    useEffect(() => {
        const aspect = size.width / size.height;
        const fov = 60;

        // 画面内に収めたいステージの横幅（単位:メートル）
        // これを増やすと、より広範囲が映る（カメラが遠ざかる）
        const targetVisibleWidth = 26;

        // 視野角(FOV)とアスペクト比から、必要なカメラ距離を逆算する公式
        // distance = (width / 2) / (tan(fov/2) * aspect)
        const distance = (targetVisibleWidth / 2) / (Math.tan(THREE.MathUtils.degToRad(fov / 2)) * aspect);

        // カメラ位置を更新（高さYと奥行きZを同じにして45度見下ろしを維持）
        // 見下ろし角度を変えずに距離だけ調整
        camera.position.set(0, distance, distance);
        camera.lookAt(0, 0, 0);
        camera.updateProjectionMatrix();

    }, [size.width, size.height, camera]);

    return null;
}

/**
 * 4. MAIN EXPORT
 */
export default function App() {
    const isHoveringFloor = useStore((state) => state.isHoveringFloor);

    return (
        <div style={{ width: '100vw', height: '100vh', backgroundColor: '#000', overflow: 'hidden', position: 'relative' }}>
            <Canvas shadows gl={{ antialias: false, pixelRatio: 1 }}>

                {/* カメラの初期設定 (ResponsiveCameraで上書きされるが、初期値として遠くに置いておく) */}
                <PerspectiveCamera
                    makeDefault
                    position={[0, 20, 20]}
                    fov={60}
                />

                {/* レスポンシブ制御 */}
                <ResponsiveCamera />

                <OrbitControls
                    makeDefault
                    enabled={!isHoveringFloor}
                    enableZoom={true}
                    enablePan={false}
                    minAzimuthAngle={-Math.PI / 4}
                    maxAzimuthAngle={Math.PI / 4}
                    minPolarAngle={Math.PI / 6}
                    maxPolarAngle={Math.PI / 2.5}
                />

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