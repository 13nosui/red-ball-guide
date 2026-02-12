import { Physics, RigidBody } from '@react-three/rapier';
import { OrbitControls } from '@react-three/drei';
import { Player } from './Player';
import { useStore } from '../store/useStore';

export function Experience() {
    return (
        <>
            {/* 背景色を少し明るめのグレーに変更して空間の広がりを出す */}
            <color attach="background" args={['#202025']} />

            {/* Lighting: ポップな雰囲気に合わせて明るく */}
            <ambientLight intensity={0.7} />
            <directionalLight
                castShadow
                position={[5, 15, 5]} // 影がきれいに落ちるように位置調整
                intensity={1.2}
                shadow-mapSize={[2048, 2048]} // 影の解像度アップ
            />

            <Physics gravity={[0, -9.81, 0]}>
                <Player />
                {/* 物理演算用の見えない床（ボールがタイルの継ぎ目に引っかからないようにする） */}
                <InvisibleFloor />

                {/* 見た目用のタイル床 */}
                <TileFloor />

                <MovableSlope />
                <Goal />
            </Physics>

            <OrbitControls makeDefault target={[0, 0, 0]} enableZoom={true} />
        </>
    );
}

/**
 * 物理演算用の見えない床
 */
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
 * 見た目用のタイルグリッド (10x10の盤面)
 */
function TileFloor() {
    // グリッドのサイズと範囲
    const size = 10;
    const half = size / 2;
    const tiles = [];

    for (let x = -half; x < half; x++) {
        for (let z = -half; z < half; z++) {
            // チェック柄の判定
            const isWhite = (x + z) % 2 === 0;
            const color = isWhite ? '#f0f0f0' : '#dcdcdc'; // 白と薄いグレー

            tiles.push(
                <mesh
                    key={`${x}-${z}`}
                    position={[x, -5.9, z]}
                    receiveShadow
                >
                    {/* タイルは少し隙間を空けると可愛くなるので 0.95 */}
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
                {/* 三角柱（スロープ） */}
                <cylinderGeometry args={[1, 1, 2, 3]} />
                <meshStandardMaterial
                    color="#fbbf24"   // 鮮やかなアンバー色
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
            {/* ゴールの目印として少し浮かせる */}
            <mesh position={[0, 0, 0.1]}>
                <ringGeometry args={[0.3, 0.4, 32]} />
                <meshBasicMaterial color="white" />
            </mesh>
        </mesh>
    );
}