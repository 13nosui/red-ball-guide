-- src/Shared/Palette.luau
local Palette = {}

-- ブロックごとのメインカラー
Palette.BlockColors = {
	Block = Color3.fromHex("#3B82F6"), -- Blue 500
	Sphere = Color3.fromHex("#F97316"), -- Orange 500
	Wedge = Color3.fromHex("#10B981"), -- Emerald 500
	CornerWedge = Color3.fromHex("#8B5CF6"), -- Violet 500
	Cylinder = Color3.fromHex("#EC4899"), -- Pink 500
}

-- キャラクター・エンティティ
Palette.Entity = {
	Ball = Color3.fromHex("#DC2626"), -- Red 600
	GoalBase = Color3.fromHex("#15803d"), -- Green 700
	GoalFlag = Color3.fromHex("#eab308"), -- Yellow 500
	GoalPole = Color3.fromHex("#f8fafc"), -- Slate 50
	GoalCup = Color3.fromHex("#334155"), -- Slate 700

	FanHousing = Color3.fromHex("#64748b"), -- Slate 500
	FanBlade = Color3.fromHex("#f1f5f9"), -- Slate 100
	WindZone = Color3.fromHex("#bae6fd"), -- Sky 200
}

-- システムカラー
Palette.System = {
	Ghost = Color3.fromHex("#94A3B8"), -- Slate 400
	Selection = Color3.fromHex("#F59E0B"), -- Amber 500
	Success = Color3.fromHex("#22C55E"), -- Green 500
	Error = Color3.fromHex("#EF4444"), -- Red 500
	Move = Color3.fromHex("#06B6D4"), -- Cyan 500

	-- ★チュートリアル用ガイド色 (点滅する黄色)
	TutorialGhost = Color3.fromHex("#FDE047"), -- Yellow 300
}

return Palette
