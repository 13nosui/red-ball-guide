import { Physics, RigidBody } from '@react-three/rapier';
import { OrbitControls, Instances, Instance } from '@react-three/drei';
import { Player } from './Player';
import { useStore } from '../store/useStore';

export function Experience() {
    return (
        <>
            {/* 背景色をタイルの暗い色に合わせて、遠くの境界を目立たなくする */}
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
                <InvisibleFloor />

                {/* 巨大なタイル床 (Instancesで軽量化) */}
                <InfiniteTileFloor />

                <MovableSlope />
                <Goal />
            </Physics>

            <OrbitControls
                makeDefault
                target={[0, 0, 0]}
                enableZoom={true}
                // ▼▼▼ パン（平行移動）を有効化 ▼▼▼
                enablePan={true}
                // パンの速度調整（お好みで）
                panSpeed={1}
            />
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
 * インスタンス描画を使った巨大なタイル床
 * 60x60 = 3600枚のタイルを軽量に描画します
 */
function InfiniteTileFloor() {
    const size = 60; // サイズを大幅に拡大
    const half = size / 2;

    // タイルの配置データを計算
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
            {/* インスタンスの定義: ジオメトリとマテリアルを共有 */}
            <Instances range={tileData.length}>
                <boxGeometry args={[0.95, 0.2, 0.95]} />
                <meshStandardMaterial roughness={0.8} flatShading />

                {/* 個々のタイルを配置 */}
                {tileData.map((data, i) => (
                    <Instance
                        key={i}
                        position={data.position as [number, number, number]}
                        color={data.color}
                    />
                ))}
            </Instances>
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