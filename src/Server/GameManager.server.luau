-- src/Server/GameManager.server.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

local GameControlEvent = require(Events.GameControlEvent)
local UpdateStageEvent = require(Events.UpdateStageEvent)
local PlaceBlockEvent = require(Events:WaitForChild("PlaceBlockEvent"))
local UpdateBlockEvent = require(Events:WaitForChild("UpdateBlockEvent"))

-- 設定
local BALL_SIZE = 4
local HOLE_SIZE = 5.5
local GOAL_THICKNESS = 4
local GOAL_WIDTH = 12
local MAGNET_RADIUS = HOLE_SIZE * 2.5
local MAX_CAPTURE_SPEED = 60

-- AIアシスト設定
local AI_ASSIST_RANGE = 10
local AI_CORRECTION_POWER = 6
local AI_MIN_SPEED = 5
local AI_NUDGE_POWER = 15

-- ■ ステージデータ
local STAGE_DATA = {
	[1] = {
		Start = Vector3.new(0, 15, 0),
		Goal = Vector3.new(0, -2, -24),
		Waypoints = { Vector3.new(0, 15, 0), Vector3.new(0, 2, 0), Vector3.new(0, 2, -24) },
		Fans = {},
		TutorialBlocks = {},
	},
	[2] = {
		Start = Vector3.new(4, 15, 0),
		Goal = Vector3.new(20, -2, -20),
		Waypoints = { Vector3.new(4, 15, 0), Vector3.new(4, 2, 0), Vector3.new(4, 2, -20), Vector3.new(20, 2, -20) },
		Fans = {},
		TutorialBlocks = {},
	},
	[3] = {
		Start = Vector3.new(0, 30, 20),
		Goal = Vector3.new(0, -2, -32),
		Waypoints = { Vector3.new(0, 30, 20), Vector3.new(0, 2, 20), Vector3.new(0, 2, -32) },
		Fans = {},
		TutorialBlocks = {},
	},
	[4] = {
		Start = Vector3.new(0, 15, 32),
		Goal = Vector3.new(0, -2, -32),
		Waypoints = { Vector3.new(0, 15, 32), Vector3.new(0, 2, 32), Vector3.new(0, 2, -32) },
		Fans = {},
		TutorialBlocks = {},
	},
	[5] = {
		Start = Vector3.new(-20, 15, 0),
		Goal = Vector3.new(20, 10, 0),
		Waypoints = { Vector3.new(-20, 15, 0), Vector3.new(-20, 2, 0), Vector3.new(16, 2, 0), Vector3.new(20, 10, 0) },
		Fans = {},
		TutorialBlocks = {},
	},
}

-- 状態
local currentStageIndex = 1
local currentBall = nil
local isGoalLocked = false
local currentStartPos = STAGE_DATA[1].Start
local currentGoalPos = STAGE_DATA[1].Goal
local activeWindZones = {}

-- 前方宣言
local spawnBall
local resetGame
local startGame
local loadStage
local clearUserBlocks

-- ■ ヘルパー関数
local function getClosestPointOnSegment(point, a, b)
	local ab = b - a
	local ap = point - a
	local t = ap:Dot(ab) / ab:Dot(ab)
	t = math.clamp(t, 0, 1)
	return a + ab * t
end

-- ■ 物理処理ループ
RunService.Heartbeat:Connect(function(dt)
	for i = #activeWindZones, 1, -1 do
		local zone = activeWindZones[i]
		if not zone.Part or not zone.Part.Parent then
			table.remove(activeWindZones, i)
		end
	end

	if not currentBall or currentBall.Anchored or isGoalLocked then
		return
	end

	-- 1. 風の処理
	for _, zoneData in ipairs(activeWindZones) do
		local zonePart = zoneData.Part
		local direction = zonePart.CFrame.LookVector
		local power = zoneData.Power or 60

		local relPos = zonePart.CFrame:PointToObjectSpace(currentBall.Position)
		local size = zonePart.Size
		if
			math.abs(relPos.X) <= size.X / 2
			and math.abs(relPos.Y) <= size.Y / 2
			and math.abs(relPos.Z) <= size.Z / 2
		then
			currentBall.AssemblyLinearVelocity = currentBall.AssemblyLinearVelocity + (direction * power * dt)
		end
	end

	-- 2. AI Navigation Assist
	local data = STAGE_DATA[currentStageIndex]
	if data and data.Waypoints and #data.Waypoints >= 2 then
		local ballPos = currentBall.Position
		local closestDist = math.huge
		local targetPoint = nil
		local targetDir = nil

		for i = 1, #data.Waypoints - 1 do
			local p1 = data.Waypoints[i]
			local p2 = data.Waypoints[i + 1]
			local p1_flat = Vector3.new(p1.X, ballPos.Y, p1.Z)
			local p2_flat = Vector3.new(p2.X, ballPos.Y, p2.Z)
			local closest = getClosestPointOnSegment(ballPos, p1_flat, p2_flat)
			local dist = (ballPos - closest).Magnitude
			if dist < closestDist then
				closestDist = dist
				targetPoint = closest
				targetDir = (p2 - p1).Unit
			end
		end

		if closestDist < AI_ASSIST_RANGE and targetPoint then
			local correctionVec = (targetPoint - ballPos) * AI_CORRECTION_POWER * dt
			correctionVec = Vector3.new(correctionVec.X, 0, correctionVec.Z)
			currentBall.AssemblyLinearVelocity = currentBall.AssemblyLinearVelocity + correctionVec

			local speed =
				Vector3.new(currentBall.AssemblyLinearVelocity.X, 0, currentBall.AssemblyLinearVelocity.Z).Magnitude
			if speed < AI_MIN_SPEED and targetDir then
				currentBall.AssemblyLinearVelocity = currentBall.AssemblyLinearVelocity
					+ (targetDir * AI_NUDGE_POWER * dt)
			end
		end
	end
end)

-- ■ 扇風機生成
local function spawnFan(position, rotation, isUserBlock)
	local model = Instance.new("Model")
	model.Name = "FanModel"
	local housing = Instance.new("Part")
	housing.Name = "Housing"
	housing.Shape = Enum.PartType.Cylinder
	housing.Size = Vector3.new(2, 6, 6)
	housing.Color = Palette.Entity.FanHousing
	housing.Material = Enum.Material.Metal
	housing.Anchored = true
	housing.CanCollide = false
	housing.CanQuery = true

	local baseCFrame = CFrame.new(position)
	if typeof(rotation) == "Vector3" then
		baseCFrame = baseCFrame * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	elseif typeof(rotation) == "CFrame" then
		baseCFrame = rotation
	else
		baseCFrame = baseCFrame * CFrame.Angles(0, math.rad(90), 0)
	end

	housing.CFrame = baseCFrame * CFrame.Angles(0, math.rad(90), 0)
	housing.Parent = model

	local blades = Instance.new("Part")
	blades.Name = "Blades"
	blades.Shape = Enum.PartType.Block
	blades.Size = Vector3.new(0.5, 5, 0.5)
	blades.Color = Palette.Entity.FanBlade
	blades.Material = Enum.Material.Plastic
	blades.Anchored = true
	blades.CanCollide = false
	blades.CanQuery = false
	blades.CFrame = housing.CFrame
	blades.Parent = model
	local blades2 = blades:Clone()
	blades2.CFrame = housing.CFrame * CFrame.Angles(math.rad(90), 0, 0)
	blades2.Parent = model

	task.spawn(function()
		while blades.Parent do
			local rot = CFrame.Angles(math.rad(15), 0, 0)
			blades.CFrame = blades.CFrame * rot
			blades2.CFrame = blades2.CFrame * rot
			task.wait(0.01)
		end
	end)

	local zone = Instance.new("Part")
	zone.Name = "WindZone"
	zone.Size = Vector3.new(8, 8, 20)
	zone.Color = Palette.Entity.WindZone
	zone.Transparency = 0.8
	zone.Material = Enum.Material.ForceField
	zone.Anchored = true
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CFrame = baseCFrame * CFrame.new(0, 0, -12)
	zone.Parent = model

	local attachment = Instance.new("Attachment", housing)
	local particle = Instance.new("ParticleEmitter")
	particle.Speed = NumberRange.new(20)
	particle.Rate = 20
	particle.Lifetime = NumberRange.new(1)
	particle.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	particle.Texture = "rbxassetid://243089629"
	particle.Color = ColorSequence.new(Palette.Entity.WindZone)
	particle.EmissionDirection = Enum.NormalId.Right
	particle.Parent = attachment

	if isUserBlock then
		model.Name = "PlacedBlock_Fan"
		model.PrimaryPart = housing
		local folder = workspace:FindFirstChild("PlacedBlocks") or Instance.new("Folder", workspace)
		folder.Name = "PlacedBlocks"
		model.Parent = folder
	else
		model.Parent = workspace
	end

	table.insert(activeWindZones, { Part = zone, Power = 60 })
	return model
end

-- ■ ブロック配置処理
PlaceBlockEvent.OnServerEvent:Connect(function(player, blockType, position, rotation)
	print("Placing:", blockType)

	if blockType == "Fan" then
		spawnFan(position, rotation, true)
		return
	end

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
		newBlock.Name = "PlacedBlock_" .. blockType
		newBlock.Size = Vector3.new(4, 4, 4)
		newBlock.Anchored = true
		newBlock.Material = Enum.Material.Plastic
		newBlock.Color = Palette.BlockColors[blockType] or Color3.new(0.8, 0.8, 0.8)

		if typeof(rotation) == "Vector3" then
			newBlock.CFrame = CFrame.new(position)
				* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		else
			newBlock.Position = position
		end

		local folder = workspace:FindFirstChild("PlacedBlocks") or Instance.new("Folder", workspace)
		folder.Name = "PlacedBlocks"
		newBlock.Parent = folder
	end
end)

-- ■ ブロック操作処理
UpdateBlockEvent.OnServerEvent:Connect(function(player, block, action, value)
	if not block or not block.Parent then
		return
	end
	local target = block
	if block.Parent:IsA("Model") then
		target = block.Parent
	end

	if action == "move" then
		if target:IsA("Model") then
			target:PivotTo(target:GetPivot() + value)
		else
			target.Position = target.Position + value
		end
	elseif action == "rotate" then
		if target:IsA("Model") then
			target:PivotTo(target:GetPivot() * CFrame.Angles(math.rad(value.X), math.rad(value.Y), math.rad(value.Z)))
		else
			target.CFrame = target.CFrame * CFrame.Angles(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
		end
	elseif action == "moveTo" then
		if target:IsA("Model") then
			local currentRot = target:GetPivot().Rotation
			target:PivotTo(CFrame.new(value) * currentRot)
		else
			target.Position = value
		end
	elseif action == "delete" then
		target:Destroy()
	end
	UpdateBlockEvent:FireAllClients(target)
end)

-- ■ ゴール吸い込み
local function captureBallIntoHole(ball, cupCenterPosition)
	if isGoalLocked then
		return
	end
	isGoalLocked = true
	ball.Anchored = true
	ball.CanCollide = false
	ball.AssemblyLinearVelocity = Vector3.zero
	print("✨ AI Assist: Capturing ball into goal...")
	local overHolePos = Vector3.new(cupCenterPosition.X, ball.Position.Y, cupCenterPosition.Z)
	TweenService
		:Create(ball, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = overHolePos })
		:Play()
	task.wait(0.3)
	local bottomPos = cupCenterPosition + Vector3.new(0, -2, 0)
	TweenService
		:Create(ball, TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { Position = bottomPos })
		:Play()
	task.wait(0.4)
	print("🎉 GOAL! Stage " .. currentStageIndex .. " Cleared!")
	task.wait(1.5)
	currentStageIndex = currentStageIndex + 1
	if currentStageIndex > #STAGE_DATA then
		currentStageIndex = 1
		print("Loop back to 1.")
	end
	loadStage(currentStageIndex)
end

clearUserBlocks = function()
	local folder = workspace:FindFirstChild("PlacedBlocks")
	if folder then
		folder:ClearAllChildren()
	end
end

-- 床の穴あけ関数は不要になったので削除
-- local function createFloorWithGap...

spawnBall = function()
	if currentBall then
		currentBall:Destroy()
	end
	local ball = Instance.new("Part")
	ball.Name = "RedBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(BALL_SIZE, BALL_SIZE, BALL_SIZE)
	ball.Color = Palette.Entity.Ball
	ball.Material = Enum.Material.Plastic
	ball.Position = currentStartPos
	ball.Anchored = true
	ball.CanCollide = true
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.05, 0.1)
	ball.Parent = workspace
	currentBall = ball
	return ball
end

-- ■ ゴール生成 (修正版: CSGを使って丸い穴を開ける)
local function spawnGoal()
	local existingGoal = workspace:FindFirstChild("GoalModel")
	if existingGoal then
		existingGoal:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "GoalModel"
	model.Parent = workspace

	-- 1. 土台となる四角いパーツを作成
	local basePart = Instance.new("Part")
	basePart.Name = "GoalBase"
	basePart.Size = Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, GOAL_WIDTH)
	basePart.CFrame = CFrame.new(currentGoalPos)
	basePart.Color = Palette.Entity.GoalBase
	basePart.Material = Enum.Material.Grass
	basePart.Anchored = true
	basePart.Parent = workspace -- 一旦workspaceに置く

	-- 2. 穴を開けるための円柱パーツを作成 (Cutter)
	local holeCutter = Instance.new("Part")
	holeCutter.Name = "Cutter"
	holeCutter.Shape = Enum.PartType.Cylinder
	-- 円柱を立てるために90度回転させる
	holeCutter.CFrame = basePart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	-- 直径をHOLE_SIZEに、高さは土台より少し高くして貫通させる
	holeCutter.Size = Vector3.new(GOAL_THICKNESS * 2, HOLE_SIZE, HOLE_SIZE)
	holeCutter.Parent = workspace

	-- 3. CSG (SubtractAsync) を実行して穴を開ける
	local success, result = pcall(function()
		-- PreciseConvexDecomposition を使用して物理形状を正確にする
		return basePart:SubtractAsync({ holeCutter }, Enum.CollisionFidelity.PreciseConvexDecomposition)
	end)

	if success and result then
		-- 成功したら、生成されたユニオンパーツをモデルに入れる
		local unionGoal = result
		unionGoal.Name = "GoalCupFrame"
		unionGoal.Anchored = true
		unionGoal.Parent = model

		-- 元のパーツとカッターを削除
		basePart:Destroy()
		holeCutter:Destroy()

		-- 4. カップの底 (見た目)
		local cupBottom = Instance.new("Part")
		cupBottom.Name = "CupBottom"
		cupBottom.Shape = Enum.PartType.Cylinder
		-- 穴より少しだけ小さくする(チラつき防止)
		cupBottom.Size = Vector3.new(0.2, HOLE_SIZE * 0.95, HOLE_SIZE * 0.95)
		cupBottom.Color = Palette.Entity.GoalCup
		cupBottom.Material = Enum.Material.Plastic
		cupBottom.Anchored = true
		cupBottom.CanCollide = true
		-- 向き調整と配置
		cupBottom.CFrame = unionGoal.CFrame
			* CFrame.Angles(0, 0, math.rad(90))
			* CFrame.new(-GOAL_THICKNESS / 2 + 0.2, 0, 0)
		cupBottom.Parent = model

		-- 5. 判定用センサー
		local magnet = Instance.new("Part")
		magnet.Name = "MagnetSensor"
		magnet.Shape = Enum.PartType.Cylinder
		magnet.Size = Vector3.new(1, MAGNET_RADIUS, MAGNET_RADIUS)
		magnet.CFrame = unionGoal.CFrame * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(1, 0, 0)
		magnet.Transparency = 1
		magnet.CanCollide = false
		magnet.Anchored = true
		magnet.Parent = model
		magnet.CanQuery = false
		magnet.Touched:Connect(function(hit)
			if isGoalLocked then
				return
			end
			if hit.Name == "RedBall" and hit.AssemblyLinearVelocity.Magnitude < MAX_CAPTURE_SPEED then
				captureBallIntoHole(hit, Vector3.new(currentGoalPos.X, 0, currentGoalPos.Z))
			end
		end)
	else
		-- CSG失敗時のフォールバック (念のため)
		warn("Failed to create circular goal hole:", result)
		basePart.Parent = model
		if holeCutter then
			holeCutter:Destroy()
		end
	end
end

loadStage = function(index)
	isGoalLocked = false
	currentStageIndex = index
	for _, zone in ipairs(activeWindZones) do
		if zone.Part and zone.Part.Parent and zone.Part.Parent.Parent then
			zone.Part.Parent:Destroy()
		end
	end
	activeWindZones = {}

	local data = STAGE_DATA[index]
	if data then
		currentStartPos = data.Start
		currentGoalPos = data.Goal
		print("Loading Stage " .. index)
		clearUserBlocks()
		spawnGoal()
		spawnBall()
		if data.Fans then
			for _, fanData in ipairs(data.Fans) do
				spawnFan(fanData.Position, CFrame.lookAt(Vector3.zero, fanData.Direction), false)
			end
		end
		UpdateStageEvent:FireAllClients(index, data)
	end
end

startGame = function()
	if currentBall then
		currentBall.Anchored = false
		isGoalLocked = false
		print("Game Started")
	else
		spawnBall()
		currentBall.Anchored = false
		isGoalLocked = false
	end
end
resetGame = function()
	isGoalLocked = false
	spawnBall()
	print("Game Reset (Ball only)")
end

Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	local data = STAGE_DATA[currentStageIndex]
	if data then
		UpdateStageEvent:FireClient(player, currentStageIndex, data)
	end
end)

task.wait(1)
loadStage(1)

GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)

print("GameManager Updated: Goal Hole is now Circular using CSG")
