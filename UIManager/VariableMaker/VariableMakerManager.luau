local VariableMakerManager = {}

local VariableMakerManagerUI: Frame, VariableManager

function VariableMakerManager:Init(variableMakerManagerUI, variableManager)
	VariableMakerManagerUI = variableMakerManagerUI
	VariableManager = variableManager
end

function VariableMakerManager:PromptMakeVariable()
	assert(VariableMakerManagerUI, "VariableMakerManager not initialized")
	
	local isForAllInstances = false
	
	local content = VariableMakerManagerUI.Content.Content
	
	content.ForThis.TextColor3 = Color3.fromRGB(127, 94, 207)
	content.ForAll.TextColor3 = Color3.fromRGB(102, 102, 102)
	
	content.NameD.TextBox.Text = ""
	VariableMakerManagerUI.Visible = true
	
	content.ForAll.MouseButton1Down:Connect(function()
		content.ForAll.TextColor3 = Color3.fromRGB(127, 94, 207)
		content.ForThis.TextColor3 = Color3.fromRGB(102, 102, 102)
		isForAllInstances = true
	end)
	
	content.ForThis.MouseButton1Down:Connect(function()
		content.ForThis.TextColor3 = Color3.fromRGB(127, 94, 207)
		content.ForAll.TextColor3 = Color3.fromRGB(102, 102, 102)
		isForAllInstances = false
	end)
	
	content.Ok.MouseButton1Down:Connect(function()
		VariableMakerManagerUI.Visible = false
		local name = content.NameD.TextBox.Text
		VariableManager:AddVariable(name, isForAllInstances)
	end)
	content.Cancel.MouseButton1Down:Connect(function()
		VariableMakerManagerUI.Visible = false
	end)
	
end

return VariableMakerManager
