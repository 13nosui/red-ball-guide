-- src/Client/GameController.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- イベント取得
local GameControlEvent = ReplicatedStorage:WaitForChild("GameControlEvent")

-- UI取得（UISetupで作成されたボタンを探す）
local screenGui = playerGui:WaitForChild("ScreenGui", 10)
if not screenGui then
	return
end

local editFrame = screenGui:WaitForChild("EditFrame")
local actionPanel = editFrame:WaitForChild("ActionPanel")

local btnStart = actionPanel:WaitForChild("ButtonStart")
local btnReset = actionPanel:WaitForChild("ButtonReset")

-- ボタンイベント接続
btnStart.MouseButton1Click:Connect(function()
	GameControlEvent:FireServer("start")
	print("Start button pressed")
end)

btnReset.MouseButton1Click:Connect(function()
	GameControlEvent:FireServer("reset")
	print("Reset button pressed")
end)

print("GameController Loaded")
