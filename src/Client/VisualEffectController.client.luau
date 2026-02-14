-- src/Client/VisualEffectController.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")
local Palette = require(Shared:WaitForChild("Palette"))

local UpdateStageEvent = require(Events:WaitForChild("UpdateStageEvent"))

local guideFolder = workspace:FindFirstChild("GuidePath") or Instance.new("Folder")
guideFolder.Name = "GuidePath"
guideFolder.Parent = workspace

local tutorialFolder = workspace:FindFirstChild("TutorialGhosts") or Instance.new("Folder")
tutorialFolder.Name = "TutorialGhosts"
tutorialFolder.Parent = workspace

local function createDottedLine(startPos, endPos)
	local distance = (endPos - startPos).Magnitude
	local direction = (endPos - startPos).Unit
	local segmentLength = 2
	local gapLength = 1.5
	local step = segmentLength + gapLength

	for i = 0, distance, step do
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
		part.CanQuery = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(100, 255, 255)
		part.CFrame = CFrame.new(startPos + direction * (i + actualLen / 2), endPos)
		part.Parent = guideFolder
	end
end

local function drawGuidePath(stageData)
	guideFolder:ClearAllChildren()
	if not stageData or not stageData.Waypoints then
		return
	end
	local points = { stageData.Start }
	for _, wp in ipairs(stageData.Waypoints) do
		table.insert(points, wp)
	end
	table.insert(points, Vector3.new(stageData.Goal.X, 0, stageData.Goal.Z))
	for i = 1, #points - 1 do
		createDottedLine(points[i], points[i + 1])
	end
	print("VisualEffectController: Guide Path Drawn")
end

local function drawTutorialGhosts(stageData)
	tutorialFolder:ClearAllChildren()

	if not stageData or not stageData.TutorialBlocks then
		return
	end

	for _, blockInfo in ipairs(stageData.TutorialBlocks) do
		local part
		local bType = blockInfo.Type

		if bType == "Block" then
			part = Instance.new("Part")
			part.Shape = Enum.PartType.Block
		elseif bType == "Sphere" then
			part = Instance.new("Part")
			part.Shape = Enum.PartType.Ball
		elseif bType == "Wedge" then
			part = Instance.new("WedgePart")
		elseif bType == "CornerWedge" then
			part = Instance.new("CornerWedgePart")
		elseif bType == "Cylinder" then
			part = Instance.new("Part")
			part.Shape = Enum.PartType.Cylinder
			part.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(90))
		end

		if part then
			part.Size = Vector3.new(4, 4, 4)
			part.Material = Enum.Material.Plastic

			if Palette.BlockColors and Palette.BlockColors[bType] then
				part.Color = Palette.BlockColors[bType]
			else
				part.Color = Color3.new(0.8, 0.8, 0.8)
			end

			-- ★修正: 透明度を固定しアニメーションさせない
			part.Transparency = 0.4
			part.Anchored = true
			part.CanCollide = false
			part.CastShadow = false
			part.CanQuery = false

			local rot = blockInfo.Rotation
			part.CFrame = CFrame.new(blockInfo.Position)
				* CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))

			local highlight = Instance.new("Highlight")
			highlight.FillColor = part.Color
			highlight.OutlineColor = Color3.new(1, 1, 1)
			-- ★修正: 塗りつぶしも固定
			highlight.FillTransparency = 0.6
			highlight.OutlineTransparency = 0
			highlight.Parent = part

			-- ※ アニメーション処理(Tween)は削除しました

			part.Parent = tutorialFolder
		end
	end

	if #stageData.TutorialBlocks > 0 then
		print("VisualEffectController: Tutorial Ghosts Drawn (Static)")
	end
end

UpdateStageEvent.OnClientEvent:Connect(function(index, data)
	drawGuidePath(data)
	drawTutorialGhosts(data)
end)

print("VisualEffectController Loaded with Static Ghosts")
