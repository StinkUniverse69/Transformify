local SearchTree = require(script.Parent.Recommend.SearchTree)

local SEARCHTREE : SearchTree.Branch;
local NAME_TO_CLASS : {[string] : SearchTree.Class} = {}

do -- prevent local bleed into module functions
	
	local Reflection = require(script.Parent.Reflection)
	
	-- for convienience
	-- iterator like pairs but uses NAME_TO_CLASS to map the classname string diectly to a SearchTree.Class
	local function mapped(t : {any})
		local classname, v;

		local function _next(t : {any})
			local _mapped;
			repeat 
				classname, v = next(t, classname)
				_mapped = NAME_TO_CLASS[classname] 
			until not classname or _mapped
			return _mapped, v
		end	

		return _next, t, nil
	end	
	
	-- create reverse map for all classes as classname to SearchTree.Class
	local classes = {}
	for classname, class in pairs(Reflection) do
		if class.Tags.NotBrowsable or class.Tags.NotCreatable then continue end -- don't show these as options
		
		local searchTreeClass = SearchTree.newClass(classname)
		NAME_TO_CLASS[classname] = searchTreeClass
		table.insert(classes, searchTreeClass)
	end
	
	-- collect all properties in reverse map
	local properties = {}
	for classname, class in pairs(Reflection) do
		properties[classname] = {}
		for _, property in ipairs(class.Properties) do
			properties[classname][property] = true
		end
	end
	
	
	-- set weights for search
	for classNameA, classA in pairs(NAME_TO_CLASS) do
		for classNameB, classB in pairs(NAME_TO_CLASS) do
			if classNameA == classNameB then continue end
			
			local reflectionA : Reflection.ClassReflection = Reflection[classNameA]
			local reflectionB : Reflection.ClassReflection = Reflection[classNameB]
			
			-- anything that is Deprecated doesn't need to be checked any further
			if reflectionB.Tags.Deprecated then 
				classA.Similar[ classB ] = -100; 
				continue
			end
			
			-- ranking score, the higher the better match
			local score = 0;
			
			score += reflectionA.Superclass == reflectionB.Superclass and 10 or 0
			score += reflectionA.Superclass == classNameB and 20 or 0
			
			-- check how many words in the class name exist in the other class' name as well
			-- the words are split before by the Reflection modul
			for _, word in ipairs(reflectionA.ClassNameWords) do
				if not string.find(classNameB, word) then continue end
				score += 10
			end
			
			-- use existing/missing properties to determine how different a class is
			local propertiesA = properties[classNameA]
			local propertiesB = properties[classNameB]
			
			-- add points for properties that the both classes have
			for property, _ in pairs(propertiesB) do
				score += propertiesA[property] and 1 or 0
			end
			-- remove poins for properties only the second class has
			for property, _ in pairs(propertiesA) do
				score -= propertiesB[property] and 0 or 1
			end

			classA.Similar[ classB ] = math.floor(score)
		end

		-- recommend converting into same instance type last 
		classA.Similar[ classA ] = -math.huge
	end
	
	local SpecialOperations = require(script.Parent.Convert.SpecialOperations)
	local Overwrite = require(script.Parent.Recommend.Overwrite)
	
	-- add all defined special operations as top results
	for _, operation in ipairs(SpecialOperations) do
		local from = NAME_TO_CLASS[operation.from]
		local to = NAME_TO_CLASS[operation.to]
		from.Similar[ to ] = math.min(from.Similar[ to ], 100) 
	end
	
	-- global overwrites
	for classB, weight in mapped(Overwrite.global) do
		for _, classA in pairs(NAME_TO_CLASS) do
			classA.Similar[ classB ] = math.floor(tonumber(weight))
		end
	end
	-- overwrites by class
	for classA, weights in mapped(Overwrite.byClass) do
		for classB, weight in mapped(weights) do
			classA.Similar[ classB ] = math.floor(tonumber(weight))
		end
	end

	 
	SEARCHTREE = table.freeze( SearchTree.new(classes) )
end

-- placeholder to avoid returning nil 
local empty_class = table.freeze({ ClassName = ""})

-- the modul table
local Recommend = {
	index = 1,
	options = { empty_class }
}

function Recommend.update( text : string , selection : {Instance} )

	if #selection < 1 then Recommend.options = empty_class; return; end

	-- find first instance in selection that is creatable
	local class;
	for i=1,#selection do
		class = NAME_TO_CLASS[ selection[i].ClassName ]
		if class then break end
	end
	if not class then Recommend.options = empty_class; return; end

	-- find relevant classes from input string
	local branch = SearchTree.find(SEARCHTREE, text)
	
	-- order options so that best match is displayed first (based on class similarity)
	table.sort( 
		branch.options, 
		function(a: SearchTree.Class, b: SearchTree.Class): boolean
			local score_a = (class.Similar[a] or -math.huge)
			local score_b = (class.Similar[b] or -math.huge)
			return (score_a == score_b and #a.ClassName < #b.ClassName) or score_a > score_b 
		end
	)
	
	-- will print the scores for all recommendations when an instance is selected
	--[=[  change to ---[=[ to enable
	local helper = {}
	for c, score in pairs(class.Similar) do
		table.insert(helper, c.ClassName)
	end 
	table.sort( 
		helper, 
		function(a: string, b: string): boolean
			local score_a = (class.Similar[NAME_TO_CLASS[a]] or -math.huge)
			local score_b = (class.Similar[NAME_TO_CLASS[b]] or -math.huge)
			return (score_a == score_b and #a < #b) or score_a > score_b 
		end
	)
	
	for _, name in ipairs(helper) do
		print(class.ClassName, ":", name, class.Similar[NAME_TO_CLASS[name]])
	end
	--]=]
	
	-- set the recommendations
	Recommend.options = branch.options
end	

-- get the current recommendation at Recommend.index, which can be set directly or 
-- changed relatively with Recommend.changeIndex
function Recommend.get() : SearchTree.Options
	return (Recommend.options[Recommend.index] or empty_class).ClassName
end

-- changes the Recommend.index by the amount i
function Recommend.changeIndex( i : number )
	Recommend.index = math.clamp(
		Recommend.index + (i or 0), 
		1, 
		math.max(1, #Recommend.options)
	)
end

return Recommend