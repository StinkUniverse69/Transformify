local plugin : Plugin = plugin

-- can be used in runmode etc as well
if not game:GetService("RunService"):IsServer() then return end

local this = script.Parent
local PLUGIN_NAME = this.Name

-- delete old ui if there already is one
do local ui = game.CoreGui:FindFirstChild(PLUGIN_NAME); if ui then ui:Destroy(); end end

local gui = script.ScreenGui:Clone()
gui.Name = PLUGIN_NAME
gui.Parent = game.CoreGui
gui.Enabled = false

script.GetPluginManager.OnInvoke = function () return plugin end

local converter = require(this.ConverterView)
local prompt = require(this.MarketPlaceView)

plugin:CreateToolbar(PLUGIN_NAME):CreateButton(
	"Instance Converter", 
	"Convert class of instances to another", 
	"rbxthumb://type=Asset&id=83506458688166&w=150&h=150"
).Click:Connect(function () 
	if converter:isVisible() then
		prompt:close()
		converter:close()
	else
		converter:open()
	end
end)

-- allow graceful reloading without upsetting the history service sometimes 
plugin.Unloading:Connect(function()
	prompt:close()
	converter:close()
end)

