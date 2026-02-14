-- src/Client/UISetup.client.luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local GameControlEvent = require(Events:WaitForChild("GameControlEvent"))
local UpdateStageEvent = require(Events:WaitForChild("UpdateStageEvent"))
local StageClearEvent = Events:WaitForChild("StageClearEvent")

local Palette = require(Shared:WaitForChild("Palette"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScreenGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local resultFrame = Instance.new("Frame")
resultFrame.Name = "ResultFrame"
resultFrame.Size = UDim2.new(1, 0, 1, 0)
resultFrame.BackgroundTransparency = 1
resultFrame.Visible = false
resultFrame.ZIndex = 100
resultFrame.Parent = screenGui

local confettiContainer = Instance.new("Frame")
confettiContainer.Name = "ConfettiContainer"
confettiContainer.Size = UDim2.new(1, 0, 1, 0)
confettiContainer.BackgroundTransparency = 1
confettiContainer.Parent = resultFrame

local clearLabel = Instance.new("TextLabel")
clearLabel.Name = "Title"
clearLabel.Text = "STAGE CLEAR!"
clearLabel.Size = UDim2.new(1, 0, 0.2, 0)
clearLabel.Position = UDim2.new(0, 0, 0.3, 0)
clearLabel.BackgroundTransparency = 1
clearLabel.TextColor3 = Color3.new(1, 1, 1)
clearLabel.TextStrokeTransparency = 0
clearLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
clearLabel.Font = Enum.Font.FredokaOne
clearLabel.TextSize = 60
clearLabel.TextTransparency = 1
clearLabel.Parent = resultFrame

local editFrame = Instance.new("Frame")
editFrame.Name = "EditFrame"
editFrame.Size = UDim2.new(1, 0, 1, 0)
editFrame.BackgroundTransparency = 1
editFrame.Parent = screenGui

-- ポップスタイル (不透明・太い縁取り)
local function applyPopStyle(guiObject, cornerRadius, isContainer)
	guiObject.BorderSizePixel = 0

	local corner = guiObject:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius or 16)
	corner.Parent = guiObject

	local stroke = guiObject:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = guiObject

	if isContainer then
		guiObject.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		guiObject.BackgroundTransparency = 0.4
		stroke.Thickness = 0
		stroke.Transparency = 1
	else
		-- ボタン用
		guiObject.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		guiObject.BackgroundTransparency = 0

		stroke.Color = Color3.fromRGB(40, 40, 60)
		stroke.Thickness = 3
		stroke.Transparency = 0

		if guiObject:IsA("GuiButton") then
			local originalColor = guiObject.BackgroundColor3
			guiObject.MouseEnter:Connect(function()
				TweenService:Create(guiObject, TweenInfo.new(0.2), { Size = guiObject.Size + UDim2.new(0, 4, 0, 4) })
					:Play()
			end)
			guiObject.MouseLeave:Connect(function()
				TweenService:Create(guiObject, TweenInfo.new(0.2), { Size = guiObject.Size - UDim2.new(0, 0, 0, 0) })
					:Play()
				TweenService:Create(guiObject, TweenInfo.new(0.2), { BackgroundColor3 = originalColor }):Play()
			end)
		end
	end
end

-- ★修正: Next Stage ボタン
local btnNext = Instance.new("TextButton")
btnNext.Name = "ButtonNext"
btnNext.Size = UDim2.new(0, 200, 0, 60)
btnNext.Position = UDim2.new(0.5, 0, 0.6, 0)
btnNext.AnchorPoint = Vector2.new(0.5, 0.5)
btnNext.Text = "Next Stage"
-- 文字色を濃い色にして視認性を確保
btnNext.TextColor3 = Color3.fromRGB(40, 40, 60)
btnNext.Font = Enum.Font.FredokaOne
btnNext.TextSize = 24
btnNext.TextTransparency = 1
btnNext.Parent = resultFrame
applyPopStyle(btnNext, 30)
-- 背景色を白に固定 (緑ではなく白ベースのポップスタイルに統一)
btnNext.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
btnNext.BackgroundTransparency = 1 -- 初期は透明

local drawerFrame = Instance.new("Frame")
drawerFrame.Name = "DrawerMenu"
drawerFrame.Size = UDim2.new(0, 100, 0.7, 0)
drawerFrame.Position = UDim2.new(0, 20, 0.15, 0)
drawerFrame.Parent = editFrame
applyPopStyle(drawerFrame, 20, true)

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
	applyPopStyle(btn, 20)

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(0.8, 0, 0.8, 0)
	viewport.Position = UDim2.new(0.1, 0, 0.1, 0)
	viewport.BackgroundTransparency = 1
	viewport.Parent = btn
	local part
	local camera = Instance.new("Camera")
	if blockType == "Block" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Block
	elseif blockType == "Sphere" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
	elseif blockType == "Wedge" then
		part = Instance.new("WedgePart")
	elseif blockType == "Fan" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.CFrame = CFrame.Angles(0, math.rad(90), 0)
	elseif blockType == "Spring" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.5, 4, 4)
		part.CFrame = CFrame.Angles(0, 0, math.rad(90))
	elseif blockType == "Conveyor" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Block
		part.Size = Vector3.new(4, 0.5, 4)
	end
	if part then
		part.Size = Vector3.new(4, 4, 4)
		if blockType == "Fan" then
			part.Color = Palette.Entity.FanHousing or Color3.new(0.5, 0.5, 0.5)
			part.Size = Vector3.new(2, 6, 6)
		elseif blockType == "Spring" then
			part.Color = Color3.fromRGB(255, 100, 100)
			part.Size = Vector3.new(1, 4, 4)
		elseif blockType == "Conveyor" then
			part.Color = Color3.fromRGB(255, 255, 100)
			part.Size = Vector3.new(4, 1, 4)
		else
			part.Color = Palette.BlockColors[blockType] or Color3.new(1, 1, 1)
		end
		part.Material = Enum.Material.Plastic
		part.Reflectance = 0.1
		part.Anchored = true
		part.Position = Vector3.new(0, 0, 0)
		part.Parent = viewport
		camera.CFrame = CFrame.new(Vector3.new(6, 5, 6), part.Position)
		viewport.CurrentCamera = camera
		camera.Parent = viewport
		task.spawn(function()
			local t = 0
			while part.Parent do
				t = t + 0.01
				part.CFrame = part.CFrame * CFrame.Angles(0, 0.03, 0)
				task.wait(0.03)
			end
		end)
	end
	return btn
end

local btnBlock = create3DButton("ButtonBlock", "Block", drawerFrame)
local btnSphere = create3DButton("ButtonSphere", "Sphere", drawerFrame)
local btnWedge = create3DButton("ButtonWedge", "Wedge", drawerFrame)
local btnFan = create3DButton("ButtonFan", "Fan", drawerFrame)
local btnSpring = create3DButton("ButtonSpring", "Spring", drawerFrame)
local btnConveyor = create3DButton("ButtonConveyor", "Conveyor", drawerFrame)

local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.AutomaticSize = Enum.AutomaticSize.X
controlPanel.Size = UDim2.new(0, 0, 0, 80)
controlPanel.AnchorPoint = Vector2.new(0.5, 1)
controlPanel.Position = UDim2.new(0.5, 0, 0.95, 0)
controlPanel.Parent = editFrame
applyPopStyle(controlPanel, 40, true)

local controlPadding = Instance.new("UIPadding")
controlPadding.PaddingTop = UDim.new(0, 15)
controlPadding.PaddingBottom = UDim.new(0, 15)
controlPadding.PaddingLeft = UDim.new(0, 15)
controlPadding.PaddingRight = UDim.new(0, 15)
controlPadding.Parent = controlPanel

local panelLayout = Instance.new("UIListLayout")
panelLayout.FillDirection = Enum.FillDirection.Horizontal
panelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
panelLayout.VerticalAlignment = Enum.VerticalAlignment.Center
panelLayout.Padding = UDim.new(0, 10)
panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
panelLayout.Parent = controlPanel

local function createTextButton(name, text, parent, color, size, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.Name = name
	local defaultSize = UDim2.new(0, 50, 0, 50)
	btn.Size = size or defaultSize
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.FredokaOne
	btn.TextSize = 16
	btn.LayoutOrder = layoutOrder or 0
	btn.Parent = parent
	applyPopStyle(btn, 25)
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0
	return btn
end

local moveColor = Palette.System.Move
local btnDown = createTextButton("ButtonDown", "Down", controlPanel, moveColor, UDim2.new(0, 50, 0, 50), 1)
local btnUp = createTextButton("ButtonUp", "Up", controlPanel, moveColor, UDim2.new(0, 50, 0, 50), 2)
local btnRotX =
	createTextButton("ButtonRotateX", "X", controlPanel, Color3.fromRGB(255, 80, 80), UDim2.new(0, 50, 0, 50), 3)
local btnRotY =
	createTextButton("ButtonRotateY", "Y", controlPanel, Color3.fromRGB(80, 255, 80), UDim2.new(0, 50, 0, 50), 4)
local btnRotZ =
	createTextButton("ButtonRotateZ", "Z", controlPanel, Color3.fromRGB(80, 80, 255), UDim2.new(0, 50, 0, 50), 5)
local btnDelete =
	createTextButton("ButtonDelete", "Del", controlPanel, Palette.System.Error, UDim2.new(0, 50, 0, 50), 6)

local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.new(0, 180, 0, 50)
headerFrame.Position = UDim2.new(0.5, 0, 0.08, 0)
headerFrame.AnchorPoint = Vector2.new(0.5, 0)
headerFrame.Parent = editFrame
applyPopStyle(headerFrame, 25, true)

local stageLabel = Instance.new("TextLabel")
stageLabel.Name = "StageLabel"
stageLabel.Size = UDim2.new(1, 0, 1, 0)
stageLabel.BackgroundTransparency = 1
stageLabel.Text = "STAGE: 01"
stageLabel.TextColor3 = Color3.new(1, 1, 1)
stageLabel.Font = Enum.Font.FredokaOne
stageLabel.TextSize = 22
stageLabel.Parent = headerFrame

local actionPanel = Instance.new("Frame")
actionPanel.Name = "ActionPanel"
actionPanel.AutomaticSize = Enum.AutomaticSize.X
actionPanel.Size = UDim2.new(0, 0, 0, 80)
actionPanel.AnchorPoint = Vector2.new(1, 1)
actionPanel.Position = UDim2.new(0.95, 0, 0.95, 0)
actionPanel.Parent = editFrame
applyPopStyle(actionPanel, 40, true)

local actionPadding = Instance.new("UIPadding")
actionPadding.PaddingTop = UDim.new(0, 15)
actionPadding.PaddingBottom = UDim.new(0, 15)
actionPadding.PaddingLeft = UDim.new(0, 15)
actionPadding.PaddingRight = UDim.new(0, 15)
actionPadding.Parent = actionPanel

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
actionLayout.Padding = UDim.new(0, 15)
actionLayout.Parent = actionPanel

local btnStart = createTextButton("ButtonStart", "Start", actionPanel, Palette.System.Success, UDim2.new(0, 70, 0, 50))
local btnReset = createTextButton("ButtonReset", "Reset", actionPanel, Palette.System.Error, UDim2.new(0, 70, 0, 50))

local confettiActive = false
local confettiPieces = {}
local colors = {
	Color3.fromRGB(255, 80, 80),
	Color3.fromRGB(80, 255, 80),
	Color3.fromRGB(80, 80, 255),
	Color3.fromRGB(255, 255, 80),
	Color3.fromRGB(255, 80, 255),
	Color3.fromRGB(80, 255, 255),
}

local function spawnConfetti()
	for i = 1, 60 do
		local piece = Instance.new("Frame")
		piece.Size = UDim2.new(0, math.random(10, 20), 0, math.random(5, 10))
		piece.BackgroundColor3 = colors[math.random(1, #colors)]
		piece.BorderSizePixel = 0
		piece.Position = UDim2.new(math.random(), 0, -0.1, 0)
		piece.Parent = confettiContainer
		table.insert(
			confettiPieces,
			{
				Gui = piece,
				Speed = math.random(100, 300),
				Sway = math.random(50, 150),
				SwaySpeed = math.random(2, 5),
				RotationSpeed = math.random(-180, 180),
				TimeOffset = math.random() * 10,
			}
		)
	end
	confettiActive = true
end

local function stopConfetti()
	confettiActive = false
	for _, data in ipairs(confettiPieces) do
		data.Gui:Destroy()
	end
	confettiPieces = {}
end

RunService.RenderStepped:Connect(function(dt)
	if not confettiActive then
		return
	end
	local screenSize = screenGui.AbsoluteSize
	for _, data in ipairs(confettiPieces) do
		local piece = data.Gui
		local time = tick() + data.TimeOffset
		local currentY = piece.Position.Y.Scale * screenSize.Y
		local newY = currentY + data.Speed * dt
		local currentX = piece.Position.X.Scale * screenSize.X
		local sway = math.sin(time * data.SwaySpeed) * data.Sway * dt
		local newX = currentX + sway
		piece.Rotation = piece.Rotation + data.RotationSpeed * dt
		if newY > screenSize.Y + 50 then
			newY = -50
			newX = math.random() * screenSize.X
		end
		piece.Position = UDim2.new(0, newX, 0, newY)
	end
end)

StageClearEvent.OnClientEvent:Connect(function(stageIndex)
	resultFrame.Visible = true
	editFrame.Visible = false
	clearLabel.Position = UDim2.new(0, 0, 0.4, 0)
	clearLabel.TextTransparency = 1
	local t1 = TweenService:Create(
		clearLabel,
		TweenInfo.new(0.8, Enum.EasingStyle.Bounce),
		{ Position = UDim2.new(0, 0, 0.3, 0), TextTransparency = 0 }
	)
	t1:Play()
	btnNext.BackgroundTransparency = 1
	btnNext.TextTransparency = 1
	task.wait(0.5)
	-- ★修正: 出現時は完全に不透明(0)にする
	local t2 = TweenService:Create(btnNext, TweenInfo.new(0.5), { BackgroundTransparency = 0, TextTransparency = 0 })
	t2:Play()
	spawnConfetti()
end)

btnNext.MouseButton1Click:Connect(function()
	GameControlEvent:FireServer("next")
end)

UpdateStageEvent.OnClientEvent:Connect(function(index, data)
	stopConfetti()
	resultFrame.Visible = false
	editFrame.Visible = true
	stageLabel.Text = "STAGE: " .. string.format("%02d", index)
end)

print("UI Setup: Button Visibility Fixed")
