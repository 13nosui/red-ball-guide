local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- タイムアウトを設定してイベントを待つ
local PlaceBlockEvent = ReplicatedStorage:WaitForChild("PlaceBlockEvent", 10)
local UpdateBlockEvent = ReplicatedStorage:WaitForChild("UpdateBlockEvent", 10)

if not PlaceBlockEvent or not UpdateBlockEvent then
	warn("Required events not found in ReplicatedStorage! Make sure the server script has run.")
	return
end

-- GUIのボタンを取得 (パスは実際のGUI構成に合わせて調整してください)
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui") -- ScreenGuiの名前
local editFrame = screenGui:WaitForChild("EditFrame") -- Frameの名前

local buttonBlock = editFrame:WaitForChild("ButtonBlock")
local buttonSphere = editFrame:WaitForChild("ButtonSphere")
local buttonWedge = editFrame:WaitForChild("ButtonWedge")
local buttonRotate = editFrame:WaitForChild("ButtonRotate") -- 回転ボタンの取得を追加

-- 現在選択しているブロックの種類と回転
local currentBlockType = "Wedge"
local currentRotation = Vector3.new(0, 0, 0)
local GRID_SIZE = 4

-- 回転処理を関数として切り出し（再利用のため）
local function rotateBlock()
	currentRotation = currentRotation + Vector3.new(0, 90, 0)
	print("Rotation (Degrees): ", currentRotation)
	-- 必要であればここでUI上の表示を更新する処理などを追加
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

-- 回転ボタンのクリックイベントを追加
buttonRotate.MouseButton1Click:Connect(function()
	rotateBlock()
end)

-- クリックした時の処理 (ブロック配置)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- GUI上のクリックなどは無視する
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if mouse.Target then
			local targetPosition = mouse.Hit.Position

			-- グリッドにスナップさせる計算
			local snappedX = math.floor(targetPosition.X / GRID_SIZE + 0.5) * GRID_SIZE
			local snappedZ = math.floor(targetPosition.Z / GRID_SIZE + 0.5) * GRID_SIZE

			-- Y軸の高さ調整
			local placePosition = Vector3.new(snappedX, targetPosition.Y + 2, snappedZ)

			-- サーバーにイベントを発火
			PlaceBlockEvent:FireServer(currentBlockType, placePosition, currentRotation)
			print("Request to place block:", currentBlockType, "at", placePosition)
		end
	end
end)

-- Rキーでの回転（関数を呼び出す形に変更）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		rotateBlock()
	end
end)
