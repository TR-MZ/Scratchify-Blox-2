local UIManager = {}


function UIManager.new(plugin, UI, FireStoreManager: typeof(require(script.Parent.FirestoreManager)))
	local self = setmetatable(UIManager, {})
	
	self.UI = UI

	-- UI references
	self.TopBar = UI.TopBar
	self._LeftBar = self.TopBar.LeftBar
	self.CreateButton = self._LeftBar.Create
	self.DownloadedButton = self._LeftBar.Downloaded
	self.SearchButton = self._LeftBar.Search
	self.GoBackButton = self.TopBar.GoBack

	self.Home = UI.Home
	self.Search = UI.Search
	self.MyBlocks = UI.MyBlocks
	self.MyPackages = UI.MyPackages
	self.CreateNewPackButton = self.MyPackages.MakePackage
	self.LoginView = UI.Login
	self.LoadingFrame = UI.Loading

	self.plugin = plugin
	-- View management
	self.ViewHistory = {UI.Home}
	self.LockView = false

	-- Callback holder
	self.onGoback = function() return true end

	return self
end


function UIManager.connectEvents(self)
	-- Button connections
	self.SearchButton.MouseButton1Up:Connect(function()
		self:toggleSearchUI()
	end)

	self.CreateButton.MouseButton1Up:Connect(function()
		self:toggleMyPackages()
	end)

	self.DownloadedButton.MouseButton1Up:Connect(function()
		self.DownloadManager:PromptMyPackages()
	end)

	self.CreateNewPackButton.MouseButton1Up:Connect(function()
		self.dataManager:NewBlockPack()
		self:refreshMyPackages()
	end)

	self.GoBackButton.MouseButton1Up:Connect(function()
		self:goBack()
	end)

end

function UIManager:init(packageEditor, blockEditor, dataManager, alertManager, dropdownManager, firestoreManager, refreshCallback)
	self.packageEditor = packageEditor
	self.blockEditor = blockEditor
	self.dataManager = dataManager
	self.alertManager = alertManager
	self.dropdownManager = dropdownManager
	self.firestoreManager = firestoreManager
	

	self.DownloadManager = require(script.Parent.DownloadManager)
	self.DownloadManager:Init(self.plugin, self.UI.DownloadBlock, self.UI.DownloadBlockContainedBlocks, self.MyBlocks, self,dataManager , firestoreManager, refreshCallback)
	-- Connect UI events
	self:connectEvents()

	-- Load top blocks
	self:LoadTopBlocks()
end

function UIManager:goBack()
	local gb, refreshedgb = self.onGoback()
	if #self.ViewHistory < 2  or not gb then return end

	self.ViewHistory[1].Visible = false
	table.remove(self.ViewHistory, 1)
	self.ViewHistory[1].Visible = true

	self.LockView = false

	if not refreshedgb then
		self.onGoback = function() return true end
	end

	if #self.ViewHistory <= 1 then
		local Defaults = require(script.Parent.Defaults)
		self.GoBackButton.Image = Defaults.DEFAULT_ICON_LIBRARY
	end
end

function UIManager:appendView(view)
	if self.LockView then return end

	view.Visible = true
	self.ViewHistory[1].Visible = false
	if table.find(self.ViewHistory, view) then
		table.remove(self.ViewHistory, table.find(self.ViewHistory, view))
	end
	table.insert(self.ViewHistory, 1, view)

	local Defaults = require(script.Parent.Defaults)
	self.GoBackButton.Image = Defaults.DEFAULT_ICON_GOBACK
end

function UIManager:toggleSearchUI()
	local isVisible = self.Search.Visible
	if isVisible then
		self:goBack()
	else
		self:appendView(self.Search)
	end
end

function UIManager:toggleDownloaded()
	local isVisible = self.MyBlocks.Visible
	if isVisible then
		self:goBack()
	else
		self:appendView(self.MyBlocks)
	end
end

function UIManager:toggleMyPackages()
	self:refreshMyPackages()
	local isVisible = self.MyPackages.Visible
	if isVisible then
		self:goBack()
	else
		self:appendView(self.MyPackages)
	end
end

function UIManager:refreshMyPackages()
	-- clear from previous
	for _, _pack in pairs(self.MyPackages:GetChildren()) do
		if _pack:IsA("ImageButton") and _pack.Visible and _pack.Name == "Package" then 
			_pack:Destroy() 
		end
	end

	-- reload new ones
	local MyPackages_Pack = self.MyPackages.Package
	
	local myCreatedPackages = self.dataManager:GetMyPackages()
	
	if not myCreatedPackages then return end
	
	for _, _pack in pairs(myCreatedPackages) do
		local Package = MyPackages_Pack:Clone()
		Package.Parent = self.MyPackages
		Package.Visible = true

		Package.TextContents.PackageName.Text = _pack.Name
		Package.TextContents.PackageDescription.Text = _pack.Description
		Package.Preview.ImageColor3 = Color3.fromHex(_pack.IconColor)
		Package.Preview.TextLabel.Text = #_pack.ContentBlockIds

		Package.Buttons.Edit.MouseButton1Up:Connect(function()
			self.packageEditor:openPackageEditor(_pack, self)
		end)

		Package.Buttons.Uninstall.MouseButton1Up:Connect(function()
			self.alertManager:promptAlert(
				"Delete <b>".._pack.Name.."</b>?", 
				"Are you sure that you want to delete this block Package? This action <b> cannot be undone. </b>", 
				"Delete", 
				"Cancel", 
				function()
					if self.dataManager:DeletePackage(_pack) then
						Package:Destroy()
						self:refreshMyPackages()
					end
				end, 
				function() end
			)
		end)
	end
end

function UIManager:LoadTopBlocks()
	for _, category in pairs(self.Home:GetChildren()) do
		if category:IsA("Frame") then
			local data = self.firestoreManager:GetTop6BlocksByTag(category.Name)
			
			local packButton = category.Content.NotSelectedItem

			for _,  doc  in pairs(data) do
				if doc.document and doc.document.fields then
					
					local pack = {}
					
					for key, field in pairs(doc.document.fields) do
						pack[key] = self.firestoreManager:ConvertFromFirestoreValue(field)
					end
					
					local myPackButton = packButton:Clone()
					myPackButton.Parent = category.Content
					myPackButton.Visible = true
					myPackButton.Title.Text = pack.Name
					myPackButton.Preview.TextLabel.Text = #pack.ContentBlockIds
					myPackButton.Preview.ImageColor3 = Color3.fromHex(pack.IconColor)

					myPackButton.MouseButton1Up:Connect(function()
						self.DownloadManager:PromptDownloadBlockPack(pack)
					end)

					packButton.Visible = false
				end
			end
		end
	end
end


function UIManager:setLockView(lock)
	self.LockView = lock
end

function UIManager:setOnGoBack(callback)
	self.onGoback = callback
end


return UIManager