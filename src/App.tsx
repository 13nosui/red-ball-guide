import React, { Suspense } from 'react';
import { Canvas } from '@react-three/fiber';
import { PerspectiveCamera } from '@react-three/drei';
import { Experience } from './components/Experience';
import { UI } from './components/UI';

export default function App() {
    return (
        <div className="w-full h-full bg-black flex flex-col overflow-hidden font-sans">
            <div className="flex-grow relative">
                <Canvas
                    shadows
                    gl={{ antialias: false }}
                    dpr={[1, 2]}
                >
                    <PerspectiveCamera
                        makeDefault
                        fov={55}
                        position={[8, 10, 10]}
                    />

                    <Suspense fallback={null}>
                        <Experience />
                    </Suspense>
                </Canvas>

                {/* Minimal HUD overlay */}
                <div className="absolute top-6 left-6 pointer-events-none select-none">
                    <h1 className="text-slate-1 font-black italic tracking-tighter text-2xl opacity-60">
                        RB.GUIDE_v4
                    </h1>
                    <div className="h-1 w-12 bg-red-9 mt-1" />
                </div>
            </div>

            <div className="h-1/3 bg-slate-12 border-t border-slate-11">
                <UI />
            </div>
        </div>
    );
}
