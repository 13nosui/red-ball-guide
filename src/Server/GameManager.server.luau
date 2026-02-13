-- src/Server/GameManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

local GameControlEvent = require(Events.GameControlEvent)

-- 設定
local GOAL_POSITION = Vector3.new(0, 3, -20)
local START_POSITION = Vector3.new(0, 15, 0)
local BALL_SIZE = 4
local HOLE_SIZE = 5.5

-- 状態
local currentBall = nil
local isGoalLocked = false

-- ■ ゴール生成関数
local function spawnGoal()
	local existingGoal = workspace:FindFirstChild("GoalModel")
	if existingGoal then
		existingGoal:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "GoalModel"

	-- 1. 土台（ベース）
	local basePart = Instance.new("Part")
	basePart.Name = "Base"
	basePart.Size = Vector3.new(12, 6, 12)
	basePart.CFrame = CFrame.new(GOAL_POSITION)
	basePart.Color = Palette.Entity.GoalBase
	basePart.Material = Enum.Material.Grass
	basePart.Anchored = true

	-- 2. 穴あけ用パーツ
	local holeCutter = Instance.new("Part")
	holeCutter.Name = "Cutter"
	holeCutter.Shape = Enum.PartType.Cylinder
	holeCutter.CFrame = basePart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	holeCutter.Size = Vector3.new(8, HOLE_SIZE, HOLE_SIZE)

	-- 3. CSG実行
	local success, unionGoal = pcall(function()
		return basePart:SubtractAsync({ holeCutter }, Enum.CollisionFidelity.PreciseConvexDecomposition)
	end)

	if success and unionGoal then
		unionGoal.Name = "GoalCup"
		unionGoal.Anchored = true
		unionGoal.Parent = model

		basePart:Destroy()
		holeCutter:Destroy()

		-- ★追加: 視覚的なカップの底
		local cupBottom = Instance.new("Part")
		cupBottom.Name = "CupBottom"
		cupBottom.Shape = Enum.PartType.Cylinder
		cupBottom.Size = Vector3.new(0.2, HOLE_SIZE * 0.95, HOLE_SIZE * 0.95) -- 薄い円柱
		cupBottom.Color = Palette.Entity.GoalCup -- 暗い色
		cupBottom.Material = Enum.Material.Plastic
		cupBottom.Anchored = true
		cupBottom.CanCollide = true -- ボールが乗るように
		-- ゴールの中央下部に配置 (高さ3の半分である-1.5の位置)
		cupBottom.CFrame = unionGoal.CFrame * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(-1.5, 0, 0)
		cupBottom.Parent = model

		-- 4. 判定センサー（カップ底の少し上）
		local sensor = Instance.new("Part")
		sensor.Name = "WinSensor"
		sensor.Size = Vector3.new(0.5, HOLE_SIZE * 0.8, HOLE_SIZE * 0.8)
		sensor.Shape = Enum.PartType.Cylinder
		-- カップ底の少し上に配置
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

		-- 5. 旗とポール
		local pole = Instance.new("Part")
		pole.Name = "Pole"
		pole.Size = Vector3.new(0.4, 12, 0.4)
		pole.Shape = Enum.PartType.Cylinder
		pole.Color = Palette.Entity.GoalPole
		pole.Anchored = true
		pole.CanCollide = false
		pole.CFrame = unionGoal.CFrame * CFrame.new(0, 5, -4)
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
		warn("Failed to create goal geometry")
		basePart.Parent = model
	end

	model.Parent = workspace
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

-- ゲーム開始
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

-- ゲームリセット
local function resetGame()
	isGoalLocked = false
	spawnBall()
	print("Game Reset")
end

-- 初期化
spawnGoal()
spawnBall()

-- イベント接続
GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)

print("GameManager Updated: Goal Cup Visual Added")
