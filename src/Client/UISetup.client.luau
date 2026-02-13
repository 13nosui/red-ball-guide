-- src/Client/UISetup.client.luau
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- メインのScreenGui作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScreenGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- エディット用フレーム
local editFrame = Instance.new("Frame")
editFrame.Name = "EditFrame"
editFrame.Size = UDim2.new(1, 0, 1, 0)
editFrame.BackgroundTransparency = 1
editFrame.Parent = screenGui

-- 1. ドロワーメニュー（左側）
local drawerFrame = Instance.new("Frame")
drawerFrame.Name = "DrawerMenu"
drawerFrame.Size = UDim2.new(0, 100, 0.5, 0)
drawerFrame.Position = UDim2.new(0, 10, 0.25, 0)
drawerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
drawerFrame.BorderSizePixel = 0
drawerFrame.Parent = editFrame

-- ■ ヘルパー関数: 3Dアイコンボタンの作成
local function create3DButton(name, blockType, parent)
	local btn = Instance.new("ImageButton") -- クリック可能な画像ボタン
	btn.Name = name
	btn.Size = UDim2.new(0, 80, 0, 80)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Parent = parent

	-- 角を丸くする
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = btn

	-- 3D表示用のフレーム
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1, 0, 1, 0)
	viewport.BackgroundTransparency = 1
	viewport.Parent = btn

	-- 表示するパーツの作成
	local part
	if blockType == "Block" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Block
	elseif blockType == "Sphere" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
	elseif blockType == "Wedge" then
		part = Instance.new("WedgePart")
	end

	if part then
		part.Size = Vector3.new(4, 4, 4)
		part.Color = BrickColor.new("Bright yellow").Color -- ブロックと同じ色
		part.Material = Enum.Material.Plastic
		part.Anchored = true
		part.Position = Vector3.new(0, 0, 0)
		part.Parent = viewport

		-- カメラ設定（斜め前から見る）
		local camera = Instance.new("Camera")
		camera.CFrame = CFrame.new(Vector3.new(5, 5, 5), part.Position)
		viewport.CurrentCamera = camera
		camera.Parent = viewport
	end

	return btn
end

-- ブロック選択ボタン（3Dアイコン）
local btnBlock = create3DButton("ButtonBlock", "Block", drawerFrame)
btnBlock.Parent = editFrame -- コントローラー参照用（従来通りEditFrame直下に配置）
btnBlock.Position = UDim2.new(0, 20, 0.3, 0)

local btnSphere = create3DButton("ButtonSphere", "Sphere", drawerFrame)
btnSphere.Parent = editFrame
btnSphere.Position = UDim2.new(0, 20, 0.3, 90)

local btnWedge = create3DButton("ButtonWedge", "Wedge", drawerFrame)
btnWedge.Parent = editFrame
btnWedge.Position = UDim2.new(0, 20, 0.3, 180)

-- 2. 操作パネル（下部）
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(0.3, 0, 0.1, 0)
controlPanel.Position = UDim2.new(0.35, 0, 0.88, 0)
controlPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
controlPanel.BorderSizePixel = 0
controlPanel.Parent = editFrame
-- 角丸
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = controlPanel

-- 回転ボタンのレイアウト
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = controlPanel

-- 回転ボタン作成関数（こちらはテキストのまま）
local function createTextButton(name, text, parent, color)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 60, 0, 60)
	btn.BackgroundColor3 = color or Color3.fromRGB(80, 80, 80)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	return btn
end

local btnRotX = createTextButton("ButtonRotateX", "Rot X", controlPanel, Color3.fromRGB(200, 50, 50))
local btnRotY = createTextButton("ButtonRotateY", "Rot Y", controlPanel, Color3.fromRGB(50, 200, 50))
local btnRotZ = createTextButton("ButtonRotateZ", "Rot Z", controlPanel, Color3.fromRGB(50, 50, 200))

print("UI Setup Completed with 3D Icons")
