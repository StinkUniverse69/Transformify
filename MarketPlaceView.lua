local InsertService = game:GetService("InsertService")

local this = script.Parent
local plugin = this.Main.GetPluginManager:Invoke()

local PLUGIN_NAME = this.Name
local GUI : typeof(script.Parent.Main.ScreenGui) = game.CoreGui[PLUGIN_NAME]

local View = require(this.View)

local MarketPlacePrompt = View.new(GUI.MarketPlacePrompt)

local CONTENT = GUI.MarketPlacePrompt.Content
local TEXTBOX_FRAME = CONTENT.TextArea.TextBoxOuter.TextBoxInner

local PREVIEW = CONTENT.TextArea.Preview
local INPUT  = TEXTBOX_FRAME.Text.Input
local PLACEHOLDER  = TEXTBOX_FRAME.Text.Recommendation
local SUMBIT = TEXTBOX_FRAME.Submit

local ITEMS = CONTENT.DisplayArea.Items
local STATUS = CONTENT.DisplayArea.Status

local MESH_ID_SELECTED_EVENT = script.MeshIdSelectedEvent

local function convertAssetIdToMeshId(assetId)
	-- asset id
	-- try loading the asset
	local binary_asset_data; 
	local success = xpcall(function(...)
		local url = string.format("https://assetdelivery.roproxy.com/v1/asset?id=%d", assetId)
		binary_asset_data = game.HttpService:GetAsync(url)	
	end, warn)

	if binary_asset_data then -- exists if is valid mesh or asset

		-- if json has been found, an error occured when requesting the asset data
		-- example : Request asset was not found
		if pcall(function(...) 
				local json = game.HttpService:JSONDecode()
				STATUS.Text = 
					tostring(
						(json.errors and json.errors[0] and json.errors[0].message) 
						or "Asset couldn't be loaded."
					)
				warn(STATUS.Text)
			end) then return end

		local _, meshIdOccurance = binary_asset_data:find("MeshId", 0, true)
		if not meshIdOccurance then 
			STATUS.Text = "Couldn't find MeshId in asset data"; 
			warn(STATUS.Text);
			return 
		end

		local meshid = binary_asset_data:match("rbx.-%d+", meshIdOccurance)
		if not meshid then
			STATUS.Text = ""
			return
		end

		return meshid

	else
		STATUS.Text = "Error when requesting asset data"
		warn(STATUS.Text)
	end
end

local function resetUiButtons()
	for _, item in ITEMS:GetChildren() do
		if not item:IsA("TextButton") then continue end
		item:Destroy()
	end
end

local function updateUiButtons(next_page_cursor)
	STATUS.Text = "Loading ..."
	
	local url = string.format(
		"https://inventory.roproxy.com/v2/users/%d/inventory/40?limit=100&sortOrder=Desc&cursor=",
		game.StudioService:GetUserId(),
		next_page_cursor or ""
	)
	local HttpService = game:GetService("HttpService")
	local response;
	if not 
		xpcall(function() 
			response = HttpService:GetAsync(url)	
		end, warn) 
	then 
		STATUS.Text = "Failed to make web api request."
		return 
	end
	
	local json; 
	xpcall(function(...) 
		json = HttpService:JSONDecode(response)
	end, warn)
	if not json then STATUS.Text = "Error decoding api response." end
	
	if not json.errors then	

		-- insert new items
		if not json.data then STATUS.Text = "Malformed response did not include data field."; return end
		for _, item in json.data do
			local assetId, name = item.assetId, item.assetName
			local ui_item = script.Item:Clone()

			ui_item.Icon.Image = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", assetId)
			ui_item.Label.Text = name

			ui_item.Parent = ITEMS
			ui_item.InputBegan:Connect(function(input: InputObject)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				
				local meshid = convertAssetIdToMeshId(assetId)
				if not meshid then 
					ui_item.Transparency = 0.5
					return
				end
				
				MESH_ID_SELECTED_EVENT:Fire(meshid)
				MarketPlacePrompt:close()
			end)
			
		end 
		
		STATUS.Text = ""
	else
		if type(json.errors) ~= "table" then json.errors = {} end
		STATUS.Text = string.format("Response Error: %s", json.errors[0] or "Unknown error")
	end
	
	return true
end

-- only open the market view once per conversion
local CACHED_MESH_ID;
this.ConverterView.ConversionFinishedEvent.Event:Connect(function() 
	CACHED_MESH_ID = nil
end)

MarketPlacePrompt.open = function (self)
	if CACHED_MESH_ID ~= nil then return CACHED_MESH_ID end
	
	INPUT:CaptureFocus()
	self:visible(true)
	
	resetUiButtons()
	if not updateUiButtons() then return end
	CACHED_MESH_ID = MESH_ID_SELECTED_EVENT.Event:Wait()
	
	return CACHED_MESH_ID 
end

MarketPlacePrompt:registerTopBarButtons(
	function (self) -- close
		INPUT:ReleaseFocus()
		self:visible(false)
		MESH_ID_SELECTED_EVENT:Fire(false)
	end,

	function () -- more 
		-- TODO
	end

)

MarketPlacePrompt:registerButton(TEXTBOX_FRAME.Submit, function (self)
	 
	local assetId = tonumber(INPUT.Text:match("%d+"))
	local meshid;
	
	local assetType;
	xpcall(function(...) 
		local info = game.MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
		assetType = info.AssetTypeId
	end, warn)
	
	if assetType == Enum.AssetType.Mesh.Value then
		meshid = INPUT.Text
	elseif assetType == Enum.AssetType.MeshPart.Value then
		meshid = convertAssetIdToMeshId(assetId)
	else
		STATUS.Text = string.format("AssetType %s not supported", Enum.AssetType:FromValue(assetType))
	end
	
	if not meshid then return end
	
	MESH_ID_SELECTED_EVENT:Fire(meshid)
	MarketPlacePrompt:close()
	
end)

MarketPlacePrompt:registerTextBox(INPUT,
	function (enterPressed: boolean)
		if enterPressed then MarketPlacePrompt:submit() end
	end,
	nil,
	function ()
		local text = INPUT.Text
		
		local id = text:match("%d+")
		
		if not text:match("^rbxassetid://%d+$") then
			INPUT.Text = string.format("rbxassetid://%s", id or "")
			INPUT.CursorPosition = INPUT.Text:len()+1
		end
		
		PREVIEW.Image = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", id or "0") 
	end
)

return MarketPlacePrompt
