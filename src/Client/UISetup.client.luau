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

local function createButton(name, text, parent, color)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 80, 0, 80)
	btn.BackgroundColor3 = color or Color3.fromRGB(80, 80, 80)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.Parent = parent
	return btn
end

-- ブロック選択ボタン
local btnBlock = createButton("ButtonBlock", "Block", drawerFrame)
btnBlock.Parent = editFrame -- コントローラー参照用
btnBlock.Position = UDim2.new(0, 20, 0.3, 0)

local btnSphere = createButton("ButtonSphere", "Sphere", drawerFrame)
btnSphere.Parent = editFrame
btnSphere.Position = UDim2.new(0, 20, 0.3, 90)

local btnWedge = createButton("ButtonWedge", "Wedge", drawerFrame)
btnWedge.Parent = editFrame
btnWedge.Position = UDim2.new(0, 20, 0.3, 180)

-- 2. 操作パネル（下部）
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(0.3, 0, 0.1, 0) -- 少し横長に
controlPanel.Position = UDim2.new(0.35, 0, 0.88, 0)
controlPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
controlPanel.BorderSizePixel = 0
controlPanel.Parent = editFrame

-- 回転ボタンのレイアウト（UIListLayoutで並べる）
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = controlPanel

-- 回転ボタン作成（RGBカラーで区別）
local btnRotX = createButton("ButtonRotateX", "Rot X", controlPanel, Color3.fromRGB(200, 50, 50))
btnRotX.Size = UDim2.new(0, 60, 0, 60)
btnRotX.Parent = editFrame
-- ControlPanelの中に配置し直す（ParentをeditFrameにするとレイアウト崩れるため、ダミー枠を使うか、コントローラー側でパスを探させるのが正攻法だが、ここでは既存の参照方法に合わせてParentを戻すハックを使わず、コントローラー側でパス指定を変える方針にします。
-- ※ただし既存コードへの影響を最小限にするため、今回は「editFrameの直下に置く」という前回のルールを変更し、「ControlPanelの中に置く」形にします。
-- PlacementController側でパスを `editFrame.ControlPanel.ButtonRotateX` のように修正します。

btnRotX.Parent = controlPanel

local btnRotY = createButton("ButtonRotateY", "Rot Y", controlPanel, Color3.fromRGB(50, 200, 50))
btnRotY.Size = UDim2.new(0, 60, 0, 60)
btnRotY.Parent = controlPanel

local btnRotZ = createButton("ButtonRotateZ", "Rot Z", controlPanel, Color3.fromRGB(50, 50, 200))
btnRotZ.Size = UDim2.new(0, 60, 0, 60)
btnRotZ.Parent = controlPanel

print("UI Setup Completed with XYZ Rotation")
