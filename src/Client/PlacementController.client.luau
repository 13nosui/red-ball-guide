-- src/Client/PlacementController.client.luau
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

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
local buttonBlock = editFrame:WaitForChild("ButtonBlock")
local buttonSphere = editFrame:WaitForChild("ButtonSphere")
local buttonWedge = editFrame:WaitForChild("ButtonWedge")
local buttonRotate = editFrame:WaitForChild("ButtonRotate")

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

-- レイキャストパラメータ
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

		-- 自分をレイキャスト無視リストに追加
		local currentFilter = raycastParams.FilterDescendantsInstances
		table.insert(currentFilter, part)
		raycastParams.FilterDescendantsInstances = currentFilter
	end

	return part
end

-- ■ ヘルパー関数: スナップ計算
local function getSnappedPosition(position)
	local snappedX = math.floor(position.X / GRID_SIZE + 0.5) * GRID_SIZE
	local snappedZ = math.floor(position.Z / GRID_SIZE + 0.5) * GRID_SIZE
	local snappedY = position.Y + 2
	return Vector3.new(snappedX, snappedY, snappedZ)
end

-- ■ ドラッグ開始処理
local function setupDragButton(button, blockType)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			draggingBlockType = blockType

			-- ゴーストを作成するが、最初は見えない場所に置くか非表示にするのも手
			-- ここでは作成だけ行い、RenderSteppedで位置を更新する
			ghostPart = createGhost(blockType)

			-- ドラッグ開始時は選択解除
			selectedBlock = nil
			selectionBox.Adornee = nil
		end
	end)
end

setupDragButton(buttonBlock, "Block")
setupDragButton(buttonSphere, "Sphere")
setupDragButton(buttonWedge, "Wedge")

-- ■ ドラッグ中の処理
RunService.RenderStepped:Connect(function()
	if isDragging and ghostPart then
		local mouseLocation = UserInputService:GetMouseLocation()
		local ray = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

		if result then
			local snapPos = getSnappedPosition(result.Position)
			ghostPart.Position = snapPos
			ghostPart.Transparency = 0.5 -- 配置可能な場所なら表示
		else
			-- 空中などを指している場合は見えなくする（または赤くする）
			ghostPart.Transparency = 1
		end
	end
end)

-- ■ ドラッグ終了処理（修正箇所）
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isDragging then
			-- gameProcessedがtrueの場合 = UIの上でマウスを離した = 配置キャンセル
			if not gameProcessed and ghostPart and ghostPart.Transparency < 1 then
				-- UI外かつ有効な場所にゴーストがある場合のみ配置
				PlaceBlockEvent:FireServer(draggingBlockType, ghostPart.Position, Vector3.new(0, 0, 0))
			end

			-- クリーンアップ
			if ghostPart then
				ghostPart:Destroy()
				ghostPart = nil
			end
			-- フィルタリストリセット
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
		print("Selected:", block.Name)
	end
end)

-- ■ 回転処理
local function rotateSelectedBlock()
	if selectedBlock and selectedBlock.Parent then
		UpdateBlockEvent:FireServer(selectedBlock, "rotate", Vector3.new(0, 90, 0))
	end
end

buttonRotate.MouseButton1Click:Connect(rotateSelectedBlock)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		rotateSelectedBlock()
	end
end)

print("Drag & Drop Controller Fixed")
