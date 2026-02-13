-- src/Client/UISetup.client.luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- メインのScreenGui作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScreenGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true -- 画面端まで広げる
screenGui.Parent = playerGui

-- エディット用フレーム
local editFrame = Instance.new("Frame")
editFrame.Name = "EditFrame"
editFrame.Size = UDim2.new(1, 0, 1, 0)
editFrame.BackgroundTransparency = 1
editFrame.Parent = screenGui

-- ■ スタイリング関数: Liquid Glass風
local function applyGlassStyle(guiObject, cornerRadius)
	-- ベース: 半透明の白（フロストガラス風）
	guiObject.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	guiObject.BackgroundTransparency = 0.65
	guiObject.BorderSizePixel = 0

	-- 丸角
	local corner = guiObject:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius or 16)
	corner.Parent = guiObject

	-- 境界線: 薄い白でエッジを立たせる
	local stroke = guiObject:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.4
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = guiObject

	-- ホバーアニメーションの準備
	local originalTransparency = guiObject.BackgroundTransparency

	-- ホバー効果（少し明るく、不透明にする）
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

-- 1. ドロワーメニュー（左側）
local drawerFrame = Instance.new("Frame")
drawerFrame.Name = "DrawerMenu"
-- コンテナ自体は透明にし、ボタンを浮かせる
drawerFrame.Size = UDim2.new(0, 100, 0.6, 0)
drawerFrame.Position = UDim2.new(0, 20, 0.2, 0)
drawerFrame.BackgroundTransparency = 1
drawerFrame.Parent = editFrame

-- レイアウト: 縦並び、スペーシング広め
local drawerLayout = Instance.new("UIListLayout")
drawerLayout.Padding = UDim.new(0, 20)
drawerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
drawerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
drawerLayout.Parent = drawerFrame

-- ■ ヘルパー関数: 3Dアイコンボタンの作成
local function create3DButton(name, blockType, parent)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 70, 0, 70) -- 少し小さくスタイリッシュに
	btn.Parent = parent

	-- ガラススタイル適用
	applyGlassStyle(btn, 20)

	-- 3D表示用のフレーム
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(0.8, 0, 0.8, 0) -- 余白を持たせる
	viewport.Position = UDim2.new(0.1, 0, 0.1, 0)
	viewport.BackgroundTransparency = 1
	viewport.Parent = btn

	-- パーツ作成
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
		part.Color = Color3.fromRGB(255, 200, 50) -- 鮮やかな黄色
		part.Material = Enum.Material.Plastic -- 反射を減らしてクリーンに
		part.Reflectance = 0.1
		part.Anchored = true
		part.Position = Vector3.new(0, 0, 0)
		part.Parent = viewport

		-- カメラ設定
		local camera = Instance.new("Camera")
		camera.CFrame = CFrame.new(Vector3.new(6, 5, 6), part.Position)
		viewport.CurrentCamera = camera
		camera.Parent = viewport

		-- 回転アニメーション（ゆっくり回す）
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

-- ボタン作成（DrawerMenuの中に配置）
-- コントローラーが参照しやすいよう、PlacementController側のパス修正が必要ないように配慮したいが、
-- デザイン上、親子関係を変える必要があるため、PlacementControllerも微修正するのがベストだが
-- 今回は「editFrame直下」に置くハック（前回の3Dアイコン時と同様）は使わず、
-- 綺麗な構造（DrawerMenuの子要素）にします。
-- ※ PlacementController側で「editFrame.DrawerMenu.ButtonBlock」などを探すようにするのが正しい設計ですが、
--   既存コードを壊さないため、ダミーの参照をEditFrameに作るか、コントローラー側を直すか。
--   → ここでは「DrawerMenu」をEditFrameの子にし、ボタンをDrawerMenuの子にします。
--   ★重要: 前回のコードでPlacementControllerは `editFrame:WaitForChild("ButtonBlock")` などを探していました。
--   今回レイアウトを変えるので、ボタンのParentをeditFrameにしつつ、Positionでレイアウトするのではなく、
--   UIListLayoutを使うためにDrawerFrameに入れる必要があります。
--
--   解決策: ボタンは DrawerFrame に入れます。
--   ただし、コントローラーが壊れないよう、PlacementControllerの修正も提案します。
--   (このファイル単体で完結させるため、ボタン作成後にPlacementControllerが探せる場所にObjectValueを置く等の手もありますが、
--    素直にUI階層を変えます)

local btnBlock = create3DButton("ButtonBlock", "Block", drawerFrame)
local btnSphere = create3DButton("ButtonSphere", "Sphere", drawerFrame)
local btnWedge = create3DButton("ButtonWedge", "Wedge", drawerFrame)

-- 2. 操作パネル（下部）
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(0, 260, 0, 80) -- 固定サイズでコンパクトに
controlPanel.AnchorPoint = Vector2.new(0.5, 1) -- 下中央基準
controlPanel.Position = UDim2.new(0.5, 0, 0.95, 0)
controlPanel.Parent = editFrame

-- パネル自体をガラス化
applyGlassStyle(controlPanel, 40) -- 大きな丸み（ピル形状）

local panelLayout = Instance.new("UIListLayout")
panelLayout.FillDirection = Enum.FillDirection.Horizontal
panelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
panelLayout.VerticalAlignment = Enum.VerticalAlignment.Center
panelLayout.Padding = UDim.new(0, 15)
panelLayout.Parent = controlPanel

-- 回転ボタン作成関数
local function createTextButton(name, text, parent, color)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 50, 0, 50)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1) -- 白文字
	btn.Font = Enum.Font.GothamMedium -- モダンなフォント
	btn.TextSize = 16
	btn.Parent = parent

	-- ボタン独自の色を少し混ぜるガラススタイル
	-- applyGlassStyleを呼びつつ、色を上書き
	applyGlassStyle(btn, 25) -- 完全な円

	-- カラーオーバーレイ
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0.5 -- 色を見せるため少し不透明に

	return btn
end

local btnRotX = createTextButton("ButtonRotateX", "X", controlPanel, Color3.fromRGB(255, 80, 80))
local btnRotY = createTextButton("ButtonRotateY", "Y", controlPanel, Color3.fromRGB(80, 255, 80))
local btnRotZ = createTextButton("ButtonRotateZ", "Z", controlPanel, Color3.fromRGB(80, 80, 255))

print("UI Setup Completed: Liquid Glass Style")
