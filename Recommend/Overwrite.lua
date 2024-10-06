return {
	global = {
		PartOperation = -1000, -- abstract class 
		WedgePart = 0, -- just use a Part bro
		CornerWedgePart = 0, -- just use a Part bro
		
	},
	byClass = {
		-- impossible to make these connections using classes and properties
		Folder = { 
			Model = 1000, 
			Frame = 999,
		},
		Model = {
			Folder = 1000,
		},
	}
}
