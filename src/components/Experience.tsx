import { Physics, RigidBody } from '@react-three/rapier';
import { Grid, Environment, OrbitControls } from '@react-three/drei';
import { Player } from './Player';
import { useStore } from '../store/useStore';
import * as THREE from 'three';

export function Experience() {
    return (
        <>
            <color attach="background" args={['#000000']} />

            {/* Lighting */}
            <ambientLight intensity={0.5} />
            <directionalLight
                castShadow
                position={[5, 10, 5]}
                intensity={1.0}
                shadow-mapSize={[1024, 1024]}
                shadow-camera-left={-20}
                shadow-camera-right={20}
                shadow-camera-top={20}
                shadow-camera-bottom={-20}
            />

            <Physics gravity={[0, -9.81, 0]}>
                <Player />
                <Floor />
                <MovableSlope />
                <Goal />
            </Physics>

            <Grid
                infiniteGrid
                fadeDistance={30}
                fadeStrength={5}
                sectionSize={2}
                sectionColor="#4c4f5a" // Radix Slate 6
                cellColor="#4c4f5a"
                position={[0, -5.99, 0]}
            />

            <OrbitControls makeDefault target={[0, 0, 0]} enableZoom={true} />
        </>
    );
}

function Floor() {
    return (
        <RigidBody type="fixed" position={[0, -6, 0]}>
            <mesh receiveShadow>
                <boxGeometry args={[30, 0.2, 30]} />
                <meshStandardMaterial color="#161618" /> {/* Radix Slate 12 Darkest */}
            </mesh>
        </RigidBody>
    );
}

function MovableSlope() {
    const slopePos = useStore((state) => state.slopePos);
    const slopeRot = useStore((state) => state.slopeRot);

    return (
        <RigidBody type="kinematicPosition" position={slopePos} rotation={[0, 0, slopeRot]}>
            <mesh castShadow receiveShadow>
                {/* Creating a solid wedge using a box + rotation or custom geometry */}
                {/* Here we use a cylinder with 3 segments for a perfect wedge prism */}
                <cylinderGeometry args={[1.5, 1.5, 2, 3]} />
                <meshStandardMaterial color="#313538" /> {/* Radix Slate 11ish */}
            </mesh>
        </RigidBody>
    );
}

function Goal() {
    return (
        <mesh position={[7, -5.8, 0]} rotation={[-Math.PI / 2, 0, 0]}>
            <planeGeometry args={[3, 2]} />
            <meshStandardMaterial color="#FFD000" transparent opacity={0.4} />
        </mesh>
    );
}
