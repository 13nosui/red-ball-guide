-- src/Client/PlacementController.client.luau
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- タイムアウトを設定してイベントを待つ
-- 構造：ReplicatedStorage -> Shared -> Events -> EventModule
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")

-- モジュールとしてrequireするのではなく、サーバーが作成したRemoteEventインスタンスを待つ
-- ※本来はモジュール経由が望ましいですが、既存コードの互換性を維持しつつRemoteを待ちます
local PlaceBlockEventModule = require(Events:WaitForChild("PlaceBlockEvent"))
local PlaceBlockEvent = ReplicatedStorage:WaitForChild("PlaceBlockEvent", 10)

-- もしReplicatedStorage直下にない場合（タイミングの問題）、モジュールから取得を試みる
if not PlaceBlockEvent then
	PlaceBlockEvent = PlaceBlockEventModule
end

local UpdateBlockEvent = ReplicatedStorage:WaitForChild("UpdateBlockEvent", 10)

if not PlaceBlockEvent then
	warn("Critical: PlaceBlockEvent not found.")
	return
end

-- UIの待機
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui", 10)
if not screenGui then
	return
end -- UI生成スクリプトが動いていない場合

local editFrame = screenGui:WaitForChild("EditFrame")

local buttonBlock = editFrame:WaitForChild("ButtonBlock")
local buttonSphere = editFrame:WaitForChild("ButtonSphere")
local buttonWedge = editFrame:WaitForChild("ButtonWedge")
local buttonRotate = editFrame:WaitForChild("ButtonRotate")

-- 現在選択しているブロックの種類と回転
local currentBlockType = "Block" -- 初期値をWedgeからBlockに変更
local currentRotation = Vector3.new(0, 0, 0)
local GRID_SIZE = 4

-- 回転処理
local function rotateBlock()
	currentRotation = currentRotation + Vector3.new(0, 90, 0)
	print("Rotation (Degrees): ", currentRotation)
end

-- ボタンのクリックイベント設定
buttonBlock.MouseButton1Click:Connect(function()
	currentBlockType = "Block"
	print("Selected: Block")
end)

buttonSphere.MouseButton1Click:Connect(function()
	currentBlockType = "Sphere"
	print("Selected: Sphere")
end)

buttonWedge.MouseButton1Click:Connect(function()
	currentBlockType = "Wedge"
	print("Selected: Wedge")
end)

buttonRotate.MouseButton1Click:Connect(function()
	rotateBlock()
end)

-- クリックした時の処理 (ブロック配置)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if mouse.Target then
			local targetPosition = mouse.Hit.Position

			-- グリッドにスナップさせる計算
			local snappedX = math.floor(targetPosition.X / GRID_SIZE + 0.5) * GRID_SIZE
			local snappedZ = math.floor(targetPosition.Z / GRID_SIZE + 0.5) * GRID_SIZE

			-- 配置高さの調整（地面に埋まらないようにする）
			local yOffset = 2 -- Block(4x4x4)の半分
			local placePosition = Vector3.new(snappedX, targetPosition.Y + yOffset, snappedZ)

			-- サーバーにイベントを発火
			PlaceBlockEvent:FireServer(currentBlockType, placePosition, currentRotation)
			print("Request to place block:", currentBlockType, "at", placePosition)
		end
	end
end)

-- Rキーでの回転
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		rotateBlock()
	end
end)

print("PlacementController Loaded")
