local function getClassIcon(classname : string, theme : "light" | "dark")
	local icon_info; 
	xpcall(function(...) 
		icon_info = game.StudioService:GetClassIcon(classname)
	end, function(a0) 
		icon_info = game.StudioService:GetClassIcon("Instance")
	end)
	if theme == "light" then
		return icon_info.Image:gsub("/Dark/", "/Light/")
	else
		return icon_info.Image:gsub("/Light/", "/Dark/")
	end
end

return getClassIcon
