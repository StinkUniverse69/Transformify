export type ExecutionTime = "changeHierarchy" | "replaceInstance" | "editProperties" | "editParent"
local Reflection = require(script.Parent.Reflection)
local ReverseHelper = require(script.ReverseHelper)
local SPECIAL = require(script.SpecialOperations)

local CollectionService = game:GetService("CollectionService")

local special_operations = {
	changeHierarchy = {},
	replaceInstance = {},
	editProperties = {},
	editParent = {},
	error = function (...) print(...); return ... end,
	default = function (...) return ... end 
}

local function getSpecialOperation(
	at : ExecutionTime, 
	from : string, -- classname
	to : string -- classname
) : (instance : Instance, new_instance : Instance) -> (Instance, Instance)
	
	local default = special_operations.default 
	local operations_from = special_operations[at][from] 
	
	return (operations_from and operations_from[to]) or default
end

local function set(t, k1, k2, v)
	t[k1] = t[k1] or {}
	t[k1][k2] = v
end


-- add all special operations from the SpecialOperations modul
for _,operation in ipairs(SPECIAL) do
	if not (special_operations[operation.at] and operation.at ~= "error" and operation.at ~= "default") then
		error(string.format("Special operation %s->%s has unknown execution time at=\"%s\"", operation.from, operation.to, operation.at))
	end
	set(
		special_operations[operation.at or "replaceInstance"], 
		operation.from, 
		operation.to, 
		operation.run() -- returns a function
	)
end

local function convert_property(property, instance, new_instance) new_instance[property] = instance[property] end
local function convert(instance : Instance, to_class: string) : (Instance, Instance)
	local from_class = instance.ClassName
	local new_instance = Instance.new(to_class)
	
	-- do something before the conversion starts	
	do
		local replaceInstance = getSpecialOperation("replaceInstance", from_class, to_class) -- special operations are the most likely part to fail, so they must be protected
		local success, old, new = xpcall(replaceInstance, warn, instance, new_instance)
		if success then instance, new_instance = old, new end 
	end
	
	new_instance.Name = instance.Name
	
	-- set properties that exist in new instance
	for _, property in ipairs(Reflection[from_class].Properties) do 
		pcall(convert_property, property, instance, new_instance)
	end
	
	-- add back children explicitly
	for _,child in ipairs(instance:GetChildren()) do
		child.Parent = new_instance
	end
	
	-- add back tags
	for _,tag in ipairs(instance:GetTags()) do
		new_instance:AddTag(tag)
	end
	
	-- add back attributes
	for name,value in pairs(instance:GetAttributes()) do
		new_instance:SetAttribute(name, value)
	end
	
	-- do something after most of the conversion has ended
	do
		local editProperties = getSpecialOperation("editProperties", from_class, to_class)
		local success, old, new = xpcall(editProperties, warn, instance, new_instance)
		if success then instance, new_instance = old, new end 
	end
	return instance, new_instance
end

local function get_property(instance, property) return instance[property] end
local function setParent(instance, parent) instance.Parent = parent end
return {
	run = function (instances : {Instance}, to_class : string)
		
		-- do something before the conversion has started
		-- the new instance is not defined yet and no returns are accepted, meaning these functions are more limited
		-- however this can be used to efficently delete children
		for i=1,#instances do
			local old = instances[i]
			local changeHierarchy = getSpecialOperation("changeHierarchy", old.ClassName, to_class)
			xpcall(changeHierarchy, warn, old)
		end
		
		local new_instances = {}
		local parents = {}
		
		-- reverse map all input instances, so they can be indexed
		local interest = {}
		for _, object in ipairs(instances) do interest[object] = {} end
		
		-- check all game instances, if they have properties with Instance values
		-- if so, add them as interested
		for _, service in ipairs(game:GetChildren()) do
			if service == game.StreamingService then continue end
			for _, object in ipairs(service:GetDescendants()) do
				local class = Reflection[object.ClassName]
				if not class then continue end -- probably some service

				for _, property in ipairs(class.InstanceProperties) do -- there are usually 0 or 1 rarely more
					local success, instance_property = xpcall(get_property, warn, object, property)
					if not success then continue end

					local interested_list = interest[instance_property]
					if interested_list then table.insert(interested_list, {instance = object, property = property}) end
				end
			end
		end
		
		
		-- collect all parents and their order of children
		for _, instance in ipairs(instances) do
			if Reflection[instance.ClassName].Tags.NotCreatable then continue end
			
			local parent = instance.Parent
			parents[parent] = parent:GetChildren() 
		end
		
		-- try converting
		local function update_property(instance, property, value)
			instance[property] = value
		end
		
		
		for _, instance in ipairs(instances) do
			if Reflection[instance.ClassName].Tags.NotCreatable then continue end
			
			local success, old, new = pcall(convert, instance, to_class) 
			if not success then warn(old); continue; end -- on faiure: pcall arg #2 is error message			
			
			-- update all interested instances
			for _, interested in ipairs(interest[old]) do
				update_property(
					interested.instance, 
					interested.property, 
					new
				)
			end
			
			-- in case the instance was a parent
			parents[new], parents[old] = parents[old], nil

			-- find old instance in it's parents saved children and update it (for later use)
			local i = table.find(parents[old.Parent], old)
			parents[old.Parent][i] = new
			table.insert(new_instances, new)
			
			old.Parent = nil -- must not be destroyed for the history service to work properly
			
		end
		
		-- restore order of children
		local keeper = Instance.new("Folder") --required to make ChangeHistoryService work
		keeper.Parent = workspace
		
		for parent, children in pairs(parents) do
			for _, child in ipairs(children) do
				pcall(setParent, child, keeper)
			end
			
			for _, child in ipairs(children) do
				pcall(setParent, child, parent)
			end
		end
		
		-- do something after the conversion has ended
		-- no returns will be accepted, meaning these functions are more limited
		for i=1,#instances do
			local old = instances[i]
			local new = new_instances[i]
				 
			xpcall(
				getSpecialOperation("editParent", old.ClassName, new.ClassName), warn,
				old, new
			)
		end
		
		ReverseHelper.add(instances, new_instances)
		
		setParent(keeper, nil)
		
		return new_instances
	end,
}