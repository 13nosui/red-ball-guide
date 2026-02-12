import { Physics, RigidBody } from '@react-three/rapier';
import { OrbitControls } from '@react-three/drei';
import { Player } from './Player';
import { useStore } from '../store/useStore';

export function Experience() {
    return (
        <>
            <color attach="background" args={['#202025']} />

            <ambientLight intensity={0.7} />
            <directionalLight
                castShadow
                position={[5, 15, 5]}
                intensity={1.2}
                shadow-mapSize={[2048, 2048]}
            />

            <Physics gravity={[0, -9.81, 0]}>
                <Player />
                <InvisibleFloor />
                <TileFloor />
                <MovableSlope />
                <Goal />
            </Physics>

            <OrbitControls makeDefault target={[0, 0, 0]} enableZoom={true} />
        </>
    );
}

function InvisibleFloor() {
    return (
        <RigidBody type="fixed" position={[0, -6, 0]} friction={0.5}>
            <mesh visible={false}>
                <boxGeometry args={[100, 0.2, 100]} />
                <meshStandardMaterial color="black" />
            </mesh>
        </RigidBody>
    );
}

/**
 * 見た目用のタイルグリッド (サイズを拡大)
 */
function TileFloor() {
    // ▼▼▼ 修正箇所 ▼▼▼
    // サイズを 10 から 20 に変更して、画面の端まで床があるように見せる
    const size = 20;
    // ▲▲▲ 修正箇所 ▲▲▲

    const half = size / 2;
    const tiles = [];

    for (let x = -half; x < half; x++) {
        for (let z = -half; z < half; z++) {
            const isWhite = (x + z) % 2 === 0;
            const color = isWhite ? '#f0f0f0' : '#dcdcdc';

            tiles.push(
                <mesh
                    key={`${x}-${z}`}
                    position={[x, -5.9, z]}
                    receiveShadow
                >
                    <boxGeometry args={[0.95, 0.2, 0.95]} />
                    <meshStandardMaterial
                        color={color}
                        roughness={0.8}
                        flatShading={true}
                    />
                </mesh>
            );
        }
    }

    return (
        <group>
            {tiles}
        </group>
    );
}

function MovableSlope() {
    const slopePos = useStore((state) => state.slopePos);
    const slopeRot = useStore((state) => state.slopeRot);

    return (
        <RigidBody type="kinematicPosition" position={slopePos} rotation={[0, 0, slopeRot]}>
            <mesh castShadow receiveShadow>
                <cylinderGeometry args={[1, 1, 2, 3]} />
                <meshStandardMaterial
                    color="#fbbf24"
                    roughness={0.8}
                    flatShading={true}
                />
            </mesh>
        </RigidBody>
    );
}

function Goal() {
    return (
        <mesh position={[4, -5.79, 0]} rotation={[-Math.PI / 2, 0, 0]} receiveShadow>
            <planeGeometry args={[1, 1]} />
            <meshStandardMaterial color="#FFD000" transparent opacity={0.6} />
            <mesh position={[0, 0, 0.1]}>
                <ringGeometry args={[0.3, 0.4, 32]} />
                <meshBasicMaterial color="white" />
            </mesh>
        </mesh>
    );
}