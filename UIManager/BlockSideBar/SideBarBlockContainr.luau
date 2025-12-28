local SideBarBlockContainer = {}


-- Services --------------------------------------------------

local TweenService = game:GetService("TweenService")

-- Constants -------------------------------------------------

-- Variables -------------------------------------------------

local SideBar: ScrollingFrame = nil

local Categories : {string} = {} -- Now stores category IDs
local CategoryNames: {[string]: string} = {} -- Maps category IDs to display names
local CategorySeparators: {[string]: TextLabel} = {} -- Maps category IDs to their separator instances
local CategoryBlocks: {[string]: {Instance}} = {}

local onScrollCategoryChangedEvent = Instance.new("BindableEvent")
SideBarBlockContainer. OnScrollCategoryChanged = onScrollCategoryChangedEvent.Event

local lastFocusedCategory = nil

local animating = false
-- Functions -------------------------------------------------

-- [Private Functions]

local function onScroll()
	if animating then return end
	
	local lastCategoryOnTop = nil
	for _, category in pairs(Categories) do
		if CategorySeparators[category].AbsolutePosition.Y <= 7 then -- if the separator is on top with a little visibility offset
			lastCategoryOnTop = category
		else 
			break
		end
	end
	
	if not lastCategoryOnTop or lastCategoryOnTop == lastFocusedCategory then return end
	lastFocusedCategory = lastCategoryOnTop
	onScrollCategoryChangedEvent:Fire(lastCategoryOnTop)
end

-- [Public Functions]

function SideBarBlockContainer:Init(sideBarFrame: ScrollingFrame)
	assert(sideBarFrame, "Argument 1 cannot be nil")
	SideBar = sideBarFrame
	
	-- Detect scroll category change
	SideBar:GetPropertyChangedSignal("CanvasPosition"):Connect(onScroll)
end

-- Function to scroll to a specific category in the sidebar
-- @param categoryId: string, the ID of the category to scroll to
function SideBarBlockContainer:ScrollToCategory(categoryId: string, withAnnimation: boolean)
	assert(table.find(Categories, categoryId), "Category ID does not exist")
    
	local DesiredPosition = SideBar.CanvasPosition.Y + CategorySeparators[categoryId].AbsolutePosition.Y - 5

    if withAnnimation then
		local Tween = TweenService:Create(SideBar, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {CanvasPosition = Vector2.new(0, DesiredPosition)})
		animating = true
		Tween:Play()
		Tween.Completed:Wait()
		animating = false
		lastFocusedCategory = categoryId
    else
        SideBar.CanvasPosition = Vector2.new(0, DesiredPosition)
    end
end

-- Function to add a block to the sidebar, under the last category
-- @param block: Frame, the block to add
-- @param categoryId: string, the category id
function SideBarBlockContainer:AddBlock(block: Frame, categoryId: string)
	assert(block:IsA("Frame"), "Block must be a Frame")

	local index = table.find(Categories, categoryId)
	assert(index, "Category cannot be nil or not registred ( "..tostring(categoryId).." )")
	
	block.LayoutOrder = index
	block.Parent = SideBar
	
	table.insert(CategoryBlocks[categoryId], block)
end

-- Function to remove a block from the sidebar
-- @param block: Frame, the block to remove
function SideBarBlockContainer:RemoveBlock(block: Frame)
    block.Parent = nil
end

-- Function to clear all blocks from the sidebar
function SideBarBlockContainer:Clear()
    for _, block in ipairs(SideBar:GetChildren()) do
        if block:IsA("Frame") or block:IsA("TextLabel") then
            block:Destroy()
        end
    end
    CategorySeparators = {}
    Categories = {}
    CategoryNames = {}
end

-- Function to get a category name from its ID
-- @param categoryId: string, the ID of the category
-- @return string, the display name of the category
function SideBarBlockContainer:GetCategoryName(categoryId: string): string
    assert(CategoryNames[categoryId], "Category ID does not exist")
    return CategoryNames[categoryId]
end

-- Function to add a category to the sidebar. It will also add the category separator
-- @param categoryId: string, the unique identifier for the category
-- @param categoryName: string, the display name for the category
function SideBarBlockContainer:AddCategory(categoryId: string, categoryName: string)
    assert(type(categoryId) == "string", "Category ID must be a string")
    assert(type(categoryName) == "string", "Category name must be a string")
    assert(not table.find(Categories, categoryId), "Category ID already exists")

    table.insert(Categories, categoryId)
    CategoryNames[categoryId] = categoryName

    local categorySeparator = script.Parent.Assets.CategoryTitleText:Clone()
	categorySeparator.Parent = SideBar
	categorySeparator.Text = categoryName
	categorySeparator.LayoutOrder = #Categories -- last of {Categories} is our category index as we just added it
	
    
    CategorySeparators[categoryId] = categorySeparator
	CategoryBlocks[categoryId] = {}
	
    return categorySeparator
end

return SideBarBlockContainer