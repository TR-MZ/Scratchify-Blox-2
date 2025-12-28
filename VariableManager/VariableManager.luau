local VariableManager = {}

-- Services -------------------------------------------------

local ReplicatedService = game:GetService("ReplicatedStorage")

-- Constants -------------------------------------------------

local BaseVariableBlockData: block = {
	specificTo = nil, 
	category = "Variables",
	blockType = "Value",
	func = "myVars[\"\"]",
	content = {
		{
			contenttype = "Text",
			content = ""
		},
	}
}

-- Modules --------------------------------------------------

local BaseBlockColors = require(script.Parent.Parent.BlocksFactory.Assets.BaseBlockPackage.BaseBlockColors)

-- Variables -------------------------------------------------

local GlobalVariables = {}
local CurrentInstanceVariables = {}

local BlocksFactory, DataManager, BlockSideBarManager

-- Dictionaries of created Templates for variables in the sidebar {[name]: BlockClass}
local CurrentInstanceVariableBlocks = {} 
local GlobalVariableBlocks = {} 

-- Functions -------------------------------------------------

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


--- Creates a ModuleScript to store global variables in the ScratchifyBloxEnvironment folder.
-- The script is initialized with an empty table as its source.
--
-- @return Instance -- The created ModuleScript instance named "GlobalVariables".
local function CreateGlobalVariablesSaveScript()
	local EnvironmentFolder = ReplicatedService:WaitForChild("ScratchifyBloxEnvironment", 10) 

	local GlobalVariablesSaveScript = Instance.new("ModuleScript")
	GlobalVariablesSaveScript.Source = "return {}"
	GlobalVariablesSaveScript.Parent = EnvironmentFolder
	GlobalVariablesSaveScript.Name = "GlobalVariables"

	return GlobalVariablesSaveScript
end

--- Loads global variables from the GlobalVariables ModuleScript.
-- If the script doesn't exist, it creates a new one using CreateGlobalVariablesSaveScript.
--
-- @return nil
local function LoadGlobalVariables()
	local EnvironmentFolder = ReplicatedService:WaitForChild("ScratchifyBloxEnvironment")

	local GlobalVariablesSaveScript = EnvironmentFolder:FindFirstChild("GlobalVariables") or CreateGlobalVariablesSaveScript()

	GlobalVariables = require(GlobalVariablesSaveScript)
end

--- Saves the current GlobalVariables table to the GlobalVariables ModuleScript.
-- The variables are formatted as a Lua table string with quoted values.
--
-- @return nil
local function SaveGlobalVariables()
	local EnvironmentFolder = ReplicatedService:WaitForChild("ScratchifyBloxEnvironment")

	local GlobalVariablesSaveScript = EnvironmentFolder:FindFirstChild("GlobalVariables") or CreateGlobalVariablesSaveScript()

	GlobalVariablesSaveScript.Source = "return {\""..table.concat(GlobalVariables, "\" , \"").."\"}"
end


---
--
local function RefreshCurrentInstanceVariableBlocks()
	for _, variableBlock in pairs(CurrentInstanceVariableBlocks) do
		variableBlock:Destroy()
	end  
	table.clear(CurrentInstanceVariableBlocks)
	
	for _, variable in pairs(CurrentInstanceVariables) do
		
		-- Set up the block content
		BaseVariableBlockData.content[1].content = variable

		-- Set up the function string using SafeLongBraked
		local myFunction = "myVars:Get( ScratchifyID.." .. SafeLongBraked(variable) .. " )"
		BaseVariableBlockData.func = myFunction

		-- Create the variable block
		local variableBlock = BlocksFactory.new(BaseVariableBlockData, nil, nil, BaseBlockColors.Variables)

		-- Set template mode
		variableBlock:SetTemplateMode(true)

		-- Add right-click action to remove the block
		variableBlock:AddRightClickAction("Remove variable", function()
			table.remove(CurrentInstanceVariableBlocks, table.find(CurrentInstanceVariableBlocks, variableBlock))
			table.remove(CurrentInstanceVariables, table.find(CurrentInstanceVariables, variable))
			
			variableBlock:Destroy()

			RefreshCurrentInstanceVariableBlocks()
		end)

		-- Add the block to the current instance list
		table.insert(CurrentInstanceVariableBlocks, variableBlock)

		-- Add the block's frame to the sidebar manager
		local blockFrame = variableBlock.blockFrame
		BlockSideBarManager:AddBlock(blockFrame, "Variables")

	end
	
end

---
-- 
local function RefreshGlobalVariableBlocks()
	for _, variableBlock in pairs(GlobalVariableBlocks) do
		variableBlock:Destroy()
	end  
	table.clear(GlobalVariableBlocks)

	for _, variable in pairs(GlobalVariables) do

		-- Set up the block content
		BaseVariableBlockData.content[1].content = variable

		-- Set up the function string using SafeLongBraked
		local myFunction = "myVars:Get( " .. SafeLongBraked(variable) .. " )"
		BaseVariableBlockData.func = myFunction

		-- Create the variable block
		local variableBlock = BlocksFactory.new(BaseVariableBlockData, nil, nil, BaseBlockColors.Variables)

		-- Set template mode
		variableBlock:SetTemplateMode(true)

		-- Add right-click action to remove the block
		variableBlock:AddRightClickAction("Remove variable", function()
			table.remove(GlobalVariableBlocks, table.find(GlobalVariableBlocks, variableBlock))
			table.remove(GlobalVariables, table.find(GlobalVariables, variable))
			
			variableBlock:Destroy()
			
			SaveGlobalVariables()
			RefreshGlobalVariableBlocks()
		end)

		-- Add the block to the current instance list
		table.insert(GlobalVariableBlocks, variableBlock)

		-- Add the block's frame to the sidebar manager
		local blockFrame = variableBlock.blockFrame
		BlockSideBarManager:AddBlock(blockFrame, "Variables")

	end
	
	RefreshCurrentInstanceVariableBlocks()
end


---
--
-- @param BlocksFactory: Module script src/BlocksFactory/
-- @param DataManager: Module script src/DataManager/
-- @param BlockSideBarManager: Module script src/UIManager/BlockSideBar/
function VariableManager:Init(blocksFactory, dataManager, blockSideBarManager)
	BlocksFactory = blocksFactory
	DataManager = dataManager
	BlockSideBarManager = blockSideBarManager
	LoadGlobalVariables()
end


--- Loads variables from save data into CurrentInstanceVariables.
-- Used by DataManager to initialize instance-specific variables.
--
-- @param variables table -- A table of variable names (strings).
-- @return nil
function VariableManager:FromSaveData(variables)
	CurrentInstanceVariables = variables
	RefreshGlobalVariableBlocks()
end

--- Retrieves all variables (global and instance-specific) for a given instance.
-- Combines GlobalVariables and CurrentInstanceVariables into a single table.
--
-- @return table -- A table containing all variable names.
function VariableManager:GetVariables()
	local allVariables = table.clone(GlobalVariables)
	table.move(CurrentInstanceVariables, 1, #CurrentInstanceVariables, #allVariables+1, allVariables)
	return allVariables
end

--- Retrieves instance specific variables for a given instance.
--
-- @return table -- A table containing all variable names.``
function VariableManager:GetInstanceVariables()
	return CurrentInstanceVariables
end


--- Adds a variable to the current instance
-- Returns true if the variable was created, or false and a string message explaining the error
-- 
-- @param name
-- @param forAllInstances
--
-- @return (boolean, string)
function VariableManager:AddVariable(name, forAllInstances)
	if table.find(GlobalVariables, name) or table.find(CurrentInstanceVariables, name) then
		return false, "This variable already exist! Try using a different name."
	end
	if forAllInstances then
		print(forAllInstances)
		table.insert(GlobalVariables, name)
		SaveGlobalVariables()
		RefreshGlobalVariableBlocks()
	else
		table.insert(CurrentInstanceVariables, name)
		RefreshCurrentInstanceVariableBlocks()
	end
end

return VariableManager