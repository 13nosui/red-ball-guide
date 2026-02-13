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
	Ball = Color3.fromHex("#DC2626"), -- Red 600 (主役の赤)
}

-- システムカラー
Palette.System = {
	Ghost = Color3.fromHex("#94A3B8"), -- Slate 400
	Selection = Color3.fromHex("#F59E0B"), -- Amber 500
	Success = Color3.fromHex("#22C55E"), -- Green 500
	Error = Color3.fromHex("#EF4444"), -- Red 500
}

return Palette
