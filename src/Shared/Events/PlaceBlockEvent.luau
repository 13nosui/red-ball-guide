-- src/Shared/Events/PlaceBlockEvent.luau
-- これは単なるフォルダではなく、サーバーとクライアントを繋ぐ「線」の役割を果たします。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- もし既にRemoteEventがあればそれを使い、なければ新しく作る
local placeBlockEvent = ReplicatedStorage:FindFirstChild("PlaceBlockEvent")

if not placeBlockEvent then
	placeBlockEvent = Instance.new("RemoteEvent")
	placeBlockEvent.Name = "PlaceBlockEvent"
	placeBlockEvent.Parent = ReplicatedStorage
end

return placeBlockEvent
