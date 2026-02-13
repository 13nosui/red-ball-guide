-- src/Client/VisualEffectController.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")

local UpdateStageEvent = require(Events:WaitForChild("UpdateStageEvent"))

local guideFolder = workspace:FindFirstChild("GuidePath") or Instance.new("Folder")
guideFolder.Name = "GuidePath"
guideFolder.Parent = workspace

local function createDottedLine(startPos, endPos)
	local distance = (endPos - startPos).Magnitude
	local direction = (endPos - startPos).Unit
	local segmentLength = 2
	local gapLength = 1.5
	local step = segmentLength + gapLength

	for i = 0, distance, step do
		-- 残りの距離がセグメントより短い場合はそこで止める
		local actualLen = math.min(segmentLength, distance - i)
		if actualLen <= 0 then
			break
		end

		local part = Instance.new("Part")
		part.Name = "GuideDot"
		part.Size = Vector3.new(0.4, 0.4, actualLen)
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(100, 255, 255) -- シアン色の光る線

		-- 位置計算: スタートからi + 半分の長さ進んだところ
		local centerPos = startPos + direction * (i + actualLen / 2)
		part.CFrame = CFrame.new(centerPos, endPos)
		part.Parent = guideFolder
	end
end

local function drawGuidePath(stageData)
	guideFolder:ClearAllChildren()

	if not stageData or not stageData.Waypoints then
		return
	end

	-- 全ポイントをリスト化: [Start, ...Waypoints, Goal]
	local points = { stageData.Start }
	for _, wp in ipairs(stageData.Waypoints) do
		table.insert(points, wp)
	end
	-- Goalの少し上を終点にする（ボールの中心座標合わせ）
	table.insert(points, Vector3.new(stageData.Goal.X, 0, stageData.Goal.Z))

	-- 点をつなぐ
	for i = 1, #points - 1 do
		local p1 = points[i]
		local p2 = points[i + 1]
		createDottedLine(p1, p2)
	end

	print("VisualEffectController: Guide Path Drawn")
end

UpdateStageEvent.OnClientEvent:Connect(function(index, data)
	drawGuidePath(data)
end)

print("VisualEffectController Loaded")
