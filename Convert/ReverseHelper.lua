local COUNTER = 1
local OPERATIONS = {}

local function compress_light(t : {Instance})
	local c = {}
	for i=1,#t do
		table.insert(c, tonumber(t[i]:GetDebugId(math.huge)))
	end
	return c
end

local function add(old : {Instance}, new : {Instance})
	OPERATIONS[COUNTER] = {
		old = compress_light(old), 
		new = compress_light(new)
	}
	COUNTER+=1
end

local function nextId()
	return COUNTER
end

local function get(id : number)
	return OPERATIONS[id]
end

return{
	add = add,
	get = get,
	nextId = nextId,
}


