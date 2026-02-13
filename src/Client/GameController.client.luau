-- src/Client/GameController.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = Shared:WaitForChild("Events")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- イベント取得
local GameControlEvent = ReplicatedStorage:WaitForChild("GameControlEvent")
local UpdateStageEvent = require(Events:WaitForChild("UpdateStageEvent"))

-- UI取得
local screenGui = playerGui:WaitForChild("ScreenGui", 10)
if not screenGui then
	return
end

local editFrame = screenGui:WaitForChild("EditFrame")
local actionPanel = editFrame:WaitForChild("ActionPanel")
local headerFrame = editFrame:WaitForChild("HeaderFrame")

local btnStart = actionPanel:WaitForChild("ButtonStart")
local btnReset = actionPanel:WaitForChild("ButtonReset")
local stageLabel = headerFrame:WaitForChild("StageLabel")

-- ボタンイベント
btnStart.MouseButton1Click:Connect(function()
	GameControlEvent:FireServer("start")
	print("Start button pressed")
end)

btnReset.MouseButton1Click:Connect(function()
	GameControlEvent:FireServer("reset")
	print("Reset button pressed")
end)

-- ステージ更新イベント
UpdateStageEvent.OnClientEvent:Connect(function(stageIndex)
	-- ★修正: ここも大文字のSTAGEにする必要があります
	stageLabel.Text = "STAGE: " .. string.format("%02d", stageIndex)
	print("UI Updated to STAGE " .. stageIndex)
end)

print("GameController Loaded with Uppercase STAGE Display")
