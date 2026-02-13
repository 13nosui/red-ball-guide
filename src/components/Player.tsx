import { useRef, useEffect } from 'react';
import { RigidBody, RigidBodyApi, BallCollider } from '@react-three/rapier';
import { useStore } from '../store/useStore';
import * as THREE from 'three';

export function Player() {
    const rbRef = useRef<RigidBodyApi>(null);
    const isPlaying = useStore((state) => state.isPlaying);
    const startPos: [number, number, number] = [-4, 6, 0];

    useEffect(() => {
        if (!isPlaying && rbRef.current) {
            // 停止時は初期位置に戻し、速度や回転を完全にゼロにする
            rbRef.current.setTranslation(new THREE.Vector3(...startPos), true);
            rbRef.current.setLinvel({ x: 0, y: 0, z: 0 }, true);
            rbRef.current.setAngvel({ x: 0, y: 0, z: 0 }, true);
            rbRef.current.setRotation({ w: 1, x: 0, y: 0, z: 0 }, true);
        } else if (isPlaying && rbRef.current) {
            // 再生開始時に確実に物理演算を起こす
            rbRef.current.wakeUp();
        }
    }, [isPlaying]);

    return (
        <RigidBody
            ref={rbRef}
            name="player"
            // ▼ typeは途中で変えずに常に dynamic にする ▼
            type="dynamic"
            // ▼ 再生中だけ重力を1（ON）にし、停止中は0（無重力）で待機させる ▼
            gravityScale={isPlaying ? 1 : 0}
            position={startPos}
            colliders={false}
            enabledTranslations={[true, true, true]}
            enabledRotations={[true, true, true]}
            ccd={true}
            // ▼ 反発係数(restitution)と摩擦(friction)を調整して自然に転がるようにする ▼
            restitution={0.3}
            friction={0.5}
        >
            <BallCollider args={[0.5]} />
            <mesh castShadow receiveShadow>
                <sphereGeometry args={[0.5, 32, 32]} />
                <meshStandardMaterial
                    color="#e5484d"
                    roughness={0.8}
                    metalness={0.1}
                    flatShading={true}
                />
            </mesh>
        </RigidBody>
    );
}