-- src/Client/UISetup.client.luau
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- メインのScreenGui作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScreenGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- エディット用フレーム（全体コンテナ）
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

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = drawerFrame

local function createButton(name, text, parent)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 80, 0, 80)
	btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Parent = parent
	return btn
end

-- PlacementControllerが参照する名前でボタンを作成
createButton("ButtonBlock", "Block", drawerFrame).Parent = editFrame -- コントローラーのパスに合わせるためEditFrame直下に配置（簡易対応）
createButton("ButtonSphere", "Sphere", drawerFrame).Parent = editFrame
createButton("ButtonWedge", "Wedge", drawerFrame).Parent = editFrame

-- レイアウト調整のため、ドロワー内にもダミーを表示（本来はScrollingFrame等で整理すべきですが、動作優先で配置）
-- PlacementControllerの参照パス（editFrame.ButtonBlock）に合わせるため、
-- 上記で作成したボタンのParentをeditFrameにしつつ、見た目上の位置を左側に固定します。
editFrame.ButtonBlock.Position = UDim2.new(0, 20, 0.3, 0)
editFrame.ButtonSphere.Position = UDim2.new(0, 20, 0.3, 90)
editFrame.ButtonWedge.Position = UDim2.new(0, 20, 0.3, 180)

-- 2. 操作パネル（下部）
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(0.4, 0, 0.15, 0)
controlPanel.Position = UDim2.new(0.3, 0, 0.85, 0)
controlPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
controlPanel.Parent = editFrame

local rotateBtn = createButton("ButtonRotate", "Rotate (R)", controlPanel)
rotateBtn.Parent = editFrame -- コントローラーの参照用
rotateBtn.Position = UDim2.new(0.5, -40, 0.85, 10) -- 画面下部中央へ

print("UI Setup Completed")
