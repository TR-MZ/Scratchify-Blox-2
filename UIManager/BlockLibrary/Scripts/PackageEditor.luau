local PackageEditor = {}
PackageEditor.__index = PackageEditor

local TAG_LIST = {
	{text = "Trending" },
	{text = "Gameplay"},
	{text = "GUI"},
	{text = "Animation"},
	{text = "Utility"},
	{text = "Effects"},
	{text = "Other"},
}

function PackageEditor.new(UI, dataManager, blockEditor, alertManager, dropdownManager)
	local self = setmetatable({}, PackageEditor)

	self.UI = UI
	self.Blocks = UI.Blocks
	self.dataManager = dataManager
	self.blockEditor = blockEditor
	self.alertManager = alertManager
	self.dropdownManager = dropdownManager

	self.didSavePackSession = false



	-- rojo didnt export this...
	UI.Title.Visible = true
	UI.Title.LayoutOrder = -1

	self:initPackEditor()

	return self
end

function PackageEditor:initPackEditor()
	self.UI.Title.Content.Title:GetPropertyChangedSignal("Text"):Connect(function()
		self.didSavePackSession = false
	end)

	self.UI.Title.Content.Description:GetPropertyChangedSignal("Text"):Connect(function()
		self.didSavePackSession = false
	end)

	self.UI.Title.Content.Tag.MouseButton1Up:Connect(function()
		self.dropdownManager:ShowDropdown(
			TAG_LIST,
			function (tag)
				self.UI.Title.Content.Tag.Content.Text = tag
				self.didSavePackSession = false
			end
		)
	end)

	-- Create a new block ; 
	self.UI.Blocks.MakeVar.MouseButton1Up:Connect(function()
		local id = self.dataManager:NewBlock(self.CurrentPackage)
		if not id then
			warn("Failed to create new block")
			return
		end
		self:refreshBlockList(self.CurrentPackage, self.uiManager)
		
		self.dataManager:SavePackage(
			self.CurrentPackage,
			self.CurrentPackage.PackId
		)
	end)

	-- Save button functionality
	self.UI.BottomBar.Save.MouseButton1Up:Connect(function()
		self:savePackage(self.CurrentPackage)
	end)

	-- Publish button functionality
	self.UI.BottomBar.Publish.MouseButton1Up:Connect(function()
		self.CurrentPackage.published = true
		self:savePackage(self.CurrentPackage)
		self:updatePublishButtons()
	end)

	-- Make Private button functionality
	self.UI.BottomBar.MakePrivate.MouseButton1Up:Connect(function()
		self.CurrentPackage.published = false
		self:savePackage(self.CurrentPackage)
		self:updatePublishButtons()
	end)

	self.UI.IconChanger.IconChanger.Frame.TextButton.MouseButton1Up:Connect(function()
		self.UI.IconChanger.IconChanger.Visible = false
		self.didSavePackSession = false
	end)

	self.UI.IconChanger.IconChanger.Frame.ImageLink.TextBox.FocusLost:Connect(function()
		local text =  self.UI.IconChanger.IconChanger.Frame.ImageLink.TextBox.Text
		if tonumber(text)  then
			self.UI.IconChanger.IconChanger.Frame.ImageLink.TextBox.Text = "rbxassetid://"..text
		end

		self.UI.IconChanger.IconChanger.Frame.Preview.Image = text

		if text ~= "" then
			
			self.UI.Title.Preview.Image = text
			self.UI.Title.Preview.ImageColor3 = Color3.new(1,1,1)
		else
			self.UI.Title.Preview.Image = "rbxassetid://132867256377090"
			self.UI.Title.Preview.ImageColor3 = Color3.fromHex(self.UI.IconChanger.IconChanger.Frame.Color.TextBox.Text)

		end
	end)

	self.UI.IconChanger.IconChanger.Frame.Color.TextBox.FocusLost:Connect(function()
		if self.UI.Title.Preview.Image == "rbxassetid://132867256377090" then
			self.UI.Title.Preview.ImageColor3 = Color3.fromHex(self.UI.IconChanger.IconChanger.Frame.Color.TextBox.Text)
		end
		self.CurrentPackage.IconColor = self.UI.IconChanger.IconChanger.Frame.Color.TextBox.Text
		self:refreshBlockList(self.CurrentPackage, self.uiManager)
	end)

	self.UI.Title.Preview.MouseEnter:Connect(function()
		self.UI.Title.Preview.ChangeImage.Visible = true
	end)

	self.UI.Title.Preview.MouseLeave:Connect(function()
		self.UI.Title.Preview.ChangeImage.Visible = false
	end)

	self.UI.Title.Preview.MouseButton1Up:Connect(function()
		self.UI.IconChanger.IconChanger.Visible = true
	
	end)

end

function PackageEditor:updatePublishButtons()
	if self.CurrentPackage.published then
		self.UI.BottomBar.Publish.Visible = false
		self.UI.BottomBar.MakePrivate.Visible = true
	else
		self.UI.BottomBar.Publish.Visible = true
		self.UI.BottomBar.MakePrivate.Visible = false
	end
end

function PackageEditor:openPackageEditor(packageData, uiManager)
	local previousOnGoBack = uiManager.onGoback

	uiManager:setOnGoBack(function()
		if self.didSavePackSession then
			uiManager:setLockView(false)
			return true
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

		return result
	end)

	self.uiManager = uiManager
	self.CurrentPackage = packageData

	-- Initialize published state if not exists
	if self.CurrentPackage.published == nil then
		self.CurrentPackage.published = false
	end

	self:updatePublishButtons()
	self:refreshBlockList(packageData, uiManager)

	-- Set UI elements
	self.UI.Title.Content.Title.Text = packageData.Name
	self.UI.Title.Content.Description.Text = packageData.Description
	if packageData.Image and packageData.Image ~= "" then
		self.UI.Title.Preview.ImageColor3 = Color3.new(1, 1, 1)
		self.UI.Title.Preview.Image = packageData.Image
	else
		self.UI.Title.Preview.ImageColor3 = Color3.fromHex(packageData.IconColor)
		self.UI.Title.Preview.Image = "rbxassetid://132867256377090"
	end

	self.UI.Title.Preview.TextLabel.Text = #packageData.ContentBlockIds
	self.UI.Title.Content.Tag.Content.Text = (packageData.Tag or "Other") == "" and "Other" or packageData.Tag
	self.UI.IconChanger.IconChanger.Frame.Color.TextBox.Text = packageData.IconColor 
	self.UI.IconChanger.IconChanger.Frame.ImageLink.TextBox.Text = packageData.Image or ""
	self.UI.IconChanger.IconChanger.Frame.Preview.Image = packageData.Image or ""


	uiManager:appendView(self.UI)
	uiManager:setLockView(true)
	self.didSavePackSession = true
end

function PackageEditor:refreshBlockList(packageData, uiManager)
	print(uiManager)
	if not typeof(uiManager) == "table" then
		error("UI Manager is wrong!")
	end 
	print(packageData)
	-- Clear previous blocks
	for _, _block in pairs(self.Blocks:GetChildren()) do
		if _block:IsA("ImageButton") and _block.Visible and _block.Name == "Block" then 
			_block:Destroy() 
		end
	end

	-- Reload new ones
	for _, _blockId in pairs(packageData.ContentBlockIds) do
		warn(_blockId)
		local _block = self.dataManager:BlockDataById(_blockId)
		local Block = self.Blocks.Block:Clone()
		Block.Parent = self.Blocks
		Block.Visible = true

		Block.TextContents.BlockName.Text = _block.Name
		Block.TextContents.BlockDescription.Text = _block.Description

		-- Clear existing preview
		local previewContainer = Block.Preview
		if previewContainer:FindFirstChild("Event") then
			previewContainer.Event:Destroy()
		end

		-- Create a new preview
		require(script.Parent.BlockPreviewer)(previewContainer, _block, packageData.IconColor)

		Block.TextContents.Buttons.Edit.MouseButton1Up:Connect(function()
			uiManager:setLockView(false)
			self.blockEditor:openBlockEditor(_block, uiManager, packageData)
		end)

		Block.TextContents.Buttons.Uninstall.MouseButton1Up:Connect(function()
			self.alertManager:promptAlert(
				"Delete <b>".._block.Name.."</b>?", 
				"Are you sure that you want to delete this block? This action <b> cannot be undone. </b>", 
				"Delete", 
				"Cancel", 
				function()
					if self.dataManager:DeleteBlock(packageData, _blockId) then
						Block:Destroy()
						self:refreshBlockList(packageData, uiManager)
					end
				end, 
				function() end
			)
		end)
	end
end

function PackageEditor:savePackage(packageData)
	
	-- modify packageData
	packageData.Name = self.UI.Title.Content.Title.Text
	packageData.Description = self.UI.Title.Content.Description.Text
	packageData.Tag = self.UI.Title.Content.Tag.Content.Text
	packageData.IconColor = self.UI.IconChanger.IconChanger.Frame.Color.TextBox.Text
	packageData.Image = self.UI.IconChanger.IconChanger.Frame.ImageLink.TextBox.Text
	
	--packageData.IconColor = self.UI.Title.Preview.ImageColor3:ToHex() skip color
	

	local success, result = self.dataManager:SavePackage(
		packageData,
		packageData.PackId
	)

	if success then
		self.didSavePackSession = true
		
		-- Refresh the package list in the UI manager
		if self.uiManager then
			self.uiManager:refreshMyPackages()
		end
	else
		self.alertManager:promptAlert(
			"Error saving package!",
			result, 
			"Ok",
			nil,
			function()end,
			nil
		)
	end
	
	return success
end

return PackageEditor