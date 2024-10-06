if not game:GetService("RunService"):IsEdit() then return end

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
	"rbxassetid://92509631227825"
).Click:Connect(function () 
	if converter:isVisible() then
		converter:close()
		prompt:close()
	else
		converter:open()
	end
end)