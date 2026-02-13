-- src/Shared/Palette.luau
local Palette = {}

-- ブロックごとのメインカラー (Radix/Apple風のソフトで鮮やかな色)
Palette.BlockColors = {
	Block = Color3.fromHex("#3B82F6"), -- Blue 500
	Sphere = Color3.fromHex("#F97316"), -- Orange 500
	Wedge = Color3.fromHex("#10B981"), -- Emerald 500
	CornerWedge = Color3.fromHex("#8B5CF6"), -- Violet 500
	Cylinder = Color3.fromHex("#EC4899"), -- Pink 500
}

-- システムカラー
Palette.System = {
	Ghost = Color3.fromHex("#94A3B8"), -- Slate 400 (半透明用)
	Selection = Color3.fromHex("#F59E0B"), -- Amber 500 (選択枠)
	Success = Color3.fromHex("#22C55E"), -- Green 500
	Error = Color3.fromHex("#EF4444"), -- Red 500
}

return Palette
