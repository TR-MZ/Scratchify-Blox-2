local AutoUpdate = {}

-- Check for updates
-- @param MarketplaceService: MarketplaceService
-- @param Meta: table
-- @return boolean : does the plugin need to be updated
function AutoUpdate:CheckForUpdates(MarketplaceService: MarketplaceService, Meta): (boolean, string)
	local success, PluginProductInfo = pcall(function()
		return MarketplaceService:GetProductInfo(Meta.ProductId)
	end)
	
	if not success  then
		warn("AutoUpdate:CheckForUpdates() failed:", PluginProductInfo)
		return
	end
	
    local PluginDescription = PluginProductInfo.Description

    -- Split plugin description where "RELEASE - " is found
    local Split = string.split(PluginDescription, "RELEASE-")
    
    -- Check if the Split was successful
    if #Split ~= 2 or not tonumber(Split[2]) then
        warn("AutoUpdate:CheckForUpdates() failed: failed to split plugin description")

        return false, ""
    end

    -- Get the version number from the split description
    local PluginVersion = tonumber(Split[2])
    
    if PluginVersion > tonumber(Meta.Build) then
        return true, PluginVersion
    end

    return false, ""
end

return AutoUpdate