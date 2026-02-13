import { RigidBody } from '@react-three/rapier';
import { Grid, Edges } from '@react-three/drei';
import { useStore } from '../store/useStore';

export function Level() {
    return (
        <>
            <Grid
                infiniteGrid
                fadeDistance={50}
                fadeStrength={5}
                sectionSize={2}
                sectionColor="#333"
                cellColor="#111"
                position={[0, -6, 0]}
            />

            {/* Floor */}
            <RigidBody type="fixed" position={[0, -6, 0]}>
                <mesh receiveShadow>
                    <boxGeometry args={[20, 1, 4]} />
                    <meshStandardMaterial color="#111" />
                    <Edges color="white" />
                </mesh>
            </RigidBody>

            {/* Goal Area */}
            <mesh position={[7, -5, 0]}>
                <boxGeometry args={[3, 1, 2]} />
                <meshStandardMaterial color="#FFD000" wireframe />
            </mesh>

            {/* Walls */}
            <RigidBody type="fixed" position={[-10.5, 0, 0]}>
                <mesh>
                    <boxGeometry args={[1, 12, 4]} />
                    <meshStandardMaterial color="#000" transparent opacity={0.1} />
                    <Edges color="white" />
                </mesh>
            </RigidBody>
            <RigidBody type="fixed" position={[10.5, 0, 0]}>
                <mesh>
                    <boxGeometry args={[1, 12, 4]} />
                    <meshStandardMaterial color="#000" transparent opacity={0.1} />
                    <Edges color="white" />
                </mesh>
            </RigidBody>
        </>
    );
}

export function MovableSlope() {
    const slopePos = useStore((state) => state.slopePos);
    const slopeRot = useStore((state) => state.slopeRot);

    return (
        <RigidBody type="kinematicPosition" position={slopePos} rotation={[0, 0, slopeRot]}>
            <mesh castShadow receiveShadow>
                {/* Simple triangle using a custom shape or rotated box */}
                <cylinderGeometry args={[1.5, 1.5, 2, 3]} rotation={[Math.PI / 2, 0, 0]} />
                <meshStandardMaterial color="#888" />
                <Edges color="white" />
            </mesh>
        </RigidBody>
    );
}
