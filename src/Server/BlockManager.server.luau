-- src/Server/BlockManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- 追加
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")

local PlaceBlockEvent = require(Events.PlaceBlockEvent)
local UpdateBlockEvent = require(Events.UpdateBlockEvent)

local blocksFolder = workspace:FindFirstChild("PlacedBlocks") or Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

-- ブロック生成
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
		newBlock.CFrame = CFrame.new(position)
			* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))

		newBlock.Name = "PlacedBlock_" .. player.Name
		newBlock.Parent = blocksFolder

		local clickDetector = Instance.new("ClickDetector")
		clickDetector.Parent = newBlock

		clickDetector.MouseClick:Connect(function(clickingPlayer)
			if clickingPlayer == player then
				UpdateBlockEvent:FireClient(player, newBlock)
			end
		end)
	end
end)

-- 更新イベント（回転アニメーション対応）
UpdateBlockEvent.OnServerEvent:Connect(function(player, block, action, value)
	if block and block.Parent and block.Name == "PlacedBlock_" .. player.Name then
		if action == "rotate" then
			-- value = Vector3 (Degrees)
			local rotationCFrame = CFrame.Angles(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))

			-- 目標となるCFrameを計算
			local targetCFrame = block.CFrame * rotationCFrame

			-- Tweenの設定 (0.3秒で滑らかに動かす)
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(block, tweenInfo, { CFrame = targetCFrame })
			tween:Play()
		elseif action == "delete" then
			block:Destroy()
		end
	end
end)

print("BlockManager with Tween Rotation Updated")
