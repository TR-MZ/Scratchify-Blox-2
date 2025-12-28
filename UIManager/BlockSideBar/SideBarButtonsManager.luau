local SideBarButtonsManager = {}

-- Constants -------------------------------------------------------------------
local BUTTON_DEFAULT_TEXT_COLOR = Color3.fromRGB(88, 94, 115)
local BUTTON_HOVER_TEXT_COLOR = Color3.fromRGB(95, 149, 248)

local BUTTON_DEFAULT_BACKGROUND_COLOR = Color3.fromRGB(255, 255, 255)
local BUTTON_SELECTED_BACKGROUND_COLOR = Color3.fromRGB(234, 238, 242)

local ButtonTemplate = script.Parent.Assets.ButtonTemplate

local CategoryChangedEvent = Instance.new("BindableEvent")
SideBarButtonsManager.OnCategoryChanged = CategoryChangedEvent.Event

-- Variables -------------------------------------------------------------------
local CurrentCategory = nil
local LibraryWindowOpen = false
local CategoryButtons: {[string]: Instance} = {}
local CategoryNames: {[string]: string} = {}
local SideBarButtonsUI = nil

-- Functions -------------------------------------------------------------------

-- [Local Functions]

-- Function to darken a color
-- @param color: Color3, the color to darken
-- @param d: float number, the darkening factor. 0 - 1 : darker, 1 - 2 : lighter
-- @return Color3, the darkened color
local function DarkenColor(color: Color3, d: number): Color3
	return Color3.new(color.R * d, color.G * d, color.B * d)
end


local function RefreshButtonBackgrounds()
    for category, button in pairs(CategoryButtons) do
        if (button.Name == CurrentCategory) or (category == "Library" and LibraryWindowOpen) then
            button.BackgroundColor3 = BUTTON_SELECTED_BACKGROUND_COLOR
        else
            button.BackgroundColor3 = BUTTON_DEFAULT_BACKGROUND_COLOR
        end
    end
end

local function InitButton(button, categoryId: string, categoryName: string, categoryColor: Color3)
	assert(button, "Button ui must be provided")
	assert(categoryId and categoryName and categoryColor, "Some argument(s) are missing or nil : ("..tostring(categoryId)..tostring(categoryName)..tostring(categoryColor).." )")
	assert(SideBarButtonsUI, "Sidebar Button Manager must have been initialized")
	
	button.Parent = SideBarButtonsUI
    button.Name = categoryId
	button.Title.Text = categoryName
    button.BackgroundColor3 = BUTTON_DEFAULT_BACKGROUND_COLOR
    button.BorderColor3 = BUTTON_DEFAULT_BACKGROUND_COLOR

	-- Set the color of the button
	if categoryId ~= "LIB" then
		button.Color.BackgroundColor3 = categoryColor
		button.Color.UIStroke.Color = DarkenColor(categoryColor, 0.75)
	end
	
    -- Some visual effects
    button.MouseEnter:Connect(function()
        button.Title.TextColor3 = BUTTON_HOVER_TEXT_COLOR
    end)

    button.MouseLeave:Connect(function()
        button.Title.TextColor3 = BUTTON_DEFAULT_TEXT_COLOR
    end)

    -- Button click event
    button.MouseButton1Click:Connect(function()

        -- Change the current category
        CurrentCategory = categoryId

        -- Fire the event
        CategoryChangedEvent:Fire(categoryId)

        -- Update the button backgrounds
        RefreshButtonBackgrounds()

    end)
end


-- [Public Functions]

function SideBarButtonsManager:Init(sideBarButtonsUI)
	assert(sideBarButtonsUI and sideBarButtonsUI:FindFirstChild("Library"), "SideBar buttons UI (Argument 1) must be provided and valid.")
	SideBarButtonsUI = sideBarButtonsUI

    -- Add the block library button
    local LibraryButton = SideBarButtonsUI.Library
    InitButton(LibraryButton, "LIB" , "Library", Color3.fromRGB(255, 255, 255))
	CategoryButtons["LIB"] = LibraryButton
	
end

-- Function to add a category
-- @param category: string
-- @param categoryColor: Color3
function SideBarButtonsManager:AddCategory(categoryId, categoryName,  categoryColor)

	assert(not CategoryButtons[categoryId], "Category already exists")
    assert(categoryColor, "Category color must be provided ("..categoryName..")" )

	
	local button = ButtonTemplate:Clone()
	InitButton(button, categoryId, categoryName, categoryColor)
	CategoryNames[categoryId] = categoryName
	CategoryButtons[categoryId] = button

end

-- Function to get the current category
function SideBarButtonsManager:GetCurrentCategory()
    return CurrentCategory
end

-- Function to set the current category
function SideBarButtonsManager:SetCurrentCategory(categoryId)
	CurrentCategory = categoryId
    RefreshButtonBackgrounds()
end

-- Function to set the library window open state
function SideBarButtonsManager:SetLibraryWindowOpen(open: boolean)
    LibraryWindowOpen = open
    RefreshButtonBackgrounds()
end

-- Functon to clear all categories 
function SideBarButtonsManager:ClearCategories()
	for cat, button in pairs(CategoryButtons) do
		
		-- do not delet lib button:
		if cat == "LIB" then continue end
        button:Destroy()
    end
    CategoryButtons = {}
end

-- Function to check if the library window is open
-- @return boolean
function SideBarButtonsManager:IsLibraryWindowOpen()
    return LibraryWindowOpen
end





return SideBarButtonsManager