-- src/Client/PlacementController.client.luau
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse() -- ★ここを追加しました

-- イベントの取得
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local PlaceBlockEvent = require(Events:WaitForChild("PlaceBlockEvent"))
local UpdateBlockEvent = require(Events:WaitForChild("UpdateBlockEvent"))

-- UIの取得
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui", 10)
if not screenGui then
	return
end

local editFrame = screenGui:WaitForChild("EditFrame")

-- ドロワーメニュー内のボタンを取得
local drawerMenu = editFrame:WaitForChild("DrawerMenu")
local buttonBlock = drawerMenu:WaitForChild("ButtonBlock")
local buttonSphere = drawerMenu:WaitForChild("ButtonSphere")
local buttonWedge = drawerMenu:WaitForChild("ButtonWedge")

-- コントロールパネル内のボタンを取得
local controlPanel = editFrame:WaitForChild("ControlPanel")
local buttonRotateX = controlPanel:WaitForChild("ButtonRotateX")
local buttonRotateY = controlPanel:WaitForChild("ButtonRotateY")
local buttonRotateZ = controlPanel:WaitForChild("ButtonRotateZ")

-- 設定
local GRID_SIZE = 4

-- 状態管理
local isDragging = false
local draggingBlockType = nil
local ghostPart = nil

local selectedBlock = nil
local selectionBox = Instance.new("SelectionBox")
selectionBox.Color3 = Color3.fromRGB(255, 170, 0)
selectionBox.LineThickness = 0.05
selectionBox.Parent = playerGui

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = { player.Character }

-- ■ ヘルパー関数: ゴースト生成
local function createGhost(blockType)
	if ghostPart then
		ghostPart:Destroy()
	end

	local part
	if blockType == "Block" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Block
	elseif blockType == "Sphere" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
	elseif blockType == "Wedge" then
		part = Instance.new("WedgePart")
	elseif blockType == "CornerWedge" then
		part = Instance.new("CornerWedgePart")
	elseif blockType == "Cylinder" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(90))
	end

	if part then
		part.Size = Vector3.new(4, 4, 4)
		part.Transparency = 0.5
		part.CanCollide = false
		part.CastShadow = false
		part.Material = Enum.Material.ForceField
		part.Color = Color3.fromRGB(0, 255, 0)
		part.Anchored = true
		part.Parent = workspace

		local currentFilter = raycastParams.FilterDescendantsInstances
		table.insert(currentFilter, part)
		raycastParams.FilterDescendantsInstances = currentFilter
	end

	return part
end

local function getSnappedPosition(position)
	local snappedX = math.floor(position.X / GRID_SIZE + 0.5) * GRID_SIZE
	local snappedZ = math.floor(position.Z / GRID_SIZE + 0.5) * GRID_SIZE
	local snappedY = position.Y + 2
	return Vector3.new(snappedX, snappedY, snappedZ)
end

-- ■ ドラッグ処理
local function setupDragButton(button, blockType)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			draggingBlockType = blockType
			ghostPart = createGhost(blockType)
			selectedBlock = nil
			selectionBox.Adornee = nil
		end
	end)
end

setupDragButton(buttonBlock, "Block")
setupDragButton(buttonSphere, "Sphere")
setupDragButton(buttonWedge, "Wedge")

RunService.RenderStepped:Connect(function()
	if isDragging and ghostPart then
		local mouseLocation = UserInputService:GetMouseLocation()
		local ray = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

		if result then
			ghostPart.Position = getSnappedPosition(result.Position)
			ghostPart.Transparency = 0.5
		else
			ghostPart.Transparency = 1
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isDragging then
			if not gameProcessed and ghostPart and ghostPart.Transparency < 1 then
				PlaceBlockEvent:FireServer(draggingBlockType, ghostPart.Position, Vector3.new(0, 0, 0))
			end
			if ghostPart then
				ghostPart:Destroy()
				ghostPart = nil
			end
			raycastParams.FilterDescendantsInstances = { player.Character }
			isDragging = false
		end
	end
end)

-- ■ 選択機能
UpdateBlockEvent.OnClientEvent:Connect(function(block)
	if block then
		selectedBlock = block
		selectionBox.Adornee = block
	end
end)

-- ■ 回転処理
local function rotateSelectedBlock(degreesVector)
	if selectedBlock and selectedBlock.Parent then
		UpdateBlockEvent:FireServer(selectedBlock, "rotate", degreesVector)
	end
end

buttonRotateX.MouseButton1Click:Connect(function()
	rotateSelectedBlock(Vector3.new(90, 0, 0))
end)
buttonRotateY.MouseButton1Click:Connect(function()
	rotateSelectedBlock(Vector3.new(0, 90, 0))
end)
buttonRotateZ.MouseButton1Click:Connect(function()
	rotateSelectedBlock(Vector3.new(0, 0, 90))
end)

-- ■ 入力処理
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		rotateSelectedBlock(Vector3.new(0, 90, 0))
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local target = mouse.Target
		local clickedBlock = false
		-- PlacedBlock_で始まる名前のパーツかどうか判定
		if target and target.Name:match("^PlacedBlock_") then
			clickedBlock = true
		end

		if not clickedBlock then
			selectedBlock = nil
			selectionBox.Adornee = nil
		end
	end
end)

print("Placement Controller Fixed (Mouse Added)")
