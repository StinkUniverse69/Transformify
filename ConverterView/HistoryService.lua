local ChangeHistoryService = game:GetService("ChangeHistoryService")

local PLUGIN_NAME = script.Parent.Parent.Name
local SERVICE_ENABLED = game:GetService("RunService"):IsEdit()
local FINISH_METHOD = Enum.FinishRecordingOperation
local RECORDING

return {
	
	-- when ChangeHistoryService is enabled
	-- returns whether or not it is safe to start conversion
	start = function () 
		if not SERVICE_ENABLED then return true end
		
		HISTORY_RECORDING = ChangeHistoryService:TryBeginRecording("Convert selected instances")

		if not HISTORY_RECORDING then 
			warn(PLUGIN_NAME .. ": Couldn't start recording history changes. Aborting conversion. Try updating the plugin and/or restarting studio."); 
			script.ConversionFinishedEvent:Fire()
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
