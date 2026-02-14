-- src/Server/EnvironmentSetup.server.luau
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- 1. ライティング設定 (ポップで鮮やかに)
Lighting.Ambient = Color3.fromRGB(150, 150, 150)
Lighting.Brightness = 2
Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1
Lighting.GlobalShadows = true
Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
Lighting.ShadowSoftness = 0.2
Lighting.ClockTime = 12 -- 真昼
Lighting.GeographicLatitude = 41.73

-- エフェクト削除 & 追加
for _, child in ipairs(Lighting:GetChildren()) do
	if not child:IsA("Sky") then
		child:Destroy()
	end
end

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "PopColorCorrection"
colorCorrection.Brightness = 0.1
colorCorrection.Contrast = 0.2
colorCorrection.Saturation = 0.4 -- 彩度を上げてポップに
colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
colorCorrection.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Name = "DreamyBloom"
bloom.Intensity = 0.4
bloom.Size = 24
bloom.Threshold = 0.8
bloom.Parent = Lighting

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(199, 244, 255)
atmosphere.Decay = Color3.fromRGB(106, 57, 9)
atmosphere.Glare = 0
atmosphere.Haze = 0
atmosphere.Parent = Lighting

-- 2. スカイボックス (カートゥーン調)
local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.Parent = Lighting
-- フリーのカートゥーン青空テクスチャIDを使用 (または好みのIDに変更可能)
sky.SkyboxBk = "http://www.roblox.com/asset/?id=6444884337"
sky.SkyboxDn = "http://www.roblox.com/asset/?id=6444884785"
sky.SkyboxFt = "http://www.roblox.com/asset/?id=6444884337"
sky.SkyboxLf = "http://www.roblox.com/asset/?id=6444884337"
sky.SkyboxRt = "http://www.roblox.com/asset/?id=6444884337"
sky.SkyboxUp = "http://www.roblox.com/asset/?id=6444884062"
sky.SunTextureId = "http://www.roblox.com/asset/?id=6196665106" -- かわいい太陽

-- 3. 無限ベースプレート (明るいデザイン)
local baseplate = Workspace:FindFirstChild("Baseplate") or Instance.new("Part")
baseplate.Name = "Baseplate"
baseplate.Size = Vector3.new(2048, 4, 2048)
baseplate.Position = Vector3.new(0, -10, 0) -- 少し下に配置
baseplate.Anchored = true
baseplate.Material = Enum.Material.Grass -- 芝生
baseplate.Color = Color3.fromRGB(125, 218, 88) -- 明るい緑
baseplate.Parent = Workspace

-- グリッドテクスチャ (少し薄く)
local texture = Instance.new("Texture")
texture.Texture = "rbxassetid://6372755229"
texture.Color3 = Color3.fromRGB(255, 255, 230) -- クリーム色
texture.Transparency = 0.8
texture.Face = Enum.NormalId.Top
texture.StudsPerTileU = 16
texture.StudsPerTileV = 16
texture.Parent = baseplate

print("Environment Setup: Pop Style Applied")
