if not game:getService("RunService"):IsRunning() then -- Rojo didn't export the .Enabled = false to the git
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteFunction = ReplicatedStorage.ScratchifyBloxEnvironment:WaitForChild("KeyValueReplicator")
local ServerBindable = ReplicatedStorage.ScratchifyBloxEnvironment:WaitForChild("KeyValueServerBindable")

-- Private server-side key-value store
local store = {}

-- Handle RemoteFunction calls from clients
RemoteFunction.OnServerInvoke = function(player, action, key, value)
	if action == "GET" then
		return store[key]
	elseif action == "SET" then
		store[key] = value
	else
		warn("Invalid action from client:", action)
	end
end

-- Handle BindableFunction calls from server-side scripts
ServerBindable.OnInvoke = function(action, key, value)
	if action == "GET" then
		return store[key]
	elseif action == "SET" then
		store[key] = value
	else
		warn("Invalid action via BindableFunction:", action)
	end
end
