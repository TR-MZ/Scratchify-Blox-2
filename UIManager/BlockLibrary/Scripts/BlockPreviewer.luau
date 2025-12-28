-- Function to darken a color
-- @param color: Color3, the color to darken
-- @param d: float number, the darkening factor. 0 - 1 : darker, 1 - 2 : lighter
-- @return Color3, the darkened color
local function DarkenColor(color: Color3, d: number): Color3
	return Color3.new(color.R * d, color.G * d, color.B * d)
end

return function (parent, block, color)
	if typeof(color) then
		color = Color3.fromHex(color)
	end

  -- Create block preview
  local path_to_element_uis = script.Parent.Parent.Parent.Parent.BlocksFactory.Assets.DefaultBlockContents
  local previewBlockFrame = script.Parent.Parent.Parent.Parent.BlocksFactory.Assets.DefaultBlockFrames:FindFirstChild(block.Type):Clone()
  previewBlockFrame.Parent = parent

  -- Add elements to preview
  for _, element in pairs(block.Elements) do
      local elementUI
      if element.contentType == "Text" then
          elementUI = path_to_element_uis.Text:Clone()
          elementUI.Text = element.content
      elseif element.contentType == "AnyValue" or element.contentType == "NumberValue" then
          elementUI = path_to_element_uis:FindFirstChild(element.contentType):Clone()
          elementUI.TextBox.Text = element.content
          elementUI.TextBox.TextEditable = false
      elseif element.contentType == "Picker" then
          elementUI = path_to_element_uis.Picker:Clone()
          elementUI.Title.Text = element.content
      elseif element.contentType == "GetValue" then
          elementUI = path_to_element_uis.GetValue:Clone()
          elementUI.Value.Block.Text.Text = element.content
          elementUI.Value.Block.Text.Visible = true
      end

      if elementUI then
          elementUI.Parent = previewBlockFrame.Block
          elementUI.LayoutOrder = table.find(block.Elements, element)
      end
  end



    -- Set preview block color
    if block.Type == "ValueBlock" then
        previewBlockFrame.Block.BackgroundColor3 = color
        previewBlockFrame.Block.UIStroke.Color = DarkenColor(color, 0.75)
    else
        previewBlockFrame.Block.ImageColor3 = color
    end
end
