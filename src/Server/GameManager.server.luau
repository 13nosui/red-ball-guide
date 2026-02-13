-- src/Server/GameManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

local GameControlEvent = require(Events.GameControlEvent)

-- 設定
local GOAL_POSITION = Vector3.new(0, -2, -20) -- Y=-2 (厚さ4なので表面はY=0)
local START_POSITION = Vector3.new(0, 15, 0)
local BALL_SIZE = 4
local HOLE_SIZE = 5.5
local GOAL_THICKNESS = 4
local GOAL_WIDTH = 12

-- 状態
local currentBall = nil
local isGoalLocked = false

-- ■ 地面生成関数（4分割法）
-- Baseplateをくり抜くのではなく、ゴールの周囲に4つのパーツを配置して「隙間」を作る
local function createFloorWithGap(gapPosition, gapSize)
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	-- 既存の分割地面があれば削除
	local oldFloor = workspace:FindFirstChild("GeneratedFloor")
	if oldFloor then
		oldFloor:Destroy()
	end

	local floorModel = Instance.new("Model")
	floorModel.Name = "GeneratedFloor"

	local WORLD_SIZE = 2048
	local FLOOR_THICKNESS = 4
	local Y_POS = -2 -- 表面が0になるように

	-- グリッドテクスチャの設定関数
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

	-- 隙間（ゴール）の中心座標
	local gx, gz = gapPosition.X, gapPosition.Z
	local gw, gd = gapSize.X, gapSize.Z

	-- 4つのエリアを計算して配置
	-- 1. 北側 (奥: -Z方向)
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

	-- 2. 南側 (手前: +Z方向)
	local southSizeZ = (WORLD_SIZE / 2) - (math.abs(gz) + gd / 2) -- 簡易計算（中心が0付近前提）
	-- 正確には (1024 - (gz + gd/2))
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

	-- 3. 西側 (左: -X方向)
	-- Zの範囲はゴールのZ幅分だけ埋める
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

	-- 4. 東側 (右: +X方向)
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

-- ■ ゴール生成関数
local function spawnGoal()
	local existingGoal = workspace:FindFirstChild("GoalModel")
	if existingGoal then
		existingGoal:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "GoalModel"
	model.Parent = workspace

	-- 0. 地面を再生成して、ゴールの場所に物理的な穴（隙間）を作る
	createFloorWithGap(GOAL_POSITION, Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, GOAL_WIDTH))

	-- 1. ゴールの土台（芝生）
	local basePart = Instance.new("Part")
	basePart.Name = "Base"
	basePart.Size = Vector3.new(GOAL_WIDTH, GOAL_THICKNESS, GOAL_WIDTH)
	basePart.CFrame = CFrame.new(GOAL_POSITION)
	basePart.Color = Palette.Entity.GoalBase
	basePart.Material = Enum.Material.Grass
	basePart.Anchored = true
	basePart.Parent = workspace -- 計算用にWorkspaceへ

	-- 2. 穴あけ用パーツ
	local holeCutter = Instance.new("Part")
	holeCutter.Name = "Cutter"
	holeCutter.Shape = Enum.PartType.Cylinder
	holeCutter.CFrame = basePart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	holeCutter.Size = Vector3.new(GOAL_THICKNESS * 2, HOLE_SIZE, HOLE_SIZE)
	holeCutter.Parent = workspace

	-- 3. CSG実行（小さなパーツ同士なら成功しやすい）
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

-- Baseplateを削除して床を作り直すため、EnvironmentSetupの直後に走るようにする
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

print("GameManager Updated: Replaced Baseplate with Gap-Floor System")
