-- src/Server/BlockManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")

local PlaceBlockEvent = require(Events.PlaceBlockEvent)
local UpdateBlockEvent = require(Events.UpdateBlockEvent)

local blocksFolder = workspace:FindFirstChild("PlacedBlocks") or Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

-- ブロック生成関数
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
		-- シリンダーの初期補正
		newBlock.CFrame = newBlock.CFrame * CFrame.Angles(0, 0, math.rad(90))
	end

	if newBlock then
		newBlock.Material = Enum.Material.Plastic
		newBlock.BrickColor = BrickColor.new("Bright yellow")
		newBlock.Anchored = true
		newBlock.Size = Vector3.new(4, 4, 4)
		return newBlock
	end
	return nil
end

-- 配置イベント
PlaceBlockEvent.OnServerEvent:Connect(function(player, blockType, position, rotation)
	local newBlock = createBlock(blockType)
	if newBlock then
		-- 位置設定（回転は初期値0で来る想定だが、指定があれば適用）
		newBlock.CFrame = CFrame.new(position)
			* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))

		newBlock.Name = "PlacedBlock_" .. player.Name
		newBlock.Parent = blocksFolder

		-- クリック検知（選択用）
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.Parent = newBlock

		clickDetector.MouseClick:Connect(function(clickingPlayer)
			if clickingPlayer == player then
				-- クリックしたプレイヤーに「これを選択したよ」と通知
				UpdateBlockEvent:FireClient(player, newBlock)
			end
		end)
	end
end)

-- 更新イベント（回転・削除など）
UpdateBlockEvent.OnServerEvent:Connect(function(player, block, action, value)
	-- 所有権チェック
	if block and block.Parent and block.Name == "PlacedBlock_" .. player.Name then
		if action == "rotate" then
			-- 現在のCFrameに対して相対的に回転を加える（その場で回転）
			-- value = Vector3(0, 90, 0) 等
			local rotationCFrame = CFrame.Angles(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
			block.CFrame = block.CFrame * rotationCFrame
		elseif action == "delete" then
			block:Destroy()
		end
	end
end)

print("BlockManager Updated")
