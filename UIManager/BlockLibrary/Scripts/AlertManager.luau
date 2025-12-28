local AlertManager = {}
AlertManager.__index = AlertManager

function AlertManager.new(alertUI)
	local self = setmetatable({}, AlertManager)
	self.AlertUI = alertUI
	return self
end

function AlertManager:promptAlert(title, description, button1, button2, onButton1, onButton2)
	local connections = {}
	local function disconnectAll()
		for _, connection in pairs(connections) do
			connection:Disconnect()
		end
	end

	local me = self.AlertUI
	me.Visible = true

	local content = me.Content

	content.Top.TextLabel.Text = title
	content.Content.TextLabel.Text = description or "Unknown error"

	content.Content.Ok.Text = button1 or "Ok" 
	table.insert(connections, content.Content.Ok.MouseButton1Up:Connect(function()
		disconnectAll()
		onButton1()
		me.Visible = false
	end))

	if button2 then
		content.Content.Cancel.Visible = true
		content.Content.Cancel.Text = button2 or "Cancel"
		table.insert(connections, content.Content.Cancel.MouseButton1Up:Connect(function()
			disconnectAll()
			onButton2()
			me.Visible = false
		end))
	else
		content.Content.Cancel.Visible = false
	end
end

return AlertManager