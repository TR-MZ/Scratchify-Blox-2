local Environment = {}

-- Constants ----------------------------------------------------------------
local LOCAL_RUNNER_SBR = [[
-- scratchify blox runner for local player.
if plugin then return end

local Remote = game.ReplicatedStorage:WaitForChild("remote.sbr") 


local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		Remote:FireServer("Input", input.KeyCode.Name)
	else
		--	Remote:FireServer("Input", input.UserInputType.Name)
	end
end)

Remote.OnClientInvoke = function(e, ...)
	local module = game.ReplicatedStorage:FindFirstChild(e)
	if module then
		require(module).new(...) 
	end
end]]



-- Functions ----------------------------------------------------------------

function Environment:Setup() 
    CheckForRemoteSBR()
	CheckForLocalRunnerSBR()
	CheckForReplicatedVariables()
end

-- Remote.sbr is a RemoteEvent that is used to communicate between the server and the client for scripts.
function CheckForRemoteSBR()
    local container = game.ReplicatedStorage:FindFirstChild("ScratchifyBloxEnvironment")
    local remote = container and game.ReplicatedStorage.ScratchifyBloxEnvironment:FindFirstChild("remote.sbr") or nil

    if not remote or not remote:IsA("RemoteFunction") then
		
		if remote then remote:Destroy() end
		
        container = container or Instance.new('Folder', game.ReplicatedStorage)
        container.Name = "ScratchifyBloxEnvironment"

        remote = Instance.new('RemoteEvent', container)
        remote.Name = "remote.sbr"
    end

    remote:GetPropertyChangedSignal("Parent"):Connect(function()
        if remote.Parent ~= container then
            remote.Parent = container
        end
    end)
end

-- locaalrunner.sbr is a LocalScript that is used to sync user interactions with the server.
function CheckForLocalRunnerSBR()
    local container = game.StarterPlayer.StarterPlayerScripts:FindFirstChild("ScratchifyBloxEnvironment")
    local localrunner = container and game.StarterPlayer.StarterPlayerScripts.ScratchifyBloxEnvironment:FindFirstChild("localrunner.sbr") or nil

    if not localrunner then

        container = container or Instance.new('Folder', game.StarterPlayer.StarterPlayerScripts)
        container.Name = "ScratchifyBloxEnvironment"

        localrunner = Instance.new('LocalScript', container)
        localrunner.Source = LOCAL_RUNNER_SBR
        localrunner.Name = "localrunner.sbr"
    end

    localrunner:GetPropertyChangedSignal("Parent"):Connect(function()
        if localrunner.Parent ~= container then
            localrunner.Parent = container
        end
    end)
end

function CheckForReplicatedVariables ()
	local container = game.ReplicatedStorage:FindFirstChild("ScratchifyBloxEnvironment")
	local ReplicatedVariables = container and container:FindFirstChild("ReplicatedVariables") or nil
	
	if not ReplicatedVariables then
		container = container or Instance.new('Folder', game.ReplicatedStorage)
		container.Name = "ScratchifyBloxEnvironment"
		
		ReplicatedVariables = script.Parent.Assets.ReplicatedVariables:Clone()
		ReplicatedVariables.Parent = container
	end

	ReplicatedVariables:GetPropertyChangedSignal("Parent"):Connect(function()
		if ReplicatedVariables.Parent ~= container then
			ReplicatedVariables.Parent = container
		end
	end)
	
	
	container = game.ServerScriptService:FindFirstChild("ScratchifyBloxEnvironment")
	local ServerReplicator = container and container:FindFirstChild("ServerReplicator") or nil

	if not ServerReplicator then
		container = container or Instance.new('Folder', game.ServerScriptService)
		container.Name = "ScratchifyBloxEnvironment"

		ServerReplicator = script.Parent.Assets.ServerReplicator:Clone()
		ServerReplicator.Parent = container
	end
	
	ServerReplicator.Enabled = true

	ReplicatedVariables:GetPropertyChangedSignal("Parent"):Connect(function()
		if ReplicatedVariables.Parent ~= container then
			ReplicatedVariables.Parent = container
		end
	end)
end


return Environment