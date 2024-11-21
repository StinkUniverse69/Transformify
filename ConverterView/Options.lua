local Options = {}

local POOL; -- high frequency reuse of GuiButtons so we use dynamic pool

local CONTENT : typeof(script.Parent.Parent.Main.ScreenGui.ConverterPrompt.Content)

local OPTIONS : typeof(CONTENT.Options.ScrollingFrame), OPTIONS_MORE : typeof(CONTENT.Options.MoreDown);
local getClassIcon = require(script.Parent.getClassIcon)

local SELECTED, DEFAULT = script.Selected, script.Default

local MAP_BY_INDEX : {[number] : typeof(DEFAULT)} = {}

local SELECTED_INDEX = 1;


function Options.fromParent(GuiElement : GuiBase2d)
	OPTIONS = GuiElement.Options.ScrollingFrame
	OPTIONS_MORE = GuiElement.Options.MoreDown
end

function Options.onButtonClick(connection : (button : GuiButton) -> ())
	local function newOption()
		local button = DEFAULT:Clone()
		button.MouseButton1Click:Connect(function() connection(button) end)
		return button
	end
	
	POOL = {
		pop = function ()
			local button = table.remove(POOL) or newOption()
			button.Visible = true
			return button
		end,
		
		push = function(button : GuiButton)
			button.Visible = false
			table.insert(POOL, button)
		end
	}
end

-- remove all options from their container
local canvas_tween : Tween;
function Options.empty()
	if canvas_tween then canvas_tween:Cancel() end
	for _, child in OPTIONS:GetChildren() do
		if not child:IsA("GuiButton") then continue end
		POOL.push(child)
	end
	table.clear(MAP_BY_INDEX)
end

function Options.fill(recommendations)
	-- add new options
	for i, option in ipairs(recommendations) do
		local className = option.ClassName
		local option_button = POOL.pop()
		option_button.Label.Text = className
		option_button.Icon.Image = getClassIcon(className, "dark")
		option_button.LayoutOrder = i
		option_button.Parent = OPTIONS
		
		-- insert button for fast access by option index
		MAP_BY_INDEX[i] = option_button
	end
end


function Options.select(index)
	if #MAP_BY_INDEX < 1 then end
	
	if SELECTED_INDEX ~= index then
		local prev_option = MAP_BY_INDEX[SELECTED_INDEX]
		prev_option.BackgroundColor3 = DEFAULT.BackgroundColor3
		prev_option.UIStroke.Color = DEFAULT.UIStroke.Color
	end
	
	SELECTED_INDEX = index
	
	local option : typeof(DEFAULT) = MAP_BY_INDEX[SELECTED_INDEX]
	option.BackgroundColor3 = SELECTED.BackgroundColor3
	option.UIStroke.Color = SELECTED.UIStroke.Color
	
	if canvas_tween then canvas_tween:Cancel() end
	canvas_tween = game.TweenService:Create(
		OPTIONS, 
		TweenInfo.new(0.25), 
		{CanvasPosition = OPTIONS.CanvasPosition + option.AbsolutePosition - OPTIONS.AbsolutePosition}
	)
	canvas_tween:Play()
end

function Options.adjustOnResize(gui : ScreenGui)
	local changeSize : BindableEvent = OPTIONS.changeSize
	
	local function requestChangeSize() changeSize:Fire() end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(requestChangeSize)
	OPTIONS:GetPropertyChangedSignal("AbsolutePosition"):Connect(requestChangeSize)
	
	local function debounce()
		xpcall(function() 
			local screen_size = gui.AbsoluteSize

			local available_height = screen_size.Y - OPTIONS.AbsolutePosition.Y - OPTIONS_MORE.AbsoluteSize.Y + gui.AbsolutePosition.Y
			local size = OPTIONS.Size

			local button_height = DEFAULT.AbsoluteSize.Y + OPTIONS.UIListLayout.Padding.Offset
			local bottom_offset = button_height
			local limit = 10
			local usable_height = math.min( math.floor(available_height/button_height), limit) * button_height - bottom_offset

			OPTIONS.Size = UDim2.new(size.X, UDim.new(0, usable_height))
		end, warn)
		
		changeSize.Event:Once(debounce)
	end
	debounce()
end

return Options