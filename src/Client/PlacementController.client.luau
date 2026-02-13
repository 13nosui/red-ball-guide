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

local controlPanel = editFrame:WaitForChild("ControlPanel")
local buttonRotateX = controlPanel:WaitForChild("ButtonRotateX")
local buttonRotateY = controlPanel:WaitForChild("ButtonRotateY")
local buttonRotateZ = controlPanel:WaitForChild("ButtonRotateZ")
local buttonUp = controlPanel:WaitForChild("ButtonUp")
local buttonDown = controlPanel:WaitForChild("ButtonDown")

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

-- ★ドラッグ＆ドロップ用の状態
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
	end
	if part then
		part.Size = Vector3.new(4, 4, 4)
		part.Transparency = 0.5
		part.CanCollide = false
		part.CastShadow = false
		part.Material = Enum.Material.ForceField
		part.Color = Palette.BlockColors[blockType] or Palette.System.Ghost
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
	-- Y座標は指定がなければ標準の高さ(2)、指定があればその高さを使用
	local snappedY = yOverride or 2
	return Vector3.new(snappedX, snappedY, snappedZ)
end

-- 1. 新規ブロックのドラッグ開始 (パレット)
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

-- 2. メインループ: ドラッグ中の表示更新
RunService.RenderStepped:Connect(function()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	-- 新規ブロック配置モード
	if isDraggingNewBlock and ghostPart then
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
		if result then
			ghostPart.Position = getSnappedPosition(result.Position)
			ghostPart.Transparency = 0.5
		else
			ghostPart.Transparency = 1
		end

	-- 既存ブロック移動モード
	elseif isDraggingExisting and dragTargetBlock then
		-- ブロック自体をFilterに追加して自分自身にRayが当たらないようにする
		local originalFilter = raycastParams.FilterDescendantsInstances
		local dragFilter = { player.Character, dragTargetBlock } -- キャラと自分を除外
		if workspace:FindFirstChild("PlacedBlocks") then
			-- 他のブロックの上にも乗れるようにしたい場合はPlacedBlocksを除外しない
			-- ここでは地面(Baseplate/GeneratedFloor)基準で動かすため、他のブロックは無視しない
		end

		local dragParams = RaycastParams.new()
		dragParams.FilterType = Enum.RaycastFilterType.Exclude
		dragParams.FilterDescendantsInstances = dragFilter

		-- マウスの指す先にRayを飛ばす（地面との交点を探す）
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, dragParams)

		if result then
			-- 高さ(Y)は維持したまま、X/Z平面を移動させる
			local currentY = dragTargetBlock.Position.Y
			local newPos = getSnappedPosition(result.Position, currentY)

			-- クライアント側で即時反映（サーバーへの送信はマウス離したとき）
			dragTargetBlock.Position = newPos
		end
	end
end)

-- 3. 入力処理
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end -- UIクリック時は無視

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local target = mouse.Target

		-- 既存ブロックをクリックした場合 -> 移動モード開始
		if target and target.Name:match("^PlacedBlock_") then
			isDraggingExisting = true
			dragTargetBlock = target
			dragStartPos = target.Position

			-- 選択状態にする
			selectedBlock = target
			selectionBox.Adornee = target

			-- Mouseのターゲットフィルタに自分を追加（ドラッグ中に自分にRayが当たらないように）
			mouse.TargetFilter = target
		else
			-- 何もないところをクリック -> 選択解除
			selectedBlock = nil
			selectionBox.Adornee = nil
		end
	end

	if input.KeyCode == Enum.KeyCode.R then
		requestUpdate("rotate", Vector3.new(0, 90, 0))
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- A. 新規ブロック配置終了
		if isDraggingNewBlock then
			if not gameProcessed and ghostPart and ghostPart.Transparency < 1 then
				PlaceBlockEvent:FireServer(draggingBlockType, ghostPart.Position, Vector3.new(0, 0, 0))
			end
			if ghostPart then
				ghostPart:Destroy()
				ghostPart = nil
			end
			raycastParams.FilterDescendantsInstances = { player.Character }
			isDraggingNewBlock = false
		end

		-- B. 既存ブロック移動終了
		if isDraggingExisting and dragTargetBlock then
			-- サーバーに最終位置を送信
			UpdateBlockEvent:FireServer(dragTargetBlock, "moveTo", dragTargetBlock.Position)

			-- 後始末
			mouse.TargetFilter = nil
			isDraggingExisting = false
			-- dragTargetBlock = nil -- 選択状態は維持したいのでnilにしない
		end
	end
end)

-- Selection & Update helper
UpdateBlockEvent.OnClientEvent:Connect(function(block)
	if block then
		selectedBlock = block
		selectionBox.Adornee = block
	end
end)

function requestUpdate(action, value)
	if selectedBlock and selectedBlock.Parent then
		UpdateBlockEvent:FireServer(selectedBlock, action, value)
	end
end

-- Rotation Buttons
buttonRotateX.MouseButton1Click:Connect(function()
	requestUpdate("rotate", Vector3.new(90, 0, 0))
end)
buttonRotateY.MouseButton1Click:Connect(function()
	requestUpdate("rotate", Vector3.new(0, 45, 0))
end)
buttonRotateZ.MouseButton1Click:Connect(function()
	requestUpdate("rotate", Vector3.new(0, 0, 90))
end)

-- Height Buttons
buttonUp.MouseButton1Click:Connect(function()
	requestUpdate("move", Vector3.new(0, MOVE_STEP, 0))
end)
buttonDown.MouseButton1Click:Connect(function()
	requestUpdate("move", Vector3.new(0, -MOVE_STEP, 0))
end)

print("Placement Controller: Drag & Drop Implemented")
