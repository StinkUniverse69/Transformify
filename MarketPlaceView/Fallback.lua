return {
	
	-- not needed unless game.GetObjects is actually removed
	convertAssetIdToMeshId = function (assetId, STATUS)
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
	
}