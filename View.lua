local this = script.Parent
local plugin = this.Main.GetPluginManager:Invoke()

local PLUGIN_NAME = this.Name
local GUI : typeof(script.Parent.Main.ScreenGui) = game.CoreGui[PLUGIN_NAME]

local INPUT_TYPE = Enum.UserInputType
local KEY = Enum.KeyCode

local InputService = game:GetService("UserInputService")

export type View = {
	-- properties
	container : Frame,
	
	-- functions
	registerTopBarButtons : (
		self : View,
		close : () -> (), 
		more : () -> ()
	) -> (),
	registerButton : (self : View) -> (),
	registerTextBox : (
		self : View, 
		input : TextBox,
		onFocusLost : () -> (),
		onFocusGained : () -> (),
		onTextChanged : () -> (),
		onKey : {[Enum.KeyCode] : (self : View) -> ()}
	) -> (),
	visible : (self : View, visible : boolean) -> (),
	
	-- can be set manually
	open : (self : View) -> (),
	
	-- most common generated functions
	-- any buttons action can be called this way as well
	close : (self : View) -> (),
	more : (self : View) -> (),
	
	-- 
	isVisible : (self : View) -> boolean,
}

local View = {}
View.__index = View

local void = function () end

function View.new(container : Frame) : View
	local view = setmetatable({
		container = container,
	}, View)
	view:enableDrag()
	view.container.Visible = false
	
	InputService.InputBegan:Connect(function(userInput: InputObject, gameProcessedEvent: boolean)
		if 
			view.container.Visible and 
			userInput.UserInputType	== INPUT_TYPE.Keyboard and
			userInput.KeyCode		== KEY.Escape
		then view:close(); return; end
	end)
	
	return view
end

function View.visible(self : View, is_visible : boolean)
	self.container.Visible = is_visible
end

function View.enableDrag(self : View)
	-- drag view
	local container = self.container
	local topbar = container.TopBar
	topbar.InputBegan:Connect(function(input: InputObject) 
		
		if input.UserInputType == INPUT_TYPE.MouseButton1 then
			topbar.Active = false
			local mouse : PluginMouse = plugin:GetMouse()
			
			local container_offset = container.AbsoluteSize*container.AnchorPoint
			local container_position = container.AbsolutePosition
			
			local offset_x = container_position.X+container_offset.X - mouse.X
			local offset_y = container_position.Y+container_offset.Y - mouse.Y
			
			local move = task.spawn(function(input: InputObject) -- mouse.Move too unreliable, UserInputService mouse stuff unavailable
				while task.wait() do
					
					-- mouse.Button1Up only fires inside the game window
					if not game.UserInputService:IsMouseButtonPressed(INPUT_TYPE.MouseButton1) then
						topbar.Active = true
						return
					end

					container.Position = UDim2.new(
						UDim.new((mouse.X + offset_x) / mouse.ViewSizeX, 0),
						UDim.new((mouse.Y + offset_y) / mouse.ViewSizeY, 0)
					)
				end
			end)
		end	
	end)
end

function View.registerTopBarButtons(
	self : View,
	close : () -> (), 
	more : () -> ()
)	
	
	local content = self.container.TopBar.Content
	self:registerButton(content.Close, close or void)
	self:registerButton(content.More, more or void)
end

function View.registerButton(
	self : View,
	button : TextButton, 
	onInteraction : () -> ()
)
	local view = self
	button.InputBegan:Connect(function(input: InputObject)
		local input_type = input.UserInputType
		if 
			input_type == INPUT_TYPE.MouseButton1 or
			input_type == INPUT_TYPE.Touch 
		then 
			onInteraction(view, input) 
		end
	end)
	
	self[string.lower(button.Name)] = onInteraction
end

function View.open(self : View) end

function View.close(self : View) end
function View.more(self : View) end

function View.registerTextBox(
	self : View, 
	input : TextBox,
	onFocusLost : () -> (),
	onFocusGained : () -> (),
	onTextChanged : () -> (),
	onKey : {[Enum.KeyCode] : (self : View) -> ()}
)
	if onFocusLost   then input.FocusLost:Connect(onFocusLost) end
	if onFocusGained then input.Focused:Connect(onFocusGained) end
	if onTextChanged then input:GetPropertyChangedSignal("Text"):Connect(onTextChanged) end
	
	if onKey then
		local view = self
		InputService.InputBegan:Connect(function(userInput: InputObject, gameProcessedEvent: boolean)
			local key = userInput.KeyCode
			local input_type = userInput.UserInputType
			
			if 
				not view:isVisible() 
				or not input:IsFocused() 
				or input_type ~= INPUT_TYPE.Keyboard
			then return end
			
			(onKey[key] or void)(view)
		end)
	end
end

function View.isVisible(self : View)
	return self.container.Visible
end

return View
