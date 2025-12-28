-- Ignore the name of this file
-- It is NOT a test file
-- This is the file that manages saving / load for the plugin
local DataManager = {}

-- Types ----------------------------



type BlockSaveData = {
	blockData: BlockData,
	replacedValues: {BlockSaveData}, -- ValueContainers containing value blocks
	child: {[string] : BlockSaveData},
	color : {r: number, g: number, b: number},
	position: {
		x: number,
		y: number,
	},
}

-- Modules --------------------------- 

local BlockFactory, VariableManager

-- Services ---------------------------

local HttpService = game:GetService("HttpService")

-- Variables --------------------------

-- Constants --------------------------

local SAVE_FILE_NAME = "save.sbsv3" 
local RUNNER_FILE_NAME = "runner.sbsv3" 

-- Functions --------------------------

--- Wraps a given string safely using Lua long bracket syntax ([[ ]], [=[ ]=], etc.).
-- The function detects any occurrences of ']=]' in the string and adjusts
-- the number of '=' signs used in the long brackets to avoid conflicts.
--
-- @param str string The string to be safely wrapped in long brackets.
-- @return string The given string wrapped in properly escaped long brackets.
local function SafeLongBraked(str) 
	-- Find the max number of consecutive '=' signs inside any ']=' sequence
	local max_equals = 0
	for eqs in str:gmatch("%](=*)%]") do
		local count = #eqs
		if count >= max_equals then
			max_equals = count + 1
		end
	end

	-- Build the delimiter with the right number of '=' signs
	local delimiter = string.rep("=", max_equals)

	-- Wrap the string using the delimiter
	return "[" .. delimiter .. "[" .. str .. "]" .. delimiter .. "]"
end


function DataManager:Init(blockFactory, variableManager)
	BlockFactory = blockFactory
	VariableManager = variableManager
end

-- Creates a block save data
-- @param block : BlockClass
-- @return : Dictionary containing the block save data
local function CreateBlockSaveData(block: BlockClass) : {}
	local data = {
		child = {},
		blockData = block.blockData,
		replacedValues = {},
		position = {
			x = block.blockFrame.Position.X.Offset,
			y = block.blockFrame.Position.Y.Offset,
		},
		color = {
			r = math.round(block.color.R * 255),
			g = math.round(block.color.G  * 255),
			b = math.round(block.color.B * 255),
		}
	}

	if block.childBlock then
		data.child = CreateBlockSaveData(block.childBlock)
	end

	for containerIndex , replacedValueBlock in pairs(block.replacedValueBlocks) do
		local replacedValueData = CreateBlockSaveData(replacedValueBlock)
		data.replacedValues[tostring(containerIndex)] = replacedValueData -- to string so conversion to json doesn't brake it.
	end
	
	return data
end

-- Creates a save data as JSON
-- The save file is the one that is loaded by the plugin
-- @param blocks : Dictionary of block (BlockFactory.BlockClass)
-- @param variables : Dictionary of variables (string)
-- @param instance : Instance containing the script
-- @return : String containing the save data
local function CreateSaveData(blocks: {BlockClass}, variables: {string}, instance: Instance) : string
	local saveData = {blocks = {}, variables = variables}

	for _, block in pairs(blocks) do
		-- We only look for blocks at root level first because children are saved when their parent is saved
		if block.parentBlock == nil  and not block.isTemplate and block.blockFrame.Parent and not block.blockFrame.Parent:FindFirstChildWhichIsA("TextBox")  then
			local blockData = CreateBlockSaveData(block)
			table.insert(saveData.blocks, blockData)		
		end
	end
	
	
	-- create new save data
	local saveFile = Instance.new("ModuleScript")
	saveFile.Name = SAVE_FILE_NAME

	local JsonSaveData = ''
	local success, err = pcall(function()
		JsonSaveData = HttpService:JSONEncode(saveData)
	end)

	if not success then
		warn("Scratchify Error while encoding save data: " .. err)
		return nil
	end

	-- remove previous save data
	if instance:FindFirstChild(SAVE_FILE_NAME) then
		instance:FindFirstChild(SAVE_FILE_NAME):Destroy()
	end

	JsonSaveData = SafeLongBraked(JsonSaveData) -- So the json data isnt broken by a ]]
	JsonSaveData = "return " .. JsonSaveData -- when the module will be require it will return the string data
	saveFile.Source = JsonSaveData
	saveFile.Parent = instance

	return saveData
end

-- Creates a block runner data
-- The runner file is the one that is executed by roblox
-- @param block : BlockClass
-- @param indent : Indentation level
-- @param enclosing: number , if > 0 , the separated content will be returned in a separated enclosed content string 
-- @return : String containing the block runner data , a second string containing a enclosed separated data ("" if not currently enclosing)
local function CreateBlockRunnerData(block: BlockClass, indent, enclosing) : (string, string)
	
	-- check for nil value
	enclosing = enclosing or 0

	local blockRunnerData = ""	

	local blockData = block.blockData
		
	
	-- Indentation (for look only)
	if block:GetBlockType() == "CBlockEnd" then
		indent -= 1
	end
	local indentString = string.rep("\t", indent)

	-- if the block is not a value block, we add the indentation and the return 
	if block:GetBlockType() ~= "ValueBlock" then
		blockRunnerData = blockRunnerData .. "\n" .. indentString
	end

	local codeEquivalent = blockData.func 

	-- we replace the @ character with the block clientID if it got one
	codeEquivalent = string.gsub(codeEquivalent, "@", blockData.clientID or "@")

	-- This function finds content at a specific index, skipping Text elements
	-- We need this because Text elements don't correspond to & placeholders in the code template
	local function getContent(contentIndex: number)
		local withoutTextLabelIndex = 0
		for _, content in pairs(blockData.content) do
			if content.contenttype ~= "Text" then
				withoutTextLabelIndex += 1
			end

			if withoutTextLabelIndex == contentIndex then
				return content
			end
		end
		
		return nil
	end

	-- we add the code to the runned data, and
	-- we replace the & character with the valueBlocks inside the block
	local valueIndex = 0
	for _, letter in pairs(codeEquivalent:split("")) do
		if letter == "&" then
			valueIndex += 1
			-- if there is a value block in the valuecontainer, we put it's runner data here, else we put the value 
			local valueBlock = block.replacedValueBlocks[valueIndex]
			if valueBlock then
				blockRunnerData = blockRunnerData .. CreateBlockRunnerData(valueBlock, indent)
			else
				local valueContent = getContent(valueIndex)
				if valueContent then
					if valueContent.contenttype == "AnyValue" then
						if tonumber(valueContent.content) then
							blockRunnerData = blockRunnerData .. valueContent.content
						else
							blockRunnerData = blockRunnerData ..  SafeLongBraked(valueContent.content)
						end
					else
						blockRunnerData = blockRunnerData .. valueContent.content
					end
				else
					warn("Scratchify Saving Error: No content found for value index " .. valueIndex .. " in block " .. blockData.id)
				end
			end
		else 
			blockRunnerData = blockRunnerData .. letter
		end
	end

	-- Indentation (for look only)
	if block:GetBlockType() == "EBlock" or block:GetBlockType() == "CBlock" or block:GetBlockType() == "EBlockMiddle" then
		indent += 1
	end
	
	
	-- Check for the enclosures
	if enclosing > 0 then
		if block:GetBlockType() == "EBlock" or block:GetBlockType() == "CBlock" then
			enclosing += 1
		elseif block:GetBlockType() == "CBlockEnd" then
			enclosing -= 1
		end
	end
	

	-- Now we add the child blocks and all
	local finalRunnerData, finalEnclosedData = "", ""
	
	if block.childBlock then
		
		local childBlockData, myEnclosedData = CreateBlockRunnerData(block.childBlock, indent, (enclosing > 0 and enclosing or (blockData.clientID and 1 or 0)) )
		
		
		if enclosing == 0 and blockData.clientID == nil then -- normal case, no enclosing 
			finalRunnerData = blockRunnerData .. "\n" .. childBlockData
		elseif enclosing > 0 then  -- we enclose what should be enclosed and separate what should be separated
			finalEnclosedData = blockRunnerData.."\n"..myEnclosedData
			finalRunnerData = childBlockData
		elseif blockData.clientID then -- if the block is the exotic "do for player (player) block"
			local localScript =  "-- this is a scratchify blox generated script (do not delet) \n local module = {} \nlocal myVars = require(game.ReplicatedStorage.ScratchifyBloxEnvironment.ReplicatedVariables) \n function module.new(ScratchifyID) \n "..myEnclosedData.."\n end \n return module"
			
			if game.ReplicatedStorage:FindFirstChild(blockData.clientID) then
				game.ReplicatedStorage:FindFirstChild(blockData.clientID):Remove()
			end
			
			local newModule = Instance.new("ModuleScript")
			newModule.Parent = game.ReplicatedStorage
			newModule.Name = blockData.clientID
			newModule.Source = localScript
						
			-- we also add the block code to call the client part
			finalRunnerData = blockRunnerData .. "\n" .. childBlockData
		end

	else
		finalRunnerData = blockRunnerData
	end
	
	
	

	return finalRunnerData, finalEnclosedData

end



-- Creates a runner data
-- The runner file is the one that is executed by roblox
-- @param blocks : Dictionary of block (BlockFactory.BlockClass)
-- @param variables : Dictionary of variables (string)
-- @param instance : Instance containing the script
-- @return : String containing the runner data
local function CreateRunnerData(blocks: {BlockClass}, variables: {string}, instance: Instance) : string

	local runnerFile = ""

	-- Add the header
	runnerFile = [[
local instance = script.Parent
local scriptRoot = Instance.new("BindableEvent")
local myVars = require(game.ReplicatedStorage.ScratchifyBloxEnvironment.ReplicatedVariables)
local Remote = game.ReplicatedStorage:WaitForChild("remote.sbr")
local ScratchifyID = instance:GetAttribute("ScratchifyID")
]]

	for _, block in pairs(blocks) do
		-- this time we only need "hatblocks" first (their children will be added in the CreateBlockRunnerData function)
		if block:GetBlockType() == "HatBlock"  and not block.isTemplate then
			local blockData = block.blockData
			local blockType = block:GetBlockType()
			if blockType then
				runnerFile = runnerFile .. CreateBlockRunnerData(block, 1)
				-- because those are hat blocks, they are ALL represented by ":Connect(function()" ; we need to add the "end)"
				runnerFile = runnerFile .. "\nend)\n"
			end
		end
	end

	runnerFile = runnerFile .. "\nscriptRoot:Fire() -- this will start the script"

	local RunnerScript = Instance.new("Script")
	RunnerScript.Name = RUNNER_FILE_NAME
	RunnerScript.Source = runnerFile

	-- remove previous runner data
	if instance:FindFirstChild(RUNNER_FILE_NAME) then
		instance:FindFirstChild(RUNNER_FILE_NAME):Destroy()
	end

	RunnerScript.Parent = instance

	-- Check if the instance has the Scratchify-ID
	if instance:GetAttribute("ScratchifyID") == nil then
		instance:SetAttribute("ScratchifyID", HttpService:GenerateGUID())
	end
	
	return runnerFile
end


local function ContainsNonTemplateBlocks(blocks)
	for _, block in pairs(blocks) do
		if not block.isTemplate and block:GetBlockType() ~= "CBlockEnd" and block:GetBlockType() ~= "EBlockMiddle" then
			return true
		end
	end
	return false
end

-- Functon to save a script
-- @param Blocks : Dictionary of block (BlockFactory.BlockClass) 
-- @return : Boolean if the script was saved
function DataManager:SaveScript(blocks: {BlockClass}, instance: Instance) : boolean
	if not ContainsNonTemplateBlocks(blocks) and #VariableManager:GetInstanceVariables() == 0 then
		local SaveScript = instance:FindFirstChild(SAVE_FILE_NAME)
		if SaveScript then SaveScript:Destroy() end

		local RunnerScript = instance:FindFirstChild(RUNNER_FILE_NAME)
		if RunnerScript then RunnerScript:Destroy() end
		
		return
	end
	
	CreateSaveData(blocks, VariableManager:GetInstanceVariables(), instance)
	CreateRunnerData(blocks, VariableManager:GetInstanceVariables(), instance)
	
end

-- Function to load a block from a save file
-- @param block : BlockSaveData
-- @param blocks : Dictionary of block (BlockFactory.BlockClass)
-- It will modify blocks list to add the block automatically
local function LoadBlock(blockSaveData: BlockSaveData, blocks: {BlockClass}): BlockClass
	if not blockSaveData.blockData then
		warn("Scratchify Error: Block data is nil, corrupt save file")
		return nil
	end

	local blockData = blockSaveData.blockData

	local color = Color3.fromRGB(blockSaveData.color.r, blockSaveData.color.g, blockSaveData.color.b)

	local block = BlockFactory.new(blockData, nil, nil, color)

	table.insert(block, blocks)
		
	block.blockFrame.Position = UDim2.new(0, blockSaveData.position.x, 0, blockSaveData.position.y)

	if blockSaveData.child and blockSaveData.child.blockData then
		local loadedChildBlock = LoadBlock(blockSaveData.child, blocks)
		block:SetChildBlock(loadedChildBlock)
	end

	for index_, replacedValueBlock in pairs(blockSaveData.replacedValues) do
		local loadedReplacedValueBlock = LoadBlock(replacedValueBlock, blocks, BlockFactory)

		block:LinkValueBlockToContainer(loadedReplacedValueBlock, block:GetValueContainers()[tonumber(index_)])
	end

	return block



end

-- Function to load a script from a save file
-- @param ModuleScript : the save.sbsv3 file 
-- Loads it diretcly to block factory
function DataManager:LoadScript(saveFile): ({BlockClass}, {string})
	assert(saveFile, "Save file cannot be nil")

	local success, saveData = pcall(function()
		return HttpService:JSONDecode(require(saveFile) or "{\"Corrupt save file!\": true}")
	end)

	if not success or not saveData.variables then
		warn("Scratchify Error while loading save data: " .. saveData)
		return nil
	end

	local blocks = {}
	local variables = saveData.variables

	for _, block in pairs(saveData.blocks) do
		LoadBlock(block, blocks)
	end
	
	VariableManager:FromSaveData(variables)
	
end

-- Loads an instance 
-- If it didnt have any save script it creates a new one
function DataManager:LoadForInstance(instance: Instance)
	if instance:FindFirstChild(SAVE_FILE_NAME) then
		DataManager:LoadScript(instance:FindFirstChild(SAVE_FILE_NAME))
	else
		VariableManager:FromSaveData({}) -- Still need to load variables
	end
end



return DataManager
