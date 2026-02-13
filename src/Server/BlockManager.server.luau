-- src/Server/BlockManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceBlockEvent = require(ReplicatedStorage.Shared.Events.PlaceBlockEvent)

-- クライアントから「ブロックを置きたい」という通信を受け取った時の処理
PlaceBlockEvent.OnServerEvent:Connect(function(player, blockType, position, rotation)
	print(player.Name .. " が " .. blockType .. " を配置しようとしています。")

	local newBlock

	if blockType == "slope" then
		newBlock = Instance.new("WedgePart")
		newBlock.BrickColor = BrickColor.new("New Yeller") -- 黄色
		newBlock.Size = Vector3.new(4, 4, 4) -- サイズはお好みで調整してください
	elseif blockType == "cube" then
		newBlock = Instance.new("Part")
		newBlock.Shape = Enum.PartType.Block
		newBlock.BrickColor = BrickColor.new("Bright blue") -- 青色
		newBlock.Size = Vector3.new(4, 4, 4)
	end

	if newBlock then
		newBlock.Anchored = true -- 落ちないように固定
		newBlock.Material = Enum.Material.SmoothPlastic
		newBlock.Position = position
		-- 回転の設定（ラジアンから度に変換）
		newBlock.Orientation = Vector3.new(rotation.X, rotation.Y, rotation.Z)

		-- Workspace（ゲームの世界）に追加して表示させる
		newBlock.Parent = game.Workspace
		newBlock.Name = "PlacedBlock_" .. player.Name
	end
end)
