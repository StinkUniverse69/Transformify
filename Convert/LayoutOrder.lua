
-- load a table of properties and save the overwritten values
local function load(from, to) for property, value in pairs(from) do to[property], from[property] = from[property], to[property] end end

-- load a table of properties
local function restore(from, to) for property, value in pairs(from) do to[property] = from[property]  end end


local function asHorizontalList(parent)
	local LayoutOrder = {}
	local children = parent:GetChildren()
	for _, child : GuiObject in ipairs(children) do
		if not child:IsA("GuiObject") then continue end
		LayoutOrder[child] = child.AbsolutePosition.X
	end

	for _, child : GuiObject in ipairs(children) do
		if not child:IsA("GuiObject") then continue end
		child.LayoutOrder, LayoutOrder[child] = LayoutOrder[child], child.LayoutOrder
	end
	return LayoutOrder
end

local Layout = {
	UIListLayout = function (self : UIListLayout)

		local properties = {
			Wraps = false,
			FillDirection = Enum.FillDirection.Horizontal
		}

		load(properties, self)

		local LayoutOrder = asHorizontalList(self.Parent)

		restore(properties, self)

		return LayoutOrder
	end,

	UIPageLayout = function (self)
		return asHorizontalList(self.Parent)
	end,

	UIGridLayout = function (self : UIGridLayout)

		local properties = {
			CellPadding = UDim2.new(0,0,0,0),
			CellSize = UDim2.new(0,1,0,1),
			FillDirection = Enum.FillDirection.Vertical,
			FillDirectionMaxCells = 1,
			StartCorner = Enum.StartCorner.TopLeft,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		}

		load(properties, self)

		local LayoutOrder = asHorizontalList(self.Parent)

		restore(properties, self)

		return LayoutOrder
	end,	
}

return {
	UILayout = Layout,
	update = function (LayoutOrder, old, new)
		LayoutOrder[new], LayoutOrder[old] = LayoutOrder[old], nil  
	end,
	restoreLayoutOrder = function (LayoutOrder, parent : Instance)
		local children = parent:GetChildren()
		table.sort(
			children, 
			function(a0: Instance, a1: Instance): boolean 
				return a0:IsA("GuiObject") and a1:IsA("GuiObject") and a0.LayoutOrder < a1.LayoutOrder 
			end
		)
		for _, child : GuiBase in ipairs(children) do
			if not child:IsA("GuiBase") then continue end
			child.LayoutOrder = LayoutOrder[child]
		end
	end
}
