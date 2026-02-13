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
	GoalBase = Color3.fromHex("#15803d"), -- Green 700 (芝生)
	GoalFlag = Color3.fromHex("#eab308"), -- Yellow 500 (旗)
	GoalPole = Color3.fromHex("#f8fafc"), -- Slate 50 (ポール)
	GoalCup = Color3.fromHex("#334155"), -- Slate 700 (カップの底) ★追加
}

-- システムカラー
Palette.System = {
	Ghost = Color3.fromHex("#94A3B8"), -- Slate 400
	Selection = Color3.fromHex("#F59E0B"), -- Amber 500
	Success = Color3.fromHex("#22C55E"), -- Green 500
	Error = Color3.fromHex("#EF4444"), -- Red 500
	Move = Color3.fromHex("#06B6D4"), -- Cyan 500
}

return Palette
