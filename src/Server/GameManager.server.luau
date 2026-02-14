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

-- ★追加: ステージクリア通知用イベントを動的生成（なければ作る）
local StageClearEvent = Events:FindFirstChild("StageClearEvent")
if not StageClearEvent then
	StageClearEvent = Instance.new("RemoteEvent")
	StageClearEvent.Name = "StageClearEvent"
	StageClearEvent.Parent = Events
end

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
			blades.CFrame = blades.CFrame * CFrame.Angles(math.rad(15), 0, 0)
			blades2.CFrame = blades2.CFrame * CFrame.Angles(math.rad(15), 0, 0)
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

-- ■ ジャンプ台生成
local function spawnSpring(position, rotation)
	local model = Instance.new("Model")
	model.Name = "PlacedBlock_Spring"
	local springPart = Instance.new("Part")
	springPart.Name = "SpringPart"
	springPart.Shape = Enum.PartType.Cylinder
	springPart.Size = Vector3.new(1, 4, 4)
	springPart.Color = Color3.fromRGB(255, 100, 100)
	springPart.Material = Enum.Material.Neon
	springPart.Anchored = true
	local baseCFrame = CFrame.new(position)
	if typeof(rotation) == "Vector3" then
		baseCFrame = baseCFrame * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	end
	springPart.CFrame = baseCFrame * CFrame.Angles(0, 0, math.rad(90))
	springPart.Parent = model

	local debounce = false
	springPart.Touched:Connect(function(hit)
		if hit.Name == "RedBall" and not debounce then
			debounce = true
			local jumpDir = springPart.CFrame.RightVector
			local JUMP_POWER = 80
			hit.AssemblyLinearVelocity = Vector3.new(hit.AssemblyLinearVelocity.X, 0, hit.AssemblyLinearVelocity.Z)
			hit:ApplyImpulse(jumpDir * hit.AssemblyMass * JUMP_POWER)
			TweenService
				:Create(springPart, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), { Size = Vector3.new(2, 4, 4) })
				:Play()
			task.wait(0.1)
			TweenService
				:Create(springPart, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), { Size = Vector3.new(1, 4, 4) })
				:Play()
			task.wait(0.5)
			debounce = false
		end
	end)
	model.PrimaryPart = springPart
	local folder = workspace:FindFirstChild("PlacedBlocks") or Instance.new("Folder", workspace)
	folder.Name = "PlacedBlocks"
	model.Parent = folder
end

-- ■ 加速床生成
local function spawnConveyor(position, rotation)
	local model = Instance.new("Model")
	model.Name = "PlacedBlock_Conveyor"
	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Shape = Enum.PartType.Block
	pad.Size = Vector3.new(4, 1, 4)
	pad.Color = Color3.fromRGB(255, 255, 100)
	pad.Material = Enum.Material.Plastic
	pad.Anchored = true
	local baseCFrame = CFrame.new(position)
	if typeof(rotation) == "Vector3" then
		baseCFrame = baseCFrame * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	end
	pad.CFrame = baseCFrame
	local SPEED = 40
	pad.AssemblyLinearVelocity = pad.CFrame.LookVector * SPEED
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.CanvasSize = Vector2.new(200, 200)
	gui.LightInfluence = 0
	gui.Parent = pad
	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.BackgroundTransparency = 1
	arrow.Text = "⬆"
	arrow.TextColor3 = Color3.new(0, 0, 0)
	arrow.TextScaled = true
	arrow.Font = Enum.Font.GothamBold
	arrow.Parent = gui
	pad.Parent = model
	model.PrimaryPart = pad
	local folder = workspace:FindFirstChild("PlacedBlocks") or Instance.new("Folder", workspace)
	folder.Name = "PlacedBlocks"
	model.Parent = folder
end

-- ■ ブロック配置処理
PlaceBlockEvent.OnServerEvent:Connect(function(player, blockType, position, rotation)
	if blockType == "Fan" then
		spawnFan(position, rotation, true)
		return
	end
	if blockType == "Spring" then
		spawnSpring(position, rotation)
		return
	end
	if blockType == "Conveyor" then
		spawnConveyor(position, rotation)
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

-- ■ ゴール吸い込み (★修正: 自動遷移を廃止し、クライアントへクリア通知)
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

	print("🎉 GOAL! Waiting for player to proceed...")

	-- ★追加: クライアントにステージクリアを通知
	StageClearEvent:FireAllClients(currentStageIndex)

	-- ここでの loadStage 自動呼び出しは削除
end

clearUserBlocks = function()
	local folder = workspace:FindFirstChild("PlacedBlocks")
	if folder then
		folder:ClearAllChildren()
	end
end

local function createFloorWithGap(gapPosition, gapSize)
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	local oldFloor = workspace:FindFirstChild("GeneratedFloor")
	if oldFloor then
		oldFloor:Destroy()
	end
	local floorModel = Instance.new("Model")
	floorModel.Name = "GeneratedFloor"
	local WORLD_SIZE = 2048
	local FLOOR_THICKNESS = 4
	local Y_POS = -2
	local function addGridTexture(part)
		local texture = Instance.new("Texture")
		texture.Face = Enum.NormalId.Top
		texture.Texture = "rbxassetid://6372755229"
		texture.Color3 = Color3.fromRGB(255, 255, 255)
		texture.Transparency = 0.8
		texture.StudsPerTileU = 4
		texture.StudsPerTileV = 4
		local cornerX = part.Position.X - part.Size.X / 2
		local cornerZ = part.Position.Z - part.Size.Z / 2
		texture.OffsetStudsU = cornerX % 4
		texture.OffsetStudsV = cornerZ % 4
		texture.Parent = part
	end
	local gx, gz = gapPosition.X, gapPosition.Z
	local gw, gd = gapSize.X, gapSize.Z
	local function makeFloor(name, size, pos)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Anchored = true
		p.Color = Color3.fromRGB(15, 15, 20)
		p.Material = Enum.Material.SmoothPlastic
		addGridTexture(p)
		p.Parent = floorModel
	end
	local northSizeZ = (WORLD_SIZE / 2) - (math.abs(gz) + gd / 2)
	if northSizeZ > 0 then
		makeFloor(
			"FloorNorth",
			Vector3.new(WORLD_SIZE, FLOOR_THICKNESS, northSizeZ),
			Vector3.new(0, Y_POS, (gz - gd / 2) - northSizeZ / 2)
		)
	end
	local southStart = gz + gd / 2
	local sSizeZ = (WORLD_SIZE / 2) - southStart
	makeFloor(
		"FloorSouth",
		Vector3.new(WORLD_SIZE, FLOOR_THICKNESS, sSizeZ),
		Vector3.new(0, Y_POS, southStart + sSizeZ / 2)
	)
	local westEnd = gx - gw / 2
	local wSizeX = westEnd - (-WORLD_SIZE / 2)
	makeFloor(
		"FloorWest",
		Vector3.new(wSizeX, FLOOR_THICKNESS, gd),
		Vector3.new((-WORLD_SIZE / 2) + wSizeX / 2, Y_POS, gz)
	)
	local eastStart = gx + gw / 2
	local eSizeX = (WORLD_SIZE / 2) - eastStart
	makeFloor("FloorEast", Vector3.new(eSizeX, FLOOR_THICKNESS, gd), Vector3.new(eastStart + eSizeX / 2, Y_POS, gz))
	floorModel.Parent = workspace
end

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

-- ■ ゴール生成 (四角い枠)
local function spawnGoal()
	local existingGoal = workspace:FindFirstChild("GoalModel")
	if existingGoal then
		existingGoal:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "GoalModel"
	model.Parent = workspace
	createFloorWithGap(currentGoalPos, Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, GOAL_WIDTH))
	local halfWidth = GOAL_WIDTH / 2
	local halfHole = HOLE_SIZE / 2
	local stripWidth = halfWidth - halfHole
	local zOffset = halfHole + (stripWidth / 2)
	local xOffset = halfHole + (stripWidth / 2)
	local function createStrip(size, offset)
		local part = Instance.new("Part")
		part.Name = "GoalFramePart"
		part.Size = size
		part.CFrame = CFrame.new(currentGoalPos) * offset
		part.Color = Palette.Entity.GoalBase
		part.Material = Enum.Material.Grass
		part.Anchored = true
		part.Parent = model
	end
	createStrip(Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, stripWidth), CFrame.new(0, 0, -zOffset))
	createStrip(Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, stripWidth), CFrame.new(0, 0, zOffset))
	createStrip(Vector3.new(stripWidth, GOAL_THICKNESS, HOLE_SIZE), CFrame.new(-xOffset, 0, 0))
	createStrip(Vector3.new(stripWidth, GOAL_THICKNESS, HOLE_SIZE), CFrame.new(xOffset, 0, 0))
	local cupBottom = Instance.new("Part")
	cupBottom.Name = "CupBottom"
	cupBottom.Shape = Enum.PartType.Block
	cupBottom.Size = Vector3.new(HOLE_SIZE * 0.95, 0.2, HOLE_SIZE * 0.95)
	cupBottom.Color = Palette.Entity.GoalCup
	cupBottom.Material = Enum.Material.Plastic
	cupBottom.Anchored = true
	cupBottom.CanCollide = true
	cupBottom.CFrame = CFrame.new(currentGoalPos) * CFrame.new(0, -GOAL_THICKNESS / 2 + 0.1, 0)
	cupBottom.Parent = model
	local magnet = Instance.new("Part")
	magnet.Name = "MagnetSensor"
	magnet.Shape = Enum.PartType.Cylinder
	magnet.Size = Vector3.new(1, MAGNET_RADIUS, MAGNET_RADIUS)
	magnet.CFrame = CFrame.new(currentGoalPos) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(1, 0, 0)
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

-- ★修正: イベントハンドリング (next処理追加)
GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	elseif action == "next" then -- 次のステージへ
		currentStageIndex = currentStageIndex + 1
		if currentStageIndex > #STAGE_DATA then
			currentStageIndex = 1
		end
		loadStage(currentStageIndex)
	end
end)

print("GameManager Updated: Stage Clear Event & Manual Transition")
