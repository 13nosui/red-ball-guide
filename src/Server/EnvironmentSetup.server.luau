-- src/Server/EnvironmentSetup.server.luau
local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- 設定
local GRID_SIZE = 4
local BASEPLATE_SIZE = 2048
local GRID_COLOR = Color3.fromRGB(255, 255, 255) -- 白い線
local BG_COLOR = Color3.fromRGB(15, 15, 20) -- ほぼ黒の背景

local function setupEnvironment()
	-- 1. Baseplateの設定
	local baseplate = workspace:FindFirstChild("Baseplate") or Instance.new("Part")
	baseplate.Name = "Baseplate"
	baseplate.Anchored = true
	baseplate.Locked = true
	baseplate.CanCollide = true
	baseplate.CastShadow = false
	baseplate.Material = Enum.Material.SmoothPlastic
	baseplate.Color = BG_COLOR
	baseplate.Size = Vector3.new(BASEPLATE_SIZE, 4, BASEPLATE_SIZE)

	-- Y=0が地面の表面になるように配置 (高さ4の半分を下にずらす)
	baseplate.Position = Vector3.new(0, -2, 0)

	-- 既存のテクスチャを削除
	for _, child in pairs(baseplate:GetChildren()) do
		if child:IsA("Texture") then
			child:Destroy()
		end
	end

	-- 2. グリッドテクスチャの適用
	local texture = Instance.new("Texture")
	texture.Name = "GridTexture"
	texture.Face = Enum.NormalId.Top
	-- Roblox標準のグリッド画像のID (枠線がはっきりしたもの)
	texture.Texture = "rbxassetid://6372755229"
	texture.Color3 = GRID_COLOR
	texture.Transparency = 0.8 -- 線を少し透かして目に優しくする（0にすると真っ白）
	texture.StudsPerTileU = GRID_SIZE
	texture.StudsPerTileV = GRID_SIZE
	texture.Parent = baseplate

	baseplate.Parent = workspace

	-- 3. ライティング調整（グリッドを見やすくするため少し暗めに）
	Lighting.Brightness = 2
	Lighting.ClockTime = 14 -- 昼間
	Lighting.Ambient = Color3.fromRGB(100, 100, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
end

setupEnvironment()

print("Environment Setup: Dark Grid Baseplate Generated")
