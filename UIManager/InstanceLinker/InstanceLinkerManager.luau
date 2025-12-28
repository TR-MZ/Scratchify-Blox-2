-- Instance Linked Manger
-- By TR-MZ
--
-- This module is responsible for managing the instance linking process, which you can find in the right sidebar.

local InstanceLinkerManager = {}



-- Services -------------------------------------------------
local SelectionService = game:GetService("Selection")
local StudioService = game:GetService("StudioService")
local CollectionService = game:GetService("CollectionService")

-- Constants -------------------------------------------------
local TAG_LINKED_INSTANCES = "Do not delete - Scratchify Blox Linked Instance"

local OnSelectedChanged = Instance.new("BindableEvent")
InstanceLinkerManager. OnSelectedChanged = OnSelectedChanged.Event

local OnInstanceRightClickEvent = Instance.new("BindableEvent")
InstanceLinkerManager.OnInstanceRightClick = OnInstanceRightClickEvent.Event

-- Variables -------------------------------------------------

local PluginMouse = nil

local SideBarInstanceLinker = nil

local LastSidebarLayoutOrder = 0

local Styles = {
    Selected = nil,
    Default = nil,
    Hovered = nil,
    LinkMe = nil,
}

-- Functions -------------------------------------------------


-- [Private Functions]

-- For Visual Effect
local function CopyStyle(Button, TargetStyle)
    
    Button.BackgroundColor3 = TargetStyle.BackgroundColor3
    Button.UIStroke.Color = TargetStyle.UIStroke.Color
    Button.UIStroke.Thickness = TargetStyle.UIStroke.Thickness
    Button.Item.BackgroundColor3 = TargetStyle.Item.BackgroundColor3
    Button.Item.Corner.BackgroundColor3 = TargetStyle.Item.BackgroundColor3
    Button.TextLabel.TextColor3 = TargetStyle.TextLabel.TextColor3
    Button.UIStroke.Transparency = TargetStyle.UIStroke.Transparency

end


-- @Class : LinkInstanceButton
local LinkInstanceButton = {}

function LinkInstanceButton.new(instance, alreadyLinked)
	local self = setmetatable({}, LinkInstanceButton)

	self.Button = alreadyLinked and Styles.Default:Clone() or  Styles.LinkMe:Clone()
	self.Button.Parent = SideBarInstanceLinker
	self.Button.Visible = true

	self.Button.TextLabel.Text = instance.Name
	self.Button.LayoutOrder = LastSidebarLayoutOrder
	LastSidebarLayoutOrder -= 1

	self.Button.Item.Icon.Image = StudioService:GetClassIcon(instance.ClassName).Image

	self.linked = alreadyLinked
	self.selected = false
	
	self._onSelectionChangedConnection = InstanceLinkerManager.OnSelectedChanged:Connect(function(selectedInstance)
		self.selected = selectedInstance == instance
		if not self.linked then
			self.Button:Destroy()
			self._onSelectionChangedConnection:Disconnect()
		elseif self.selected then 
			CopyStyle(self.Button, Styles.Selected)
		else
			CopyStyle(self.Button, Styles.Default)
		end
	end)

	self._deletOnStudioSelectionChangedConnection = SelectionService.SelectionChanged:Connect(function()
		if not self.linked then
			self.Button:Destroy()
			self._deletOnStudioSelectionChangedConnection:Disconnect()
			self._onSelectionChangedConnection:Disconnect()
		end
	end)

	self.Button:GetPropertyChangedSignal("GuiState"):Connect(function()
		if self.Button.GuiState == Enum.GuiState.Hover then
			PluginMouse.Icon = "rbxasset://SystemCursors/PointingHand"
			if self.linked and not self.selected then
				CopyStyle(self.Button, Styles.Hovered)    
			end
		elseif self.Button.GuiState == Enum.GuiState.Idle then
			PluginMouse.Icon = "rbxasset://SystemCursors/Arrow"
			if self.linked and not self.selected then
				CopyStyle(self.Button, Styles.Default)
			end
		end
	end)

	self.Button.MouseButton1Click:Connect(function()
		self.linked = true
		self.selected = true

		if self.Button:FindFirstChild("PlusIcon") then
			self.Button.PlusIcon:Destroy()
		end

		instance:AddTag(TAG_LINKED_INSTANCES)
		OnSelectedChanged:Fire(instance)
	end)
	
	self.Button.MouseButton2Click:Connect(function()
		OnInstanceRightClickEvent:Fire(instance)
	end)

	return self
end


-- When Studio's selection changes
local function OnSelectionChanged()
	local selection = SelectionService:Get()
	
    -- Check if the selection is empty
    if not selection or #selection == 0 then
        return
    end

    local SelectedFirst: Instance = selection[1]

    -- Check if the selected instance is a linked instance
    if SelectedFirst:HasTag(TAG_LINKED_INSTANCES) then return end
	LinkInstanceButton.new(SelectedFirst, false)
end

-- [Public Functions]

function InstanceLinkerManager:Init(plugin, sideBarInstanceLinker)
	
	assert(plugin)
	assert(sideBarInstanceLinker, "Argument 2 missing or nil")
	
    PluginMouse = plugin:GetMouse()

	SideBarInstanceLinker = sideBarInstanceLinker

    Styles.Default = script.Parent.Assets.NotSelectedItem
    Styles.Selected = script.Parent.Assets.SelectedItem
    Styles.Hovered = script.Parent.Assets.HoveredInstance
    Styles.LinkMe = script.Parent.Assets.LinkAnInstance

	-- Init all already linked instance in the workspace
	for _, linked in pairs(CollectionService:GetTagged(TAG_LINKED_INSTANCES)) do
		LinkInstanceButton.new(linked, true)
	end
end





-- Connections -------------------------------------------------
SelectionService.SelectionChanged:Connect(OnSelectionChanged)

return InstanceLinkerManager
