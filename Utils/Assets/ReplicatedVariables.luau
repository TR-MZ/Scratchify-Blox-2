local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

-- RemoteFunction for client-server communication
local RemoteFunction = script.Parent:FindFirstChild("KeyValueReplicator")
if not RemoteFunction then
	if IS_SERVER then
		RemoteFunction = Instance.new("RemoteFunction")
		RemoteFunction.Name = "KeyValueReplicator"
		RemoteFunction.Parent = script.Parent
	else
		RemoteFunction = script.Parent:WaitForChild("KeyValueReplicator")
	end
end

-- BindableFunction for server-side access
local ServerBindable
if IS_SERVER then
	ServerBindable = Instance.new("BindableFunction")
	ServerBindable.Name = "KeyValueServerBindable"
	ServerBindable.Parent = script.Parent
end

local ReplicatedKeyValueStore = {}

function ReplicatedKeyValueStore:Get(key)
	if IS_SERVER then
		-- Call the local server bindable for synchronous access
		return ServerBindable:Invoke("GET", key )
	else
		-- Ask server via RemoteFunction
		return RemoteFunction:InvokeServer("GET", key)
	end
end

function ReplicatedKeyValueStore:Set(key, value)
	if IS_SERVER then
		-- Call the local server bindable for synchronous access
		ServerBindable:Invoke("SET", key, value)
	else
		-- Ask server via RemoteFunction
		RemoteFunction:InvokeServer("SET", key, value)
	end
end

return ReplicatedKeyValueStore
