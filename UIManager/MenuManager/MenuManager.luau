
local MenuManager = {}



-- Services -------------------------------------------------
local TweenService = game:GetService("TweenService")
-- Types ----------------------------------------------------
export type MenuOption = {
	Name: string,
	Callback : () -> any
}
-- Constants -------------------------------------------------
local PADDING = 8

local MenuUI = script.Parent.Assets.Menu
local FocusButton = script.Parent.Assets.FocusButton 
local MenuOptionTemplate = script.Parent.Assets.MenuOption

-- Variables -------------------------------------------------

local currentMenuContent = {}

local Widget: DockWidgetPluginGui
local Plugin: plugin

local Hovered = false
-- Functions -------------------------------------------------


-- [Private Functions]

-- [Public Functions]

function MenuManager:Init(plugin: Plugin, widget: DockWidgetPluginGui)
	assert(plugin and widget, "Missing arguments")
	Widget = widget
	Plugin = plugin

	plugin:GetMouse().Button1Down:Connect(function()
		MenuManager:Clear()
	end)

	MenuUI.MouseEnter:Connect(function()
		Hovered = true
	end)
	MenuUI.MouseLeave:Connect(function()
		Hovered = false
	end)

	FocusButton.MouseButton1Down:Connect(function()
		MenuManager:Clear()
	end)
end

function MenuManager:Menu(position, options)

	FocusButton.Parent = Widget

	for _, element in pairs(currentMenuContent) do
		element:Destroy()
	end

	table.clear(currentMenuContent)

	MenuUI.Parent = Widget
	MenuUI.Position = position

	local SizeY = 0
	
	local largerButtonWidth = 0
	for _, option in pairs(options) do
		local menuOption: TextButton = MenuOptionTemplate:Clone()
		menuOption.Parent = MenuUI.Content
		menuOption.Text = option.Name
		menuOption.Visible = true

		menuOption.MouseButton1Down:Connect(function()
			MenuManager:Clear()
			option.Callback()
		end)

		table.insert(currentMenuContent, menuOption)

		SizeY += menuOption.Size.Y.Offset 
		
		
		
		largerButtonWidth = math.max(menuOption.TextBounds.X + PADDING * 2, largerButtonWidth)
	end


	MenuUI.Size = UDim2.new()
	
	for _, option in pairs(currentMenuContent) do
		option.Size = UDim2.fromOffset(largerButtonWidth, option.Size.Y.Offset)
	end

	local Tween = TweenService:Create(MenuUI, 
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.fromOffset( 0, SizeY + 2 * PADDING )})

	Tween:Play()
end

function MenuManager:Clear()
	for _, element in pairs(currentMenuContent) do
		element:Destroy()
	end
	table.clear(currentMenuContent)

	MenuUI.Parent = nil
	FocusButton.Parent = nil
end

return MenuManager
