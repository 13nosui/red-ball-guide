// ... (imports)
import { Canvas, useThree } from '@react-three/fiber';
import { PerspectiveCamera, OrbitControls } from '@react-three/drei';
// ... (他のimportはそのまま)

// ... (GameState, GameUI などは変更なし)

/**
 * 4. MAIN EXPORT
 */
export default function App() {
    const isHoveringFloor = useStore((state) => state.isHoveringFloor);

    return (
        <div style={{ width: '100vw', height: '100vh', backgroundColor: '#dcdcdc', overflow: 'hidden', position: 'relative' }}>
            <Canvas shadows gl={{ antialias: false, pixelRatio: 1 }}>

                <PerspectiveCamera
                    makeDefault
                    position={[0, 20, 20]}
                    fov={60}
                />

                <ResponsiveCamera />

                <OrbitControls
                    makeDefault
                    enabled={!isHoveringFloor}
                    enableZoom={true}
                    // ▼▼▼ ここを変更 ▼▼▼
                    enablePan={true} // パンを許可
                    enableRotate={true} // 回転も許可（必要ならfalseに戻す）
                    // ▲▲▲ ここまで ▲▲▲
                    minAzimuthAngle={-Math.PI / 4}
                    maxAzimuthAngle={Math.PI / 4}
                    minPolarAngle={Math.PI / 6}
                    maxPolarAngle={Math.PI / 2.5}
                />

                <Suspense fallback={null}>
                    <Physics gravity={[0, -9.81, 0]}>
                        <Experience />
                    </Physics>
                </Suspense>
            </Canvas>
            <GameUI />
        </div>
    );
}

// ... (ResponsiveCamera コンポーネントはそのまま)