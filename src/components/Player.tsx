import { useRef, useEffect } from 'react';
import { useFrame } from '@react-three/fiber';
import { RigidBody, RigidBodyApi } from '@react-three/rapier';
import { useStore } from '../store/useStore';
import * as THREE from 'three';

export function Player() {
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
            colliders="ball"
            restitution={0.5}
        >
            <mesh castShadow>
                <sphereGeometry args={[0.5, 32, 32]} />
                <meshStandardMaterial color="#E5484D" roughness={0.8} metalness={0.2} />
            </mesh>
        </RigidBody>
    );
}
