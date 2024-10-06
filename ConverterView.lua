local this = script.Parent
local main = this.Main
local plugin = main.GetPluginManager:Invoke()

-- This script only deals with the Plugin UI 
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local SELECTION_CONNECTION : RBXScriptConnection;


local View = require(this.View)
local Convert = require(this.Convert)
local Recommend = require(this.Recommend)

local PLUGIN_NAME = this.Name
local GUI : typeof(script.Parent.Main.ScreenGui) = game.CoreGui[PLUGIN_NAME]

local Converter = View.new(GUI.Container)

local TEXTBOX_FRAME = Converter.container.Content.TextBoxOuter.TextBoxInner
local INPUT = TEXTBOX_FRAME.Text.Input
local RECOMMENDATION = TEXTBOX_FRAME.Text.Recommendation

local function setByIndexRecommendation()
	local recommended = Recommend.get() -- by index (Recommend.index)

	RECOMMENDATION.Text = recommended
	INPUT.Text = recommended:sub(1,#INPUT.Text) -- if there is only one option left this will prevent you from typing anything else (it replaces what you wrote)
	
	local icon; 
	xpcall(function(...) 
		icon = game.StudioService:GetClassIcon(recommended)
	end, function(a0) 
		icon = game.StudioService:GetClassIcon("Instance")
	end)
	TEXTBOX_FRAME.Image.ImageLabel.Image = icon.Image:gsub("/Dark/", "/Light/")
end

local function setPreferredRecommendation()
	Recommend.update(INPUT.Text, Selection:Get())
	Recommend.index = 1
	setByIndexRecommendation()
end

Converter.open = function (self)
	plugin:Activate(true)
	INPUT:CaptureFocus()
	setPreferredRecommendation()
	SELECTION_CONNECTION = Selection.SelectionChanged:Connect(setPreferredRecommendation)
	self:visible(true)
	GUI.Enabled = true
end

Converter:registerTextBox( INPUT,
	-- onFocusLost 
	function(enterPressed: boolean) 
		if enterPressed then Converter:submit() end
	end,
	-- onFocusGained
	nil, 
	-- onTextChanged
	setPreferredRecommendation,
	-- onKey
	{
		[Enum.KeyCode.Up] = function ()
			Recommend.changeIndex(1)
			setByIndexRecommendation()	
		end,
		[Enum.KeyCode.Down] = function ()
			Recommend.changeIndex(-1)
			setByIndexRecommendation()	
		end,
	}
)

Converter:registerTopBarButtons(
	function (self) -- close
		SELECTION_CONNECTION:Disconnect()
		plugin:Deactivate()
		INPUT:ReleaseFocus()
		self:visible(false)
		GUI.Enabled = false
	end,

	function (self) -- more 
		-- TODO
	end

)

Converter:registerButton(TEXTBOX_FRAME.Submit, function (self)
	local class = RECOMMENDATION.Text
	if not class or #class < 1 then return end

	local recording = ChangeHistoryService:TryBeginRecording(string.format("Convert selected instances to %s", class))
	local revert_recording = function () ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel) end

	local FinishMethod = Enum.FinishRecordingOperation

	if not recording then 
		warn(PLUGIN_NAME .. ": Couldn't start recording history changes. Aborting conversion. Try updating the plugin and/or restarting studio."); 
		ChangeHistoryService:FinishRecording(recording, FinishMethod.Cancel)
		script.ConversionFinishedEvent:Fire()
		return 
	end 

	local success = xpcall(function(...)
		Selection:Set( Convert.run(Selection:Get(), class) )
	end, warn)

	ChangeHistoryService:FinishRecording(recording, (success and FinishMethod.Commit) or FinishMethod.Cancel)	

	self:close()
	script.ConversionFinishedEvent:Fire()
end)

return Converter
