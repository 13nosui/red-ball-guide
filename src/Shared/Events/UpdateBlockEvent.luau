-- src/Shared/Events/UpdateBlockEvent.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local updateBlockEvent = ReplicatedStorage:FindFirstChild("UpdateBlockEvent")

if not updateBlockEvent then
	updateBlockEvent = Instance.new("RemoteEvent")
	updateBlockEvent.Name = "UpdateBlockEvent"
	updateBlockEvent.Parent = ReplicatedStorage
end

return updateBlockEvent
