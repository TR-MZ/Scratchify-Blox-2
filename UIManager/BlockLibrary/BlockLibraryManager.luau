local BlockLibrary = {}
BlockLibrary.dataManager = {}
-- Import submodules
local Types = require(script.Parent.Scripts.Types)
local Defaults = require(script.Parent.Scripts.Defaults)
local DataManager = require(script.Parent.Scripts.DataManager)
local UIManager = require(script.Parent.Scripts.UIManager)
local BlockEditor = require(script.Parent.Scripts.BlockEditor)
local PackageEditor = require(script.Parent.Scripts.PackageEditor)
local AlertManager = require(script.Parent.Scripts.AlertManager)
local DropdownManager = require(script.Parent.Scripts.DropdownManager)
local FireStoreManager = require(script.Parent.Scripts.FirestoreManager)

-- Initialize function - main entry point
-- @param plugin: The plugin instance
-- @param UI: The UI instance (Library frame)
function BlockLibrary:Init(plugin, UI: Frame, refreshSideBarCallback: () -> any)
	
	
	
	
	-- Initialize all managers with required dependencies
	local dropdownManager = DropdownManager.new(plugin)
	local alertManager = AlertManager.new(UI.Alert)
	local uiManager = UIManager.new(plugin, UI)
	local dataManager = DataManager.new()
	local packageEditorManager = PackageEditor.new(UI.Create, dataManager, nil, alertManager, dropdownManager)
	local blockEditorManager = BlockEditor.new(UI.BlockEditor, dropdownManager, alertManager, dataManager, packageEditorManager, uiManager)


	-- Store the dataManager as self. so it can be accessed in EditorUIManager
	self.dataManager = dataManager 

	dataManager:Init(plugin, uiManager.LoadingFrame)
	-- Set the block editor in package editor after it's created
	packageEditorManager.blockEditor = blockEditorManager
	
	FireStoreManager:Init(uiManager, UI.Login, plugin)
	
	-- Initialize UI components and connect everything
	--uiManager:init(
	--	packageEditorManager,
	--	blockEditorManager,
	--	dataManager,
	--	alertManager,
	--	dropdownManager,
	--	FireStoreManager,
	--	refreshSideBarCallback
	--)

	export type BlockPack = {
		Name: string,
		Description: string, 
		IconColor: string, -- hex color
		ContentBlockIds: {string}, -- firebase references
	}

end

return BlockLibrary