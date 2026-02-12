import React, { Suspense, useEffect } from 'react';
import { Canvas, useThree } from '@react-three/fiber';
import {
    PerspectiveCamera,
    OrbitControls,
} from '@react-three/drei';
import { Physics } from '@react-three/rapier';
import { RotateCw, Play, Square, RotateCcw, MousePointer2 } from 'lucide-react';
import { Experience } from './components/Experience';
import * as THREE from 'three';
// ▼▼▼ 新しく作ったファイルからインポート ▼▼▼
import { useStore } from './store/useStore';

// 【削除】interface GameState ... 
// 【削除】export const useStore = create<GameState> ... 
// ↑ これらはもう store/useStore.ts に移動したので削除済みとして扱います

/**
 * 2. UI COMPONENTS
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
 * 3. RESPONSIVE CAMERA LOGIC
 */
function ResponsiveCamera() {
    const { camera, size } = useThree();

    useEffect(() => {
        const aspect = size.width / size.height;
        const fov = 60;
        const targetVisibleWidth = 14;

        const distance = (targetVisibleWidth / 2) / (Math.tan(THREE.MathUtils.degToRad(fov / 2)) * aspect);

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
        <div style={{ width: '100vw', height: '100vh', backgroundColor: '#dcdcdc', overflow: 'hidden', position: 'relative' }}>
            <Canvas shadows gl={{ antialias: false, pixelRatio: 1 }}>

                <PerspectiveCamera
                    makeDefault
                    position={[0, 20, 20]}
                    fov={60}
                />

                <ResponsiveCamera />

                <OrbitControls
                    makeDefault
                    enabled={!isHoveringFloor}
                    enableZoom={true}
                    enablePan={true}
                    enableRotate={true}
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