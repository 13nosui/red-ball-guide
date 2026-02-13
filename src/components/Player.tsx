import { useRef, useEffect } from 'react';
import { RigidBody, RigidBodyApi, BallCollider } from '@react-three/rapier';
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
            name="player"
            type={isPlaying ? "dynamic" : "kinematicPosition"}
            position={startPos}
            colliders={false}
            // ▼▼▼ Z軸方向への移動と回転も解放して、3D空間を転がれるようにする ▼▼▼
            enabledTranslations={[true, true, true]}
            enabledRotations={[true, true, true]}
        >
            {/* ▼▼▼ 四角形から球体（ボール）に変更 ▼▼▼ */}
            <BallCollider args={[0.5]} />
            <mesh castShadow receiveShadow>
                {/* 32分割の滑らかな球体。あえてflatShadingをつけてレトロ感を出す */}
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