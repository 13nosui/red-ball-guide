-- src/Client/PlacementController.client.luau
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local PlaceBlockEvent = require(ReplicatedStorage.Shared.Events.PlaceBlockEvent)

-- 現在選択しているブロックの種類と回転
local currentBlockType = "slope"
local currentRotation = Vector3.new(0, 0, 0)

-- クリックした時の処理
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- UIなどをクリックした時は無視する
	if gameProcessed then
		return
	end

	-- 左クリックされたら
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- マウスが指している3D空間の座標を取得
		local targetPosition = mouse.Hit.Position

		-- 少し上に浮かせて配置する（床にめり込まないように）
		local placePosition = Vector3.new(targetPosition.X, targetPosition.Y + 2, targetPosition.Z)

		-- サーバーに配置を依頼する
		PlaceBlockEvent:FireServer(currentBlockType, placePosition, currentRotation)
	end
end)
