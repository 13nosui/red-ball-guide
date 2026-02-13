-- src/Shared/Events/UpdateStageEvent.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eventName = "UpdateStageEvent"
local event = ReplicatedStorage:FindFirstChild(eventName)

if not event then
	event = Instance.new("RemoteEvent")
	event.Name = eventName
	event.Parent = ReplicatedStorage
end

return event
