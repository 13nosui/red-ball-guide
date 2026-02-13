-- src/Server/GameManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared:WaitForChild("Palette"))

-- イベント取得（なければ待機）
local GameControlEvent = ReplicatedStorage:WaitForChild("GameControlEvent", 10)
if not GameControlEvent then
	-- イベントファイルがまだ読み込まれていない場合のフォールバック（通常はModule経由で生成されるため不要だが安全策）
	GameControlEvent = Instance.new("RemoteEvent")
	GameControlEvent.Name = "GameControlEvent"
	GameControlEvent.Parent = ReplicatedStorage
end

-- 設定
local START_POSITION = Vector3.new(0, 15, 0) -- 開始位置（高さ15）
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
	ball.Anchored = true -- 初期状態は固定
	ball.CanCollide = true
	ball.Restitution = 0.8 -- 少し弾む
	ball.Parent = workspace

	currentBall = ball
	return ball
end

-- ゲーム開始（物理演算有効化）
local function startGame()
	if currentBall then
		currentBall.Anchored = false
		print("Game Started: Ball physics enabled")
	end
end

-- ゲームリセット（位置戻し・固定）
local function resetGame()
	if currentBall then
		currentBall.Anchored = true
		currentBall.Position = START_POSITION
		currentBall.AssemblyLinearVelocity = Vector3.zero
		currentBall.AssemblyAngularVelocity = Vector3.zero
		print("Game Reset: Ball returned to start")
	else
		spawnBall()
	end
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

print("GameManager Initialized")
