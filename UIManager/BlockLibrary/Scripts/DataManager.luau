local DataManager = {}
DataManager.__index = DataManager

local Types = require(script.Parent.Types)
local Defaults = require(script.Parent.Defaults)
local FirestoreManager = require(script.Parent.FirestoreManager)
local HttpService = game:GetService("HttpService")
local plugin = nil -- Will be set in Init
local loadingFrame = nil

local StudioService = game:GetService("StudioService")

function DataManager.new()
	local self = setmetatable({}, DataManager)

	-- Cache for blocks
	self.CacheBlocks = {}
	
	-- Cache for block packs
	self.CacheBlockPacks = {}

	-- My packages data
	self.Data_MyPackages = nil
	
	-- Local storage for unpublished packs
	self.LocalPacks = {}

	return self
end

function DataManager:Init(pluginInstance, _loadingFrame)
	plugin = pluginInstance
	loadingFrame = _loadingFrame
	-- Load local packs from plugin settings
	local localPacksData = plugin:GetSetting("LocalPacks") or "{}"
	self.LocalPacks = HttpService:JSONDecode(localPacksData)
	
	-- Cache local blocks
	for packId, pack in pairs(self.LocalPacks) do
		self.CacheBlockPacks[packId] = pack.blockPack
		for _, blockId in pairs(pack.blockPack.ContentBlockIds) do
			if pack.blockPack.published then
				-- For published packs, blocks are in Firestore
				continue
			end
			-- For unpublished packs, blocks are in the pack data
			local blockData = pack.blocks[blockId]
			if blockData then
				self.CacheBlocks[blockId] = blockData
			end
		end
	end


	spawn(function()
		while true do for i = 1, 12 do _loadingFrame.ImageLabel.Rotation = (360/12) * i wait(0.1) end end
	end)
end

function DataManager:Empty_Data_Block() 
	return {
		Name = "My new block",
		Description = "This is a new block",
		Type = "Block",
		Elements = {
			{content = "Print hello", contentType = "Text"}, 
			{content= "5", contentType = "NumberValue"},
			{content = "times", contentType = "Text"}, 
		},
		Code = "for i = 1, & do print(\"hello\") end",
	}
end


function DataManager:Empty_Data_BlockPack() 
	return {
		Name = "Example Name",
		Description = "This is an example description.",
		PackId = "12345",
		IconColor = "#FF5733",
		Tag = "",
		ContentBlockIds = {},
		Downloads = {}, -- List containing everyuser who downloaded the package
	}
end

function DataManager:BlockDataById(id)
	return self.CacheBlocks[id] or (function()
		
		-- try from local :
		for _,  blockPack in pairs(self.LocalPacks) do
			if blockPack.blocks then
				for _id, block in pairs(blockPack.blocks) do
					self.CacheBlocks[_id] = block
				end
			end
		end

		if self.CacheBlocks[id] then return self.CacheBlocks[id] end

		-- else we try from firebase
		local newData = FirestoreManager:ReadDocument(id).fields
		
		for key, value in pairs(newData) do
			if type(value) == "table" then
				newData[key] = FirestoreManager:ConvertFromFirestoreValue(value)
			end
		end

		self.CacheBlocks[id] = newData
		newData.BlockId = id

		return self.CacheBlocks[id]
	end)()
end

function DataManager:GetMyPackages() -- Caching 
	loadingFrame.Visible = true
	if self.Data_MyPackages then
		local allPacks = table.clone(self.Data_MyPackages)
		for id,  block in pairs(self.LocalPacks) do
			if block.blockPack then
				table.insert(allPacks, block.blockPack)
			end
		end
		loadingFrame.Visible = false
		return allPacks
	else
		-- Add published packages from Firestore
		local GetMyBlocksPackages = FirestoreManager:GetMyBlocksPackages()
		
		if not GetMyBlocksPackages then 
			loadingFrame.Visible = false
			return
		 end
		local myPackages = {}

		self.Data_MyPackages = {}
		for _, document in pairs(GetMyBlocksPackages) do
			
			document = document.document

			if not document then continue end

			local packageData = document.fields
			
			if not packageData then continue end
			for key, value in pairs(packageData) do
				if type(value) == "table" then
					packageData[key] = FirestoreManager:ConvertFromFirestoreValue(value)
				end
			end

			packageData.PackId = document.name
			table.insert(myPackages, packageData)
			table.insert(self.Data_MyPackages, packageData)
			
			-- Cache the block pack
			self.CacheBlockPacks[packageData.PackId] = packageData
		end

		-- Add local packages
		for packId, packData in pairs(self.LocalPacks) do
			if packData and packData.blockPack then
				table.insert(myPackages, packData.blockPack)
				
				-- Cache the block pack if not already cached
				if not self.CacheBlockPacks[packId] then
					self.CacheBlockPacks[packId] = packData.blockPack
				end
			end
		end

		loadingFrame.Visible = false
		return myPackages
	end

end

-- Check if a string starts with a specific prefix
local function startsWith(str, prefix)
	return string.sub(str, 1, string.len(prefix)) == prefix
end

-- Generate a local ID
local function generateLocalId()
	return "local/" .. HttpService:GenerateGUID()
end

function DataManager:SavePackage(packageData, id)
	loadingFrame.Visible = true

	packageData.Creator = StudioService:GetUserId()


	-- Check for transitioning states
	if packageData.published and startsWith(id, "local/") then
		-- CASE 1: Pack is transitioning from local to published
		
		-- Move all blocks to Firestore
		local localBlocks = {}
		if self.LocalPacks[id] and self.LocalPacks[id].blocks then
			localBlocks = self.LocalPacks[id].blocks
		end
		
		-- Remove from local storage
		self.LocalPacks[id] = nil
		
		for i, blockId in pairs(packageData.ContentBlockIds) do
			-- Upload block to Firestore
			local blockData = localBlocks[blockId]
			
			-- Create new block on Firestore
			local blockSuccess, newBlockId = FirestoreManager:PostBlock(blockData)
			blockData.BlockId = newBlockId
			if blockSuccess then
				packageData.ContentBlockIds[i] = newBlockId
				
				-- Update cache with new ID
				self.CacheBlocks[newBlockId] = blockData
				self.CacheBlocks[blockId] = nil
			else
				warn("Error publishing block:", blockId)
			end
		end
		-- Create new Firestore document for the pack
		local success, firestoreId = FirestoreManager:CreateBlockPack(packageData)
		if not success then
			warn("Failed to publish pack: ", firestoreId)
			loadingFrame.Visible = false
			return false
		end


		-- Now we have the new ID, we need to update the block owner_packId

		for _, blockId in pairs(packageData.ContentBlockIds) do
			local blockData = self.CacheBlocks[blockId]
			if blockData then
				blockData.OwnerPackId = firestoreId
				self.CacheBlocks[blockId] = blockData

				-- Update the block in Firestore
				local blockSuccess = FirestoreManager:ModifyDocument(blockId, blockData)
				if not blockSuccess then
					warn("Failed to update block in Firestore:", blockId)
				end

			end
		end

		-- Update the package ID
		packageData.PackId = firestoreId
		
		-- Add to Data_MyPackages if not already there
		local exists = false
		for i, pack in ipairs(self.Data_MyPackages or {}) do
			if pack.PackId == firestoreId then
				exists = true
				self.Data_MyPackages[i] = packageData
				break
			end
		end
		
		if not exists and self.Data_MyPackages then
			table.insert(self.Data_MyPackages, packageData)
		end
		
		-- Update cache
		self.CacheBlockPacks[id] = nil
		self.CacheBlockPacks[firestoreId] = packageData
		
		-- Save local packs to plugin settings
		plugin:SetSetting("LocalPacks", HttpService:JSONEncode(self.LocalPacks))
		
		loadingFrame.Visible = false

		-- Return true since the pack was successfully published
		return true
	elseif not packageData.published and not startsWith(id, "local/") then
		-- CASE 2: Pack is transitioning from published to unpublished
		-- Create new local ID
		local localId = generateLocalId()
		
		-- Create local storage entry
		local localPack = {
			blockPack = packageData,
			blocks = {}
		}
		
		
		-- Move all blocks to local storage
		for _, blockId in pairs(packageData.ContentBlockIds) do
			if not startsWith(blockId, "local/") then
				-- Get block data from cache or Firestore
				local blockData = self.CacheBlocks[blockId]
				if not blockData then
					-- Try to get from Firestore
					local doc = FirestoreManager:ReadDocument(blockId)
					if doc and doc.fields then
						blockData = doc.fields
						for key, value in pairs(blockData) do
							if type(value) == "table" then
								blockData[key] = FirestoreManager:ConvertFromFirestoreValue(value)
							end
						end
						blockData.BlockId = blockId
					end
				end
				
				if blockData then
					-- Create new local ID for the block
					local localBlockId = generateLocalId()
					
					-- Replace ID in ContentBlockIds
					for i, bId in ipairs(packageData.ContentBlockIds) do
						if bId == blockId then
							packageData.ContentBlockIds[i] = localBlockId
							break
						end
					end
					
					-- Add to local blocks
					blockData.BlockId = localBlockId
					blockData.OwnerPackId = localId
					localPack.blocks[localBlockId] = blockData
					
					-- Update cache
					self.CacheBlocks[localBlockId] = blockData
					
					-- Remove from Firestore
					FirestoreManager:RemoveDocument(blockId)
				end
			end
		end
		
		-- Remove from Firestore
		FirestoreManager:RemoveDocument(id)
		
		-- Remove from Data_MyPackages
		if self.Data_MyPackages then
			for i, pack in ipairs(self.Data_MyPackages) do
				if pack.PackId == id then
					warn("REM")
					table.remove(self.Data_MyPackages, i)
					break
				end
			end
		end

		-- Update package ID
		packageData.PackId = localId
		
		-- Store in local packs
		self.LocalPacks[localId] = localPack
		
		-- Update cache
		self.CacheBlockPacks[id] = nil
		self.CacheBlockPacks[localId] = packageData
		
		-- Save local packs to plugin settings
		plugin:SetSetting("LocalPacks", HttpService:JSONEncode(self.LocalPacks))
		
		loadingFrame.Visible = false

		-- Return true since the pack was successfully converted to local
		return true
	elseif packageData.published then
		local success, result = FirestoreManager:ModifyDocument(id, packageData)

		loadingFrame.Visible = false
		-- Regular published pack save
		return success, result
	else
		-- Regular unpublished pack save
		local localPack = {
			blockPack = packageData,
			blocks = {}
		}
		
		-- Store blocks that belong to this pack
		for _, blockId in pairs(packageData.ContentBlockIds) do
			local blockData = self.CacheBlocks[blockId]
			if blockData then
				localPack.blocks[blockId] = blockData
			end
		end
		
		-- Store in local packs table
		self.LocalPacks[id] = localPack
		
		loadingFrame.Visible = false

		-- Save to plugin settings
		plugin:SetSetting("LocalPacks", HttpService:JSONEncode(self.LocalPacks))
		return true
	end
end


function DataManager:DeletePackage(packageData)
	local packId = packageData.PackId
	if startsWith(packId, "local/") then
		-- Delete local pack
		self.LocalPacks[packId] = nil
		plugin:SetSetting("LocalPacks", HttpService:JSONEncode(self.LocalPacks))
	else
		loadingFrame.Visible = true
		-- Delete published pack from Firestore
		local index = table.find(self.Data_MyPackages, packageData)
		if not index then return false end

		-- first remove every block in the package
		for _, blockId in pairs(packageData.ContentBlockIds) do
			FirestoreManager:RemoveDocument(blockId)
		end

		-- remove the package
		FirestoreManager:RemoveDocument(packId)

		table.remove(self.Data_MyPackages, index)

		loadingFrame.Visible = false
	end
	
	-- Clear from cache
	self.CacheBlockPacks[packId] = nil
	return true
end

function DataManager:DeleteBlock(packageData, blockId)
	-- Find the block index in the package's ContentBlockIds
	local blockIndex = table.find(packageData.ContentBlockIds, blockId)
	if not blockIndex then
		return false, "Block not found in package"
	end
	
	-- Remove the block ID from the package's ContentBlockIds
	table.remove(packageData.ContentBlockIds, blockIndex)
	
	if startsWith(blockId, "local/") then
		-- Delete local block
		if self.LocalPacks[packageData.PackId] and self.LocalPacks[packageData.PackId].blocks then
			self.LocalPacks[packageData.PackId].blocks[blockId] = nil
		end
		
		-- Save updated package to local storage
		plugin:SetSetting("LocalPacks", HttpService:JSONEncode(self.LocalPacks))
	else
		loadingFrame.Visible = true
		-- Delete published block from Firestore
		FirestoreManager:RemoveDocument(blockId)
		loadingFrame.Visible = false
	end
	
	-- Update the package
	self:SavePackage(packageData, packageData.PackId)
	
	-- Remove from cache
	self.CacheBlocks[blockId] = nil
	
	return true, "Block deleted successfully"
end

function DataManager:NewBlockPack()
	local newPack = self:Empty_Data_BlockPack()
	newPack.published = false -- Default to unpublished
	
	-- Generate a local ID
	newPack.PackId = generateLocalId()
	
	-- Add to local storage
	self.LocalPacks[newPack.PackId] = {
		blockPack = newPack,
		blocks = {}
	}
	
	-- Save to plugin settings
	plugin:SetSetting("LocalPacks", HttpService:JSONEncode(self.LocalPacks))
	
	-- Add to cache
	self.CacheBlockPacks[newPack.PackId] = newPack

	return newPack
end

function DataManager:NewBlock(Package: FirestoreManager.BlockPack): FirestoreManager.Block?
	local newBlock = self:Empty_Data_Block()
	
	if Package.published  then
		loadingFrame.Visible = true
		-- For published packs, save block to Firestore
		local success, result = FirestoreManager:PostBlock(newBlock)
		if not success then
			warn("error sending block to firebase")
			return nil
		end
		newBlock.BlockId = result

		loadingFrame.Visible = false
	else
		newBlock.BlockId = generateLocalId()
		warn(newBlock.BlockId)
	end
	
	newBlock.OwnerPackId = Package.PackId
	self.CacheBlocks[newBlock.BlockId] = newBlock
	table.insert(Package.ContentBlockIds, newBlock.BlockId)
	
	self:SavePackage(Package, Package.PackId)
	
	warn(newBlock)
	return newBlock
end


function DataManager:SaveBlock( block: FirestoreManager.Block, blockId ): (boolean, string)

	if not  block.OwnerPackId then
		warn("Cannot save block pack: missing ownerpackid")
		return false, "Cannot save block pack: missing ownerpackid"
	end
	

	local parentPackage = self:GetBlockPackById(block.OwnerPackId)
	if not parentPackage then
		warn("Errror getting parent pack")
		return false, "Error getting parent pack"
	end
	
	if parentPackage.published  then
		loadingFrame.Visible = true
		-- For published packs, save block to Firestore
		local success, result = FirestoreManager:ModifyDocument(blockId, block)
		if not success then
			warn("error sending block to firebase")
			return false, "Error saving block to cloud"
		end
		block.BlockId = result
		loadingFrame.Visible = false
	else
		
	end
	
	self:SavePackage(parentPackage, parentPackage.PackId)
	
	return true, "Operation succesfull"
end

function DataManager:GetBlockPackById(packId: string)
	warn(packId)
	-- First check cache
	if self.CacheBlockPacks[packId] then
		return self.CacheBlockPacks[packId]
	end
	
	-- Check local storage
	local localPack = self.LocalPacks[packId]
	if localPack then
		self.CacheBlockPacks[packId] = localPack.blockPack
		return localPack.blockPack
	end
	
	-- If not found locally, try Firestore
	loadingFrame.Visible = true
	return (function()
		local success, result = pcall(function()
			local url = "https://firestore.googleapis.com/v1/projects/".. packId
			local response = HttpService:GetAsync(url)
			return HttpService:JSONDecode(response)
		end)
		
		if not success then
			warn("Failed to fetch block pack:", result)
			loadingFrame.Visible = false
			return nil
		end
		
		local packageData = result.fields
		if not packageData then 
			loadingFrame.Visible = false
			return nil 
		end
		
		-- Convert Firestore values to Lua values
		for key, value in pairs(packageData) do
			if type(value) == "table" then
				packageData[key] = FirestoreManager:ConvertFromFirestoreValue(value)
			end
		end
		
		packageData.PackId = packId
		self.CacheBlockPacks[packId] = packageData
		loadingFrame.Visible = false
		return packageData
	end)()
end

return DataManager