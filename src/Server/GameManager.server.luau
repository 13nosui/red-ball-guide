-- src/Server/GameManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

local GameControlEvent = require(Events.GameControlEvent)

-- 設定
local GOAL_POSITION = Vector3.new(0, -2, -20)
local START_POSITION = Vector3.new(0, 15, 0)
local BALL_SIZE = 4
local HOLE_SIZE = 5.5
local GOAL_THICKNESS = 4
local GOAL_WIDTH = 12

-- 状態
local currentBall = nil
local isGoalLocked = false

-- ■ Baseplateの加工処理
local function cutBaseplateForGoal(targetCFrame, size)
	local baseplate = workspace:FindFirstChild("Baseplate")
	if not baseplate then
		return
	end

	if baseplate:IsA("UnionOperation") and baseplate.Name == "BaseplateWithHole" then
		return
	end

	print("Cutting Baseplate to fit goal...")

	local cutter = Instance.new("Part")
	cutter.Name = "BaseplateCutter"
	cutter.Size = Vector3.new(size.X, 20, size.Z)
	cutter.CFrame = targetCFrame
	cutter.Anchored = true
	cutter.Parent = workspace

	local success, result = pcall(function()
		-- ★修正1: Baseplateの穴も精密に計算する
		return baseplate:SubtractAsync({ cutter }, Enum.CollisionFidelity.PreciseConvexDecomposition)
	end)

	if success and result then
		result.Name = "BaseplateWithHole"
		result.Anchored = true
		result.CanCollide = true
		result.Parent = workspace

		for _, child in pairs(baseplate:GetChildren()) do
			if child:IsA("Texture") then
				child.Parent = result
			end
		end

		baseplate:Destroy()
	else
		warn("Failed to cut Baseplate:", result)
	end

	cutter:Destroy()
end

-- ■ ゴール生成関数
local function spawnGoal()
	local existingGoal = workspace:FindFirstChild("GoalModel")
	if existingGoal then
		existingGoal:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "GoalModel"
	model.Parent = workspace

	-- 0. Baseplateに穴を空ける
	cutBaseplateForGoal(CFrame.new(GOAL_POSITION), Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, GOAL_WIDTH))

	-- 1. ゴールの土台
	local basePart = Instance.new("Part")
	basePart.Name = "Base"
	basePart.Size = Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, GOAL_WIDTH)
	basePart.CFrame = CFrame.new(GOAL_POSITION)
	basePart.Color = Palette.Entity.GoalBase
	basePart.Material = Enum.Material.Grass
	basePart.Anchored = true
	basePart.Parent = workspace

	-- 2. 穴あけ用パーツ
	local holeCutter = Instance.new("Part")
	holeCutter.Name = "Cutter"
	holeCutter.Shape = Enum.PartType.Cylinder
	holeCutter.CFrame = basePart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	holeCutter.Size = Vector3.new(GOAL_THICKNESS * 2, HOLE_SIZE, HOLE_SIZE)
	holeCutter.Parent = workspace

	-- 3. CSG実行
	local success, result = pcall(function()
		-- ★修正2: ゴールの穴を精密に計算する (ここが重要)
		return basePart:SubtractAsync({ holeCutter }, Enum.CollisionFidelity.PreciseConvexDecomposition)
	end)

	if success and result then
		local unionGoal = result
		unionGoal.Name = "GoalCup"
		unionGoal.Anchored = true
		unionGoal.Parent = model

		basePart:Destroy()
		holeCutter:Destroy()

		-- 4. カップの底
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

		-- 5. 判定センサー
		local sensor = Instance.new("Part")
		sensor.Name = "WinSensor"
		sensor.Size = Vector3.new(0.5, HOLE_SIZE * 0.8, HOLE_SIZE * 0.8)
		sensor.Shape = Enum.PartType.Cylinder
		sensor.CFrame = cupBottom.CFrame * CFrame.new(0.5, 0, 0)
		sensor.Transparency = 1
		sensor.CanCollide = false
		sensor.Anchored = true
		sensor.Parent = model

		sensor.Touched:Connect(function(hit)
			if hit.Name == "RedBall" and not isGoalLocked then
				isGoalLocked = true
				print("🎉 GOAL! Stage Cleared!")
				task.wait(1.5)
				resetGame()
			end
		end)

		-- 6. 旗とポール
		local pole = Instance.new("Part")
		pole.Name = "Pole"
		pole.Size = Vector3.new(0.4, 12, 0.4)
		pole.Shape = Enum.PartType.Cylinder
		pole.Color = Palette.Entity.GoalPole
		pole.Anchored = true
		pole.CanCollide = false
		pole.CFrame = CFrame.new(GOAL_POSITION.X, 0 + 6, GOAL_POSITION.Z - 4)
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

-- ■ ボール生成
local function spawnBall()
	if currentBall then
		currentBall:Destroy()
	end

	local ball = Instance.new("Part")
	ball.Name = "RedBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(BALL_SIZE, BALL_SIZE, BALL_SIZE)
	ball.Color = Palette.Entity.Ball
	ball.Material = Enum.Material.Plastic
	ball.Position = START_POSITION
	ball.Anchored = true
	ball.CanCollide = true
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.1)
	ball.Parent = workspace

	currentBall = ball
	return ball
end

local function startGame()
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

local function resetGame()
	isGoalLocked = false
	spawnBall()
	print("Game Reset")
end

task.wait(1)
spawnGoal()
spawnBall()

GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)

print("GameManager Updated: Precise Collision for Goal Hole")
