-- src/Shared/Events/GameControlEvent.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eventName = "GameControlEvent"
local gameControlEvent = ReplicatedStorage:FindFirstChild(eventName)

if not gameControlEvent then
	gameControlEvent = Instance.new("RemoteEvent")
	gameControlEvent.Name = eventName
	gameControlEvent.Parent = ReplicatedStorage
end

return gameControlEvent
