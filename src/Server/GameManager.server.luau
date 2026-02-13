loadStage = function(index)
	isGoalLocked = false
	currentStageIndex = index
	for _, zone in ipairs(activeWindZones) do
		if zone.Part and zone.Part.Parent and zone.Part.Parent.Parent then
			zone.Part.Parent:Destroy()
		end
	end
	activeWindZones = {}
	local data = STAGE_DATA[index]
	if data then
		currentStartPos = data.Start
		currentGoalPos = data.Goal
		print("Loading Stage " .. index)
		clearUserBlocks()
		spawnGoal()
		spawnBall()
		if data.Fans then
			for _, fanData in ipairs(data.Fans) do
				spawnFan(fanData)
			end
		end
		UpdateStageEvent:FireAllClients(index, data)
	end
end
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
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	local data = STAGE_DATA[currentStageIndex]
	if data then
		UpdateStageEvent:FireClient(player, currentStageIndex, data)
	end
end)
task.wait(1)
loadStage(1)
GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)
print("GameManager Updated: CanQuery False for Sensors")
loadStage = function(index)
	isGoalLocked = false
	currentStageIndex = index
	for _, zone in ipairs(activeWindZones) do
		if zone.Part and zone.Part.Parent and zone.Part.Parent.Parent then
			zone.Part.Parent:Destroy()
		end
	end
	activeWindZones = {}
	local data = STAGE_DATA[index]
	if data then
		currentStartPos = data.Start
		currentGoalPos = data.Goal
		print("Loading Stage " .. index)
		clearUserBlocks()
		spawnGoal()
		spawnBall()
		if data.Fans then
			for _, fanData in ipairs(data.Fans) do
				spawnFan(fanData)
			end
		end
		UpdateStageEvent:FireAllClients(index, data)
	end
end

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

Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	local data = STAGE_DATA[currentStageIndex]
	if data then
		UpdateStageEvent:FireClient(player, currentStageIndex, data)
	end
end)

task.wait(1)
loadStage(1)

GameControlEvent.OnServerEvent:Connect(function(player, action)
	if action == "start" then
		startGame()
	elseif action == "reset" then
		resetGame()
	end
end)

print("GameManager Updated: Texture Alignment Fix")
