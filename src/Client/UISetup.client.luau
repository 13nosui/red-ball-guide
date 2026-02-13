-- src/Client/UISetup.client.luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared:WaitForChild("Palette"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScreenGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local editFrame = Instance.new("Frame")
editFrame.Name = "EditFrame"
editFrame.Size = UDim2.new(1, 0, 1, 0)
editFrame.BackgroundTransparency = 1
editFrame.Parent = screenGui

-- ■ スタイリング関数
local function applyGlassStyle(guiObject, cornerRadius)
	guiObject.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	guiObject.BackgroundTransparency = 0.65
	guiObject.BorderSizePixel = 0

	local corner = guiObject:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius or 16)
	corner.Parent = guiObject

	local stroke = guiObject:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.4
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = guiObject

	local originalTransparency = guiObject.BackgroundTransparency

	if guiObject:IsA("GuiButton") then
		guiObject.MouseEnter:Connect(function()
			TweenService:Create(guiObject, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
				BackgroundTransparency = 0.4,
				BackgroundColor3 = Color3.fromRGB(240, 240, 255),
			}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 0.1 }):Play()
		end)

		guiObject.MouseLeave:Connect(function()
			TweenService:Create(guiObject, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
				BackgroundTransparency = originalTransparency,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 0.4 }):Play()
		end)
	end
end

-- 1. ドロワーメニュー
local drawerFrame = Instance.new("Frame")
drawerFrame.Name = "DrawerMenu"
drawerFrame.Size = UDim2.new(0, 100, 0.6, 0)
drawerFrame.Position = UDim2.new(0, 20, 0.2, 0)
drawerFrame.BackgroundTransparency = 1
drawerFrame.Parent = editFrame

local drawerLayout = Instance.new("UIListLayout")
drawerLayout.Padding = UDim.new(0, 20)
drawerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
drawerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
drawerLayout.Parent = drawerFrame

local function create3DButton(name, blockType, parent)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 70, 0, 70)
	btn.Parent = parent
	applyGlassStyle(btn, 20)

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(0.8, 0, 0.8, 0)
	viewport.Position = UDim2.new(0.1, 0, 0.1, 0)
	viewport.BackgroundTransparency = 1
	viewport.Parent = btn

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
		part.Color = Palette.BlockColors[blockType] or Color3.new(1, 1, 1)
		part.Material = Enum.Material.Plastic
		part.Reflectance = 0.1
		part.Anchored = true
		part.Position = Vector3.new(0, 0, 0)
		part.Parent = viewport

		local camera = Instance.new("Camera")
		camera.CFrame = CFrame.new(Vector3.new(6, 5, 6), part.Position)
		viewport.CurrentCamera = camera
		camera.Parent = viewport

		task.spawn(function()
			local t = 0
			while part.Parent do
				t = t + 0.01
				part.CFrame = CFrame.Angles(0, t, 0)
				task.wait(0.03)
			end
		end)
	end
	return btn
end

local btnBlock = create3DButton("ButtonBlock", "Block", drawerFrame)
local btnSphere = create3DButton("ButtonSphere", "Sphere", drawerFrame)
local btnWedge = create3DButton("ButtonWedge", "Wedge", drawerFrame)

-- 2. 操作パネル（移動＆回転）
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(0, 620, 0, 80)
controlPanel.AnchorPoint = Vector2.new(0.5, 1)
controlPanel.Position = UDim2.new(0.5, 0, 0.95, 0)
controlPanel.Parent = editFrame

applyGlassStyle(controlPanel, 40)

local panelLayout = Instance.new("UIListLayout")
panelLayout.FillDirection = Enum.FillDirection.Horizontal
panelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
panelLayout.VerticalAlignment = Enum.VerticalAlignment.Center
panelLayout.Padding = UDim.new(0, 10)
panelLayout.SortOrder = Enum.SortOrder.LayoutOrder -- ★順序指定モードにする
panelLayout.Parent = controlPanel

-- Helper: テキストボタン (LayoutOrder引数を追加)
local function createTextButton(name, text, parent, color, size, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = size or UDim2.new(0, 50, 0, 50)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 16
	btn.LayoutOrder = layoutOrder or 0 -- ★表示順序を設定
	btn.Parent = parent
	applyGlassStyle(btn, 25)
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0.5
	return btn
end

-- ■ ボタン配置（LayoutOrderを指定して順序を保証）
local moveColor = Palette.System.Move

-- 1. ↓ (Backward / 手前)
local btnBackward = createTextButton("ButtonBackward", "↓", controlPanel, moveColor, nil, 1)
-- 2. ↑ (Forward / 奥)
local btnForward = createTextButton("ButtonForward", "↑", controlPanel, moveColor, nil, 2)
-- 3. ← (Left)
local btnLeft = createTextButton("ButtonLeft", "←", controlPanel, moveColor, nil, 3)
-- 4. → (Right)
local btnRight = createTextButton("ButtonRight", "→", controlPanel, moveColor, nil, 4)

-- 5. Down (下降)
local btnDown = createTextButton("ButtonDown", "Down", controlPanel, moveColor, nil, 5)
-- 6. Up (上昇)
local btnUp = createTextButton("ButtonUp", "Up", controlPanel, moveColor, nil, 6)

-- 7-9. 回転ボタン (Rot X, Y, Z)
local btnRotX =
	createTextButton("ButtonRotateX", "Rot X", controlPanel, Color3.fromRGB(255, 80, 80), UDim2.new(0, 60, 0, 50), 7)
local btnRotY =
	createTextButton("ButtonRotateY", "Rot Y", controlPanel, Color3.fromRGB(80, 255, 80), UDim2.new(0, 60, 0, 50), 8)
local btnRotZ =
	createTextButton("ButtonRotateZ", "Rot Z", controlPanel, Color3.fromRGB(80, 80, 255), UDim2.new(0, 60, 0, 50), 9)

-- 3. ヘッダー
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.new(0, 180, 0, 50)
headerFrame.Position = UDim2.new(0.5, 0, 0.08, 0)
headerFrame.AnchorPoint = Vector2.new(0.5, 0)
headerFrame.Parent = editFrame
applyGlassStyle(headerFrame, 25)

local stageLabel = Instance.new("TextLabel")
stageLabel.Name = "StageLabel"
stageLabel.Size = UDim2.new(1, 0, 1, 0)
stageLabel.BackgroundTransparency = 1
stageLabel.Text = "Stage: 01"
stageLabel.TextColor3 = Color3.new(1, 1, 1)
stageLabel.Font = Enum.Font.GothamBold
stageLabel.TextSize = 22
stageLabel.Parent = headerFrame

-- 4. アクションパネル
local actionPanel = Instance.new("Frame")
actionPanel.Name = "ActionPanel"
actionPanel.Size = UDim2.new(0, 180, 0, 80)
actionPanel.AnchorPoint = Vector2.new(1, 1)
actionPanel.Position = UDim2.new(0.95, 0, 0.95, 0)
actionPanel.Parent = editFrame
applyGlassStyle(actionPanel, 40)

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
actionLayout.Padding = UDim.new(0, 15)
actionLayout.Parent = actionPanel

local btnStart = createTextButton("ButtonStart", "Start", actionPanel, Palette.System.Success, UDim2.new(0, 70, 0, 50))
local btnReset = createTextButton("ButtonReset", "Reset", actionPanel, Palette.System.Error, UDim2.new(0, 70, 0, 50))

print("UI Setup: Button Order Fixed with LayoutOrder")
