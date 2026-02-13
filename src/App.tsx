import React, { Suspense, useEffect } from 'react';
import { Canvas, useThree } from '@react-three/fiber';
import { PerspectiveCamera, OrbitControls } from '@react-three/drei';
import { Physics } from '@react-three/rapier';
import { ChevronUp, ChevronDown, ChevronLeft, ChevronRight, Play, Square, RotateCcw, Trophy } from 'lucide-react';
import { Experience } from './components/Experience';
import * as THREE from 'three';
import { useStore } from './store/useStore';

function GameUI() {
    const { isPlaying, togglePlay, reset, rotateSlope, moveSlope, gameStatus } = useStore();

    if (gameStatus === 'cleared') return <ClearScreen />;

    const bottomBarContainer: React.CSSProperties = {
        position: 'absolute',
        bottom: '30px',
        left: '50%',
        transform: 'translateX(-50%)',
        display: 'flex',
        gap: '40px',
        alignItems: 'flex-end',
        pointerEvents: 'auto',
    };

    const dpadContainer: React.CSSProperties = {
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 50px)',
        gridTemplateRows: 'repeat(3, 50px)',
        gap: '4px',
    };

    const actionContainer: React.CSSProperties = {
        display: 'flex',
        flexDirection: 'column',
        gap: '8px',
        width: '160px', // 右側のボタンエリアの幅を固定
    };

    const btnStyle = (isActive = false): React.CSSProperties => ({
        width: '100%', height: '100%', backgroundColor: '#111',
        color: isActive ? '#4ade80' : '#fff', border: `1px solid ${isActive ? '#4ade80' : '#444'}`,
        borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center',
        cursor: isPlaying ? 'not-allowed' : 'pointer', opacity: isPlaying ? 0.5 : 1, outline: 'none',
    });

    return (
        <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
            <div style={{ position: 'absolute', top: '24px', left: '24px', opacity: 0.5 }}>
                <h1 style={{ color: '#fff', margin: 0, fontSize: '14px', letterSpacing: '4px', fontWeight: 900 }}>RB_GUIDE_3D</h1>
            </div>

            <div style={bottomBarContainer}>
                {/* 左側: 十字キー */}
                <div style={dpadContainer}>
                    <div />
                    <button style={btnStyle()} disabled={isPlaying} onClick={() => moveSlope(0, -1)}><ChevronUp size={28} /></button>
                    <div />
                    <button style={btnStyle()} disabled={isPlaying} onClick={() => moveSlope(-1, 0)}><ChevronLeft size={28} /></button>
                    <div />
                    <button style={btnStyle()} disabled={isPlaying} onClick={() => moveSlope(1, 0)}><ChevronRight size={28} /></button>
                    <div />
                    <button style={btnStyle()} disabled={isPlaying} onClick={() => moveSlope(0, 1)}><ChevronDown size={28} /></button>
                    <div />
                </div>

                {/* 右側: アクションボタン */}
                <div style={actionContainer}>
                    {/* ▼ XYZ独立回転ボタン ▼ */}
                    <div style={{ display: 'flex', gap: '6px', height: '40px' }}>
                        <button style={{ ...btnStyle(), fontSize: '12px', fontWeight: 'bold' }} disabled={isPlaying} onClick={() => rotateSlope('x')}>Rx</button>
                        <button style={{ ...btnStyle(), fontSize: '12px', fontWeight: 'bold' }} disabled={isPlaying} onClick={() => rotateSlope('y')}>Ry</button>
                        <button style={{ ...btnStyle(), fontSize: '12px', fontWeight: 'bold' }} disabled={isPlaying} onClick={() => rotateSlope('z')}>Rz</button>
                    </div>

                    <div style={{ display: 'flex', gap: '6px', height: '60px' }}>
                        <button
                            style={{ ...btnStyle(isPlaying), flex: 2, cursor: 'pointer', opacity: 1, borderColor: isPlaying ? '#4ade80' : '#f87171', color: isPlaying ? '#4ade80' : '#f87171' }}
                            onClick={togglePlay}
                        >
                            {isPlaying ? <Square size={24} fill="currentColor" /> : <Play size={24} fill="currentColor" />}
                        </button>
                        <button style={{ ...btnStyle(), flex: 1 }} onClick={reset} title="Reset">
                            <RotateCcw size={20} />
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}

// ... ClearScreen, ResponsiveCamera, App コンポーネントは変更なし ...
function ClearScreen() {
    const reset = useStore((state) => state.reset);
    return (
        <div style={{
            position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center', backgroundColor: 'rgba(0,0,0,0.6)',
            pointerEvents: 'auto', zIndex: 10,
        }}>
            <Trophy size={80} color="#FFD000" style={{ marginBottom: '20px' }} />
            <h1 style={{ color: '#fff', fontSize: '48px', fontWeight: 900, margin: 0, letterSpacing: '4px' }}>CLEAR!!</h1>
            <button onClick={reset} style={{ padding: '16px 48px', fontSize: '18px', fontWeight: 'bold', marginTop: '40px', backgroundColor: '#FFD000', color: '#000', border: 'none', borderRadius: '50px', cursor: 'pointer', boxShadow: '0 4px 15px rgba(255, 208, 0, 0.4)' }}>REPLAY</button>
        </div>
    );
}

function ResponsiveCamera() {
    const { camera, size } = useThree();
    useEffect(() => {
        const aspect = size.width / size.height;
        const distance = (14 / 2) / (Math.tan(THREE.MathUtils.degToRad(30)) * aspect);
        camera.position.set(0, distance, distance);
        camera.lookAt(0, 0, 0);
        camera.updateProjectionMatrix();
    }, [size.width, size.height, camera]);
    return null;
}

export default function App() {
    return (
        <div style={{ width: '100vw', height: '100vh', backgroundColor: '#dcdcdc', overflow: 'hidden', position: 'relative' }}>
            <Canvas shadows gl={{ antialias: false, pixelRatio: 1 }}>
                <PerspectiveCamera makeDefault position={[0, 20, 20]} fov={60} />
                <ResponsiveCamera />
                <OrbitControls makeDefault enableZoom={true} enablePan={true} enableRotate={true} minAzimuthAngle={-Math.PI / 4} maxAzimuthAngle={Math.PI / 4} minPolarAngle={Math.PI / 6} maxPolarAngle={Math.PI / 2.5} />
                <Suspense fallback={null}><Physics gravity={[0, -9.81, 0]}><Experience /></Physics></Suspense>
            </Canvas>
            <GameUI />
        </div>
    );
}