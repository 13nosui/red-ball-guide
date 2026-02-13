-- src/Server/GameManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

-- 修正点1: WaitForChildではなく、モジュールを直接requireしてイベントを即座に確保する
local GameControlEvent = require(Events.GameControlEvent)

-- 設定
local START_POSITION = Vector3.new(0, 15, 0)
local BALL_SIZE = 4

-- ボールの参照
local currentBall = nil

-- ボール生成関数
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

	-- 修正点2: RestitutionではなくCustomPhysicalPropertiesを使用する
	-- PhysicalProperties.new(Density, Friction, Elasticity)
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.8)

	ball.Parent = workspace

	currentBall = ball
	return ball
end

-- ゲーム開始
local function startGame()
	if currentBall then
		currentBall.Anchored = false
		print("Game Started: Ball physics enabled")
	else
		-- ボールがない場合は生成してからスタート
		spawnBall()
		currentBall.Anchored = false
	end
end

-- ゲームリセット
local function resetGame()
	spawnBall() -- 作り直して初期位置へ
	print("Game Reset: Ball returned to start")
end

-- 初期化
spawnBall()

-- イベント接続
GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)

print("GameManager Initialized (Fixed)")
