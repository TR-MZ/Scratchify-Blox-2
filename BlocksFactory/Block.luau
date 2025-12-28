

-- Services ------------------------------------

local HttpService = game:GetService("HttpService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local TweenService = game:GetService("TweenService")
-- Types ----------------------------------------

export type BlockContent = {
	contenttype : "Text" | "AnyValue" | "NumberValue" | "Picker" | "GetValue" | "",
	content		: {string} | string | nil | number 
}

-- Bridge for naming conventions from ScratchifyBloxV2 to ScratchifyBlox3 blocks. Will be removed when all blocks are ported to V3.
-- type : [string V3 type]: string V2 type
local BlockTypeNameV2Bridge = {
	Normal = "Block",
	ClosureStart = "CBlock", 
	ClosureEnd = "CBlockEnd",
	ClosureMiddle = "EBlockMiddle", 
	Event = "HatBlock",
	Value = "ValueBlock",
	DoubleClosureStart = "EBlock"
}

export type BlockTypeV2 = "Normal" | "ClosureStart" | "ClosureEnd" | "ClosureMiddle" | "Event" | "Value" | "DoubleClosureStart"
export type BlockTypeV3 = "Block" | "CBlock" | "CBlockEnd" | "EBlockMiddle" | "HatBlock" | "ValueBlock" | "Terminal" | "EBlock"

export type BlockCategory =  "Motion" | "Looks" | "Sound" | "Events" | "Controls" | "Sensing" | "Operators" | "Variables"

export type BlockData = {
	id			: string | number,

	specificTo	: string | nil , -- the block will be filtered to this specific instance type and not visible in the editor if the selected instance is not of this type.

	category	: BlockCategory ,

	blockType	: BlockTypeV2 | BlockTypeV3, -- the block type, such as "Normal" or "ClosureStart"

	content		: {BlockContent},

	func : string -- the function to call when the block is executed, as a string. 
}


-- Variables ------------------------------------


local DataManager = nil
local Blocks: {[string]: BlockClass} = {}
local plugin = nil
local widget: DockWidgetPluginGui = nil
local canvasFrame: ScrollingFrame = nil

local _LastZindex = 1

local RegistredBlocks: {[string]: Block} = {}

local RegistredBlockContainers: {[Block]: {Frame}} = {} -- each block here will have only 1 container, so the lists will be #1 in length
local RegistredValueContainers: {[Block]: {Frame}} = {}

local BlockByFrame: {[Frame]: Block} = {} -- this will be used to get the block by its frame

local DraggingBlock: BlockClass = nil

local HighlighterFrames : {[Frame]: Frame} = {} -- [Container]: HighlightFrame

local VariableManager
-- Constants ------------------------------------

-- [UI Elements]

local FOLDER_DEFAULTBLOCK_FRAME = script.Parent.Assets.DefaultBlockFrames
local FOLDER_DEFAULTBLOCK_CONTENT = script.Parent.Assets.DefaultBlockContents
local ASSET_VALUEHIGHLIGHTER = script.Parent.Assets.ValueHighlight
local ASSET_DROPDOWN = script.Parent.Assets.Dropdown
local ASSET_FOCUSBUTTON = script.Parent.Assets.FocusButton
-- [Helper Block Datas]

local Data_CBlockEnd : BlockData = {
	specificTo = nil,
	category = nil,
	func = "end\n",
	blockType = "CBlockEnd",
	content = {
		{contenttype = "Text",
			content = "End",}
	}
}

local Data_EBlockMiddle: block = {
	specificTo = nil,
	category = nil,
	func = "else\n",
	blockType = "EBlockMiddle",
	content = {
		{contenttype = "Text",
			content = "Else",}
	}
}


-- Module Definition ----------------------------

export type BlockClass = {
	new: (blockData: BlockData, parent: Instance, frame: Frame?, color: Color3) -> BlockClass,
	Init: (self: BlockClass, _plugin: any, _widget: any, _canvasFrame: any) -> (),
	Clone: (self: BlockClass, parent: Instance?) -> BlockClass,
	SetTemplateMode: (self: BlockClass, isTemplate: boolean) -> (),
	StopDragging: (self: BlockClass) -> (),
	StartDragging: (self: BlockClass) -> BlockClass?,
	GetBlockType: (self: BlockClass) -> BlockTypeV3?,
	GetChildBlock: (self: BlockClass) -> BlockClass?,
	RemoveChildBlock: (self: BlockClass) -> BlockClass?,
	UnparentBlock: (self: BlockClass) -> (),
	SetChildBlock: (self: BlockClass, block: BlockClass) -> (),
	LinkValueBlockToContainer: (self: BlockClass, block: BlockClass, container: Frame) -> boolean,
	UnlinkFromContainer: (self: BlockClass) -> (),
	GetValueContainers : (self: BlockClass) -> {Frame},
	GetTreeSize: (self: BlockClass) -> Vector2,
	
	blockData: BlockData?,
	color: Color3?,
	blockFrame: Frame?,
	isTemplate: boolean?,
	IsDragging: boolean?,
	BlockData: BlockData?,
	frame: Frame?,
	childBlock: BlockClass?,
	parentBlock: BlockClass?,
	replacedValueBlocks : {BlockClass}, -- {[index of the content] : value block BlockClass}
	
	Changed: RBXScriptSignal
}

local Block = {}
Block.__index = Block
	
	
-- Events  --------------------------------------

local onScriptChangedEvent = Instance.new("BindableEvent")
Block.Changed = onScriptChangedEvent.Event


local BlockRightClickEvent = Instance.new("BindableEvent")
Block.OnBlockRightRightClicked = BlockRightClickEvent.Event

-- Functions ------------------------------------

-- [Private Functions]

-- Function to darken a color
-- @param color: Color3, the color to darken
-- @param d: float number, the darkening factor. 0 - 1 : darker, 1 - 2 : lighter
-- @return Color3, the darkened color
local function DarkenColor(color: Color3, d: number): Color3
	return Color3.new(color.R * d, color.G * d, color.B * d)
end

-- Function to deep copy a table
-- @param t: table, the table to deep copy
-- @return table, the deep copied table
local function DeepCopy(t: {}): {}
	local result = {}
	for k, v in pairs(t) do
		if typeof(v) == "table" then
			result[k] = DeepCopy(v)
		else
			result[k] = v
		end
	end
	return result
end

-- Shows a dropdown picker UI below (or above) the given frame with selectable options.
-- Handles option selection, visual highlighting, and animation.
--
-- @param frame Frame - The UI frame under/above which the dropdown should appear.
-- @param content table - A table containing:
--        - pickerContent: table of strings (or objects convertible to strings) to show in the dropdown.
--        - content: string representing the currently selected value.
-- @param color Color3 - The background color for each dropdown row and the dropdown background.
-- @param callback function - Function to call when a new option is selected. Passes the selected string as an argument.
local function ShowDropdownPicker(frame: Frame, content: {pickerContent: {string}, content: string}, color, callback: (string) -> any)
	-- Set the focus button’s parent to our widget (assumed to be defined in your scope)
	ASSET_FOCUSBUTTON.Parent = widget

	local focusButtonConnection

	-- Function to cleanup dropdown and focus button
	local function closeDropdown()
		ASSET_DROPDOWN.Parent = nil
		ASSET_FOCUSBUTTON.Parent = nil
		if focusButtonConnection then
			focusButtonConnection:Disconnect()
		end
	end

	-- Connect focus button click to callback and close dropdown
	focusButtonConnection = ASSET_FOCUSBUTTON.MouseButton1Down:Connect(function()
		callback(content.content)
		closeDropdown()
	end)
	


	-- Clear existing rows from dropdown content
	for _, child in pairs(ASSET_DROPDOWN.Content:GetChildren()) do
		if child.Name == "Row" then
			child:Destroy()
		end
	end

	-- Set dropdown parent and adjust content sizing
	ASSET_DROPDOWN.Parent = widget
	ASSET_DROPDOWN.Content.AutomaticSize = Enum.AutomaticSize.Y
	ASSET_DROPDOWN.Content.Size = UDim2.fromOffset(180, 40)

	-- Populate dropdown rows from pickerContent
	for _, item in ipairs(content.pickerContent) do
		local itemText = typeof(item) == "string" and item or (item.Name or tostring(item))
		local row = ASSET_DROPDOWN.Content.RowTemp:Clone()
		row.Parent = ASSET_DROPDOWN.Content
		row.Visible = true
		row.Name = "Row"
		row.Check.Visible = (itemText == content.content)
		row.TextLabel.Text = itemText or ""
		row.BackgroundColor3 = color

		row.MouseButton1Down:Connect(function()
			content.content = itemText
			callback(itemText)
			closeDropdown()
		end)
	end

	-- Adjust dropdown height if necessary
	if ASSET_DROPDOWN.Content.AbsoluteSize.Y > widget.AbsoluteSize.Y / 2 - 40 then
		ASSET_DROPDOWN.Content.AutomaticSize = Enum.AutomaticSize.None
		ASSET_DROPDOWN.Content.Size = UDim2.fromOffset(180, widget.AbsoluteSize.Y / 2 - 40)
	end

	ASSET_DROPDOWN.ImageColor3 = color

	-- Set initial dropdown position below the frame
	local initialPosition = UDim2.fromOffset(
		frame.AbsolutePosition.X + frame.AbsoluteSize.X / 2, 
		frame.AbsolutePosition.Y + frame.AbsoluteSize.Y - 15
	)
	ASSET_DROPDOWN.Position = initialPosition

	local dropdownHeight = ASSET_DROPDOWN.Content.AbsoluteSize.Y + 30
	local belowY = frame.AbsolutePosition.Y + frame.AbsoluteSize.Y - 15
	local aboveY = frame.AbsolutePosition.Y - dropdownHeight + 45
	

	local baseX = frame.AbsolutePosition.X + frame.AbsoluteSize.X / 2

	if belowY + dropdownHeight > widget.AbsoluteSize.Y then
		-- Show above the frame
		local positionAbove = UDim2.fromOffset(baseX, aboveY)
		ASSET_DROPDOWN.Position = positionAbove
		ASSET_DROPDOWN.Content.Position = UDim2.new(0.5, 0, 0, 0)
		ASSET_DROPDOWN.Image = "rbxassetid://18429068180"
		ASSET_DROPDOWN.Content.UIPadding.PaddingBottom = UDim.new(0, 13)

		TweenService:Create(ASSET_DROPDOWN, TweenInfo.new(0.4, Enum.EasingStyle.Circular), {
			Position = positionAbove - UDim2.fromOffset(0, 25)
		}):Play()
	else
		-- Show below the frame
		local positionBelow = UDim2.fromOffset(baseX, belowY)
		ASSET_DROPDOWN.Position = positionBelow
		ASSET_DROPDOWN.Content.Position = UDim2.new(0.5, 0, 0, 8)
		ASSET_DROPDOWN.Image = "rbxassetid://18429060428"
		ASSET_DROPDOWN.Content.UIPadding.PaddingBottom = UDim.new(0, 5)

		TweenService:Create(ASSET_DROPDOWN, TweenInfo.new(0.4, Enum.EasingStyle.Circular), {
			Position = positionBelow + UDim2.fromOffset(0, 25)
		}):Play()
	end

end

-- Function to set the plugin mouse icon
-- @param icon: string? the icon asset url. Default is arrow
local function SetPluginMouseIcon(icon: string )
	icon = icon or "rbxasset://SystemCursors/Arrow"

	plugin:GetMouse().Icon = icon
end

-- Function to get the mouse position relative to the widget
-- @return Vector2, the mouse position relative to the widget
local function GetMousePosition()
	return widget:GetRelativeMousePosition()
end

-- Function to generate a new GUID
-- @return string, the new GUID
local function GenerateGUID()
	return HttpService:GenerateGUID(false)
end

-- Function to move a frame to the top of the ZIndex
-- @param frame: Frame, the frame to move to the top
local function MoveToTop(frame: Frame)
	_LastZindex += 1
	for _, ins in pairs(frame:GetDescendants()) do
		if ins:IsA("GuiObject") then
			ins.ZIndex = _LastZindex
		end
	end
end

-- Get the last enclosed block in the current enclosure.
-- @param blockFrame: Frame, the block frame to get the content from
local function GetBlockCBlockContent(block: BlockClass): BlockClass
	local count = 0

	local currentBlock = block
	
	if currentBlock:GetBlockType() == "CBlock" or currentBlock:GetBlockType() == "EBlock" then
		count += 1
	end
	
	if not block.childBlock then return end

	while true do
		if currentBlock.childBlock:GetBlockType() == "CBlock" or currentBlock.childBlock:GetBlockType() == "EBlock" then
			count += 1
		elseif currentBlock.childBlock:GetBlockType() == "CBlockEnd" or currentBlock.childBlock:GetBlockType() == "EBlockMiddle" then
			count -= 1
		end
		if count < 0 then
			return currentBlock
		else
			if currentBlock.childBlock:GetBlockType() == "EBlockMiddle" then
				count += 1
			end
			local sub = currentBlock.childBlock
			if sub.childBlock then
				currentBlock = sub
			else
				return nil
			end 
		end



	end

end

-- Helper function to see if a 2D box contains a 2D point
-- @param Start: Vector2, the start position of the box
-- @param End: Vector2, the end position of the box
-- @param point: Vector2, the point to check
-- @return boolean, true if the point is inside the box
local function IsPointInBox(Start: Vector2, End: Vector2, point: Vector2): boolean
	return point.X >= Start.X and point.X <= End.X and point.Y >= Start.Y and point.Y <= End.Y
end

-- @param block: BlockClass, the block to check to blacklist . This will also be used to check the type of the contained (value or block)
-- @param position: Vector2, the position to check
-- @return BlockClass, Frame, the block which child container is at the mouse position
local function GetChildContainerAtPosition(block: BlockClass, position: Vector2): (BlockClass, Frame)
	assert(block, "block cannot be nil")

	-- TODO, this gotta be optimized 

	local highestZIndex = 0
	local highestBlock = nil
	local highestFrame = nil

	local containerTable = block:GetBlockType() == "ValueBlock" and RegistredValueContainers or RegistredBlockContainers

	-- because childContainer is a frame inside block frame, this will also blocklist the child blocks
	local blacklistedContainers = block.blockFrame:GetDescendants()

	for block, containers: Frame in pairs(containerTable) do 
		for _, container in pairs(containers) do
			-- check if the container is blacklisted or if the block is a template
			if table.find(blacklistedContainers, container) or block.isTemplate then continue end


			local Start = container.AbsolutePosition
			local End = container.AbsolutePosition + container.AbsoluteSize


			if IsPointInBox(Start, End, position) and container.ZIndex > highestZIndex then
				highestZIndex = container.ZIndex
				highestBlock = block
				highestFrame = container
			end
		end

	end

	return highestBlock, highestFrame

end


-- Function to highlight/unhighlight a block container (used in dragging functionality when a container is hovered)
-- @param block: BlockClass, the block to put in the container (reference for highlighting)
-- @param container: Frame, the container to highlight
-- @param highlight: boolean, true to highlight, false to unhighlight
local function HighlightContainer(block: BlockClass, container: Frame, highlight: boolean)
	if block:GetBlockType() == "ValueBlock" then
		if highlight then
			if HighlighterFrames[container] then return end 
			
			local hFrame = ASSET_VALUEHIGHLIGHTER:Clone()
			hFrame.Parent = widget -- the BlockFrame 
			
			hFrame.Bound.Image.ZIndex = container.ZIndex + 1
			
			hFrame.Bound.Position = UDim2.fromOffset( container.AbsolutePosition.X,  container.AbsolutePosition.Y)
			
			hFrame.Bound.Size = UDim2.fromOffset(container.AbsoluteSize.X, container.AbsoluteSize.Y)
			
			HighlighterFrames[container] = hFrame

		else
			if HighlighterFrames[container] then
				HighlighterFrames[container] :Destroy()
				HighlighterFrames[container] = nil
			end
		end
	else
		if highlight then
			if HighlighterFrames[container] then return end -- no need to highlight again
			
			local treeHeight = block:GetTreeSize().Y
			local containerChild = container:FindFirstChildWhichIsA("Frame")
			if containerChild then
				containerChild.Position = UDim2.fromOffset(0, treeHeight) -- we move the child to offset it
			end
			
			local hFrame = block.blockFrame:Clone()
			hFrame.Parent = widget
			
			-- Clear the frame to make only visible the block images + make the blocks gray and transparent, and set the Zindex to the container Zindex
			local currentFrame: Frame =  hFrame
			while currentFrame do
				
				local BlockFrame : ImageButton = currentFrame.Block
				
				local BlockFrameABSSize = BlockFrame.AbsoluteSize -- when deleting the content, the size will come back to minimal as it is AutomaticSize, so we set the size manually
				BlockFrame.Size = UDim2.fromOffset(BlockFrameABSSize.X, BlockFrameABSSize.Y)
				
				for _, child in pairs(BlockFrame:GetChildren()) do
					child:Destroy()
				end
				
				BlockFrame.ImageTransparency = 0.6
				BlockFrame.ImageColor3 = Color3.new(0.574151, 0.574166, 0.574151)
				BlockFrame.ZIndex = container.ZIndex
				
				currentFrame =  currentFrame:FindFirstChild("ChildContainer") and currentFrame.ChildContainer:FindFirstChildWhichIsA("Frame")
			end
			
			-- for block with indent
			local indent = container:FindFirstChild("UIPadding") and container.UIPadding.PaddingLeft.Offset or 0
			
			hFrame.Position = UDim2.fromOffset(container.AbsolutePosition.X + indent , container.AbsolutePosition.Y) 
			
			HighlighterFrames[container] = hFrame
		else
			local containerChild = container:FindFirstChildWhichIsA("Frame")
			if containerChild then
				containerChild.Position = UDim2.new()
			end

			if HighlighterFrames[container] then
				HighlighterFrames[container] :Destroy()
				HighlighterFrames[container] = nil
			end
		end
	end
end

-- [Public Functions]

-- Function to get a block frame using it's UID

-- Function to init the block module
-- @param _plugin: Plugin, the plugin instance
-- @param _widget: DockWidgetPluginGui, the editor widget instance
-- @param _canvasFrame: ScrollingFrame, the canvas frame
function Block:Init(_plugin, _widget, _canvasFrame, variableManager)
	assert(_plugin and _widget and _canvasFrame and variableManager , "Block:Init() : Invalid arguments!")

	if plugin then 
		warn(":Init() has already been called!")
	end

	plugin = _plugin
	widget = _widget
	canvasFrame = _canvasFrame
	VariableManager = variableManager
end

-- Creates a new **Block**
-- @param blockData: BlockData, the data of the block content

-- @param parent: Instance?, the instance which the block frame will be parented to. If a frame is provided (Arg 3) , the parent will be frame's parent.
-- @param frame: Frame? , a frame to init the block on if not wanting to make a new block frame. (like appliying a blockdata on an existing frame.)
function Block.new(blockData: BlockData, parent: Instance, frame: Frame?, color: Color3)


	-- Check if the module was initalized first
	assert(plugin, "To use the block module, you need to first initialize it using :Init()")

	assert(blockData and blockData.blockType, "block data MUST be provided")

	local self : BlockClass = setmetatable({}, Block)

	blockData = DeepCopy(blockData)

	assert(blockData and blockData.blockType, "error copying block data")

	self. blockData = blockData
	self. color = color

	-- Convert the blockType from V2 to V3 
	if BlockTypeNameV2Bridge[blockData.blockType] then
		blockData.blockType = BlockTypeNameV2Bridge[blockData.blockType]
	end

	if frame then
		self. blockFrame = frame
	else
		local frameFound = FOLDER_DEFAULTBLOCK_FRAME:FindFirstChild(blockData.blockType)

		if not frameFound then
			local errorDescription = {
				Inside = "Block.new() function, in Block module.",
				Error = "Block template frame not found for blocktype "..tostring(blockData.blockType), 
				Blockdata = blockData
			}
			warn("Scratchify Important error: block could'nt be initialized. Expend to see more:", errorDescription)

			return nil
		end		

		self.blockFrame = frameFound:Clone()
	end
	
	-- Color the block

	if blockData.blockType == "ValueBlock" then
		self.blockFrame .Block.BackgroundColor3 = color
		self.blockFrame .Block.UIStroke.Color = DarkenColor(color, 0.75)
	else
		self.blockFrame .Block.ImageColor3 = color
	end
	
	-- clientID is specialy
	if self.blockData.clientID and self.blockData.clientID == "" then
		local id = GenerateGUID()
		self.blockData.clientID = id 
	end

	-- init the block ui
	local function initUI()

		self. blockFrame.Parent = frame and frame.Parent or (parent or canvasFrame)
		self. blockFrame.BackgroundColor3 = color

		-- Darken the block strokes if they exist
		local UIStroke = self. blockFrame.Block:FindFirstChild("UIStroke")
		if UIStroke then
			UIStroke.Color = DarkenColor(color, 0.8)
		end

		-- Registed the block container
		if self.blockData.blockType ~= "ValueBlock" and self.blockData.blockType ~= "Terminal" then
			-- Valueblock child containers are registred in 'initContent'
			RegistredBlockContainers[self] = {self.blockFrame.ChildContainer}
		end

	end

	-- init the block centent
	local function initContent()

		RegistredValueContainers[self] = {}

		for i, content: BlockContent in pairs(blockData.content) do

			local contentUI = FOLDER_DEFAULTBLOCK_CONTENT:FindFirstChild(content.contenttype)

			if not contentUI  then
				local errorDescription = {
					Inside = "Block.new() -> initContent function, in Block module.",
					Error = "Block content template frame not found for contentype "..tostring(content.contenttype), 
					Content = content
				}
				warn("Scratchify Important error: block could'nt be initialized. Expend to see more:", errorDescription)
				return
			end

			contentUI = contentUI:Clone()

			contentUI.Parent = self.blockFrame.Block

			if content.contenttype == "Text" then

				contentUI.Text = content.content or ""



			elseif content.contenttype == "NumberValue" then -- Number input

				contentUI.TextBox.Text = content.content or ""

				local previousContent = content.content
				contentUI.TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- check if valid number input
					if tonumber(contentUI.TextBox.Text) or contentUI.TextBox.Text == "" then
						previousContent = contentUI.TextBox.Text
					else
						contentUI.TextBox.Text = previousContent or ""
					end
					self.blockData.content[i].content = previousContent
				end)

				table.insert(RegistredValueContainers[self], contentUI)
				
				-- Saving
				contentUI.TextBox.FocusLost:Connect(function()
					onScriptChangedEvent:Fire()
				end)

			elseif content.contenttype == "AnyValue" then -- Any type input

				contentUI.TextBox.Text = content.content or ""
				contentUI.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
					self.blockData.content[i].content = contentUI.TextBox.Text
				end)

				table.insert(RegistredValueContainers[self], contentUI)
				
				-- Saving
				contentUI.TextBox.FocusLost:Connect(function()
					onScriptChangedEvent:Fire()
				end)
				
			elseif content.contenttype == "Picker" then -- Dropdown picker
				
				
				contentUI.Title.Text = content.content or ""
				
				contentUI.MouseButton1Down:Connect(function()
					if content.pickerContentName == "variables" then
						content.pickerContent = VariableManager:GetVariables()
					end
					
					ShowDropdownPicker(contentUI, content, color, function(selected)
						content.content = selected
						contentUI.Title.Text = selected or ""
					end)
				end)
				
			elseif content.contenttype == "GetValue" then -- Ouput

				local contentBlockData: block = {
					specificTo = nil,
					category = self.blockData.category,
					blockType = "Value",
					func = content.content ,
					content = {
						{
							content = content.contentLabel,
							contenttype = "Text"
						}
					}
				}

				local ouputBlock: BlockClass = Block.new(contentBlockData, nil, contentUI.Value, color)
				ouputBlock:SetTemplateMode(true)

			end	
		end
	end

	local function initdragging()

		-- Dragging functionality
		local function onMouseButton1Down()
			self:StartDragging()
		end

		local function onMouseButton1Up()
			self:StopDragging()
		end

		local function onMouseEnter()
			wait()
			if not DraggingBlock then
				SetPluginMouseIcon("rbxasset://SystemCursors/OpenHand")
			end
		end

		local function onMouseLeave()
			if not DraggingBlock then
				SetPluginMouseIcon("rbxasset://SystemCursors/Arrow")
			end
		end
		
		self.RightClickActions = {
			{Name = "Duplicate", Callback = function()
				local clone = self:Clone()
				clone:StartDragging(Vector2.new(10, 10))
			end,},
			{Name = "Delet", Callback = function()
				self:Destroy()
			end}
		}
		
		local function onRightClick()
			-- A bug makes it not passing the self so i have to pass the needed functions
			BlockRightClickEvent:Fire(self.RightClickActions)
			
		end

		self.blockFrame.Block.MouseButton1Down:Connect(onMouseButton1Down)
		self.blockFrame.Block.MouseButton1Up:Connect(onMouseButton1Up)
		self.blockFrame.Block.MouseEnter:Connect(onMouseEnter)
		self.blockFrame.Block.MouseLeave:Connect(onMouseLeave)
		self.blockFrame.Block.MouseButton2Down:Connect(onRightClick)
		
	end



	initUI()
	initContent()
	
	-- Make the child container alway keep the same width as the block
	local childContainer: Frame = self.blockFrame:FindFirstChild("ChildContainer") 
	local blockFrame = self.blockFrame
	if childContainer then
		
		childContainer.Visible = true
		
		local function resizeChildContainer()
			childContainer.Size = UDim2.fromOffset(blockFrame.AbsoluteSize.X, childContainer.Size.Y.Offset)
		end
		
		blockFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeChildContainer)

		resizeChildContainer()
	end
	
	if self:GetBlockType() ~= "CBlockEnd" and self:GetBlockType() ~= "EBlockMiddle" then
		initdragging()
	end


	-- Add the CBlockend and EBlockMiddle for CBlock 
	-- We add to blockdata a tag saying it was added so when we save / load , endblock and otner don't multyplie
	if not blockData.didInitCBlockSubs then
		if self:GetBlockType() == "CBlock" or self:GetBlockType() == "EBlockMiddle" then

			local cBlockEnd = Block.new(Data_CBlockEnd, self.blockFrame.ChildContainer , nil, color)
			self:SetChildBlock(cBlockEnd)
			
			blockData.didInitCBlockSubs = true
			
			
		elseif self:GetBlockType() == "EBlock" then
			local cBlockMiddle= Block.new(Data_EBlockMiddle, self.blockFrame.ChildContainer , nil, color)
			self:SetChildBlock(cBlockMiddle)
			
			blockData.didInitCBlockSubs = true
			
		end
	end

	BlockByFrame[self.blockFrame] = self
	self.replacedValueBlocks = {}
	
	MoveToTop(self.blockFrame)
	
	
	
	return self
end


-- Adds a action to the menu when the block is right clicked
function Block:AddRightClickAction (name, action)
	table.insert(self.RightClickActions, {
		Name = name,
		Callback = action
	})
end

-- Clear all the blocks from the canvas / registering
-- Used for changing 
function Block.Clear()
	for _, block: BlockClass in pairs(BlockByFrame) do
		block:Destroy()
	end
	table.clear(BlockByFrame)
	table.clear(RegistredValueContainers)
	table.clear(RegistredBlocks)
	table.clear(RegistredBlockContainers)
end



-- Function to clone the block
-- @param parent: Instance?, the instance which the block frame will be parented to. If nil, the block will keep the same parent.
-- @return BlockClass, the cloned block
function Block:Clone(parent: Instance?): BlockClass
	local clone: BlockClass = Block.new(self.blockData, parent or canvasFrame, nil, self.color)
	-- Content:
	
	for index: number, valueC: Frame in pairs( RegistredValueContainers[self]) do
		local valueBlock : BlockClass = self.replacedValueBlocks[index]
		if valueBlock then
			local valueBlockClone = valueBlock:Clone()
			clone:LinkValueBlockToContainer(valueBlock, valueC)
		end
	end
	
	-- now do child
	if self.childBlock then
		local clonedChild = self.childBlock:Clone()
		clone:SetChildBlock(clonedChild)
	end
	
	return clone
end

-- Function to set the block as a template, meaning it will clone itself when dragged and not move
-- @param isTemplate: boolean, whenever the block is a template, such as the blocks inside the BlokSideBar. The block will make a blone of itself when dragged.
function Block:SetTemplateMode(isTemplate)
	self.isTemplate = isTemplate
	if self:GetBlockType() ~= "ValueBlock" and self:GetBlockType() ~= "Terminal" and self:GetBlockType() ~= "CBlock" and self:GetBlockType() ~= "EBlock" and self:GetBlockType() ~= "EBlockMiddle" then

		self.blockFrame.ChildContainer.Visible = not isTemplate
	end
end

-- Function to stop dragging the block
function Block:StopDragging()
	self.IsDragging = false
end

-- Function to start dragging the block
-- @param draggingOffset: Vector2? optional dragging offset block-mouse overide
-- Returns a new block if the block is a template, otherwise returns the block itself
function Block:StartDragging(draggingOffset: Vector2?) : BlockClass
	
	

	local blockFrame = self.blockFrame
	local blockType: BlockTypeV3 = self:GetBlockType()
	local mousePosition = GetMousePosition()

	draggingOffset = draggingOffset or (mousePosition - blockFrame.AbsolutePosition)

	if self.isTemplate  then
		local block: BlockClass = self:Clone()
		block:SetTemplateMode(false)
		block:StartDragging(draggingOffset)
		return block
	end

	self.IsDragging = true
	DraggingBlock = self

	SetPluginMouseIcon("rbxasset://SystemCursors/ClosedHand")


	MoveToTop(blockFrame)
	MoveToTop(blockFrame)

	if self:GetBlockType() == "ValueBlock" then
		self:UnlinkFromContainer()
	else 
		-- Unparent this block if it has a parent block
		local parentBlock: BlockClass = self.parentBlock
		if parentBlock then
			parentBlock:RemoveChildBlock()

			-- Check for enclosure, if the block is inside a CBlock enclosure, we will not move the blocks outside the enclosure
			-- And we parent the "end" or "middleend" to our current parent.
			local lastBlock = GetBlockCBlockContent(self)
			if lastBlock and lastBlock:GetChildBlock() then
				local childBlock = lastBlock:RemoveChildBlock()
				parentBlock:SetChildBlock(childBlock)
			end

		end
	end

	blockFrame.Parent = widget

	local hoveredContainer, hoveredFrame = nil
	local previoushoveredContainer, previousHoveredFrame = nil
	while self.IsDragging do
		mousePosition = GetMousePosition()
		blockFrame.Position = UDim2.fromOffset(mousePosition.X - draggingOffset.X, mousePosition.Y - draggingOffset.Y)

		-- Highlight hovered block containers --
		if blockType ~= "HatBlock" then
			-- Check if the mouse is inside a container
			hoveredContainer, hoveredFrame = GetChildContainerAtPosition(self, mousePosition)
			-- If the mouse is inside a container, highlight it
			if previousHoveredFrame ~= hoveredFrame then
				
				if previoushoveredContainer  then
					HighlightContainer(self, previousHoveredFrame, false)
				end
				
				-- Check again because blocks moved:
				hoveredContainer, hoveredFrame = GetChildContainerAtPosition(self, mousePosition)
				
				if hoveredContainer then
					HighlightContainer(self, hoveredFrame, true)
				end
				
				previoushoveredContainer, previousHoveredFrame = hoveredContainer, hoveredFrame
			end
		end

		wait()
	end

	if hoveredContainer then
		HighlightContainer(self, hoveredFrame, false)

		if blockType == "ValueBlock" then
			hoveredContainer:LinkValueBlockToContainer(self, hoveredFrame)
		else
			hoveredContainer:SetChildBlock(self) 
		end
	else
		-- Position the frame relative to the canvas and its canva scroll position
		local finalposition = canvasFrame.CanvasPosition + mousePosition - draggingOffset - canvasFrame.AbsolutePosition

		blockFrame.Position = UDim2.fromOffset(
			finalposition.X,
			finalposition.Y
		)

		blockFrame.Parent = canvasFrame
	end
	
	-- Destroy if hovering the left sidebar
	if mousePosition.X < canvasFrame.AbsolutePosition.X then
		self:Destroy()
	end
	
	
	SetPluginMouseIcon("rbxasset://SystemCursors/OpenHand")
	
	DraggingBlock = nil
	
	
	
	-- Save
	onScriptChangedEvent:Fire()
	
	
	return self
end



function Block.GetBlocks()
	return BlockByFrame
end

-- Function to get the blockType
-- @return BlockTypeV3? , nil if the blockData is not set
-- it will automatically convert the blockType from V2 to V3 if needed
function Block:GetBlockType(): BlockTypeV3?
	if self.blockData then
		local blocktype = self.blockData.blockType
		if BlockTypeNameV2Bridge[blocktype] then
			return BlockTypeNameV2Bridge[blocktype]
		else
			return blocktype
		end
	end
	return nil
end

-- Function to get the child block of the block
-- @return BlockClass? , nil if the block has no child block
function Block:GetChildBlock(): BlockClass?
	return self.childBlock
end

-- Function to remove the child of this block
-- It will be parented to the canvas frame
-- @return BlockClass? , nil if the block has no child block
function Block:RemoveChildBlock(): BlockClass?
	if self.childBlock then
		local childBlock = self.childBlock
		self.childBlock = nil
		childBlock.parentBlock = nil

		local position = childBlock.blockFrame.AbsolutePosition + canvasFrame.CanvasPosition
		
		childBlock.blockFrame.Parent = canvasFrame
		childBlock.blockFrame.Position = UDim2.fromOffset(position.X + 20, position.Y + 20)

		return childBlock
	end
	return nil
end

-- Function that returns the table of value containers of a block
function Block:GetValueContainers()
	return RegistredValueContainers[self]
end

-- Function to add a block to a value container
-- @param block: BlockClass, the block to add
-- @param container: Frame, the container to add the block to
-- @return boolean, true if the block was added, false if there was an error
-- this will also remove any current block in the container
function Block:LinkValueBlockToContainer(block: BlockClass, container: Frame) : boolean
	assert(block, "block cannot be nil")
	assert(container, "container cannot be nil")

	-- Check if the block is a value block
	if block:GetBlockType() ~= "ValueBlock" then
		warn("Block:LinkValueBlockToContainer() : Block is not a value block")
		return false
	end

	-- if a block is already in this container, remove it
	local currentBlock = container:FindFirstChildWhichIsA("Frame")
	if currentBlock and BlockByFrame[currentBlock] then
		BlockByFrame[currentBlock]:UnlinkFromContainer()
	end
	
	local containerIndex = table.find(RegistredValueContainers[self], container)

	-- Link the block to the container
	block.blockFrame.Parent = container
	block.blockFrame.Position = UDim2.new()
	
	self.replacedValueBlocks[containerIndex] = block 

	-- hide the container value textBox
	local textBox = container:FindFirstChild("TextBox")
	if textBox then
		textBox.Visible = false
	end

end

-- Function to remove a value block from its container
function Block:UnlinkFromContainer()
	if self.blockFrame.Parent == canvasFrame then
		return
	end
	-- Remove the block from the value container
	local container = self.blockFrame.Parent
	local containerBlock: BlockClass = BlockByFrame[container.Parent.Parent] -- container -> BlockImageButton -> BlockFrame
	
	if not containerBlock then
		return
	end
	
	local containerIndex = table.find(RegistredValueContainers[containerBlock], self.blockFrame.Parent)
	containerBlock.replacedValueBlocks[containerIndex] = nil

	local canvaPosition = self.blockFrame.AbsolutePosition + canvasFrame.CanvasPosition - canvasFrame.AbsolutePosition

	self.blockFrame.Parent = canvasFrame -- this removes the block
	self.blockFrame.Position =  UDim2.fromOffset(canvaPosition.X + 20,canvaPosition.Y  +20)

	-- Show container value textBox
	local textBox = container:FindFirstChild("TextBox")
	if textBox then
		textBox.Visible = true
	end
end

-- Function to unparent the block from its current parent
function Block:UnparentBlock()
	if self.parentBlock then
		self.parentBlock:RemoveChildBlock()
	end
end

-- Function to set the child block of this block
-- If it has already a child block, the child block will be moved down to the lowest block in the block tree of the inputed block
-- @param block: BlockClass, the block to set as child
function Block:SetChildBlock(block: BlockClass)
	-- TODO : this will not work for valueBlocks, so implemeent value block working
	if block.parentBlock then
		block.parentBlock:RemoveChildBlock()
	end

	if self.childBlock then

		local childBlock = self:RemoveChildBlock() 

		local lowestBlock = block
		while lowestBlock.childBlock do
			lowestBlock = lowestBlock.childBlock
		end

		-- check if this block can have a child block
		if lowestBlock:GetBlockType() ~= "Terminal" then
			lowestBlock:SetChildBlock(childBlock)
		end
	end

	block.parentBlock = self
	self.childBlock = block

	block.blockFrame.Parent = self.blockFrame.ChildContainer
	block.blockFrame.Position = UDim2.new()
end


-- Function to get the bounding box of a block and its descendants
-- @return: Vector2 bouding box size
function Block:GetTreeSize()
	local sizeY = 0
	local sizeX = 0 
	
	local block = self
	while block  do
		local myABSSize = block.blockFrame.AbsoluteSize
		
		sizeY += myABSSize.Y -- We add Y Size
		
		local childContainer: Frame = block.blockFrame:FindFirstChild("ChildContainer")
		if childContainer then
			sizeY -= childContainer.AbsoluteSize.Y
		end
		
		sizeX = math.max(sizeX, myABSSize.X) -- We check if this block is wider the the widest from before
		
		block = block.childBlock
	end
	
	return Vector2.new(sizeX, sizeY)
end



-- Function to delet the block and its children
function Block:Destroy()
	if self.parentBlock then 
		self.parentBlock:RemoveChildBlock()
	end

	
	if self.childBlock then
		self.childBlock:Destroy()
	end
	
	-- If its already destroyed return
	if not self.blockFrame then return end
	
	-- Destroy it
	BlockByFrame[self.blockFrame] = nil
	RegistredBlockContainers[self] = nil
	RegistredValueContainers[self] = nil
	
	if self.blockFrame then
		self.blockFrame:Destroy()
	end
	
	table.clear(self)
	
end

return Block