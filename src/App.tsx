import React, { Suspense } from 'react';
import { Canvas } from '@react-three/fiber';
import { Physics } from '@react-three/rapier';
import { PerspectiveCamera, Environment } from '@react-three/drei';
import * as THREE from 'three';
import { Player } from './components/Player';
import { Level, MovableSlope } from './components/Level';
import { UI } from './components/UI';

export default function App() {
    return (
        <div className="w-full h-full bg-black flex flex-col overflow-hidden">
            <div className="flex-grow relative">
                <Canvas
                    shadows={{ type: THREE.BasicShadowMap }}
                    gl={{ antialias: false }}
                    onCreated={({ gl }) => {
                        gl.setClearColor('#000000');
                    }}
                >
                    <PerspectiveCamera
                        makeDefault
                        fov={85}
                        position={[10, 10, 15]}
                    />

                    <ambientLight intensity={0.5} />
                    <directionalLight
                        castShadow
                        position={[10, 20, 10]}
                        intensity={1.5}
                        shadow-mapSize={[512, 512]}
                        shadow-camera-left={-20}
                        shadow-camera-right={20}
                        shadow-camera-top={20}
                        shadow-camera-bottom={-20}
                    />

                    <Suspense fallback={null}>
                        <Physics gravity={[0, -9.81, 0]}>
                            <Player />
                            <MovableSlope />
                            <Level />
                        </Physics>
                    </Suspense>
                </Canvas>

                <div className="absolute top-4 w-full text-center pointer-events-none">
                    <h1 className="text-slate-1 font-bold tracking-widest text-xl opacity-80">RED BALL GUIDE</h1>
                </div>
            </div>

            <div className="h-1/3 bg-slate-12 border-t border-slate-11">
                <UI />
            </div>
        </div>
    );
}
