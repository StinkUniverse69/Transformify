local UUID = 1
local OPERATIONS = {}

local function getDebugId(instance)
	return tonumber(instance:GetDebugId(math.huge))
end

local function compress(t : {Instance})
	local ids = {}
	for i=1,#t do
		local debug_id = tonumber(t[i]:GetDebugId(math.huge))
		table.insert(ids, debug_id)
	end
	return ids
end

local function add(old : {Instance}, new : {Instance}, layout_order : { [Instance] : {Instance}})
	local operation = {
		old = compress(old), 
		new = compress(new),
	}
	
	if layout_order and next(layout_order) then
		
		local layouts = {}
		for parent, dict in layout_order do
			
			-- create order=>instance map and order array 
			local order_to_instance = {}
			local array = {}
			for instance, order in dict do
				order_to_instance[order] = instance
				table.insert(array, order) 
			end
			-- convert order array to ordered debugid array 
			table.sort(array)
			for i, order in ipairs(array) do
				array[i] = getDebugId(order_to_instance[order])
			end
			
			layouts[getDebugId(parent)] = array
		end
		
		operation.layout_order = layouts
	end
	
	OPERATIONS[UUID] = table.freeze(operation)
	UUID+=1
end

local function nextId() return UUID end

local function get(id : number)
	return OPERATIONS[id]
end

return{
	add = add,
	get = get,
	nextId = nextId,
}


