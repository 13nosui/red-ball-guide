import React, { Suspense, useEffect } from 'react';
import { Canvas, useThree } from '@react-three/fiber';
import { PerspectiveCamera, OrbitControls } from '@react-three/drei';
import { Physics } from '@react-three/rapier';
import { RotateCw, Play, Square, RotateCcw, MousePointer2, Trophy } from 'lucide-react'; // Trophy追加
import { Experience } from './components/Experience';
import * as THREE from 'three';
import { useStore } from './store/useStore';

/**
 * 2. UI COMPONENTS
 */
function GameUI() {
    const { isPlaying, togglePlay, reset, rotateCursor, placeSlope, gameStatus } = useStore();

    // クリア時は操作パネルを隠す
    if (gameStatus === 'cleared') return <ClearScreen />;

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
 * ▼▼▼ クリア画面のコンポーネント (新規追加) ▼▼▼
 */
function ClearScreen() {
    const reset = useStore((state) => state.reset);

    return (
        <div style={{
            position: 'absolute',
            inset: 0,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: 'rgba(0,0,0,0.6)', // 半透明の黒背景
            pointerEvents: 'auto',
            zIndex: 10,
        }}>
            <Trophy size={80} color="#FFD000" style={{ marginBottom: '20px' }} />
            <h1 style={{ color: '#fff', fontSize: '48px', fontWeight: 900, margin: 0, letterSpacing: '4px' }}>
                CLEAR!!
            </h1>
            <p style={{ color: '#ccc', marginTop: '10px', marginBottom: '40px' }}>Great Job!</p>

            <button
                onClick={reset}
                style={{
                    padding: '16px 48px',
                    fontSize: '18px',
                    fontWeight: 'bold',
                    backgroundColor: '#FFD000',
                    color: '#000',
                    border: 'none',
                    borderRadius: '50px',
                    cursor: 'pointer',
                    boxShadow: '0 4px 15px rgba(255, 208, 0, 0.4)'
                }}
            >
                REPLAY
            </button>
        </div>
    );
}

// ... (ResponsiveCamera は変更なし)
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
                <PerspectiveCamera makeDefault position={[0, 20, 20]} fov={60} />
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