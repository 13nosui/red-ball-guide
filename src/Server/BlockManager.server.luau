-- src/Server/BlockManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")

-- サーバー側でイベントモジュールをrequireしてRemoteEventを確実に生成/取得する
local PlaceBlockEvent = require(Events.PlaceBlockEvent)
local UpdateBlockEvent = require(Events.UpdateBlockEvent)

-- ブロックの親フォルダ
local blocksFolder = Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

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
		newBlock.Material = Enum.Material.Plastic
		newBlock.BrickColor = BrickColor.new("Bright yellow")
		newBlock.Anchored = true
		newBlock.Size = Vector3.new(4, 4, 4) -- グリッドサイズに合わせる
		return newBlock
	end
	return nil
end

-- ブロック配置イベント
PlaceBlockEvent.OnServerEvent:Connect(function(player, blockType, position, rotation)
	local newBlock = createBlock(blockType)
	if newBlock then
		-- 位置と回転を設定
		-- rotationはVector3 (Degrees) で来ることを想定
		newBlock.CFrame = CFrame.new(position)
			* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))

		newBlock.Name = "PlacedBlock_" .. player.Name
		newBlock.Parent = blocksFolder

		-- 生成したブロックにClickDetectorを追加して、クリック検知可能にする
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.Parent = newBlock

		-- クリックイベントで編集UIを表示する処理
		clickDetector.MouseClick:Connect(function(clickingPlayer)
			if clickingPlayer == player then -- 自分の置いたブロックだけ編集可能
				-- クライアントに編集UI表示のイベントを送信
				UpdateBlockEvent:FireClient(player, newBlock)
			end
		end)

		print(player.Name .. " placed " .. blockType)
	end
end)

-- ブロック更新イベント（サイズ・回転・削除など）
UpdateBlockEvent.OnServerEvent:Connect(function(player, block, action, value)
	if block and block.Parent and block.Name == "PlacedBlock_" .. player.Name then
		if action == "resize" then
			block.Size = value
		elseif action == "rotate" then
			-- 相対的な回転を加える
			block.CFrame = block.CFrame * CFrame.Angles(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
		elseif action == "delete" then
			block:Destroy()
		end
	end
end)

print("BlockManager Initialized")
