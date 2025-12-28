local Utils = {}




-- CheckForScriptInjectionAllowed

local scriptInjectionDummy = Instance.new("Script")

-- Check if the user have allowed script injection
function Utils:CheckForScriptInjectionAllowed(): boolean
    local scriptInjectionCheck, _ = pcall(function()
        scriptInjectionDummy.Source = "print()"
		scriptInjectionDummy.Parent = game.StarterPlayer
	end)
	
    if scriptInjectionDummy.Parent == game.StarterPlayer then
        scriptInjectionDummy.Parent = nil
    end

	return scriptInjectionCheck
end

-- Get Script Injection Widget

local scriptInjectionWidget: DockWidgetPluginGui

-- Get the script injection widget, creates a new one if it doesn't exist
function Utils:GetScriptInjectionWidget(plugin): DockWidgetPluginGui
    if not scriptInjectionWidget then
        scriptInjectionWidget = plugin:CreateDockWidgetPluginGui(
            "ScriptInjectionWidget",
            DockWidgetPluginGuiInfo.new(
                Enum.InitialDockState.Float,
                false,
                false,
                500,
                150,
                150,
                200
            )
        )

        local text = Instance.new("TextLabel", scriptInjectionWidget)
        text.Size = UDim2.fromScale(1, 1)
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.RichText = true
        text.TextWrapped = true

        text.Text = [[
        The <b>Scratchify Blox</b> plugin for Roblox Studio requires <b>script injection</b> to work, as it dynamically generates and inserts Lua scripts into your game.

        To enable it:  
            1. Go to <b>Plugins &gt; Manage Plugins &gt; Scratchify Blox</b>.  
            2. Toggle <b>Allow Third-Party Script Injection</b>.

        This setting is essential for the plugin to function properly.

        <b>You may need to restart Studio for the changes to take effect.</b>

        Click on the toolbar button to try again.
        ]]
    end

    return scriptInjectionWidget
end

return Utils