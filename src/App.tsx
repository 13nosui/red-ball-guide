import React, { Suspense, useRef, useEffect } from 'react';
import { Canvas } from '@react-three/fiber';
import {
    PerspectiveCamera,
    OrbitControls,
    Grid,
    // Edgesは不要なので削除
    Html
} from '@react-three/drei';
import { Physics, RigidBody, RigidBodyApi, CuboidCollider } from '@react-three/rapier';
import * as THREE from 'three';
import { create } from 'zustand';
import { RotateCw, Play, Square, RotateCcw, MousePointer2 } from 'lucide-react';

/**
 * 1. GAME STATE
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

const useStore = create<GameState>((set) => ({
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
 * 2. COMPONENTS
 */
function Player() {
    const rbRef = useRef<RigidBodyApi>(null);
    const isPlaying = useStore((state) => state.isPlaying);
    const startPos: [number, number, number] = [-6, 6, 0];

    useEffect(() => {
        if (!isPlaying && rbRef.current) {
            rbRef.current.setTranslation(new THREE.Vector3(...startPos), true);
            rbRef.current.setLinvel({ x: 0, y: 0, z: 0 }, true);
            rbRef.current.setAngvel({ x: 0, y: 0, z: 0 }, true);
            rbRef.current.setRotation({ w: 1, x: 0, y: 0, z: 0 }, true);
        }
    }, [isPlaying]);

    return (
        <RigidBody
            ref={rbRef}
            type={isPlaying ? "dynamic" : "kinematicPosition"}
            position={startPos}
            colliders={false}
            enabledTranslations={[true, true, false]}
            enabledRotations={[false, false, true]}
        >
            <CuboidCollider args={[0.5, 0.5, 0.5]} />
            <mesh castShadow receiveShadow>
                <boxGeometry args={[1, 1, 1]} />
                {/* flatShadingを追加して面を際立たせる */}
                <meshStandardMaterial color="#e5484d" roughness={0.8} flatShading />
            </mesh>
        </RigidBody>
    );
}

function Experience() {
    const { cursorPos, cursorRot, slopePos, slopeRot, setCursorPos, setHoveringFloor, isPlaying } = useStore();

    const onPointerMove = (e: any) => {
        if (isPlaying) return;
        const { x } = e.point;
        const snappedX = Math.max(-10, Math.min(10, Math.round(x)));
        setCursorPos([snappedX, -5.9, 0]);
    };

    return (
        <>
            <color attach="background" args={['#000000']} />
            <ambientLight intensity={0.6} />
            <directionalLight castShadow position={[5, 10, 5]} intensity={1.5} shadow-mapSize={[1024, 1024]} />

            {/* Collision Detection Floor */}
            <mesh
                rotation={[-Math.PI / 2, 0, 0]}
                position={[0, -5.95, 0]}
                onPointerMove={onPointerMove}
                onPointerOver={() => setHoveringFloor(true)}
                onPointerOut={() => setHoveringFloor(false)}
                visible={false}
            >
                <planeGeometry args={[30, 30]} />
            </mesh>

            <Grid
                args={[20, 20]}
                cellColor="#333"
                sectionColor="#555"
                fadeDistance={25}
                position={[0, -5.99, 0]}
            />

            <RigidBody type="fixed" position={[0, -6, 0]}>
                <mesh receiveShadow>
                    <boxGeometry args={[30, 0.2, 30]} />
                    <meshStandardMaterial color="#111" />
                </mesh>
            </RigidBody>

            {/* Snapping Cursor (Box) */}
            {!isPlaying && useStore.getState().isHoveringFloor && (
                <group position={cursorPos}>
                    <mesh>
                        <boxGeometry args={[1, 0.1, 1]} />
                        {/* Edgesを削除し、半透明の面のみにする */}
                        <meshStandardMaterial color="white" transparent opacity={0.3} flatShading />
                    </mesh>
                    {/* Ghost Slope Preview */}
                    <mesh position={[0, 1, 0]} rotation={[0, 0, useStore.getState().cursorRot]}>
                        <cylinderGeometry args={[1, 1, 2, 3]} />
                        {/* プレビューも面で見せる */}
                        <meshStandardMaterial color="#fbbf24" transparent opacity={0.3} flatShading />
                    </mesh>
                </group>
            )}

            {/* Real Slope (ここに鮮やかな色を適用) */}
            <RigidBody type="kinematicPosition" position={slopePos} rotation={[0, 0, slopeRot]}>
                <mesh castShadow receiveShadow>
                    <cylinderGeometry args={[1, 1, 2, 3]} />
                    {/* 暗い色をやめ、質感.pngのような鮮やかな黄色に変更し、flatShadingをON */}
                    <meshStandardMaterial color="#fbbf24" roughness={0.8} flatShading />
                    {/* <Edges /> は削除 */}
                </mesh>
            </RigidBody>

            {/* Goal */}
            <mesh position={[7, -5.8, 0]} rotation={[-Math.PI / 2, 0, 0]}>
                <planeGeometry args={[3, 2]} />
                <meshStandardMaterial color="#ffd000" transparent opacity={0.4} />
            </mesh>
        </>
    );
}

/**
 * 3. UI (Using Inline Styles for strict positioning)
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
            {/* Title */}
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
 * 4. MAIN EXPORT
 */
export default function App() {
    const isHoveringFloor = useStore((state) => state.isHoveringFloor);

    return (
        <div style={{ width: '100vw', height: '100vh', backgroundColor: '#000', overflow: 'hidden', position: 'relative' }}>
            {/* antialias: false, pixelRatio: 1 はそのまま維持しレトロ感を保つ */}
            <Canvas shadows gl={{ antialias: false, pixelRatio: 1 }}>
                <PerspectiveCamera
                    makeDefault
                    position={[5, 5, 5]}
                    fov={50}
                />
                <OrbitControls
                    makeDefault
                    enabled={!isHoveringFloor}
                    enableZoom={false}
                    enablePan={false}
                    minPolarAngle={Math.PI / 4}
                    maxPolarAngle={Math.PI / 3}
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