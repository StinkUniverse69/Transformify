local this = script.Parent
local main = this.Main
local plugin = main.GetPluginManager:Invoke()

local Selection = game:GetService("Selection")
local SELECTION_CONNECTION : RBXScriptConnection;

local View = require(this.View)
local Convert = require(this.Convert)
local Recommend = require(this.Recommend)

local HistoryService = require(script.HistoryService)

local PLUGIN_NAME = this.Name
local GUI : typeof(script.Parent.Main.ScreenGui) = game.CoreGui[PLUGIN_NAME]

local Converter = View.new(GUI.ConverterPrompt)

local CONTENT :typeof(GUI.ConverterPrompt.Content) = Converter.container.Content

local TEXTBOX_FRAME = CONTENT.TextBoxOuter.TextBoxInner
local INPUT = TEXTBOX_FRAME.Text.Input
local RECOMMENDATION = TEXTBOX_FRAME.Text.Recommendation
---------

local getClassIcon = require(script.getClassIcon)
local Options = require(script.Options)

Options.fromParent(CONTENT)
Options.onButtonClick(function(button)
	INPUT.Text = button.Label.Text
	task.wait() -- so that the text actually gets changed
	Converter:submit()
end)
Options.adjustOnResize(GUI)

-- set another recommendation as active, by changing Recommend.index
local function setByIndexRecommendation()
	local recommended = Recommend.get() -- by index (Recommend.index)
	
	if #Recommend.options > 0 then
		Options.select(Recommend.index)
	end
	
	RECOMMENDATION.Text = recommended
	INPUT.Text = recommended:sub(1,#INPUT.Text) -- if there is only one option left this will prevent you from typing anything else (it replaces what you wrote)

	local icon = getClassIcon(recommended, "light")
	TEXTBOX_FRAME.Image.ImageLabel.Image = icon
end

-- update recommendations and
-- set #1 recommendation as active
local function setPreferredRecommendation()
	local selection = Selection:Get()
	
	Recommend.update(INPUT.Text, selection)
	Recommend.index = 1
	
	Options.empty()
	if #selection > 0 then
		Options.fill(Recommend.options)
	end
	
	setByIndexRecommendation()
end

-- when view is opened 
function Converter.open(self)
	plugin:Activate(true) -- capture mouse
	
	INPUT:CaptureFocus() -- focus textbox 
	
	-- update recommendations
	setPreferredRecommendation()
	SELECTION_CONNECTION = Selection.SelectionChanged:Connect(setPreferredRecommendation)
	
	-- set visible
	self:visible(true)
	GUI.Enabled = true
end

local fast_key_task = {
	down = nil,
	up = nil,
}
Converter:registerTextBox( INPUT,
	-- onFocusLost 
	function(enterPressed: boolean) 
		if enterPressed then Converter:submit() end -- does the same as pressing the submit button
	end,
	-- onFocusGained
	nil, 
	-- onTextChanged
	setPreferredRecommendation,
	-- onKey
	{
		[Enum.KeyCode.Down] = function ()
			Recommend.changeIndex(1)
			setByIndexRecommendation()
			
			if fast_key_task.down then 
				task.cancel(fast_key_task.down)
				fast_key_task.down = nil
			end
			fast_key_task.down = task.spawn(function()
				task.wait(0.5)
				while game.UserInputService:IsKeyDown(Enum.KeyCode.Down) do
					Recommend.changeIndex(1)
					setByIndexRecommendation()
					task.wait(0.1)
				end	
				fast_key_task.down = nil
			end)
		end,
		[Enum.KeyCode.Up] = function ()
			Recommend.changeIndex(-1)
			setByIndexRecommendation()
			
			if fast_key_task.up then 
				task.cancel(fast_key_task.up)
				fast_key_task.up = nil
			end
			fast_key_task.up = task.spawn(function()
				task.wait(0.5)
				while game.UserInputService:IsKeyDown(Enum.KeyCode.Up) do
					Recommend.changeIndex(-1)
					setByIndexRecommendation()
					task.wait(0.1)
				end
				fast_key_task.up = nil
			end)
		end,
	}
)


Converter:registerTopBarButtons(
	function (self, conversion_success) -- close
		
		HistoryService.finish(conversion_success)
		
		if SELECTION_CONNECTION then
			SELECTION_CONNECTION:Disconnect()
		end
		plugin:Deactivate()
		INPUT:ReleaseFocus()
		self:visible(false)
		GUI.Enabled = false
	end,

	function (self) -- more 
		
	end

)

local function startConversion(class)	
	return 
		xpcall(function(...)
			Selection:Set( Convert.run(Selection:Get(), class) )
		end, warn)	
end

---- Submit Button -----
-- this auto-generates the ConverterView:submit method
Converter:registerButton(TEXTBOX_FRAME.Submit, function (self)
	local class = RECOMMENDATION.Text
	if not class or #class < 1 then return end
	
	local conversion_success = HistoryService.start() and startConversion(class)
	self:close(conversion_success)
	script.ConversionFinishedEvent:Fire()
end)

return Converter
