export type Member = {
	Category : string,
	MemberType : string,
	Name : string,
	Security : {
		Read : string,
		Write : string,
	},
	Serilization : {
		CanLoad : string,
		CanSave : string,
	},
	ThreadSafety : string,
	ValueType : {
		Category : string,
		Name : string,
	}
}

export type Class = {
	Members : {[number] : Member},
	Name : string,
	MemoryCategory : string,
	Superclass : string,
	Tags : { [number] : string }
}


local httpService = game:GetService("HttpService")
local _, dump : string = xpcall(
	function(...)
		return httpService:RequestAsync(
			{
				Url = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json",
				Method = "GET",
			}
		).Body;
	end, 
	function(error_message : string)
		local Dump = script.Parent.Api.Dump
		warn(error_message)
		warn(string.format(
			"Loading class reflection dump from Roblox Client Tracker failed, using built-in version %s (last updated: %s).", 			
			Dump:GetAttribute("Version"),
			Dump:GetAttribute("LastModified")
		))
		return require(Dump)	
	end
)

local api : {[number] : Class} = table.freeze(httpService:JSONDecode(dump).Classes)

return api
