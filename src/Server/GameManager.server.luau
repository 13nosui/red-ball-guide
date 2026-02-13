-- src/Server/GameManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

local GameControlEvent = require(Events.GameControlEvent)
local UpdateStageEvent = require(Events.UpdateStageEvent)

-- 設定
local STAGE_DATA = {
	[1] = {
		-- 直線のみ
		Start = Vector3.new(0, 15, 0),
		Goal = Vector3.new(0, -2, -20),
		Waypoints = {
			Vector3.new(0, 15, 0), -- 始点
			Vector3.new(0, 2, 0), -- 着地地点
			Vector3.new(0, 2, -20), -- 直進
		},
	},
	[2] = {
		-- 右に90度曲がるルート (Wedgeで反射させる想定)
		Start = Vector3.new(0, 15, 0),
		Goal = Vector3.new(20, -2, -20),
		Waypoints = {
			Vector3.new(0, 15, 0), -- 始点
			Vector3.new(0, 2, 0), -- 着地
			Vector3.new(0, 2, -20), -- 直進して...
			Vector3.new(20, 2, -20), -- ここで右に曲がる（角にWedgeを置くヒント）
		},
	},
	[3] = {
		-- 2回曲がる複雑なルート
		Start = Vector3.new(-10, 20, 10),
		Goal = Vector3.new(10, -2, -30),
		Waypoints = {
			Vector3.new(-10, 20, 10), -- 始点
			Vector3.new(-10, 2, 10), -- 着地
			Vector3.new(10, 2, 10), -- 右へ（1回目の反射）
			Vector3.new(10, 2, -30), -- 奥へ（2回目の反射）
		},
	},
}

local BALL_SIZE = 4
local HOLE_SIZE = 5.5
local GOAL_THICKNESS = 4
local GOAL_WIDTH = 12
local MAGNET_RADIUS = HOLE_SIZE * 1.5
local MAX_CAPTURE_SPEED = 40

-- 状態
local currentStageIndex = 1
local currentBall = nil
local isGoalLocked = false
local currentStartPos = STAGE_DATA[1].Start
local currentGoalPos = STAGE_DATA[1].Goal

-- 前方宣言
local spawnBall
local resetGame
local startGame
local loadStage
local clearUserBlocks

-- ■ ゴール吸い込み
local function captureBallIntoHole(ball, cupCenterPosition)
	if isGoalLocked then
		return
	end
	isGoalLocked = true

	ball.Anchored = true
	ball.CanCollide = false
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero

	print("✨ AI Assist: Capturing ball into goal...")

	local overHolePos = Vector3.new(cupCenterPosition.X, ball.Position.Y, cupCenterPosition.Z)
	local tween1 = TweenService:Create(ball, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = overHolePos,
	})
	tween1:Play()
	tween1.Completed:Wait()

	local bottomPos = cupCenterPosition + Vector3.new(0, -2, 0)
	local tween2 = TweenService:Create(ball, TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
		Position = bottomPos,
	})
	tween2:Play()
	tween2.Completed:Wait()

	print("🎉 GOAL! Stage " .. currentStageIndex .. " Cleared!")
	task.wait(1.5)

	currentStageIndex = currentStageIndex + 1
	if currentStageIndex > #STAGE_DATA then
		currentStageIndex = 1
		print("All stages cleared! Loop back to 1.")
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

-- ■ 地面生成
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
		texture.Name = "GridTexture"
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

	-- 北
	local northSizeZ = (WORLD_SIZE / 2) - (math.abs(gz) + gd / 2)
	local northPosZ = (gz - gd / 2) - northSizeZ / 2
	if northSizeZ > 0 then
		local p = Instance.new("Part")
		p.Name = "FloorNorth"
		p.Size = Vector3.new(WORLD_SIZE, FLOOR_THICKNESS, northSizeZ)
		p.Position = Vector3.new(0, Y_POS, northPosZ)
		p.Anchored = true
		p.Color = Color3.fromRGB(15, 15, 20)
		p.Material = Enum.Material.SmoothPlastic
		addGridTexture(p)
		p.Parent = floorModel
	end

	-- 南
	local southStart = gz + gd / 2
	local southEnd = WORLD_SIZE / 2
	local sSizeZ = southEnd - southStart
	local sPosZ = southStart + sSizeZ / 2
	local pSouth = Instance.new("Part")
	pSouth.Name = "FloorSouth"
	pSouth.Size = Vector3.new(WORLD_SIZE, FLOOR_THICKNESS, sSizeZ)
	pSouth.Position = Vector3.new(0, Y_POS, sPosZ)
	pSouth.Anchored = true
	pSouth.Color = Color3.fromRGB(15, 15, 20)
	pSouth.Material = Enum.Material.SmoothPlastic
	addGridTexture(pSouth)
	pSouth.Parent = floorModel

	-- 西
	local westStart = -WORLD_SIZE / 2
	local westEnd = gx - gw / 2
	local wSizeX = westEnd - westStart
	local wPosX = westStart + wSizeX / 2
	local pWest = Instance.new("Part")
	pWest.Name = "FloorWest"
	pWest.Size = Vector3.new(wSizeX, FLOOR_THICKNESS, gd)
	pWest.Position = Vector3.new(wPosX, Y_POS, gz)
	pWest.Anchored = true
	pWest.Color = Color3.fromRGB(15, 15, 20)
	pWest.Material = Enum.Material.SmoothPlastic
	addGridTexture(pWest)
	pWest.Parent = floorModel

	-- 東
	local eastStart = gx + gw / 2
	local eastEnd = WORLD_SIZE / 2
	local eSizeX = eastEnd - eastStart
	local ePosX = eastStart + eSizeX / 2
	local pEast = Instance.new("Part")
	pEast.Name = "FloorEast"
	pEast.Size = Vector3.new(eSizeX, FLOOR_THICKNESS, gd)
	pEast.Position = Vector3.new(ePosX, Y_POS, gz)
	pEast.Anchored = true
	pEast.Color = Color3.fromRGB(15, 15, 20)
	pEast.Material = Enum.Material.SmoothPlastic
	addGridTexture(pEast)
	pEast.Parent = floorModel

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
			if hit.Name == "RedBall" then
				local velocity = hit.AssemblyLinearVelocity.Magnitude
				if velocity < MAX_CAPTURE_SPEED then
					local goalCenter = Vector3.new(currentGoalPos.X, 0, currentGoalPos.Z)
					captureBallIntoHole(hit, goalCenter)
				end
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

	local data = STAGE_DATA[index]
	if data then
		currentStartPos = data.Start
		currentGoalPos = data.Goal

		print("Loading Stage " .. index)
		clearUserBlocks()
		spawnGoal()
		spawnBall()

		UpdateStageEvent:FireAllClients(index, data)
	end
end

-- ゲームフロー
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

-- 初期化
task.wait(1)
loadStage(1)

GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)

print("GameManager Updated: Waypoints set to 90-degree turns")
