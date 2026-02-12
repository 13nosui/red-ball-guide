import { useRef, useEffect } from 'react';
import { RigidBody, RigidBodyApi, CuboidCollider } from '@react-three/rapier';
import { useStore } from '../store/useStore';
import * as THREE from 'three';

export function Player() {
    const rbRef = useRef<RigidBodyApi>(null);
    const isPlaying = useStore((state) => state.isPlaying);
    // Starting slightly higher for dramatic drop
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
            // Keep it constrained to the 2D plane for gameplay consistency
            enabledTranslations={[true, true, false]}
            enabledRotations={[false, false, true]}
        >
            <CuboidCollider args={[0.5, 0.5, 0.5]} />
            <mesh castShadow receiveShadow>
                <boxGeometry args={[1, 1, 1]} />
                <meshStandardMaterial
                    color="#e5484d" // Radix Red 9
                    roughness={0.8}
                    metalness={0.1}
                />
            </mesh>
        </RigidBody>
    );
}
