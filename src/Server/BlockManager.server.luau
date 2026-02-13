-- src/Server/BlockManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceBlockEvent = require(ReplicatedStorage.Shared.Events.PlaceBlockEvent)
local UpdateBlockEvent = require(ReplicatedStorage.Shared.Events.UpdateBlockEvent) -- 新しいイベントの追加

-- ブロックの種類に応じた形状を設定
local function createBlock(blockType)
	local newBlock
	if blockType == "Block" then
		newBlock = Instance.new("Part")
		newBlock.Shape = Enum.PartType.Block
	elseif blockType == "Sphere" then
		newBlock = Instance.new("Part")
		newBlock.Shape = Enum.PartType.Ball
	elseif blockType == "Wedge" then
		newBlock = Instance.new("WedgePart")
	elseif blockType == "CornerWedge" then
		newBlock = Instance.new("CornerWedgePart")
	elseif blockType == "Cylinder" then
		newBlock = Instance.new("Part")
		newBlock.Shape = Enum.PartType.Cylinder
		-- シリンダーは向きが特殊なので初期回転を設定
		newBlock.CFrame = newBlock.CFrame * CFrame.Angles(0, 0, math.rad(90))
	end

	if newBlock then
		newBlock.Material = Enum.Material.Plastic -- 見た目を見やすくする
		newBlock.BrickColor = BrickColor.new("Bright yellow") -- 初期色
		newBlock.Anchored = true -- 初期状態は固定
		return newBlock
	end
	return nil
end

-- ブロック配置イベント
PlaceBlockEvent.OnServerEvent:Connect(function(player, blockType, position, rotation)
	local newBlock = createBlock(blockType)
	if newBlock then
		-- 位置と回転を設定
		newBlock.CFrame = CFrame.new(position)
			* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		newBlock.Parent = game.Workspace
		newBlock.Name = "PlacedBlock_" .. player.Name -- 名前をユニークにする

		-- 生成したブロックにClickDetectorを追加して、クリック検知可能にする
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.Parent = newBlock

		-- クリックイベントで編集UIを表示する処理（後述）
		clickDetector.MouseClick:Connect(function(clickingPlayer)
			if clickingPlayer == player then -- 自分の置いたブロックだけ編集可能
				-- クライアントに編集UI表示のイベントを送信（後述）
				UpdateBlockEvent:FireClient(player, newBlock)
			end
		end)
	end
end)

-- ブロック更新イベント（サイズ・回転・削除など）
UpdateBlockEvent.OnServerEvent:Connect(function(player, block, action, value)
	if block and block.Parent and block.Name == "PlacedBlock_" .. player.Name then
		if action == "resize" then
			block.Size = value -- valueはVector3
		elseif action == "rotate" then
			block.CFrame = block.CFrame * CFrame.Angles(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
		elseif action == "delete" then
			block:Destroy()
		end
	end
end)
