-- src/Server/GameManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

local GameControlEvent = require(Events.GameControlEvent)
local UpdateStageEvent = require(Events.UpdateStageEvent)

-- 設定
local BALL_SIZE = 4
local HOLE_SIZE = 5.5
local GOAL_THICKNESS = 4
local GOAL_WIDTH = 12
local MAGNET_RADIUS = HOLE_SIZE * 1.5
local MAX_CAPTURE_SPEED = 40

-- ■ ステージデータ
-- TutorialBlocks: {Type, Position, Rotation} のリスト
local STAGE_DATA = {
	[1] = {
		Start = Vector3.new(0, 15, 0),
		Goal = Vector3.new(0, -2, -20),
		Waypoints = { Vector3.new(0, 15, 0), Vector3.new(0, 2, 0), Vector3.new(0, 2, -20) },
		Fans = {},
		TutorialBlocks = {}, -- なし
	},
	[2] = {
		Start = Vector3.new(0, 15, 0),
		Goal = Vector3.new(20, -2, -20),
		Waypoints = { Vector3.new(0, 15, 0), Vector3.new(0, 2, 0), Vector3.new(0, 2, -20), Vector3.new(20, 2, -20) },
		Fans = {},
		TutorialBlocks = {}, -- なし（自分で考える）
	},
	-- Stage 3: 坂道チュートリアル
	-- 下の床がない部分にWedgeを置いて橋渡し＆加速させる
	[3] = {
		Start = Vector3.new(0, 30, 20),
		Goal = Vector3.new(0, -2, -30),
		Waypoints = {
			Vector3.new(0, 30, 20),
			Vector3.new(0, 2, 20),
			Vector3.new(0, 2, 0),
			Vector3.new(0, 2, -30),
		},
		Fans = {},
		TutorialBlocks = {
			-- 落下地点にWedgeを置いて滑り台にする
			{ Type = "Wedge", Position = Vector3.new(0, 2, 20), Rotation = Vector3.new(0, 180, 0) },
			-- もう一つ繋げてスムーズにする
			{ Type = "Wedge", Position = Vector3.new(0, 2, 16), Rotation = Vector3.new(0, 180, 0) },
		},
	},
	-- Stage 4: 扇風機チュートリアル
	-- 穴を埋めるためのブロックを示す
	[4] = {
		Start = Vector3.new(0, 15, 30),
		Goal = Vector3.new(0, -2, -30),
		Waypoints = {
			Vector3.new(0, 15, 30),
			Vector3.new(0, 2, 30),
			Vector3.new(0, 2, 0),
			Vector3.new(0, 5, -15),
			Vector3.new(0, 2, -30),
		},
		Fans = {
			{
				Position = Vector3.new(0, 2, 0),
				Direction = Vector3.new(0, 0, -1), -- 奥へ
				Power = 60,
				Size = Vector3.new(8, 8, 20),
			},
		},
		TutorialBlocks = {
			-- スタート直後の着地点を作る
			{ Type = "Block", Position = Vector3.new(0, 2, 30), Rotation = Vector3.new(0, 0, 0) },
			-- 風の手前まで道をつなぐ
			{ Type = "Block", Position = Vector3.new(0, 2, 26), Rotation = Vector3.new(0, 0, 0) },
		},
	},
	-- Stage 5: 風×坂道
	-- 風で流された先にある壁（坂道）を示す
	[5] = {
		Start = Vector3.new(-20, 15, 0),
		Goal = Vector3.new(20, 10, 0),
		Waypoints = {
			Vector3.new(-20, 15, 0),
			Vector3.new(-20, 2, 0),
			Vector3.new(0, 2, 0),
			Vector3.new(15, 5, 0),
			Vector3.new(20, 10, 0),
		},
		Fans = {
			{
				Position = Vector3.new(-10, 2, 0),
				Direction = Vector3.new(1, 0, 0), -- 右へ
				Power = 80,
				Size = Vector3.new(20, 8, 8),
			},
		},
		TutorialBlocks = {
			-- 右側の壁際にWedgeを置いて、風の力で登らせる
			{ Type = "Wedge", Position = Vector3.new(16, 2, 0), Rotation = Vector3.new(0, -90, 0) },
			-- 高さを稼ぐためのBlock
			{ Type = "Block", Position = Vector3.new(20, 2, 0), Rotation = Vector3.new(0, 0, 0) },
			-- 最後のゴールの足場
			{ Type = "Block", Position = Vector3.new(20, 6, 0), Rotation = Vector3.new(0, 0, 0) },
		},
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

-- ■ 風の物理処理
RunService.Heartbeat:Connect(function(dt)
	if not currentBall or currentBall.Anchored then
		return
	end

	for _, zoneData in ipairs(activeWindZones) do
		local zonePart = zoneData.Part
		local direction = zoneData.Direction
		local power = zoneData.Power

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
end)

-- ■ 扇風機生成
local function spawnFan(fanData)
	local model = Instance.new("Model")
	model.Name = "FanModel"
	local housing = Instance.new("Part")
	housing.Name = "Housing"
	housing.Shape = Enum.PartType.Cylinder
	housing.Size = Vector3.new(2, 6, 6)
	housing.Color = Palette.Entity.FanHousing
	housing.Material = Enum.Material.Metal
	housing.Anchored = true
	housing.CFrame = CFrame.lookAt(fanData.Position, fanData.Position + fanData.Direction)
		* CFrame.Angles(0, math.rad(90), 0)
	housing.Parent = model

	local blades = Instance.new("Part")
	blades.Name = "Blades"
	blades.Shape = Enum.PartType.Block
	blades.Size = Vector3.new(0.5, 5, 0.5)
	blades.Color = Palette.Entity.FanBlade
	blades.Material = Enum.Material.Plastic
	blades.Anchored = true
	blades.CanCollide = false
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
	zone.Size = fanData.Size
	zone.Color = Palette.Entity.WindZone
	zone.Transparency = 0.8
	zone.Material = Enum.Material.ForceField
	zone.Anchored = true
	zone.CanCollide = false
	zone.CFrame = CFrame.lookAt(fanData.Position, fanData.Position + fanData.Direction)
		* CFrame.new(0, 0, -fanData.Size.Z / 2 - 1)
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

	model.Parent = workspace
	table.insert(activeWindZones, { Part = zone, Direction = fanData.Direction, Power = fanData.Power })
end

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

-- ■ ユーザーブロック消去
clearUserBlocks = function()
	local folder = workspace:FindFirstChild("PlacedBlocks")
	if folder then
		folder:ClearAllChildren()
	end
end

-- ■ 地面生成 (省略)
local function createFloorWithGap(gapPosition, gapSize)
	-- (既存コードと同じため、変更点のみ記述: なし)
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

-- ■ ボール生成
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
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.1)
	ball.Parent = workspace
	currentBall = ball
	return ball
end

-- ■ ゴール生成
local function spawnGoal()
	local existingGoal = workspace:FindFirstChild("GoalModel")
	if existingGoal then
		existingGoal:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "GoalModel"
	model.Parent = workspace
	createFloorWithGap(currentGoalPos, Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, GOAL_WIDTH))
	local basePart = Instance.new("Part")
	basePart.Name = "Base"
	basePart.Size = Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, GOAL_WIDTH)
	basePart.CFrame = CFrame.new(currentGoalPos)
	basePart.Color = Palette.Entity.GoalBase
	basePart.Material = Enum.Material.Grass
	basePart.Anchored = true
	basePart.Parent = workspace
	local holeCutter = Instance.new("Part")
	holeCutter.Name = "Cutter"
	holeCutter.Shape = Enum.PartType.Cylinder
	holeCutter.CFrame = basePart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	holeCutter.Size = Vector3.new(GOAL_THICKNESS * 2, HOLE_SIZE, HOLE_SIZE)
	holeCutter.Parent = workspace
	local success, result = pcall(function()
		return basePart:SubtractAsync({ holeCutter }, Enum.CollisionFidelity.PreciseConvexDecomposition)
	end)
	if success and result then
		local unionGoal = result
		unionGoal.Name = "GoalCup"
		unionGoal.Anchored = true
		unionGoal.Parent = model
		basePart:Destroy()
		holeCutter:Destroy()
		local cupBottom = Instance.new("Part")
		cupBottom.Name = "CupBottom"
		cupBottom.Shape = Enum.PartType.Cylinder
		cupBottom.Size = Vector3.new(0.2, HOLE_SIZE * 0.95, HOLE_SIZE * 0.95)
		cupBottom.Color = Palette.Entity.GoalCup
		cupBottom.Material = Enum.Material.Plastic
		cupBottom.Anchored = true
		cupBottom.CanCollide = true
		cupBottom.CFrame = unionGoal.CFrame
			* CFrame.Angles(0, 0, math.rad(90))
			* CFrame.new(-GOAL_THICKNESS / 2 + 0.2, 0, 0)
		cupBottom.Parent = model
		local magnet = Instance.new("Part")
		magnet.Name = "MagnetSensor"
		magnet.Shape = Enum.PartType.Cylinder
		magnet.Size = Vector3.new(1, MAGNET_RADIUS, MAGNET_RADIUS)
		magnet.CFrame = unionGoal.CFrame * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(1, 0, 0)
		magnet.Transparency = 1
		magnet.CanCollide = false
		magnet.Anchored = true
		magnet.Parent = model
		magnet.Touched:Connect(function(hit)
			if isGoalLocked then
				return
			end
			if hit.Name == "RedBall" and hit.AssemblyLinearVelocity.Magnitude < MAX_CAPTURE_SPEED then
				captureBallIntoHole(hit, Vector3.new(currentGoalPos.X, 0, currentGoalPos.Z))
			end
		end)
		local pole = Instance.new("Part")
		pole.Name = "Pole"
		pole.Size = Vector3.new(0.4, 12, 0.4)
		pole.Shape = Enum.PartType.Cylinder
		pole.Color = Palette.Entity.GoalPole
		pole.Anchored = true
		pole.CanCollide = false
		pole.CFrame = CFrame.new(currentGoalPos.X, 0 + 6, currentGoalPos.Z - 4)
		pole.Parent = model
		local flag = Instance.new("Part")
		flag.Name = "Flag"
		flag.Size = Vector3.new(0.2, 3, 4)
		flag.Color = Palette.Entity.GoalFlag
		flag.Anchored = true
		flag.CanCollide = false
		flag.CFrame = pole.CFrame * CFrame.new(0, 4, -2)
		flag.Parent = model
	else
		warn("Failed to create goal geometry:", result)
		basePart.Parent = model
		if holeCutter then
			holeCutter:Destroy()
		end
	end
end

-- ステージロード
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
				spawnFan(fanData)
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
task.wait(1)
loadStage(1)
GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)

print("GameManager Updated: Tutorial Ghost Blocks Added")
