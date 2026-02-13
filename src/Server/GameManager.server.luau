-- src/Server/GameManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

local GameControlEvent = require(Events.GameControlEvent)
-- 新しいイベントを追加
local UpdateStageEvent = require(Events.UpdateStageEvent)

-- ■ ステージデータ定義
-- ここに各ステージの構成を記述します
local STAGE_DATA = {
	[1] = {
		Start = Vector3.new(0, 15, 0),
		Goal = Vector3.new(0, -2, -20),
	},
	[2] = {
		Start = Vector3.new(0, 15, 0),
		Goal = Vector3.new(20, -2, -20), -- 右奥へ
	},
	[3] = {
		Start = Vector3.new(-10, 20, 10),
		Goal = Vector3.new(10, -2, -30), -- 高低差と距離
	},
}

-- 設定定数
local BALL_SIZE = 4
local HOLE_SIZE = 5.5
local GOAL_THICKNESS = 4
local GOAL_WIDTH = 12

-- 状態変数
local currentStageIndex = 1
local currentBall = nil
local isGoalLocked = false

-- 現在のステージ設定（初期値はステージ1）
local currentStartPos = STAGE_DATA[1].Start
local currentGoalPos = STAGE_DATA[1].Goal

-- 前方宣言
local spawnBall
local resetGame
local startGame
local loadStage
local clearUserBlocks

-- ■ 1. ユーザーが配置したブロックを消去する関数
clearUserBlocks = function()
	local folder = workspace:FindFirstChild("PlacedBlocks")
	if folder then
		folder:ClearAllChildren()
	end
end

-- ■ 2. 地面生成関数（穴の位置を動的に変更）
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

	-- 北側
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

	-- 南側
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

	-- 西側
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

	-- 東側
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

-- ■ 3. ボール生成
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
	ball.Position = currentStartPos -- 現在のステージ設定を使用
	ball.Anchored = true
	ball.CanCollide = true
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.1)
	ball.Parent = workspace

	currentBall = ball
	return ball
end

-- ■ 4. ゴール生成
local function spawnGoal()
	local existingGoal = workspace:FindFirstChild("GoalModel")
	if existingGoal then
		existingGoal:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "GoalModel"
	model.Parent = workspace

	-- 床の再生成（現在のゴール位置に合わせて穴を開ける）
	createFloorWithGap(currentGoalPos, Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, GOAL_WIDTH))

	-- ゴール土台
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

		-- カップの底
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

		-- 判定センサー
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
				print("🎉 GOAL! Stage " .. currentStageIndex .. " Cleared!")

				-- 少し待ってから次のステージへ
				task.wait(2)

				-- ステージを進める
				currentStageIndex = currentStageIndex + 1
				if currentStageIndex > #STAGE_DATA then
					currentStageIndex = 1 -- 最後まで行ったら最初に戻る（ループ）
					print("All stages cleared! Loop back to 1.")
				end

				loadStage(currentStageIndex)
			end
		end)

		-- 旗とポール
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

-- ■ 5. ステージロード関数
loadStage = function(index)
	isGoalLocked = false
	currentStageIndex = index

	local data = STAGE_DATA[index]
	if data then
		currentStartPos = data.Start
		currentGoalPos = data.Goal

		print("Loading Stage " .. index)

		-- ユーザーのブロックを消す（新しいパズルにするため）
		clearUserBlocks()

		-- ゴールとボールを再配置
		spawnGoal()
		spawnBall()

		-- クライアントにステージ番号更新を通知
		UpdateStageEvent:FireAllClients(index)
	end
end

-- ■ 6. ゲームフロー制御
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
	-- リセット時は現在のステージを再ロードする（ブロックは消さない方が親切かもしれないが、今回は配置を戻す）
	-- ※ 仕様書では「配置したブロックはそのまま維持」とあるので、loadStageではなくspawnBallのみ行うのが正しい

	isGoalLocked = false
	spawnBall() -- ボールだけ戻す
	print("Game Reset (Ball only)")
end

-- 初期化
task.wait(1)
loadStage(1) -- 最初はステージ1をロード

GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)

print("GameManager Updated: Stage Progression System Implemented")
