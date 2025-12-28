--[[

ScratchifyBlox2
A plugin that converts code in Roblox like you would in Scratch.

- by @Ph0enixx_31 (TR-MZ)

]]

-- Check if the plugin is running in a plugin environment
assert(plugin, "ScratchifyBlox2 requires to be run in a plugin environment")

-- Check if studio is not in Run mode (silently return if it is)
if game:GetService("RunService"):IsRunning() then return end

-- Load the plugin Services
local PluginService = game:GetService("PluginGuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local SelectionService = game:GetService("Selection")
local HttpService = game:GetService("HttpService")
local toolbar = plugin:CreateToolbar("Editor")
local StudioService = game:GetService("StudioService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Constants -------------------------------------------------------------

local FOLDER_UTILS = script.Parent.Utils

-- Load the plugin modules -----------------------------------------------

local ScriptInjectionManager = require(FOLDER_UTILS.ScriptInjectionManager)
local AutoUpdate = require(FOLDER_UTILS.AutoUpdate)
local EnvironmentManager = require(FOLDER_UTILS.EnvironmentManager)
local Meta = require(FOLDER_UTILS.Meta)
local Constants = require(script.Parent.Constants.MainConstants)
local UIManager = require(script.Parent.UIManager.EditorUIManager)
-- Create the plugin GUI -------------------------------------------------
local UIPluginButton = toolbar:CreateButton(
	"Toggle Editor",
	"Scratchify",
	"rbxassetid://18563280627" 
)
UIPluginButton.ClickableWhenViewportHidden = true
-- Check for script injection --------------------------------------------

-- First register a on plugin button clicked to show the script injection error widget
if not ScriptInjectionManager:CheckForScriptInjectionAllowed() then
	-- Show the script injection error widget when the plugin button is clicked
	local pluginButtonConnection = UIPluginButton.Click:Connect(function()
		ScriptInjectionManager:GetScriptInjectionWidget(plugin).Enabled = true
	end)
	
	-- Wait until the user allows script injection
	while not ScriptInjectionManager:CheckForScriptInjectionAllowed() do
		wait(2)
	end

	-- The user has allowed script injection, disconnect the plugin button connection
	pluginButtonConnection:Disconnect()
end

-- Setup the plugin environment ------------------------------------------
EnvironmentManager:Setup()


-- Create Main Widget ----------------------------------------------------

local EditorWidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float ,
	true,
	false,
	500,
	500,
	500,
	500
)

local EditorWidget = plugin:CreateDockWidgetPluginGui("ScratchifyEditor", EditorWidgetInfo)
EditorWidget.Title = "Editor - Scratchify Blox - Build: " .. Meta.Build

UIPluginButton.Click:Connect(function()
	EditorWidget.Enabled = not EditorWidget.Enabled
end)



-- Check for updates -----------------------------------------------------
local updateAvailable, latest = AutoUpdate:CheckForUpdates(MarketplaceService, Meta)
if updateAvailable then
	local newVersion = script.Parent.NewVersion
	newVersion.Parent = EditorWidget
	newVersion.TextLabel2.Text = "New Version Available - Current: "..Meta.Build
	newVersion.NOTE.Text = "RELEASE-"..latest

	warn("Scratchify Blox: New Update available!")
	
	newVersion.TextButton.MouseButton1Down:Wait()
	newVersion:Destroy()
end

-- Initialize the UI ------------------------------------------------
UIManager:Init(EditorWidget, plugin)

