// ▼ CuboidCollider をインポートに追加 ▼
import { Physics, RigidBody, CuboidCollider } from '@react-three/rapier';
import { OrbitControls, Instances, Instance } from '@react-three/drei';
import { Player } from './Player';
import { useStore } from '../store/useStore';

export function Experience() {
    return (
        <>
            <color attach="background" args={['#dcdcdc']} />
            <ambientLight intensity={0.7} />
            <directionalLight
                castShadow
                position={[5, 15, 5]}
                intensity={1.2}
                shadow-mapSize={[2048, 2048]}
            />

            <Physics gravity={[0, -9.81, 0]}>
                <Player />

                <RigidBody type="fixed" position={[0, -6.9, 0]} friction={0.5}>
                    {/* ▼ 見えない床が確実に判定を持つように明示 ▼ */}
                    <CuboidCollider args={[50, 1, 50]} />
                    <mesh visible={false}>
                        <boxGeometry args={[100, 2, 100]} />
                        <meshStandardMaterial color="black" />
                    </mesh>
                </RigidBody>

                <InfiniteTileFloor />
                <MovableSlope />
                <Goal />
            </Physics>

            <OrbitControls
                makeDefault
                target={[0, 0, 0]}
                enableZoom={true}
                enablePan={true}
                panSpeed={1}
            />
        </>
    );
}

function InfiniteTileFloor() {
    const size = 60;
    const half = size / 2;
    const tileData = [];
    for (let x = -half; x < half; x++) {
        for (let z = -half; z < half; z++) {
            const isWhite = (x + z) % 2 === 0;
            const color = isWhite ? '#f0f0f0' : '#dcdcdc';
            tileData.push({ position: [x, -5.9, z], color });
        }
    }
    return (
        <group>
            <Instances range={tileData.length} limit={tileData.length}>
                <boxGeometry args={[0.95, 0.2, 0.95]} />
                <meshStandardMaterial roughness={0.8} flatShading />
                {tileData.map((data, i) => (
                    <Instance key={i} position={data.position as [number, number, number]} color={data.color} />
                ))}
            </Instances>
        </group>
    );
}

function MovableSlope() {
    const slopePos = useStore((state) => state.slopePos);
    const slopeRot = useStore((state) => state.slopeRot);

    return (
        <RigidBody
            type="kinematicPosition"
            position={slopePos}
            rotation={slopeRot}
            // ▼ 四角い判定ではなく「実際の三角形の見た目」に当たり判定を合わせる ▼
            colliders="hull"
            friction={0.2}
        >
            <mesh castShadow receiveShadow>
                <cylinderGeometry args={[1, 1, 2, 3]} />
                <meshStandardMaterial color="#fbbf24" roughness={0.8} flatShading={true} />
            </mesh>
        </RigidBody>
    );
}

function Goal() {
    const setGameStatus = useStore((state) => state.setGameStatus);
    const isPlaying = useStore((state) => state.isPlaying);

    return (
        <RigidBody
            type="fixed"
            sensor
            position={[4, -5.79, 0]}
            rotation={[-Math.PI / 2, 0, 0]}
            onIntersectionEnter={({ other }) => {
                if (isPlaying && other.rigidBodyObject?.name === "player") {
                    setGameStatus('cleared');
                }
            }}
        >
            <mesh receiveShadow>
                <planeGeometry args={[1, 1]} />
                <meshStandardMaterial color="#FFD000" transparent opacity={0.6} />
                <mesh position={[0, 0, 0.1]}>
                    <ringGeometry args={[0.3, 0.4, 32]} />
                    <meshBasicMaterial color="white" />
                </mesh>
            </mesh>
        </RigidBody>
    );
}