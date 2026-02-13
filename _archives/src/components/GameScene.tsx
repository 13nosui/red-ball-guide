import { RigidBody } from '@react-three/rapier';
import { Grid, OrbitControls, PerspectiveCamera } from '@react-three/drei';
import { useStore } from '../store/useStore';

export function GameScene() {
    return (
        <>
            {/* 1. Camera Setting */}
            <PerspectiveCamera
                makeDefault
                fov={75}
                position={[10, 12, 10]}
            />
            <OrbitControls target={[0, 0, 0]} enableZoom={true} enableRotate={true} />

            {/* 2. Environment (Grid Space) */}
            <color attach="background" args={['#000000']} />

            {/* 3. Lighting */}
            <ambientLight intensity={0.4} />
            <directionalLight
                castShadow
                position={[5, 10, 5]}
                intensity={1.0}
                shadow-mapSize={[1024, 1024]}
            />

            {/* Floor */}
            <PhysicsFloor />

            {/* Grid Visual */}
            <Grid
                infiniteGrid
                fadeDistance={40}
                fadeStrength={5}
                sectionSize={2}
                sectionColor="white"
                cellColor="white"
                position={[0, -6.01, 0]} // Slightly below floor to check shadow
            />

            {/* Goal Area */}
            <mesh position={[7, -5.5, 0]} rotation={[-Math.PI / 2, 0, 0]}>
                <planeGeometry args={[3, 2]} />
                <meshStandardMaterial color="#FFD000" transparent opacity={0.3} />
                <Edges color="#FFD000" />
            </mesh>
        </>
    );
}

function PhysicsFloor() {
    return (
        <RigidBody type="fixed" position={[0, -6, 0]}>
            <mesh receiveShadow>
                <boxGeometry args={[30, 0.1, 30]} />
                <meshStandardMaterial color="#050505" />
            </mesh>
        </RigidBody>
    );
}

function Edges({ color }: { color: string }) {
    return (
        <lineSegments>
            <edgesGeometry args={[new THREE.PlaneGeometry(3, 2)]} />
            <lineBasicMaterial color={color} />
        </lineSegments>
    );
}

import * as THREE from 'three';
