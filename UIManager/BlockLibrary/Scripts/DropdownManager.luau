local DropdownManager = {}
DropdownManager.__index = DropdownManager

function DropdownManager.new(plugin)
	local self = setmetatable({}, DropdownManager)
	self.plugin = plugin
	self.__DefaultMenu = plugin:CreatePluginMenu("DropdownMenu", "Select an Option")
	return self
end

function DropdownManager:ShowDropdown(options: {{text:string, icon:string}}, callback)
	self.__DefaultMenu:Clear()

	-- Add options as actions
	for _, option in ipairs(options) do
		if option == "---" then
			self.__DefaultMenu:AddSeparator()
		else
			self.__DefaultMenu:AddNewAction(math.random(), option.text, option.icon)
		end
	end

	-- Show the menu and handle selection
	local selectedAction = self.__DefaultMenu:ShowAsync()
	if selectedAction and callback then
		callback(selectedAction.Text)
	end
end

return DropdownManager