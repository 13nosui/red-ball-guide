-- src/Server/BlockManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")

local PlaceBlockEvent = require(Events.PlaceBlockEvent)
local UpdateBlockEvent = require(Events.UpdateBlockEvent)
local Palette = require(Shared:WaitForChild("Palette"))

local blocksFolder = workspace:FindFirstChild("PlacedBlocks") or Instance.new("Folder")
blocksFolder.Name = "PlacedBlocks"
blocksFolder.Parent = workspace

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
		newBlock.Color = Palette.BlockColors[blockType] or Color3.new(1, 1, 1)
		newBlock.Anchored = true
		newBlock.Size = Vector3.new(4, 4, 4)
		return newBlock
	end
	return nil
end

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

-- 更新イベント（移動・回転・削除）
UpdateBlockEvent.OnServerEvent:Connect(function(player, block, action, value)
	if block and block.Parent and block.Name == "PlacedBlock_" .. player.Name then
		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		if action == "rotate" then
			local rotationCFrame = CFrame.Angles(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
			local targetCFrame = block.CFrame * rotationCFrame
			TweenService:Create(block, tweenInfo, { CFrame = targetCFrame }):Play()
		elseif action == "move" then
			-- 相対移動（ボタン操作用: Up/Downで使用）
			local targetPosition = block.Position + value
			if targetPosition.Y >= 0 then
				TweenService:Create(block, tweenInfo, { Position = targetPosition }):Play()
			end
		elseif action == "moveTo" then
			-- ★追加: 絶対座標移動（ドラッグ＆ドロップ用）
			local targetPosition = value
			-- 地面(Y=0付近)より下にいかないようにする
			if targetPosition.Y >= -2 then
				-- Tweenを使わず即時反映（ドラッグ操作の追従性重視）
				-- あるいは非常に短いTweenで滑らかにする
				TweenService:Create(block, TweenInfo.new(0.1), { Position = targetPosition }):Play()
			end
		elseif action == "delete" then
			block:Destroy()
		end
	end
end)

print("BlockManager: Added moveTo action")
