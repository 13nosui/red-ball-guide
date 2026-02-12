import React, { Suspense, useRef, useEffect } from 'react';
import { Canvas } from '@react-three/fiber';
import {
    PerspectiveCamera,
    OrbitControls,
    Grid,
    Edges,
    Html
} from '@react-three/drei';
import { Physics, RigidBody, RigidBodyApi, CuboidCollider } from '@react-three/rapier';
import * as THREE from 'three';
import { create } from 'zustand';
import { RotateCw, Play, Square, ChevronLeft, ChevronRight, RotateCcw } from 'lucide-react';

/**
 * Radix-like Colors (Constants to ensure zero dependencies on theme context if it's missing)
 */
const COLORS = {
    red9: '#e5484d',
    slate12: '#111113',
    slate6: '#4c4f5a',
};

/**
 * 1. GAME STATE (Zustand)
 */
interface GameState {
    isPlaying: boolean;
    slopePos: [number, number, number];
    slopeRot: number;
    togglePlay: () => void;
    reset: () => void;
    moveSlope: (dir: number) => void;
    rotateSlope: () => void;
}

const useStore = create<GameState>((set) => ({
    isPlaying: false,
    slopePos: [0, -4, 0],
    slopeRot: 0,
    togglePlay: () => set((state) => ({ isPlaying: !state.isPlaying })),
    reset: () => set({ isPlaying: false, slopePos: [0, -4, 0], slopeRot: 0 }),
    moveSlope: (dir) => set((state) => ({
        slopePos: [state.slopePos[0] + dir * 2, state.slopePos[1], state.slopePos[2]]
    })),
    rotateSlope: () => set((state) => ({
        slopeRot: state.slopeRot + Math.PI / 2
    })),
}));

/**
 * 2. PLAYER COMPONENT (Red Block)
 */
function Player() {
    const rbRef = useRef<RigidBodyApi>(null);
    const isPlaying = useStore((state) => state.isPlaying);
    const startPos: [number, number, number] = [-8, 6, 0];

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
                <meshStandardMaterial color={COLORS.red9} roughness={0.8} />
            </mesh>
        </RigidBody>
    );
}

/**
 * 3. SCENE COMPONENTS
 */
function Environment() {
    const slopePos = useStore((state) => state.slopePos);
    const slopeRot = useStore((state) => state.slopeRot);

    return (
        <>
            <color attach="background" args={['#000000']} />
            <ambientLight intensity={0.5} />
            <directionalLight
                castShadow
                position={[5, 10, 5]}
                intensity={1.2}
                shadow-mapSize={[1024, 1024]}
            />

            {/* Grid Floor Visual */}
            <Grid
                args={[20, 20]}
                cellColor={COLORS.slate6}
                sectionColor={COLORS.slate6}
                fadeDistance={30}
                position={[0, -5.99, 0]}
            />

            {/* Physics Floor */}
            <RigidBody type="fixed" position={[0, -6, 0]}>
                <mesh receiveShadow>
                    <boxGeometry args={[30, 0.2, 30]} />
                    <meshStandardMaterial color={COLORS.slate12} />
                </mesh>
            </RigidBody>

            {/* Movable Slope */}
            <RigidBody type="kinematicPosition" position={slopePos} rotation={[0, 0, slopeRot]}>
                <mesh castShadow receiveShadow>
                    <cylinderGeometry args={[1.5, 1.5, 2, 3]} />
                    <meshStandardMaterial color="#2a2e33" />
                    <Edges color="white" />
                </mesh>
            </RigidBody>

            {/* Goal Area */}
            <mesh position={[7, -5.8, 0]} rotation={[-Math.PI / 2, 0, 0]}>
                <planeGeometry args={[3, 2]} />
                <meshStandardMaterial color="#ffd000" transparent opacity={0.4} />
            </mesh>
        </>
    );
}

/**
 * 4. UI OVERLAY
 */
function UI() {
    const { isPlaying, togglePlay, reset, moveSlope, rotateSlope } = useStore();

    const ControlButton = ({ icon: Icon, onClick, color = 'slate' }: any) => (
        <button
            onPointerDown={(e) => { e.preventDefault(); onClick(); }}
            className={`
        w-14 h-14 flex items-center justify-center rounded-sm border-2
        ${color === 'red' ? 'border-red-500 text-red-500 bg-red-950/20' :
                    color === 'green' ? 'border-green-500 text-green-500 bg-green-950/20' :
                        'border-slate-500 text-slate-500 bg-slate-900/50'}
        active:scale-90 transition-transform select-none
      `}
        >
            <Icon size={28} />
        </button>
    );

    return (
        <div className="absolute inset-x-0 bottom-0 pointer-events-none flex flex-col justify-end p-6 pb-12">
            <div className="w-full flex justify-between items-center pointer-events-auto max-w-2xl mx-auto">
                <div className="flex gap-4">
                    <ControlButton icon={RotateCw} onClick={rotateSlope} />
                    <ControlButton
                        icon={isPlaying ? Square : Play}
                        onClick={togglePlay}
                        color={isPlaying ? 'green' : 'red'}
                    />
                    <ControlButton icon={RotateCcw} onClick={reset} />
                </div>

                <div className="flex gap-4">
                    <ControlButton icon={ChevronLeft} onClick={() => moveSlope(-1)} />
                    <ControlButton icon={ChevronRight} onClick={() => moveSlope(1)} />
                </div>
            </div>
        </div>
    );
}

/**
 * 5. MAIN APP
 */
export default function App() {
    return (
        <div className="w-screen h-screen bg-black overflow-hidden relative touch-none">
            <Canvas
                shadows
                gl={{ antialias: false, pixelRatio: 1 }}
                style={{ width: '100%', height: '100%' }}
            >
                <PerspectiveCamera
                    makeDefault
                    position={[10, 10, 10]}
                    fov={50}
                />
                <OrbitControls
                    enableZoom={false}
                    enablePan={false}
                    minPolarAngle={Math.PI / 4}
                    maxPolarAngle={Math.PI / 3}
                />

                <Suspense fallback={<Html center className="text-white">SYSTEM_BOOTING...</Html>}>
                    <Physics gravity={[0, -9.81, 0]}>
                        <Player />
                        <Environment />
                    </Physics>
                </Suspense>
            </Canvas>

            <div className="absolute top-6 left-6 pointer-events-none opacity-40">
                <h1 className="text-white font-black italic tracking-widest text-lg">RED_BLOCK_GUIDE_v5</h1>
                <div className="h-0.5 w-16 bg-red-600 mt-1" />
            </div>

            <UI />
        </div>
    );
}
