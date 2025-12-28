local BlockEditor = {}
BlockEditor.__index = BlockEditor

-- Constants
local ELEMENT_TYPES = {Text = "Text", Input = "AnyValue", ["Number Input"] = "NumberValue", Picker = "Picker", ["Output"] = "GetValue"}
local BLOCK_TYPES = { "Block" , "CBlock", "EBlock", "HatBlock" , "ValueBlock"  }
local SAVE_COLOR = Color3.fromRGB(14, 122, 240)
local SAVED_COLOR = Color3.fromRGB(207, 207, 207)



-- Function to darken a color
-- @param color: Color3, the color to darken
-- @param d: float number, the darkening factor. 0 - 1 : darker, 1 - 2 : lighter
-- @return Color3, the darkened color
local function DarkenColor(color: Color3, d: number): Color3
	return Color3.new(color.R * d, color.G * d, color.B * d)
end

-- Helper function to create a deep copy of a table
function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Helper function to check if two tables are equal
function tablesEqual(t1, t2)
	if type(t1) ~= "table" or type(t2) ~= "table" then
		return t1 == t2
	end
	
	-- Check if all keys in t1 exist in t2 with the same values
	for k, v in pairs(t1) do
		if not tablesEqual(v, t2[k]) then
			return false
		end
	end
	
	
	return true
end

function BlockEditor.new(UI, dropdownManager, alertManager, dataManager, packageEditor, uiManager)
	local self = setmetatable({}, BlockEditor)

	self.UI = UI
	self.TopBar = UI.TopBar
	self.CodeBox = UI.CodeBox
	self.DragElements = UI.DragElements
	self.elementDraggerUI = self.DragElements.Element
	self.Preview = UI.Preview
	self.BottomBar = UI.BottomBar

	self.dropdownManager = dropdownManager
	self.alertManager = alertManager
	self.dataManager = dataManager
	self.packageEditor = packageEditor
	self.uiManager = uiManager

	self.didSaveBlockSession = false
	self.connections = {} -- Store all connections for cleanup

	-- Initialize the code editor highlighting
	self:initHighlightingCodeBox()
	self:initBlockEditor()

	return self
end

function BlockEditor:initHighlightingCodeBox()
	local Highligher = require(self.CodeBox.Highlighter)

	self.CodeBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		local highlited = Highligher.run(self.CodeBox.TextBox.Text)
		self.CodeBox.Text.Text = highlited
	end)
end

function BlockEditor:initBlockEditor()
	local TopBar = self.TopBar

	local function setTopBarButtonActive(button)
		for _, btn in pairs(TopBar:GetChildren()) do
			if btn:IsA("ImageButton") then
				btn.BackgroundTransparency = 1
			end
		end
		button.BackgroundTransparency = 0
	end

	-- We'll only initialize these connections once, not during cleanup
	if not self.topBarInitialized then
		self.topBarConnections = {}

		table.insert(self.topBarConnections, TopBar.Overview.MouseButton1Down:Connect(function()
			self.CodeBox.Visible = false
			self.UI.Title.Visible = true
			self.DragElements.Visible = false
			setTopBarButtonActive(TopBar.Overview)
		end))

		table.insert(self.topBarConnections, TopBar.Content.MouseButton1Down:Connect(function()
			self.CodeBox.Visible = false
			self.UI.Title.Visible = false
			self.DragElements.Visible = true
			setTopBarButtonActive(TopBar.Content)
		end))

		table.insert(self.topBarConnections, TopBar.Script.MouseButton1Down:Connect(function()
			self.CodeBox.Visible = true
			self.UI.Title.Visible = false
			self.DragElements.Visible = false
			setTopBarButtonActive(TopBar.Script)
		end))

		-- Initialize Save button
		table.insert(self.topBarConnections, self.BottomBar.Save.MouseButton1Down:Connect(function()
			self:saveBlock()
		end))

		self.topBarInitialized = true
	end

	-- Set initial state
	self.CodeBox.Visible = false
	self.UI.Title.Visible = true
	self.DragElements.Visible = false
	setTopBarButtonActive(TopBar.Overview)
end

function BlockEditor:updateSaveButtonColor(forceSaved)
	if not self.originalBlock or not self.CurrentBlock then
		warn("return")
		return
	end

	local hasChanges = not forceSaved
	if not hasChanges then
		-- Compare only if we haven't already determined there are changes
		hasChanges = not tablesEqual(self.originalBlock, self.CurrentBlock)
	end

	local targetColor = hasChanges and SAVE_COLOR or SAVED_COLOR
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	-- Create a TweenService and tween the button color
	local tweenService = game:GetService("TweenService")
	local tween = tweenService:Create(self.BottomBar.Save, tweenInfo, {BackgroundColor3 = targetColor})
	tween:Play()
	
	self.didSaveBlockSession = not hasChanges
end

function BlockEditor:markUnsaved()
	self.didSaveBlockSession = false
	self:updateSaveButtonColor()
end

function BlockEditor:cleanup()
	-- Disconnect all connections except top bar buttons
	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
	self.connections = {}

	-- Clear any remaining UI elements
	for _, child in pairs(self.DragElements:GetChildren()) do
		if child:IsA("Frame") and child.Visible then
			child:Destroy()
		end
	end

	local previewBlockFrame = self.Preview.Preview:FindFirstChildWhichIsA("Frame") 
	if previewBlockFrame then
		for _, child in pairs(previewBlockFrame.Block:GetChildren()) do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
				child:Destroy()
			end
		end
	end

	-- Reset state
	self.didSaveBlockSession = false
end

function BlockEditor:openBlockEditor(blockData, uiManager, packageData)
	local previousOnGoBack = uiManager.onGoback

	uiManager:setOnGoBack(function()
		if self.didSaveBlockSession then
			uiManager:setLockView(false)
			uiManager.onGoback = previousOnGoBack
			self:cleanup()
			return true, true
		end

		local finished = false
		local result = nil

		self.alertManager:promptAlert(
			"Exit without saving?", 
			"You have not saved your work. Part or all of it will be lost if you do not save.", 
			"Exit", 
			"Cancel", 
			function()
				-- Exit
				result = true
				finished = true
			end, 
			function()
				-- Cancel
				result = false
				finished = true
			end
		)

		while not finished do wait() end

		uiManager:setLockView(not result)

		if result then
			uiManager.onGoback = previousOnGoBack
			self:cleanup()
		end

		return result, true
	end)
	
	-- Store original block and make a deep copy for editing
	self.originalBlock = blockData
	self.packageData = packageData
	self.CurrentBlock = deepCopy(blockData)
	self:loadBlockIntoEditor(self.CurrentBlock)
	
	-- Initialize save button color
	self.BottomBar.Save.BackgroundColor3 = SAVED_COLOR
	self.didSaveBlockSession = true

	uiManager:appendView(self.UI)
	uiManager:setLockView(true)
end

function BlockEditor:loadBlockIntoEditor(data)
	-- Clear existing elements in dragger section
	for _, child in pairs(self.DragElements:GetChildren()) do
		if child:IsA("Frame") and child.Visible  then
			child:Destroy()
		end
	end
	
	local previewBlockFrame = self.Preview.Preview:FindFirstChildWhichIsA("Frame") 
	if data.Type == "ValueBlock" then
		previewBlockFrame.Block.BackgroundColor3 = Color3.fromHex(self.packageData.IconColor)
		previewBlockFrame.Block.UIStroke.Color = DarkenColor(Color3.fromHex(self.packageData.IconColor), 0.75)
	else
		previewBlockFrame.Block.ImageColor3 = Color3.fromHex(self.packageData.IconColor)
	end

	-- Clear existing elements n the block preview
	for _, child in pairs(previewBlockFrame.Block:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	
	
	-- Load code
	self.CodeBox.TextBox.Text = data.Code

	-- Load elements
	local cleanUps = {}
	local reindexEvent = Instance.new("BindableEvent")
	
	local function refreshAllElements()
		for _, cleanUp in pairs(cleanUps) do
			cleanUp()
		end
		
		for _, element in pairs(data.Elements) do
			local _, cleanUp = self:newElementDragger(element, data.Elements, reindexEvent)
			table.insert(cleanUps, cleanUp)
		end
		reindexEvent:Fire()
	end
	
	refreshAllElements()
	
	-- Store the current block data
	self.CurrentBlock = data
	
	-- Add element
	table.insert(self.connections, self.elementDraggerUI.Parent.AddElement.MouseButton1Down:Connect(function()
		local element = {}
		element.contentType = "Text"
		element.content = "New element"
		
		table.insert(data.Elements, element)
		
		local _, cleanUp = self:newElementDragger(element, data.Elements, reindexEvent)
		reindexEvent:Fire()
		
		table.insert(cleanUps, cleanUp)
		self:markUnsaved()
	end))
	
	-- Load title
	self.UI.Title.Content.Title.Text = data.Name or ""
	self.UI.Title.Content.Description.Text = data.Description or ""
	self.UI.Title.Content.SpecificTo.Text = data.SpecificTo or ""

	self.UI.Title.Content.Type.Content.Text = data.Type or "Block"
	
	table.insert(self.connections, self.UI.Title.Content.Type.MouseButton1Down:Connect(function()
		local dropdownContent = {}
		for _, t in pairs(BLOCK_TYPES) do
			table.insert(dropdownContent, {text= t})
		end
		self.dropdownManager:ShowDropdown(dropdownContent, function(a0: string)
			data.Type = a0
			self.UI.Title.Content.Type.Content.Text = a0
			
			local previewBlockFrame = self.Preview.Preview:FindFirstChildWhichIsA("Frame") 
			if previewBlockFrame then
				previewBlockFrame:Destroy()
			end
			
			previewBlockFrame = script.Parent.Parent.Parent.Parent.BlocksFactory.Assets.DefaultBlockFrames:FindFirstChild(data.Type):Clone()
			previewBlockFrame.Parent = self.Preview.Preview

			--

			if data.Type == "ValueBlock" then
				previewBlockFrame.Block.BackgroundColor3 = Color3.fromHex(self.packageData.IconColor)
				previewBlockFrame.Block.UIStroke.Color = DarkenColor(Color3.fromHex(self.packageData.IconColor), 0.75)
			else
				previewBlockFrame.Block.ImageColor3 = Color3.fromHex(self.packageData.IconColor)
			end

			refreshAllElements()
			self:markUnsaved()
		end)
	end))
	
	-- Connect text changes to mark as unsaved
	table.insert(self.connections, self.UI.Title.Content.Title:GetPropertyChangedSignal("Text"):Connect(function()
		data.Name = self.UI.Title.Content.Title.Text
		self:markUnsaved()
	end))
	
	table.insert(self.connections, self.UI.Title.Content.Description:GetPropertyChangedSignal("Text"):Connect(function()
		data.Description = self.UI.Title.Content.Description.Text
		self:markUnsaved()
	end))

	table.insert(self.connections, self.UI.Title.Content.SpecificTo:GetPropertyChangedSignal("Text"):Connect(function()
		data.SpecificTo = self.UI.Title.Content.SpecificTo.Text
		self:markUnsaved()
	end))
	
	table.insert(self.connections, self.CodeBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		data.Code = self.CodeBox.TextBox.Text
		self:markUnsaved()
	end))

	-- Connect reindex event to detect element order changes
	table.insert(self.connections, reindexEvent.Event:Connect(function()
		self:markUnsaved()
	end))
end

function BlockEditor:newElementDragger(element, elements, reindexEvent)
	local myUI = self.elementDraggerUI:Clone()
	myUI.Visible = true
	myUI.Parent = self.elementDraggerUI.Parent
	myUI.Type.Content.Text = element.contentType

	local previewBlockFrame = self.Preview.Preview:FindFirstChildWhichIsA("Frame") 
	local path_to_element_uis = script.Parent.Parent.Parent.Parent.BlocksFactory.Assets.DefaultBlockContents

	local inBlockPreview
	local contentRefreshConnection

	-- Function to clean up existing connections and UI elements when changing type
	local function cleanupCurrentElements()
		if contentRefreshConnection then
			contentRefreshConnection:Disconnect()
			contentRefreshConnection = nil
		end

		if inBlockPreview then
			inBlockPreview:Destroy()
			inBlockPreview = nil
		end
	end
	
	local function getNameForType(elementType)
		for name, t in pairs(ELEMENT_TYPES) do
			if t == elementType then
				return name
			end
		end
	end
	
	-- Function to setup UI based on element type
	local function setupElementUI(elementType)
		-- Clean up any existing elements first
		cleanupCurrentElements()

		-- Update the type display
		element.contentType = elementType
		myUI.Type.Content.Text = getNameForType(elementType)

		if elementType == "Picker" then
			-- Initialize picker content if it doesn't exist
			if not element.pickerContent then
				element.pickerContent = {"Default"}
				element.content = "Default"
			end

			-- Add to block preview
			inBlockPreview = path_to_element_uis.Picker:Clone()
			inBlockPreview.Parent = previewBlockFrame.Block

			local function refreshPreview()
				inBlockPreview.Title.Text = element.content
				myUI.Content.Content.Text = element.content
			end

			refreshPreview()

			-- Configure content field
			myUI.Content.Content.TextEditable = false

			contentRefreshConnection = myUI.Content.Content.InputBegan:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local dropDownContent = {}
					for _, el in pairs(element.pickerContent) do
						table.insert(dropDownContent, {text = '"'..el..'"'})
					end

					table.insert(dropDownContent, "---")

					table.insert(dropDownContent, {text = "New element..."})
					table.insert(dropDownContent, {text = "Rename \""..element.content.."\""})

					if #element.pickerContent > 1 then
						table.insert(dropDownContent, {text = "Delete \""..element.content.."\""})
					end				

					self.dropdownManager:ShowDropdown(dropDownContent, function(a0: string)
						if string.gsub(a0, " \""..element.content.."\"", "") == "Delete" then
							local deletionIndex = table.find(element.pickerContent, element.content)
							table.remove(element.pickerContent, deletionIndex)
							element.content = element.pickerContent[math.min(deletionIndex, #element.pickerContent)]

							refreshPreview()
						elseif string.gsub(a0, " \""..element.content.."\"", "") == "Rename" then
							myUI.Content.Content.TextEditable = true
							myUI.Content.Content:CaptureFocus()
							myUI.Content.Content.FocusLost:Wait()

							local renamingIndex = table.find(element.pickerContent, element.content)

							element.pickerContent[renamingIndex] = myUI.Content.Content.Text
							element.content = myUI.Content.Content.Text

							myUI.Content.Content.TextEditable = false

							refreshPreview()
						elseif a0 == "New element..." then
							myUI.Content.Content.Text = ""
							myUI.Content.Content.TextEditable = true
							myUI.Content.Content:CaptureFocus()
							myUI.Content.Content.FocusLost:Wait()

							table.insert(element.pickerContent, myUI.Content.Content.Text)  
							element.content = myUI.Content.Content.Text

							myUI.Content.Content.TextEditable = false

							refreshPreview()
						elseif a0:sub(1, 1) == "\"" then
							element.content = string.gsub(a0, "\"", "")
							refreshPreview()
							self:markUnsaved()
						end
					end)
				end
			end)
		elseif elementType == "Text" then
			-- Initialize content if needed
			if not element.content or element.content == "" then
				element.content = "Text"
			end

			-- Configure content field
			myUI.Content.Content.Text = element.content
			myUI.Content.Content.TextEditable = true

			-- Add to block preview
			inBlockPreview = path_to_element_uis.Text:Clone()
			inBlockPreview.Parent = previewBlockFrame.Block

			local function refreshPreview()
				inBlockPreview.Text = element.content
			end

			refreshPreview()
			contentRefreshConnection = myUI.Content.Content:GetPropertyChangedSignal("Text"):Connect(function()
				element.content = myUI.Content.Content.Text
				refreshPreview()
				self:markUnsaved()
			end)
		elseif elementType == "AnyValue" or elementType == "NumberValue" then
			-- Initialize content if needed
			if not element.content or element.content == "" then
				element.content = elementType == "NumberValue" and "0" or "value"
			end

			-- Configure content field
			myUI.Content.Content.Text = element.content
			myUI.Content.Content.TextEditable = true

			-- Add to block preview
			inBlockPreview = path_to_element_uis:FindFirstChild(elementType):Clone()
			inBlockPreview.Parent = previewBlockFrame.Block
			inBlockPreview.TextBox.TextEditable = false
			
			local function refreshPreview()
				inBlockPreview.TextBox.Text = element.content
			end

			refreshPreview()
			contentRefreshConnection = myUI.Content.Content:GetPropertyChangedSignal("Text"):Connect(function()
				element.content = myUI.Content.Content.Text
				refreshPreview()
				self:markUnsaved()
			end)
		elseif elementType == "GetValue" then
			-- Initialize content if needed
			if not element.content or element.content == "" then
				element.content = "variable"
			end

			-- Configure content field
			myUI.Content.Content.Text = element.content
			myUI.Content.Content.TextEditable = true

			-- Add to block preview
			inBlockPreview = path_to_element_uis.GetValue:Clone()
			inBlockPreview.Parent = previewBlockFrame.Block
			inBlockPreview.Value.Block.Text.Visible = true

			local function refreshPreview()
				inBlockPreview.Value.Block.Text.Text = element.content
			end

			refreshPreview()
			contentRefreshConnection = myUI.Content.Content:GetPropertyChangedSignal("Text"):Connect(function()
				element.content = myUI.Content.Content.Text
				refreshPreview()
				self:markUnsaved()
			end)
		end

		-- Ensure the element is properly ordered in the preview
		if inBlockPreview then
			local myIndex = table.find(elements, element)
			inBlockPreview.LayoutOrder = myIndex
		end
	end

	-- Initial setup based on the element's current type
	setupElementUI(element.contentType)

	-- Handle type changes
	myUI.Type.MouseButton1Down:Connect(function()
		local dropdownContent = {}
		for el, i in pairs(ELEMENT_TYPES) do
			table.insert(dropdownContent, {text = el})
		end

		self.dropdownManager:ShowDropdown(dropdownContent, function(choice)
			-- Don't do anything if the type hasn't changed
			choice = ELEMENT_TYPES[choice]
			if choice == element.contentType then
				return
			end


			-- Reset content based on the new type
			if choice == "Picker" then
				element.pickerContent = {"Default"}
				element.content = "Default"
			elseif choice == "Text" then
				element.content = "Text"
			elseif choice == "AnyValue" then
				element.content = "Default text"
			elseif choice == "NumberValue" then
				element.content = "0"
			elseif choice == "GetValue" then
				element.content = "variable"
			end
			
			-- Handle element type change
			setupElementUI(choice)

			-- Trigger reindex to ensure proper UI ordering
			reindexEvent:Fire()
			self:markUnsaved()
		end)
	end)

	-- Setup movement controls
	myUI.Move.MoveUp.MouseButton1Down:Connect(function()
		local currentIndex = table.find(elements, element)
		local desiredIndex = math.clamp(currentIndex - 1, 1, #elements)
		table.remove(elements, currentIndex)
		table.insert(elements, desiredIndex, element)
		reindexEvent:Fire()
		self:markUnsaved()
	end)

	myUI.Move.MoveDown.MouseButton1Down:Connect(function()
		local currentIndex = table.find(elements, element)
		local desiredIndex = math.clamp(currentIndex + 1, 1, #elements)
		table.remove(elements, currentIndex)
		table.insert(elements, desiredIndex, element)
		reindexEvent:Fire()
		self:markUnsaved()
	end)

	-- Handle reindexing
	local reindexConnection = reindexEvent.Event:Connect(function()
		local myIndex = table.find(elements, element)
		if inBlockPreview then
			inBlockPreview.LayoutOrder = myIndex
		end
		myUI.LayoutOrder = myIndex
	end)

	-- Cleanup function for when the element is removed
	local function cleanup()
		myUI:Destroy()
		if inBlockPreview then
			inBlockPreview:Destroy()
		end
		reindexConnection:Disconnect()
		reindexEvent:Fire()
	end
	
	
	-- On delet
	myUI.Delet.MouseButton1Down:Connect(function()
		local currentIndex = table.find(elements, element)
		table.remove(elements, currentIndex)

		cleanup()
		self:markUnsaved()
	end)

	

	return myUI, cleanup
end

function BlockEditor:saveBlock()
	-- Update the original block with our copied and modified data
	for key, value in pairs(self.CurrentBlock) do
		if typeof(value) == "table" then
			self.originalBlock[key] = deepCopy(value)
		else
			self.originalBlock[key] = value
		end
	end
	
	-- Ensure all fields are properly copied
	self.originalBlock.Name = self.CurrentBlock.Name
	self.originalBlock.Description = self.CurrentBlock.Description
	self.originalBlock.SpecificTo = self.CurrentBlock.SpecificTo
	self.originalBlock.Code = self.CurrentBlock.Code
	self.originalBlock.Type = self.CurrentBlock.Type
	self.originalBlock.Elements = deepCopy(self.CurrentBlock.Elements)
	
	local success, description = self.dataManager:SaveBlock(self.CurrentBlock, self.originalBlock.BlockId)
	if success then
		-- Update the current block to match the saved state
		self.CurrentBlock = deepCopy(self.originalBlock)
		self.didSaveBlockSession = true
		-- Update the save button color to show saved state
		self:updateSaveButtonColor(true)
		
		-- Refresh the package editor's block list to show updated block info
		if self.packageEditor and self.packageData then
			self.packageEditor:refreshBlockList(self.packageData, self.uiManager)
		end
	else
		-- Show error message if save failed
		local finished = false
		self.alertManager:promptAlert(
			"Save Failed", 
			"Failed to save block: " .. (description or "Unknown error"), 
			"OK", 
			nil, 
			function()
				finished = true
			end, 
			nil
		)
		while not finished do wait() end
	end
	return success
end

return BlockEditor