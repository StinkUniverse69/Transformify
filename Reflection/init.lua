export type ClassReflection = { 
	ClassNameWords : {string},
	Superclass : string,
	InstanceProperties : {string},
	Properties : {string},
	Tags : { 
		Deprecated : boolean,
		NotCreatable : boolean,
		NotBrowsable : boolean,
		[string] : boolean, -- and any other tags that may exist
	}
}

local Reflection : {[string] : ClassReflection } = {}

 
local CAPABILITY = {
	None = true,
	PluginSecurity = true,
}

-- if a property has a tag like this, it cannot be read & written to
local INACCESSIBLE_PROPERTY_TAGS = {
	ReadOnly = true,
	NotScriptable = true
}

local VOID = function () end
local MEMBER_TYPE = {
	Property = function (class : ClassReflection, member : ApiMember)
		
		if not (
			(CAPABILITY[member.Security.Read] and CAPABILITY[member.Security.Write]) -- plugins are allowed to read and write this property
		) then return end
		
		if member.Tags then
			for _, tag in ipairs(member.Tags) do
				if INACCESSIBLE_PROPERTY_TAGS[tag] then return end
			end
		end
		
		table.insert(class.Properties, member.Name)
		
		if not (
			(member.ValueType and Reflection[member.ValueType.Name]) and -- sneaky use of Reflection :)
			member.Name ~= "Parent" -- exclude Parent, since we're taking care of that manually
		) then return end
		
		table.insert(class.InstanceProperties, member.Name)
	end,

	Event = VOID,
	Function = VOID,
	Callback = VOID
}


local function getWords( class : string) : {string}
	local words = {}
	local _start = 1;
	while true do
		local i, j, match = string.find(class, "([%u%d]%l+)", _start)
		if not i then 
			if _start < #class then table.insert(words, string.sub(class, _start)) end
			break;
		end

		if i ~= _start then
			table.insert(words, string.sub(class, _start, i-1))
		end

		table.insert(words, match)

		_start = j+1
	end

	return words
end

local function newClassReflection(classname : string)
	return {
		ClassNameWords = getWords(classname),
		Properties = {}, 
		InstanceProperties = {}, 
		Tags = {},
	}
end

-- convert class from API Dump to more efficient and purpose bound ClassReflection
-- needs to be done in a seperate loop, after establishing all ClassReflections
local function fillClassFromApi(class : ClassReflection, api_class : ApiClass) : ClassReflection
	class.Superclass = api_class.Superclass
	
	for _,member in ipairs(api_class.Members) do
		MEMBER_TYPE[member.MemberType](class, member);
	end
	
	if api_class.Tags then
		for i, tag in ipairs(api_class.Tags) do
			class.Tags[tag] = true
		end 
	end
	
	-- adds all properties that can be inherited from superclasses into this class
	local super : ClassReflection? = Reflection[class.Superclass]
	if not super then return class end

	for _, property in pairs(super.Properties) do
		table.insert(class.Properties, property)
	end
	
	for _, property in ipairs(super.InstanceProperties) do
		table.insert(class.InstanceProperties, property)	
	end
end


local Api = require(script.Parent.Reflection.Api)

-- initialize all classes first so they can be accessed
for _, api_class in ipairs(Api) do
	Reflection[api_class.Name] = newClassReflection(api_class.Name)
end

for _, api_class in ipairs(Api) do
	fillClassFromApi(Reflection[api_class.Name], api_class)
end

return table.freeze(Reflection)