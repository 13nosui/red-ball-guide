import { Physics, RigidBody } from '@react-three/rapier';
import { Grid, OrbitControls } from '@react-three/drei';
import { Player } from './Player';
import { useStore } from '../store/useStore';
// import * as THREE from 'three'; // 未使用なら削除可

export function Experience() {
    return (
        <>
            <color attach="background" args={['#000000']} />

            {/* Lighting: レトロ感を出すため少し明るめに */}
            <ambientLight intensity={0.6} />
            <directionalLight
                castShadow
                position={[5, 10, 5]}
                intensity={1.5}
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

            {/* Grid: 少し控えめにしてブロックを目立たせる */}
            <Grid
                infiniteGrid
                fadeDistance={30}
                fadeStrength={5}
                sectionSize={2}
                sectionColor="#444"
                cellColor="#222"
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
                {/* 床もマットな質感に */}
                <meshStandardMaterial color="#161618" roughness={0.8} flatShading />
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
                {/* 三角柱（スロープ）の形状 */}
                <cylinderGeometry args={[1, 1, 2, 3]} />

                {/* ▼▼▼ ここが変更点 ▼▼▼ */}
                {/* 「質感.png」の黄色いブロックのような見た目にする */}
                <meshStandardMaterial
                    color="#fbbf24"   /* 鮮やかなアンバー色 */
                    roughness={0.8}   /* マットな質感 */
                    flatShading={true} /* ポリゴンのカクカク感を出す */
                />
                {/* ▲▲▲ ここまで ▲▲▲ */}
            </mesh>
        </RigidBody>
    );
}

function Goal() {
    return (
        <mesh position={[7, -5.8, 0]} rotation={[-Math.PI / 2, 0, 0]}>
            <planeGeometry args={[3, 2]} />
            <meshStandardMaterial color="#FFD000" transparent opacity={0.4} flatShading />
        </mesh>
    );
}