import React, { Suspense, useRef, useEffect, useState } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
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
 * 1. GAME STATE (Zustand integrated inside)
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
                <meshStandardMaterial color="#e5484d" roughness={0.8} />
            </mesh>
        </RigidBody>
    );
}

/**
 * 3. LEVEL COMPONENTS (Solid 3D Objects)
 */
function Level() {
    return (
        <>
            {/* Floor - Solid slab to receive shadows */}
            <RigidBody type="fixed" position={[0, -6, 0]}>
                <mesh receiveShadow>
                    <boxGeometry args={[30, 0.5, 10]} />
                    <meshStandardMaterial color="#161618" />
                </mesh>
            </RigidBody>

            {/* Visual Grid for Cyberspace feel */}
            <Grid
                infiniteGrid
                args={[10, 10]}
                cellColor="#444"
                sectionColor="#888"
                fadeDistance={20}
                position={[0, -5.7, 0]}
            />

            {/* Goal Area (Pure 3D Solid Plane) */}
            <RigidBody type="fixed" position={[7, -5.7, 0]}>
                <mesh rotation={[-Math.PI / 2, 0, 0]}>
                    <planeGeometry args={[3, 2]} />
                    <meshStandardMaterial color="#FFD000" transparent opacity={0.4} />
                </mesh>
            </RigidBody>
        </>
    );
}

function MovableSlope() {
    const slopePos = useStore((state) => state.slopePos);
    const slopeRot = useStore((state) => state.slopeRot);

    return (
        <RigidBody type="kinematicPosition" position={slopePos} rotation={[0, 0, slopeRot]}>
            <mesh castShadow receiveShadow>
                {/* Wedge Prism using cylinder with 3 sides */}
                <cylinderGeometry args={[1.5, 1.5, 2, 3]} />
                <meshStandardMaterial color="#313538" />
                <Edges color="white" />
            </mesh>
        </RigidBody>
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
                        'border-slate-400 text-slate-400 bg-slate-900/50'}
        active:scale-90 transition-transform select-none
      `}
        >
            <Icon size={28} fill={color !== 'slate' ? "currentColor" : "none"} />
        </button>
    );

    return (
        <div className="absolute inset-0 pointer-events-none flex flex-col justify-end p-6">
            {/* 3D VIEW HUD */}
            <div className="absolute top-6 left-6 opacity-40">
                <h2 className="text-white font-black italic tracking-widest text-sm">3D VIEW_ACTIVE</h2>
                <div className="h-0.5 w-16 bg-red-600" />
            </div>

            <div className="w-full flex justify-between items-center pointer-events-auto max-w-2xl mx-auto">
                <div className="flex gap-3">
                    <ControlButton icon={RotateCw} onClick={rotateSlope} />
                    <ControlButton
                        icon={isPlaying ? Square : Play}
                        onClick={togglePlay}
                        color={isPlaying ? 'green' : 'red'}
                    />
                    <ControlButton icon={RotateCcw} onClick={reset} />
                </div>

                <div className="flex gap-3">
                    <ControlButton icon={ChevronLeft} onClick={() => moveSlope(-1)} />
                    <ControlButton icon={ChevronRight} onClick={() => moveSlope(1)} />
                </div>
            </div>
        </div>
    );
}

/**
 * 5. MAIN APP (Single File Entry)
 */
export default function App() {
    return (
        <div className="w-full h-screen bg-black overflow-hidden relative">
            <Canvas
                shadows
                gl={{
                    antialias: false,
                    pixelRatio: 1  // Forced jaggy look
                }}
                dpr={[1, 1]} // Double confirmation for low pixel density
            >
                <PerspectiveCamera
                    makeDefault
                    position={[10, 10, 10]}
                    fov={50}
                />

                <OrbitControls
                    makeDefault
                    enableZoom={false}
                    enablePan={false}
                    minPolarAngle={Math.PI / 4}
                    maxPolarAngle={Math.PI / 3}
                />

                <color attach="background" args={['#000000']} />

                {/* Lights */}
                <ambientLight intensity={0.5} />
                <directionalLight
                    castShadow
                    position={[5, 10, 5]}
                    intensity={1.2}
                    shadow-mapSize={[512, 512]}
                    shadow-camera-left={-15}
                    shadow-camera-right={15}
                    shadow-camera-top={15}
                    shadow-camera-bottom={-15}
                />

                <Suspense fallback={<Html center className="text-white">LOADING_BLOCKS...</Html>}>
                    <Physics gravity={[0, -9.81, 0]}>
                        <Player />
                        <MovableSlope />
                        <Level />
                    </Physics>
                </Suspense>
            </Canvas>

            <UI />
        </div>
    );
}
