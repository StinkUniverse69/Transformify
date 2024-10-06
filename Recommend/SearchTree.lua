export type Class = { 
	ClassName : string, 
	ClassNameWords : {string},
	Similar : {[Class] : number} 
}
export type Options = {Class}
export type Chars = {[number] : Branch}

export type Branch = {
	options : Options,
	chars : Chars
}

local getNormalizedCharIndex;
local getLowerCodepoint;
do
	local to_lower = {}
	for _, codepoint in utf8.codes("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz") do
		to_lower[codepoint] = utf8.codepoint(utf8.char(codepoint):lower())
	end
	
	-- get the utf8 code of a letters lower form where the letter itself is also represented by a utf8 code @codepoint
	getLowerCodepoint = function (codepoint : number)
		return to_lower[codepoint] or codepoint
	end
	
	-- get lower versions utf8 code of the letter at index @i in @text 
	getNormalizedCharIndex = function (text : string, i : number)
		return getLowerCodepoint(utf8.codepoint(text, i))
	end	

end

return {
	
	-- new empty SearchTree.Class
	newClass = function (classname) : Class 
		return { 
			ClassName = classname,
			Similar = {} 
		}  
	end,
	
	-- a SearchTree based on the 
	new = (function ()
		local function byLength(a0, a1) return #a0 < #a1 end -- sort condition
		
		-- returns a new SearchTree.Branch with new SearchTree.Options' for 
		-- every distinct letter at @letter_index in the elements of @options
		local function fill( options : Options , letter_index : number) : Branch	
			local newBranch : Branch = {options = options, chars = {}}
			table.sort(newBranch.options, byLength)

			if #options <= 1 or letter_index >= 30 then return newBranch end

			for j,classpointer in ipairs(options) do
				if #classpointer.ClassName < letter_index then continue end

				local chars = newBranch.chars
				local charcode = getNormalizedCharIndex(classpointer.ClassName, letter_index)
				if not chars[charcode] then 
					chars[charcode] = {classpointer}
				else 
					table.insert(chars[charcode], classpointer) 
				end 
			end
			return newBranch
		end
		
		-- recursion to build a tree with fill()
		local function recursion(parent : Options, i) : Branch	
			local branches = fill(parent, i) 
			for charcode, classes in pairs(branches.chars) do
				branches.chars[charcode] = recursion(classes, i+1)
			end	
			return branches
		end

		return function (availableClasses : Options) return recursion(availableClasses, 1) end
	end)(),


	-- find classes that begin with @text
	find = function (tree : Branch, text : string)
		for _, codepoint in utf8.codes(text) do
			local normalized_codepoint = getLowerCodepoint(codepoint)
			local new_tree = tree.chars[ normalized_codepoint ] 
			if new_tree then tree = new_tree else break end
		end
		return tree
	end,
	
}