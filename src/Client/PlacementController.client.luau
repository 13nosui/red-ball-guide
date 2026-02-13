-- src/Client/PlacementController.client.luau
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- イベントの取得（ReplicatedStorageの構成に合わせる）
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
-- モジュール経由でRemoteEventを取得
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
local ROTATION_STEP = 90

-- 状態管理
local isDragging = false
local draggingBlockType = nil
local ghostPart = nil

local selectedBlock = nil
local selectionBox = Instance.new("SelectionBox")
selectionBox.Color3 = Color3.fromRGB(255, 170, 0) -- 選択時の色（オレンジ）
selectionBox.LineThickness = 0.05
selectionBox.Parent = playerGui

-- レイキャスト用のパラメータ
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
-- ゴースト自身とプレイヤーキャラクターを無視
raycastParams.FilterDescendantsInstances = { player.Character }

-- ■ ヘルパー関数: ゴーストの生成
local function createGhost(blockType)
	if ghostPart then
		ghostPart:Destroy()
	end

	-- 形状に応じたパーツ作成
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
		part.Material = Enum.Material.ForceField -- ガイドっぽく見せる
		part.Color = Color3.fromRGB(0, 255, 0)
		part.Anchored = true
		part.Parent = workspace

		-- レイキャストで自分を無視リストに追加
		local currentFilter = raycastParams.FilterDescendantsInstances
		table.insert(currentFilter, part)
		raycastParams.FilterDescendantsInstances = currentFilter
	end

	return part
end

-- ■ ヘルパー関数: グリッドスナップ計算
local function getSnappedPosition(position)
	local snappedX = math.floor(position.X / GRID_SIZE + 0.5) * GRID_SIZE
	local snappedZ = math.floor(position.Z / GRID_SIZE + 0.5) * GRID_SIZE
	-- Y座標は地面(Target)の上に置くため、高さの半分(2)を足す（必要に応じて調整）
	local snappedY = position.Y + 2
	return Vector3.new(snappedX, snappedY, snappedZ)
end

-- ■ ドラッグ開始処理（UIボタンのInputBegan）
local function setupDragButton(button, blockType)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			draggingBlockType = blockType
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

-- ■ ドラッグ中の処理（毎フレーム更新）
RunService.RenderStepped:Connect(function()
	if isDragging and ghostPart then
		local mouseLocation = UserInputService:GetMouseLocation()
		local ray = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

		if result then
			local snapPos = getSnappedPosition(result.Position)
			ghostPart.Position = snapPos
		else
			-- 空中の場合はカメラ前方に仮表示するか、隠す
			ghostPart.Position = ray.Origin + ray.Direction * 20
		end
	end
end)

-- ■ ドラッグ終了処理（ドロップ＆配置）
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isDragging then
			if ghostPart then
				-- 配置イベント送信
				-- ゴーストの位置が有効なら配置
				PlaceBlockEvent:FireServer(draggingBlockType, ghostPart.Position, Vector3.new(0, 0, 0))

				-- クリーンアップ
				ghostPart:Destroy()
				ghostPart = nil
				-- フィルタリストのリセット（簡易的）
				raycastParams.FilterDescendantsInstances = { player.Character }
			end
			isDragging = false
		end
	end
end)

-- ■ 選択機能（サーバーからの通知を受け取る）
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
		-- サーバーに回転リクエスト送信 (Y軸90度)
		UpdateBlockEvent:FireServer(selectedBlock, "rotate", Vector3.new(0, 90, 0))
	end
end

-- 回転ボタン
buttonRotate.MouseButton1Click:Connect(rotateSelectedBlock)

-- Rキーショートカット
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		rotateSelectedBlock()
	end
end)

print("Drag & Drop Placement Controller Loaded")
