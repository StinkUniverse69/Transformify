local UNIFIED_SHAPE = {
	-- mesh ids are added as keys later
	Sphere 							= 0,
	[Enum.PartType.Ball]			= 0,
	[Enum.MeshType.Sphere]			= 0,

	Block							= 1,
	[Enum.PartType.Block]			= 1,
	[Enum.MeshType.Torso]			= 1,
	[Enum.MeshType.Brick]			= 1, -- this will be set as reverse

	Cylinder 						= 2,
	[Enum.PartType.Cylinder]		= 2,
	[Enum.MeshType.Cylinder]		= 2,

	Wedge 							= 3,
	[Enum.PartType.Wedge]			= 3,
	[Enum.MeshType.Wedge]			= 3,

	CornerWedge 					= 4,
	[Enum.PartType.CornerWedge]		= 4,
	[Enum.MeshType.CornerWedge]		= 4,

	Head							= 5,
	[Enum.MeshType.Head]			= 5,
}

-- reverse to UNIFIED_SHAPE
local UNIFIED_ID : {
	Name : string,
	PartType : Enum.PartType,
	MeshType : Enum.MeshType,
} = {
	-- automatically generated
}

local MESH_ID = {}
for unified, meshid in {
	[UNIFIED_SHAPE.Sphere]		= 6914995538,
	[UNIFIED_SHAPE.Block]		= 15636311856,
	[UNIFIED_SHAPE.Cylinder]	= 118955107419920,
	[UNIFIED_SHAPE.Wedge]		= 4729450112,
	[UNIFIED_SHAPE.CornerWedge]	= 76890435647894,
	[UNIFIED_SHAPE.Head] 		= 14448893416,
} do
	MESH_ID[unified] = string.format("rbxassetid://%d", meshid)
	UNIFIED_SHAPE[meshid] = unified
	UNIFIED_ID[unified] = UNIFIED_ID[unified] or {}
end

-- generate UNIFIED_ID
for key : EnumItem | string, unified in UNIFIED_SHAPE do
	local _type = typeof(key)
	if _type == "EnumItem" then
		UNIFIED_ID[unified][tostring(key.EnumType)] = key

	elseif _type == "string" then
		UNIFIED_ID[unified].Name = key
		
	elseif _type == "number" then
		UNIFIED_ID[unified].MeshId = key

	else
		warn(string.format('Unknown UNIFIED_SHAPE key type "%s", skipped', tostring(key)))
	end
end


return {
	Id 		= UNIFIED_ID,
	Shape 	= UNIFIED_SHAPE,
	MeshId 	= MESH_ID,
}
