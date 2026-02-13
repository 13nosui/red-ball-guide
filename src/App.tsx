import React, { Suspense, useEffect } from 'react';
import { Canvas, useThree } from '@react-three/fiber';
import { PerspectiveCamera, OrbitControls } from '@react-three/drei';
import { Physics } from '@react-three/rapier';
// ▼ 十字キー用のアイコンを追加インポート ▼
import { ChevronUp, ChevronDown, ChevronLeft, ChevronRight, RotateCw, Play, Square, RotateCcw, Trophy } from 'lucide-react';
import { Experience } from './components/Experience';
import * as THREE from 'three';
import { useStore } from './store/useStore';

/**
 * 2. UI COMPONENTS
 */
function GameUI() {
    const { isPlaying, togglePlay, reset, rotateSlope, moveSlope, gameStatus } = useStore();

    if (gameStatus === 'cleared') return <ClearScreen />;

    // --- スタイル定義 ---
    const bottomBarContainer: React.CSSProperties = {
        position: 'absolute',
        bottom: '30px',
        left: '50%',
        transform: 'translateX(-50%)',
        display: 'flex',
        gap: '40px', // 十字キーとアクションボタンの間の隙間
        alignItems: 'flex-end',
        pointerEvents: 'auto',
    };

    // 十字キーを3x3のグリッドで配置
    const dpadContainer: React.CSSProperties = {
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 50px)',
        gridTemplateRows: 'repeat(3, 50px)',
        gap: '4px',
    };

    const actionContainer: React.CSSProperties = {
        display: 'flex',
        flexDirection: 'column',
        gap: '12px',
    };

    const actionRow: React.CSSProperties = {
        display: 'flex',
        gap: '12px',
    };

    // 基本のボタンデザイン
    const btnStyle = (isActive = false): React.CSSProperties => ({
        width: '100%',
        height: '100%',
        backgroundColor: '#111',
        color: isActive ? '#4ade80' : '#fff',
        border: `1px solid ${isActive ? '#4ade80' : '#444'}`,
        borderRadius: '8px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: isPlaying ? 'not-allowed' : 'pointer',
        opacity: isPlaying ? 0.5 : 1, // 再生中は半透明にして押せない感触を出す
        outline: 'none',
    });

    // 再生ボタンは特別（プレイ中も押せるのでopacityを下げない）
    const playBtnStyle: React.CSSProperties = {
        ...btnStyle(isPlaying),
        cursor: 'pointer',
        opacity: 1,
        height: '60px',
        borderColor: isPlaying ? '#4ade80' : '#f87171',
        color: isPlaying ? '#4ade80' : '#f87171',
    };

    return (
        <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
            <div style={{ position: 'absolute', top: '24px', left: '24px', opacity: 0.5 }}>
                <h1 style={{ color: '#fff', margin: 0, fontSize: '14px', letterSpacing: '4px', fontWeight: 900 }}>RB_GUIDE_3D</h1>
            </div>

            <div style={bottomBarContainer}>
                {/* ▼ 左側: 十字キー (D-Pad) ▼ */}
                <div style={dpadContainer}>
                    <div /> {/* 左上 空白 */}
                    <button style={btnStyle()} disabled={isPlaying} onClick={() => moveSlope(0, -1)}>
                        <ChevronUp size={28} />
                    </button>
                    <div /> {/* 右上 空白 */}

                    <button style={btnStyle()} disabled={isPlaying} onClick={() => moveSlope(-1, 0)}>
                        <ChevronLeft size={28} />
                    </button>
                    <div /> {/* 中央 空白 */}
                    <button style={btnStyle()} disabled={isPlaying} onClick={() => moveSlope(1, 0)}>
                        <ChevronRight size={28} />
                    </button>

                    <div /> {/* 左下 空白 */}
                    <button style={btnStyle()} disabled={isPlaying} onClick={() => moveSlope(0, 1)}>
                        <ChevronDown size={28} />
                    </button>
                    <div /> {/* 右下 空白 */}
                </div>

                {/* ▼ 右側: アクションボタン ▼ */}
                <div style={actionContainer}>
                    <div style={actionRow}>
                        <button style={{ ...btnStyle(), width: '60px', height: '60px' }} disabled={isPlaying} onClick={rotateSlope} title="Rotate">
                            <RotateCw size={24} />
                        </button>
                        <button style={{ ...btnStyle(), width: '60px', height: '60px' }} onClick={reset} title="Reset">
                            <RotateCcw size={24} />
                        </button>
                    </div>
                    <button style={playBtnStyle} onClick={togglePlay}>
                        {isPlaying ? <Square size={24} fill="currentColor" /> : <Play size={24} fill="currentColor" />}
                    </button>
                </div>
            </div>
        </div>
    );
}

// ... ClearScreen, ResponsiveCamera, App コンポーネントは前回のまま変更なし ...
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
            <button
                onClick={reset}
                style={{
                    padding: '16px 48px', fontSize: '18px', fontWeight: 'bold', marginTop: '40px',
                    backgroundColor: '#FFD000', color: '#000', border: 'none',
                    borderRadius: '50px', cursor: 'pointer', boxShadow: '0 4px 15px rgba(255, 208, 0, 0.4)'
                }}
            >
                REPLAY
            </button>
        </div>
    );
}

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

export default function App() {
    return (
        <div style={{ width: '100vw', height: '100vh', backgroundColor: '#dcdcdc', overflow: 'hidden', position: 'relative' }}>
            <Canvas shadows gl={{ antialias: false, pixelRatio: 1 }}>
                <PerspectiveCamera makeDefault position={[0, 20, 20]} fov={60} />
                <ResponsiveCamera />
                <OrbitControls
                    makeDefault
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