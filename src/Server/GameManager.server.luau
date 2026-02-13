-- src/Server/GameManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

local GameControlEvent = require(Events.GameControlEvent)

-- 設定
local START_POSITION = Vector3.new(0, 15, 0)
local GOAL_POSITION = Vector3.new(0, 0, -20) -- ゴール位置（手前奥側）
local BALL_SIZE = 4
local HOLE_SIZE = 5.5 -- ボールより少し大きく

-- 状態
local currentBall = nil
local isGoalLocked = false -- 連続ゴール判定防止用

-- ■ ゴール生成関数 (CSGを使用)
local function spawnGoal()
	local existingGoal = workspace:FindFirstChild("GoalModel")
	if existingGoal then
		existingGoal:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "GoalModel"

	-- 1. 土台（ベース）を作成
	local basePart = Instance.new("Part")
	basePart.Name = "Base"
	basePart.Size = Vector3.new(12, 2, 12)
	basePart.CFrame = CFrame.new(GOAL_POSITION)
	basePart.Color = Palette.Entity.GoalBase
	basePart.Material = Enum.Material.Grass
	basePart.Anchored = true

	-- 2. 穴あけ用のパーツ（ネガティブパーツ）
	local holeCutter = Instance.new("Part")
	holeCutter.Name = "Cutter"
	holeCutter.Shape = Enum.PartType.Cylinder
	-- Cylinderは横向きがデフォルトなので回転させる
	holeCutter.CFrame = basePart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	holeCutter.Size = Vector3.new(4, HOLE_SIZE, HOLE_SIZE) -- 高さ(X), 直径(Y), 直径(Z)

	-- 3. CSG実行（土台 - カッター）
	local success, unionGoal = pcall(function()
		return basePart:SubtractAsync({ holeCutter }, Enum.CollisionFidelity.PreciseConvexDecomposition)
	end)

	if success and unionGoal then
		unionGoal.Name = "GoalCup"
		unionGoal.Anchored = true
		unionGoal.Parent = model

		-- 元のパーツは不要なので破棄（SubtractAsyncは新しいパーツを返すため）
		basePart:Destroy()
		holeCutter:Destroy()

		-- 4. 判定センサー（穴の底）
		local sensor = Instance.new("Part")
		sensor.Name = "WinSensor"
		sensor.Size = Vector3.new(HOLE_SIZE * 0.8, 0.5, HOLE_SIZE * 0.8)
		sensor.Shape = Enum.PartType.Cylinder
		-- 穴の底より少し上に配置
		sensor.CFrame = unionGoal.CFrame * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(-0.5, 0, 0)
		sensor.Transparency = 1
		sensor.CanCollide = false
		sensor.Anchored = true
		sensor.Parent = model

		-- ゴール判定イベント
		sensor.Touched:Connect(function(hit)
			if hit.Name == "RedBall" and not isGoalLocked then
				isGoalLocked = true
				print("🎉 GOAL! Stage Cleared!")

				-- 演出：ボールを消して少し待ってからリセット
				task.wait(1.5)
				resetGame()
			end
		end)

		-- 5. 旗とポール（見た目）
		local pole = Instance.new("Part")
		pole.Name = "Pole"
		pole.Size = Vector3.new(0.4, 12, 0.4)
		pole.Shape = Enum.PartType.Cylinder
		pole.Color = Palette.Entity.GoalPole
		pole.Anchored = true
		pole.CanCollide = false
		-- 穴の後ろ側に立てる
		pole.CFrame = unionGoal.CFrame * CFrame.new(0, 5, -4)
		pole.Parent = model

		local flag = Instance.new("Part")
		flag.Name = "Flag"
		flag.Size = Vector3.new(0.2, 3, 4)
		flag.Color = Palette.Entity.GoalFlag
		flag.Anchored = true
		flag.CanCollide = false
		flag.CFrame = pole.CFrame * CFrame.new(0, 4, -2) -- ポールの上の方
		flag.Parent = model
	else
		warn("Failed to create goal geometry")
		basePart.Parent = model -- 失敗時は穴なし土台を表示
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

	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5) -- 弾み具合調整
	ball.Parent = workspace

	currentBall = ball
	return ball
end

-- ゲーム開始
local function startGame()
	if currentBall then
		currentBall.Anchored = false
		isGoalLocked = false -- ゴール判定有効化
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
spawnGoal() -- ゴール設置
spawnBall()

-- イベント接続
GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)

print("GameManager Initialized (with Goal Hole)")
