local EditorUIManager = {}

-- Services -------------------------------------------------

local SelectionService = game:GetService("Selection")
local StudioService = game:GetService("StudioService")
local HttpService = game:GetService("HttpService")
-- Constants -------------------------------------------------

local Assets = script.Parent.Assets
local PS_KEY_DOWNLOADED = "Downloaded"

-- Modules --------------------------------------------------

local BlockLibraryManager = require(script.Parent.BlockLibrary.BlockLibraryManager)
local SideBarButtonsManager = require(script.Parent.BlockSideBar.SideBarButtonsManager)
local SidebarBlockContainer = require(script.Parent.BlockSideBar.SideBarBlockContainr)
local BlockFactory = require(script.Parent.Parent.BlocksFactory.Block)
local DataManager = require(script.Parent.Parent.DataManager.Datamanager)
local MenuManager = require(script.Parent.MenuManager.MenuManager)
local BaseBlockPack = require(script.Parent.Parent.BlocksFactory.Assets.BaseBlockPackage.BaseBlockPackage)
local BaseBlockColors = require(script.Parent.Parent.BlocksFactory.Assets.BaseBlockPackage.BaseBlockColors)
local VariableMakerManager = require(script.Parent.VariableMaker.VariableMakerManager)
local VariableManager = require(script.Parent.Parent.VariableManager.VariableManager)

-- Variables -------------------------------------------------

-- [UI Elements]

EditorUIManager. UI = nil
EditorUIManager. BlockSidebarButtons = nil
EditorUIManager. BlockSideBar = nil
EditorUIManager. LinkedInstancesSideBar = nil
EditorUIManager. Canvas = nil
EditorUIManager. Dropdown = nil
EditorUIManager. Menu = nil
EditorUIManager. BlockLibrary = nil

-- [Editor]

local plugin = nil
local PluginMouse = nil

-- Functions -------------------------------------------------


--- Returns a formatted breadcrumb path to the given instance.
-- The path excludes the instance itself and uses " > " as a separator.
-- If the hierarchy is deeper than 3 levels, it will be condensed with " > ... > ".
--
-- Example:
--    Given an instance at workspace.Folder1.Folder2.Folder3.Part,
--    the result will be: "workspace > Folder1 > ... > Folder3"
--
-- @param instance Instance -- The instance to get the breadcrumb path for.
-- @return string -- A string representing the breadcrumb path to the instance.
local function GetBreadcrumbPath(instance)
	local pathParts = {}
	local current = instance.Parent -- Exclude the instance itself

	while current and current ~= game do
		table.insert(pathParts, 1, current.Name)
		current = current.Parent
	end

	-- Add workspace if it’s part of the path
	if instance:IsDescendantOf(workspace) then
		table.insert(pathParts, 1, "workspace")
	elseif current == game then
		table.insert(pathParts, 1, "game")
	end

	local len = #pathParts
	if len > 3 then
		return pathParts[1] .. " > " .. pathParts[2] .. " > ... > " .. pathParts[len]
	else
		return table.concat(pathParts, " > ")
	end
end

--- Updates the target display UI to show information about a given instance.
-- If the instance is nil, the display will be hidden. Otherwise, it shows the instance's
-- name, class icon, and location in the hierarchy using a breadcrumb path.
--
-- @param targetDisplay Frame -- The UI frame that displays information about the instance.
--        It must contain `Preview` (an ImageLabel), `Title` (a TextLabel), and `Location` (a TextLabel).
-- @param instance Instance -- The instance to display. If nil, the display will be hidden.
local function SetTargetDisplay(targetDisplay: Frame, instance: Instance)
	if instance == nil then
		targetDisplay.Visible = false
	else
		targetDisplay.Visible = true
		
		targetDisplay.Preview.Image = StudioService:GetClassIcon(instance.ClassName).Image or ""
		
		targetDisplay.Title.Text = instance.Name
		targetDisplay.Location.Text = GetBreadcrumbPath(instance)
	end
end

-- Function to get blockdata from cloud block
-- Because i wrote the firestore before  ScratchifyBlox3 and didnt think about that
-- @param cloudBlockData
-- @return BlockData
local function GetBlockDataFromCloudData (cloudBlockData)
	local BlockData = {
		id = cloudBlockData.BlockId,
		specificTo = cloudBlockData.SpecificTo,
		category = nil,
		blockType = cloudBlockData.Type,
		content = {},
		func = cloudBlockData.Code
	}
	for _, element in pairs(cloudBlockData.Elements) do
		local contentType = element.contentType
		local content = element.content

		table.insert(BlockData.content , {
			contenttype = contentType,
			content = content,
			pickerContent = element.pickerContent,
		})
	end
	return BlockData
end



-- Refreshes the sidebar by adding blocks and categories to the sidebar.
-- It iterates through the BaseBlockPack, creating blocks and adding them to the sidebar.
-- If a block has a specific type, it will only be added if the current selection matches that type.
local currentSelection
local function RefreshSideBar()
	
	if not currentSelection then return end
	SidebarBlockContainer:Clear()
	SideBarButtonsManager:ClearCategories()


	-- Add side bar blocks
	for _, block in pairs(BaseBlockPack) do
		if typeof(block) == "string" then -- block category tag
			local cName = string.gsub(block, "CAT_", "")
			SideBarButtonsManager:AddCategory(cName, cName , BaseBlockColors[cName]) -- TODO: color
			SidebarBlockContainer:AddCategory(cName, cName)
		else
			if not block.category then continue end
			
			if block.specificTo and not currentSelection:IsA(block.specificTo) then continue end
			
			local _block = BlockFactory.new(block, nil, nil, BaseBlockColors[block.category])
			_block:SetTemplateMode(true)

			local blockFrame = _block.blockFrame
			SidebarBlockContainer:AddBlock(blockFrame, block.category)
		end
	end

	-- Add the user Created blocks
	local createdPack = BlockLibraryManager.dataManager.GetMyPackages and BlockLibraryManager.dataManager:GetMyPackages() or {} 

	for _, blockPack in pairs(createdPack) do
		
		local createdBlocks = {}
		local success, error = pcall(function()

			SideBarButtonsManager:AddCategory(blockPack.PackId, blockPack.Name, Color3.fromHex(blockPack.IconColor))
			SidebarBlockContainer:AddCategory(blockPack.PackId, blockPack.Name)
			for _, block in pairs(blockPack.ContentBlockIds) do
				block = BlockLibraryManager.dataManager:BlockDataById(block)
				if not block then return end

				block = GetBlockDataFromCloudData(block)

				local _block = BlockFactory.new(block, nil, nil, Color3.fromHex(blockPack.IconColor))
				table.insert(createdBlocks, _block)
				_block:SetTemplateMode(true)

				local blockFrame = _block.blockFrame
				SidebarBlockContainer:AddBlock(blockFrame, blockPack.PackId)
			end
		end)
		if not success then
			for _, c in pairs(createdBlocks) do
				c.Frame:Destroy()
				c:Destroy()
			end
			warn("Error loading block pack: " .. blockPack.PackId .. " - " .. error)
		end
	end

	-- Add the Downloaded blocks 
	local downloadedBlocks = plugin:GetSetting(PS_KEY_DOWNLOADED) or "{}"
	local downloadedBlocksTable = HttpService:JSONDecode(downloadedBlocks)
	for _, blockPackContainer in pairs(downloadedBlocksTable) do
		if blockPackContainer.BlockPack == nil or blockPackContainer.BlockPack.PackId == nil then continue end
		local createdBlocks = {}
		local success, error = pcall(function()
			if not blockPackContainer.Enabled then return true end

			local blockPack = blockPackContainer.BlockPack

			SideBarButtonsManager:AddCategory(blockPack.PackId, blockPack.Name, Color3.fromHex(blockPack.IconColor))
			SidebarBlockContainer:AddCategory(blockPack.PackId, blockPack.Name)
			for _, block in pairs(blockPackContainer.Blocks) do

				block = GetBlockDataFromCloudData(block)
				local _block = BlockFactory.new(block, nil, nil, Color3.fromHex(blockPack.IconColor))
				table.insert(createdBlocks, _block)

				_block:SetTemplateMode(true)

				local blockFrame = _block.blockFrame
				SidebarBlockContainer:AddBlock(blockFrame, blockPack.PackId)
			end
		end)
		if not success then
			for _, c in pairs(createdBlocks) do
				c.Frame:Destroy()
				c:Destroy()
			end
			warn("Error loading block pack: " .. blockPackContainer.BlockPack.PackId .. " - " .. error)
		end
	end
end


-- Initializes the Editor UI Manager.
-- This function sets up the UI elements, initializes managers, and connects events.
-- @param EditorWidget DockWidgetPluginGui -- The widget to which the UI will be attached.
-- @param plugin Plugin -- The plugin instance.
-- @return void
function EditorUIManager:Init(EditorWidget: DockWidgetPluginGui, _plugin: Plugin)
	assert(EditorWidget, "Widget must be provided")

	self. UI = Assets.Main:Clone()
	self. UI.Parent = EditorWidget

	self. SideBarbuttons = self. UI.SidebarButtons
	self. BlockSidebar = self. UI.BlockSideBar
	self. Canvas = self. UI.Canvas
	self. BlockLibrary = self. UI.BlockLibrary
	
	self. TargetDisplay = self .Canvas.Target

	plugin = _plugin
	PluginMouse = plugin:GetMouse()

	-- Setup the Block Library
	local BlockLibraryOppened = false
	BlockLibraryManager = BlockLibraryManager or {}
	--BlockLibraryManager:Init(plugin, self.BlockLibrary, RefreshSideBar)
	
	-- Setup the VariableManager
	VariableManager:Init(BlockFactory, DataManager, SidebarBlockContainer)
	
	-- Setup the VariableMakerManager
	VariableMakerManager:Init(self.UI.VariableMaker, VariableManager)
	self.BlockSidebar.Content.MakeVar.MouseButton1Down:Connect(VariableMakerManager.PromptMakeVariable)
	
	-- Init the menu Manager
	MenuManager:Init(plugin, EditorWidget)
	
	SelectionService.SelectionChanged:Connect(function()
		if BlockLibraryOppened then return end
		-- TODO make the lock instance so it locks on a edited instance and doesnt change
		
		-- Save last instance
		if currentSelection then
			DataManager:SaveScript(BlockFactory.GetBlocks(), currentSelection) -- TODO: Variables
		end
		
		local selected = SelectionService:Get()
		if #selected == 0 then return end
		
		currentSelection = selected[1]

		SetTargetDisplay(self.TargetDisplay, currentSelection)
		
		BlockFactory.Clear()
		
		RefreshSideBar()

		DataManager:LoadForInstance(currentSelection)
	end)

	-- Setup the Block Side Bar
	print()
	SidebarBlockContainer:Init(self.BlockSidebar.Content)
	SideBarButtonsManager:Init(self.SideBarbuttons)

	SideBarButtonsManager:ClearCategories()
	SidebarBlockContainer:Clear()
	
	-- Setup the Block Factory
	BlockFactory:Init(plugin, EditorWidget, self.Canvas.ScrollingFrame, VariableManager)

	BlockFactory.Changed:Connect(function()
		DataManager:SaveScript(BlockFactory.GetBlocks(), currentSelection) -- TODO: Variables
	end)
	
	BlockFactory.OnBlockRightRightClicked:Connect(function(actions)
		MenuManager:Menu(
			UDim2.fromOffset(EditorWidget:GetRelativeMousePosition().X, EditorWidget:GetRelativeMousePosition().Y),
			actions
		)
	end)
	
	-- Setup the DataManager
	DataManager:Init(BlockFactory, VariableManager)
	
	
	
	SideBarButtonsManager.OnCategoryChanged:Connect(function(category)
		if category == "LIB" then
			--BlockLibraryOppened = not BlockLibraryOppened
			--self.BlockLibrary.Visible = BlockLibraryOppened
			--self.Canvas.Visible =  not BlockLibraryOppened
			--self.BlockSidebar.Visible = not BlockLibraryOppened
		else
			SidebarBlockContainer:ScrollToCategory(category, true)
		end
	end)

	SidebarBlockContainer.OnScrollCategoryChanged:Connect(function(category)
		SideBarButtonsManager:SetCurrentCategory(category)
	end)
	

end


return EditorUIManager