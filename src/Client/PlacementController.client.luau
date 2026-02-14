-- src/Client/PlacementController.client.luau
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local PlaceBlockEvent = require(Events:WaitForChild("PlaceBlockEvent"))
local UpdateBlockEvent = require(Events:WaitForChild("UpdateBlockEvent"))
local Palette = require(Shared:WaitForChild("Palette"))

local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui", 10)
if not screenGui then
	return
end

local editFrame = screenGui:WaitForChild("EditFrame")
local drawerMenu = editFrame:WaitForChild("DrawerMenu")
local buttonBlock = drawerMenu:WaitForChild("ButtonBlock")
local buttonSphere = drawerMenu:WaitForChild("ButtonSphere")
local buttonWedge = drawerMenu:WaitForChild("ButtonWedge")
local buttonFan = drawerMenu:WaitForChild("ButtonFan")

local controlPanel = editFrame:WaitForChild("ControlPanel")
local buttonRotateX = controlPanel:WaitForChild("ButtonRotateX")
local buttonRotateY = controlPanel:WaitForChild("ButtonRotateY")
local buttonRotateZ = controlPanel:WaitForChild("ButtonRotateZ")
local buttonUp = controlPanel:WaitForChild("ButtonUp")
local buttonDown = controlPanel:WaitForChild("ButtonDown")
local buttonDelete = controlPanel:WaitForChild("ButtonDelete")

-- 設定
local GRID_SIZE = 4
local MOVE_STEP = 4

-- 状態
local isDraggingNewBlock = false
local draggingBlockType = nil
local ghostPart = nil

local selectedBlock = nil
local selectionBox = Instance.new("SelectionBox")
selectionBox.Color3 = Palette.System.Selection
selectionBox.LineThickness = 0.05
selectionBox.Parent = playerGui

local isDraggingExisting = false
local dragTargetBlock = nil
local dragStartPos = nil

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = { player.Character }

-- Helper Functions
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
	elseif blockType == "Fan" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(2, 6, 6)
		part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(90), 0)

		local decal = Instance.new("Decal")
		decal.Texture = "rbxassetid://6005741632"
		decal.Face = Enum.NormalId.Right
		decal.Parent = part
	end

	if part then
		if blockType ~= "Fan" then
			part.Size = Vector3.new(4, 4, 4)
		end

		-- ★修正: 透明度を下げて視認性を上げる (0.5 -> 0.25)
		part.Transparency = 0.25

		part.CanCollide = false
		part.CastShadow = false
		part.Material = Enum.Material.ForceField

		if blockType == "Fan" then
			part.Color = Palette.Entity.FanHousing
		else
			part.Color = Palette.BlockColors[blockType] or Palette.System.Ghost
		end

		part.Anchored = true
		part.Parent = workspace
		local currentFilter = raycastParams.FilterDescendantsInstances
		table.insert(currentFilter, part)
		raycastParams.FilterDescendantsInstances = currentFilter
	end
	return part
end

local function getSnappedPosition(position, yOverride)
	local snappedX = math.floor(position.X / GRID_SIZE + 0.5) * GRID_SIZE
	local snappedZ = math.floor(position.Z / GRID_SIZE + 0.5) * GRID_SIZE
	local snappedY = yOverride or 2
	return Vector3.new(snappedX, snappedY, snappedZ)
end

-- 1. 新規ブロックのドラッグ
local function setupDragButton(button, blockType)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDraggingNewBlock = true
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
setupDragButton(buttonFan, "Fan")

-- 2. メインループ
RunService.RenderStepped:Connect(function()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	if isDraggingNewBlock and ghostPart then
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
		if result then
			ghostPart.Position = getSnappedPosition(result.Position)
			-- ドラッグ中は常にこの透明度 (0.25)
			ghostPart.Transparency = 0.25
		else
			ghostPart.Transparency = 1
		end
	elseif isDraggingExisting and dragTargetBlock then
		local dragFilter = { player.Character, dragTargetBlock }
		local dragParams = RaycastParams.new()
		dragParams.FilterType = Enum.RaycastFilterType.Exclude
		dragParams.FilterDescendantsInstances = dragFilter

		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, dragParams)

		if result then
			local currentY = dragTargetBlock.Position.Y
			local newPos = getSnappedPosition(result.Position, currentY)
			dragTargetBlock.Position = newPos
		end
	end
end)

-- 3. 入力処理
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local target = mouse.Target

		if
			target
			and (target.Name:match("^PlacedBlock_") or target:IsDescendantOf(workspace:FindFirstChild("PlacedBlocks")))
		then
			local model = target:FindFirstAncestorOfClass("Model")
			if model and model.Name == "FanModel" then
				target = model.PrimaryPart or target
			end

			isDraggingExisting = true
			dragTargetBlock = target
			dragStartPos = target.Position
			selectedBlock = target
			selectionBox.Adornee = target
			mouse.TargetFilter = target
		else
			selectedBlock = nil
			selectionBox.Adornee = nil
		end
	end

	if input.KeyCode == Enum.KeyCode.R then
		requestUpdate("rotate", Vector3.new(0, 90, 0))
	elseif input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Backspace then
		requestUpdate("delete", nil)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isDraggingNewBlock then
			if not gameProcessed and ghostPart and ghostPart.Transparency < 1 then
				local rot = ghostPart.Orientation
				PlaceBlockEvent:FireServer(draggingBlockType, ghostPart.Position, rot)
			end
			if ghostPart then
				ghostPart:Destroy()
				ghostPart = nil
			end
			raycastParams.FilterDescendantsInstances = { player.Character }
			isDraggingNewBlock = false
		end

		if isDraggingExisting and dragTargetBlock then
			UpdateBlockEvent:FireServer(dragTargetBlock, "moveTo", dragTargetBlock.Position)
			mouse.TargetFilter = nil
			isDraggingExisting = false
		end
	end
end)

UpdateBlockEvent.OnClientEvent:Connect(function(block)
	if block then
		selectedBlock = block
		selectionBox.Adornee = block
	end
end)

function requestUpdate(action, value)
	if selectedBlock and selectedBlock.Parent then
		UpdateBlockEvent:FireServer(selectedBlock, action, value)
		if action == "delete" then
			selectedBlock = nil
			selectionBox.Adornee = nil
		end
	end
end

buttonRotateX.MouseButton1Click:Connect(function()
	requestUpdate("rotate", Vector3.new(45, 0, 0))
end)
buttonRotateY.MouseButton1Click:Connect(function()
	requestUpdate("rotate", Vector3.new(0, 45, 0))
end)
buttonRotateZ.MouseButton1Click:Connect(function()
	requestUpdate("rotate", Vector3.new(0, 0, 45))
end)
buttonUp.MouseButton1Click:Connect(function()
	requestUpdate("move", Vector3.new(0, MOVE_STEP, 0))
end)
buttonDown.MouseButton1Click:Connect(function()
	requestUpdate("move", Vector3.new(0, -MOVE_STEP, 0))
end)
buttonDelete.MouseButton1Click:Connect(function()
	requestUpdate("delete", nil)
end)

print("Placement Controller: Ghost Transparency Lowered to 0.25")
