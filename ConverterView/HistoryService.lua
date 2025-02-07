local ChangeHistoryService = game:GetService("ChangeHistoryService")

local HISTORY_IDENTIFIER = "TransformifyHistoryEvent"

local PLUGIN_NAME = script.Parent.Parent.Name
local SERVICE_ENABLED = game:GetService("RunService"):IsEdit()
local FINISH_METHOD = Enum.FinishRecordingOperation
local RECORDING

local ReverseHelper = require(script.Parent.Parent.Convert.ReverseHelper)

local function onHistoryEvent(waypoint : string, eventType : "undo" | "redo") 

	local reverse_helper_id = tonumber(waypoint:match(string.format("^%s:(.*)$", HISTORY_IDENTIFIER)))
	if not reverse_helper_id then return end
	
	local content = ReverseHelper.get(reverse_helper_id)

	-- create reverse lookup table for debug ids we are looking for
	local isPartOfSet = {}
	for _, id in ipairs(content[eventType == "undo" and "old" or "new"]) do
		isPartOfSet[tostring(id)] = true
	end

	-- check all instances, unfortunatly this can't be avoided easily
	local set = {}
	for _, descendant in ipairs(game:GetDescendants()) do
		if not isPartOfSet[descendant:GetDebugId(math.huge)] then continue end
		table.insert(set, descendant)
	end
	
	--- TODO : correct layout order

	game.Selection:Set(set)
end

local function onHistoryEventFailure(msg : string)
	warn(msg)
	game.Selection:Set({})
end

-- correctly set the selection to the instances before the conversion
-- since ChangeHistoryService is unable to
ChangeHistoryService.OnUndo:Connect(function(waypoint: string)
	xpcall(onHistoryEvent, onHistoryEventFailure, waypoint, "undo")
end)

ChangeHistoryService.OnRedo:Connect(function(waypoint: string) 
	xpcall(onHistoryEvent, onHistoryEventFailure, waypoint, "redo")
end)


return {
	
	-- when ChangeHistoryService is enabled
	-- returns whether or not it is safe to start conversion
	start = function () 
		if not SERVICE_ENABLED then return true end
		
		local reverse_helper_id = ReverseHelper.nextId()
		
		HISTORY_RECORDING = ChangeHistoryService:TryBeginRecording( 
			string.format("%s:%s", HISTORY_IDENTIFIER, reverse_helper_id),
			string.format("%s: Convert selected instances", PLUGIN_NAME)
		)

		if not HISTORY_RECORDING then 
			warn(PLUGIN_NAME .. ": Couldn't start recording history changes. Aborting conversion. Try updating the plugin and/or restarting studio."); 
			script.Parent.ConversionFinishedEvent:Fire()
			return false 
		end
		
		return true
	end,
	
	finish = function (conversion_success)
		if HISTORY_RECORDING then
			ChangeHistoryService:FinishRecording(
				HISTORY_RECORDING, 
				if conversion_success then FINISH_METHOD.Commit else FINISH_METHOD.Cancel
			)
			HISTORY_RECORDING = nil
		end
	end,
	
}
