local BASIC_BLOCKS = {}

local motion : {block} = {
	-- Set Position to x: y: z:
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Normal",
		func = "instance.Position = Vector3.new(&,&,&) \n",
		content = {
			{
				contenttype = "Text",
				content = "Set Position to x:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "y:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "z:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
		}
	},
	-- Move by
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Normal",
		func = "instance.Position += Vector3.new(&,&,&) \n",
		content = {
			{
				contenttype = "Text",
				content = "Move by x:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "y:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "z:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
		}
	},
	-- Rotate by x: y: z:
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Normal",
		func = "instance.Orientation += Vector3.new(&,&,&) \n",
		content = {
			{
				contenttype = "Text",
				content = "Rotate by x:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "y:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "z:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
		}
	},
	-- Set x to:
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Normal",
		func = "instance.Position = Vector3.new(&, instance.Position.Y, instance.Position.Z) \n",
		content = {
			{
				contenttype = "Text",
				content = "Set x to:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
		}
	},

	-- Set y to:
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Normal",
		func = "instance.Position = Vector3.new(instance.Position.X, &, instance.Position.Z) \n",
		content = {
			{
				contenttype = "Text",
				content = "Set y ro:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
		}
	},

	-- Change z by:
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Normal",
		func = "instance.Position = Vector3.new(instance.Position.X, instance.Position.Y, &) \n",
		content = {
			{
				contenttype = "Text",
				content = "Set z to:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
		}
	},
	-- Get x :
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Value",
		func = "instance.Position.X",
		content = {
			{
				contenttype = "Text",
				content = "X postion"
			}, 
		}
	},
	-- Get y :
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Value",
		func = "instance.Position.Y",
		content = {
			{
				contenttype = "Text",
				content = "Y postion"
			}, 
		}
	},
	-- Get z :
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Value",
		func = "instance.Position.Z",
		content = {
			{
				contenttype = "Text",
				content = "Z postion"
			}, 
		}
	},
	---------------------------- gui object
	-- Set UDim position :
	{
		specificTo = "GuiObject",
		category = "Motion",
		blockType = "Normal",
		func = "instance.Position = UDim2.from&(&, &)",
		content = {
			{
				contenttype = "Text",
				content = "Set position using:"
			},
			{
				contenttype = "Picker",
				content = "Offset",
				pickerContent = {"Offset", "Scale"}
			},
			{
				contenttype = "Text",
				content = "to x:"
			},
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "y:"
			},
			{
				contenttype = "NumberValue",
				content = 0
			},
		},

	},
	-- Set Anchor point to :
	{
		specificTo = "GuiObject",
		category = "Motion",
		blockType = "Normal",
		func = "instance.AnchorPoint = Vector2.new(&,&)",
		content = {
			{
				contenttype = "Text",
				content = "Set anchor point to x:"
			},
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "y:"
			},
			{
				contenttype = "NumberValue",
				content = 0
			},
		},

	},

}

local looks : {block} = {
	---------------------- Base part
	-- transparency
	{
		specificTo = "BasePart", 
		category = "Look",
		blockType = "Normal",
		func = "instance.Transparency = & \n",
		content = {
			{
				contenttype = "Text",
				content = "Set transparency to"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			}, 
		}
	},

	-- set size
	{
		specificTo = "BasePart", 
		category = "Look",
		blockType = "Normal",
		func = "instance.Size = Vector3.new(&, &, &) \n", 
		content = {
			{
				contenttype = "Text",
				content = "Set size to x:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "y:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "z:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
		},
		-- scale
		{
			specificTo = "BasePart", 
			category = "Look",
			blockType = "Normal",
			func = "instance.Size = instance.Size * & \n",
			content = {
				{
					contenttype = "Text",
					content = "Scale current size by:"
				}, 
				{
					contenttype = "NumberValue",
					content = 0
				},
			},
		}
	},
	-- Set rotation to x: y: z:
	{
		specificTo = "BasePart", 
		category = "Motion",
		blockType = "Normal",
		func = "instance.Orientation = Vector3.new(&,&,&) \n",
		content = {
			{
				contenttype = "Text",
				content = "Set rotation to x:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "y:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "z:"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
		}
	},
	--------- Gui object
	{
		specificTo = "GuiButton", 
		category = "Events",
		blockType = "Event",
		func = "instance.MouseButton1Down:Connect(function() \n local playerwhopressed = instance:FindFirstAncestorOfClass('player') \n",
		content = {
			{
				contenttype = "Text",
				content = "When this button is pressed"
			}, 

			{
				contenttype = "GetValue",
				content =   "playerwhopressed",
				contentLabel = "Player"
			},
		}
	},
	{
		specificTo = "GuiButton", 
		category = "Events",
		blockType = "Event",
		func = "instance.MouseButton1Up:Connect(function() \n local playerwhopressed = instance:FindFirstAncestorOfClass('player') \n",
		content = {
			{
				contenttype = "Text",
				content = "When this button is released"
			}, 

			{
				contenttype = "GetValue",
				content =   "playerwhopressed",
				contentLabel = "Player"
			},
		}
	},
	{
		specificTo = "GuiObject", 
		category = "Events",
		blockType = "Event",
		func = "instance.MouseEnter:Connect(function() \n local playerwhopressed = instance:FindFirstAncestorOfClass('player') \n",
		content = {
			{
				contenttype = "Text",
				content = "When mouse enters me"
			}, 

			{
				contenttype = "GetValue",
				content =   "playerwhopressed",
				contentLabel = "Player"
			},
		}
	},
	{
		specificTo = "GuiObject", 
		category = "Events",
		blockType = "Event",
		func = "instance.MouseLeave:Connect(function() \n local playerwhopressed = instance:FindFirstAncestorOfClass('player') \n",
		content = {
			{
				contenttype = "Text",
				content = "When mouse leaves me"
			}, 

			{
				contenttype = "GetValue",
				content =   "playerwhopressed",
				contentLabel = "Player"
			},
		}
	},

	{
		specificTo = "GuiObject", 
		category = "Sensing",
		blockType = "Value",
		func = "Color3.fromRGB(&,&,&)",

		content = {
			{
				contenttype = "Text",
				content = "color with red"

			}, 
			{
				contenttype = "NumberValue",
				content = ""

			}, 
			{
				contenttype = "Text",
				content = "green"

			}, 
			{
				contenttype = "NumberValue",
				content = ""

			}, 
			{
				contenttype = "Text",
				content = "blue"

			}, 
			{
				contenttype = "NumberValue",
				content = ""

			}, 
		}
	},
	{
		specificTo = "GuiObject", 
		category = "Sensing",
		blockType = "Value",
		func = "instance.BackgroundColor3",

		content = {
			{
				contenttype = "Text",
				content = "my background color"

			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(function() \n local color = & \n local keys = {red = 'R', green = 'G', blue = 'B'} local key = keys['&'] \n return color[key]  end)()",
		content = {
			{
				contenttype = "Text",
				content = "in color"

			}, 
			{
				contenttype = "AnyValue",
				content = ""
			}, 
			{
				contenttype = "Text",
				content = ", get the amount of "
			}, 
			{
				contenttype = "Picker",
				content = "red",
				pickerContent = {"red", "green", "blue"}	
			},
		}
	},

}

local sound = {

}

local _keys = {}
for _, k in pairs(Enum.KeyCode:GetEnumItems()) do
	if k.Name:find("World") then continue end
	table.insert(_keys, k.Name)
end

local Events = {
	{
		specificTo = nil, 
		category = "Events",
		blockType = "Event",
		func = "scriptRoot.Event:Connect(function() \n",
		content = {
			{
				contenttype = "Text",
				content = "When the game starts"
			}, 
		}
	},

	{
		specificTo = nil,
		category = "Events",
		blockType = "Event",
		func = "Remote.OnServerEvent:Connect(function(playerwhopressed, e, input) \n if e ~= \"Input\" or input ~= \"&\" then return end \n " ,
		content = {
			{ 
				contenttype = "Text",
				content = "When a player presses the key"
			},
			{
				contenttype = "Picker",
				content = "Space",
				pickerContent = _keys	
			},
			{
				contenttype = "GetValue",
				content =   "playerwhopressed",
				contentLabel = "Player"
			},
		}
	},

	--- player joined
	{
		specificTo = nil,
		category = "Events",
		blockType = "Event",
		func = "game.Players.PlayerAdded:Connect(function(playerwhojoined)",
		content = {
			{ 
				contenttype = "Text",
				content = "When a player joins"
			},
			{
				contenttype = "GetValue",
				content =   "playerwhojoined",
				contentLabel = "Player"
			},
		}
	},

	-- do for only one player
	{
		specificTo = nil,
		category = "Events",
		blockType = "ClosureStart",
		clientID = "",
		func = "if true then  pcall(function() Remote:InvokeClient(&, \"@\", ScratchifyID) end)",
		content = {
			{ 
				contenttype = "Text",
				content = "Do only for player "
			},
			{
				contenttype = "AnyValue",
				content =  ""		
			},
		}
	},

	{
		specificTo = nil,
		category = "Events",
		blockType = "Event",
		func = "instance.Touched:Connect(function(thingThatTouchedMe) thingThatTouchedMe = game.Players:GetPlayerFromCharacter(thingThatTouchedMe.Parent) if not thingThatTouchedMe then return end ",
		content = {
			{ 
				contenttype = "Text",
				content = "When i am touched by a"
			},
			{
				contenttype = "GetValue",
				content =   "thingThatTouchedMe",
				contentLabel = "player"
			},
		}
	},
	{
		specificTo = nil,
		category = "Events",
		blockType = "Event",
		func = "instance.Touched:Connect(function(thingThatTouchedMe)",
		content = {
			{ 
				contenttype = "Text",
				content = "When i am touched by"
			},
			{
				contenttype = "GetValue",
				content =   "thingThatTouchedMe",
				contentLabel = "something"
			},
		}
	},




}

local controls = {{
	specificTo = nil, 
	category = "Controls",
	blockType = "Normal",
	func = "wait(&)\n",
	content = {
		{
			contenttype = "Text",
			content = "Wait"
		},
		{
			contenttype = "NumberValue",
			content = 1
		}, 
	}
},
	--- print
	{
		specificTo = nil, 
		category = "Controls",
		blockType = "Normal", 
		func = "print(&)\n",
		content = {
			{
				contenttype = "Text",
				content = "Print to console"
			},
			{
				contenttype = "AnyValue",
				content = 1
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Controls",
		blockType = "ClosureStart",
		func = "if (&) then \n",
		content = {
			{
				contenttype = "Text",
				content = "if"
			}, 
			{
				contenttype = "AnyValue",
				content = ""
			},
			{
				contenttype = "Text",
				content = "then"
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Controls",
		blockType = "DoubleClosureStart",
		func = "if (&) then \n",
		content = {
			{
				contenttype = "Text",
				content = "if"
			}, 
			{
				contenttype = "AnyValue",
				content = ""
			},
			{
				contenttype = "Text",
				content = "then"
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Controls",
		blockType = "ClosureStart",
		func = "for _ = 1, tonumber(&) do \n",
		content = {
			{
				contenttype = "Text",
				content = "Repeat"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			},
			{
				contenttype = "Text",
				content = "times"
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Controls",
		blockType = "ClosureStart",
		func = "while (&) do \n",
		content = {
			{
				contenttype = "Text",
				content = "While"
			}, 
			{
				contenttype = "AnyValue",
				content = ""
			},
			{
				contenttype = "Text",
				content = "do"
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Controls",
		blockType = "Normal", 
		func = "break\n",
		content = {
			{
				contenttype = "Text",
				content = "End loop"
			},
		}
	},
	{
		specificTo = nil, 
		category = "Controls",
		blockType = "Normal", 
		func = "continue\n",
		content = {
			{
				contenttype = "Text",
				content = "Next loop iteration"
			},
		}
	},
	{
		specificTo = nil, 
		category = "Controls",
		blockType = "Normal", 
		func = "return\n",
		content = {
			{
				contenttype = "Text",
				content = "Stop this script"
			},
		}
	},
	-- do for only one player
	{
		specificTo = "BasePart",
		category = "Controls",
		blockType = "ClosureStart",
		func = "if true then local instance = & \n",
		content = {
			{ 
				contenttype = "Text",
				content = "Do for instance "
			},
			{
				contenttype = "AnyValue",
				content =  ""		
			},
		}
	},
}


local sensors: {block} = {
	--	{
	--		specificTo = nil, 
	--		category = "Sensing",
	--		blockType = "Value",
	--		func = [[local _playerCharacters = {}
	--for i, p in game.Players:GetPlayers() do
	--	local _playerCharacter = player.Character
	--	if _playerCharacter then table.insert(_playerCharacters, _playerCharacter) end
	--end

	--]],
	--		content = {
	--			{
	--				contenttype = "Text",
	--				content = "Get nearest player"
	--			},
	--			{
	--				contenttype = "NumberValue",
	--				content = 1
	--			}, 
	--		}
	--	},

	{
		specificTo = "BasePart", 
		category = "Sensing",
		blockType = "Value",
		func = [[( function () 
	local d = &
	local _playerCharacters = {}
	for i, p in game.Players:GetPlayers() do
		local _playerCharacter = p.Character
		if _playerCharacter then 
			local _playerCharacterPosition = _playerCharacter.PrimaryPart and _playerCharacter.PrimaryPart.Position or _playerCharacter:GetPivot().Position 
			if (instance.Position - _playerCharacterPosition).Magnitude <= d then
			return true
			end
		end
	end
	return false
	end )()  ]],
		content = {
			{
				contenttype = "Text",
				content = "Is any player in range"
			},
			{
				contenttype = "NumberValue",
				content = 5
			},
			{
				contenttype = "Text",
				content = "studs"
			},
		},
	},

}

local operators = {
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(tonumber(&) + tonumber(&))",
		content = {
			{
				contenttype = "NumberValue",
				content = 0
			}, 
			{
				contenttype = "Text",
				content = "+"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(tonumber(&) - tonumber(&))",
		content = {
			{
				contenttype = "NumberValue",
				content = 0
			}, 
			{
				contenttype = "Text",
				content = "-"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(tonumber(&) * tonumber(&))",
		content = {
			{
				contenttype = "NumberValue",
				content = 0
			}, 
			{
				contenttype = "Text",
				content = "*"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(tonumber(&) / tonumber(&))",
		content = {
			{
				contenttype = "NumberValue",
				content = 0
			}, 
			{
				contenttype = "Text",
				content = "/"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "math.&(tonumber(&))",
		content = {
			{
				contenttype = "Picker",
				content = "abs",
				pickerContent = {
					"abs",
					"floor",
					"ceil",
					"sqrt",
					"sin",
					"cos",
					"tan",
					"asin",
					"acos",
					"atan",
					"log",
					"exp",
				}
			},
			{
				contenttype = "Text",
				content = "of"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "math.round(&)",
		content = {
			{
				contenttype = "Text",
				content = "round"
			}, 
			{
				contenttype = "NumberValue",
				content = 0
			}, 
		}
	},


	-- 
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value", 
		func = "tostring(&)..tostring(&)",
		content = {
			{
				contenttype = "Text",
				content = "Join",
			},
			{
				contenttype = "AnyValue",
				content = ""
			}, 
			{
				contenttype = "Text",
				content = "and",
			},
			{
				contenttype = "AnyValue",
				content = ""
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value", 
		func = "tostring(&):split(\"\")[&]",
		content = {
			{
				contenttype = "Text",
				content = "in",
			},
			{
				contenttype = "AnyValue",
				content = ""
			}, 
			{
				contenttype = "Text",
				content = "letter number",
			},
			{
				contenttype = "NumberValue",
				content = ""
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value", 
		func = "#tostring(&):split(\"\")",
		content = {
			{
				contenttype = "Text",
				content = "lenght of",
			},
			{
				contenttype = "AnyValue",
				content = ""
			}, 
		}
	},
	{
		specificTo = nil, 
		category = "Operators",
		blockType = "Value", 
		func = "math.random(tonumber(&),tonumber(&))",
		content = {
			{
				contenttype = "Text",
				content = "random number between",
			},
			{
				contenttype = "NumberValue",
				content = ""
			}, 
			{
				contenttype = "Text",
				content = "and",
			},
			{
				contenttype = "NumberValue",
				content = ""
			}, 
		}
	},
	{ -- true / false
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "true",
		content = {
			{
				contenttype = "Text",
				content = " true ",
			},
		}
	},
	{ -- true / false
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "false",
		content = {
			{
				contenttype = "Text",
				content = " false ",
			},
		}
	},

	{ -- true / false
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(& == &)",
		content = {
			{
				contenttype = "Text",
				content = "is",
			},
			{
				contenttype = "AnyValue",
				content = "",
			},
			{
				contenttype = "Text",
				content = "=",
			},
			{
				contenttype = "AnyValue",
				content = "",
			},
			{
				contenttype = "Text",
				content = "?",
			},
		}
	},
	{ -- true / false
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(& > &)",
		content = {
			{
				contenttype = "Text",
				content = "is",
			},
			{
				contenttype = "AnyValue",
				content = "",
			},
			{
				contenttype = "Text",
				content = ">",
			},
			{
				contenttype = "AnyValue",
				content = "",
			},
			{
				contenttype = "Text",
				content = "?",
			},
		}
	},
	{ -- true / false
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(& < &)",
		content = {
			{
				contenttype = "Text",
				content = "is",
			},
			{
				contenttype = "AnyValue",
				content = "",
			},
			{
				contenttype = "Text",
				content = "<",
			},
			{
				contenttype = "AnyValue",
				content = "",
			},
			{
				contenttype = "Text",
				content = "?",
			},
		}
	},
	{ -- true / false
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(& and &)",
		content = {
			{
				contenttype = "AnyValue",
				content = "",
			},
			{
				contenttype = "Text",
				content = "and",
			},
			{
				contenttype = "AnyValue",
				content = "",
			},
		}
	},
	{ -- true / false
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(& or &)",
		content = {
			{
				contenttype = "AnyValue",
				content = "",
			},
			{
				contenttype = "Text",
				content = "or",
			},
			{
				contenttype = "AnyValue",
				content = "",
			},
		}
	},
	{ -- true / false
		specificTo = nil, 
		category = "Operators",
		blockType = "Value",
		func = "(not &)",
		content = {
			{
				contenttype = "Text",
				content = "not",
			},
			{
				contenttype = "AnyValue",
				content = "",
			},
		}
	},

}



local variables = {

	{
		specificTo = nil, 
		category = "Variables",
		blockType = "Normal",
		func = "local varName = \"&\" myVars:Set( table.find(require(game.ReplicatedStorage.ScratchifyBloxEnvironment.GlobalVariables), varName) and varName or ScratchifyID..varName, & ) \n",
		content = {
			{
				contenttype = "Text",
				content = "Set var"
			},
			{
				contenttype = "Picker",
				content = "",
				pickerContentName = "variables"
			}, 
			{
				contenttype = "Text",
				content = "to value"
			},
			{
				contenttype = "AnyValue",
				content = ""
			}, 
		}
	},

	{
		specificTo = nil, 
		category = "Variables",
		blockType = "Normal",
		func = "local varName = \"&\" myVars:Set( table.find(require(game.ReplicatedStorage.ScratchifyBloxEnvironment.GlobalVariables), varName) and varName or ScratchifyID..varName, {} ) \n",
		content = {
			{
				contenttype = "Text",
				content = "Set var"
			},
			{
				contenttype = "Picker",
				content = "",
				pickerContentName = "variables"
			}, 
			{
				contenttype = "Text",
				content = "to an empty list"
			}
		}
	},
	-- Add element to list
	{
		specificTo = nil, 
		category = "Variables",
		blockType = "Normal",
		func = [[local varName = "&"
varName = table.find(require(game.ReplicatedStorage.ScratchifyBloxEnvironment.GlobalVariables), varName) and varName or ScratchifyID..varName
local initialValue = myVars:Get(varName) or {}
if typeof(initialValue) ~= "table" then
	initialValue = {initialValue}
end
table.insert(initialValue, &)
myVars:Set(
	 varName,
	 initialValue
)
]],
		content = {
			{
				contenttype = "Text",
				content = "Add to list"
			},
			{
				contenttype = "Picker",
				content = "",
				pickerContentName = "variables"
			}, 
			{
				contenttype = "Text",
				content = "element"
			},
			{
				contenttype = "AnyValue",
				content = ""
			}
		}
	},
	-- set element at key in list
	{
		specificTo = nil, 
		category = "Variables",
		blockType = "Normal",
		func = [[
local key = &
local varName = "&"
varName = table.find(require(game.ReplicatedStorage.ScratchifyBloxEnvironment.GlobalVariables), varName) and varName or ScratchifyID..varName
local initialValue = myVars:Get(varName) or {}
if typeof(initialValue) ~= "table" then
	initialValue = {initialValue}
end
initialValue[key] = &
myVars:Set(
	 varName,
	 initialValue
)
]],
		content = {
			{
				contenttype = "Text",
				content = "Set element at"
			},
			{
				contenttype = "AnyValue",
				content = ""
			},
			{
				contenttype = "Text",
				content = "in list"
			},
			{
				contenttype = "Picker",
				content = "",
				pickerContentName = "variables"
			}, 
			{
				contenttype = "Text",
				content = "to value"
			},
			{
				contenttype = "AnyValue",
				content = ""
			},
		}
	},

	{
		specificTo = nil, 
		category = "Variables",
		blockType = "Value",
		func = [[(function() local key = &
local varName = "&"
varName = table.find(require(game.ReplicatedStorage.ScratchifyBloxEnvironment.GlobalVariables), varName) and varName or ScratchifyID..varName
local initialValue = myVars:Get(varName) or {}
if typeof(initialValue) ~= "table" then
	initialValue = {initialValue}
end
return initialValue[key]
end)()
]],
		content = {
			{
				contenttype = "Text",
				content = "Element at"
			},
			{
				contenttype = "AnyValue",
				content = ""
			},
			{
				contenttype = "Text",
				content = "in list"
			},
			{
				contenttype = "Picker",
				content = "",
				pickerContentName = "variables"
			}, 
		}
	},

	

	{
		specificTo = nil, 
		category = "Variables",
		blockType = "Value",
		func = "#&",
		content = {
			{
				contenttype = "Text",
				content = "Number of elements in list"
			},
			{
				contenttype = "AnyValue",
				content = ""
			}, 
		}
	},


}

local Players : {block} = {

	{
		specificTo = nil, 
		category = "Players",
		blockType = "Value", 
		func = "game.Players:GetPlayers()",
		content = {
			{
				contenttype = "Text",
				content = "Get all players",
			}
		}
	},
	{

		specificTo = nil, 
		category = "Players",
		blockType = "Normal", 
		func = [[
    (function() 
        local d = &  -- Assign a valid number or value
        local p = &  -- Example of a valid assignment
        if p.Character and p.Character:FindFirstChildWhichIsA("Humanoid") then 
            p.Character:FindFirstChildWhichIsA("Humanoid"):TakeDamage(d)  
        end 
    end)()
]],

		content = {
			{
				contenttype = "Text",
				content = "Deal",
			},
			{
				contenttype = "NumberValue",
				content = "10",
			},
			{
				contenttype = "Text",
				content = "damage to player",
			},
			{
				contenttype = "AnyValue",
				content = "",
			}
		}
	},
}


-- Copies everything from t1 to t2
local function addToTable(t1, t2)
	
	
	for _, el in pairs(t1) do
		table.insert(t2, el)
	end
end

local function addCategoryTag(t1, cat)
	table.insert(t1, "CAT_"..cat)
end


addCategoryTag(BASIC_BLOCKS, "Motion")
addCategoryTag(BASIC_BLOCKS, "Look")
addCategoryTag(BASIC_BLOCKS, "Sounds")
addCategoryTag(BASIC_BLOCKS, "Events")
addCategoryTag(BASIC_BLOCKS, "Controls")
addCategoryTag(BASIC_BLOCKS, "Sensing")
addCategoryTag(BASIC_BLOCKS, "Operators")
addCategoryTag(BASIC_BLOCKS, "Variables")
addCategoryTag(BASIC_BLOCKS, "Players")
addToTable(motion, BASIC_BLOCKS)
addToTable(looks, BASIC_BLOCKS)
addToTable(sound, BASIC_BLOCKS)
addToTable(Events, BASIC_BLOCKS)
addToTable(controls, BASIC_BLOCKS)
addToTable(sensors, BASIC_BLOCKS)
addToTable(operators, BASIC_BLOCKS)
addToTable(variables, BASIC_BLOCKS)
addToTable(Players, BASIC_BLOCKS)


return BASIC_BLOCKS