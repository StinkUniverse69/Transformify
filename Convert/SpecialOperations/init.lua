local Reflection = require(script.Parent.Parent.Reflection)
local InsertService = game:GetService("InsertService")

local UnifiedType = require(script.UnifiedType)

-- add an attribute that can be read and removed by another special operation step afterwards
local function pushProperty(new_instance : Instance, property_name, property_value)
	new_instance:SetAttribute(string.format("__Transformify_%s", property_name), property_value)
end

-- read and removed an attribute that was added by another special operation step before
local function popProperty(new_instance : Instance, property_name)
	local attribute_name = string.format("__Transformify_%s", property_name)
	local property_value = new_instance:GetAttribute(attribute_name)
	
	new_instance:SetAttribute(attribute_name) --reset in case sth was there
	return property_value 
end

-- use normal ids to figure out the size of a face of a block
local face_to_2dSize = {
	[Enum.NormalId.Top] = function (size : Vector3) return size.X, size.Z end,
	[Enum.NormalId.Bottom] = function (size : Vector3) return size.X, size.Z end,
	[Enum.NormalId.Back] = function (size : Vector3) return size.X, size.Y end,
	[Enum.NormalId.Front] = function (size : Vector3) return size.X, size.Y end,
	[Enum.NormalId.Left] = function (size : Vector3) return size.Z, size.Y end,
	[Enum.NormalId.Right] = function (size : Vector3) return size.Z, size.Y end,
}

--[[
	from : Class name of the instance that you're converting
	to   : Class name you want to convert it to
	at
		- changeHierarchy : before the hierarchy (parents/children) has been processed. No returns accepted. No new instance.
		- replaceInstance  : before any properties have been set.
		- editProperties : After properties have been set, but changeHierarchy parent is set.
		- editParent  : After parent has been set. No returns accepted.
	
	run : 
	A function that allows you to control the conversion process. 
	
	"run" gets executed when the plugin loads all it's data, so you can save 
	local variables your conversion needs in a close scope, instead of in 
	the file itself.
	
	It returns a function that can access and change the to-be-converted (@instance) 
	and the to-be-returned (@new_instance) instance.
	
	Returns of this function are used to replace the internally used instances,
	meaning you can return a completly different instance and the script will
	continue working with that.
	
	However be aware of when "at" you let your operation execute. Replacing 
	an instance at editParent isn't prossible and at editProperties will discard all 
	automatically transfered properties.
	
	Class hierarchy will be ignored for the execution of these operations. I.e. an 
	operation set for BasePart will not execute for Part or MeshPart.
]]
export type Operation = {
	from : string,
	to : string,
	at :   "changeHierarchy"| "replaceInstance" | "editProperties" | "editParent",
	run : () -> ( (instance: Instance, new_instance: Instance) -> (Instance, Instance) )
}

local SpecialOperations : {Operation}  = {
	
	-------------------------------------------------------------------------------
	
	-- note: for some reason special mesh "Head" turns into a cylinder when it gets to long, I'm not gonna account for that tho cause that doesn't feel like it should be the intended outcome
	{
		from="Part",to="MeshPart",at="replaceInstance",
		run = function ()
			return function (instance : Part, new_instance : MeshPart)
				local special_mesh = instance:FindFirstChildWhichIsA("SpecialMesh")
				
				local unified_id, mesh_id
				if special_mesh then
					unified_id = UnifiedType.Shape[special_mesh.MeshType]
					mesh_id = UnifiedType.MeshId[unified_id] or special_mesh.MeshId
				else
					unified_id = UnifiedType.Shape[instance.Shape]
					mesh_id = UnifiedType.MeshId[unified_id]
				end
				
				local mesh = InsertService:CreateMeshPartAsync(
					mesh_id,
					Enum.CollisionFidelity.Default,
					Enum.RenderFidelity.Automatic
				)
				
				if special_mesh then
					
					local size = 
						if special_mesh.MeshType == Enum.MeshType.FileMesh then
							mesh.MeshSize*special_mesh.Scale 
						else 
							instance.Size*special_mesh.Scale
					
					pushProperty(mesh, "size", size)
					
					if 
						special_mesh.TextureId ~= "" and
						special_mesh.VertexColor ~= Vector3.one 
					then
						local surface_appearance = Instance.new("SurfaceAppearance")
						surface_appearance.ColorMap = special_mesh.TextureId
						surface_appearance.Color = Color3.new(
							special_mesh.VertexColor.X,
							special_mesh.VertexColor.Y,
							special_mesh.VertexColor.Z
						)
						surface_appearance.Parent = mesh
					else
						mesh.TextureID = special_mesh.TextureId
					end
					special_mesh:Remove()
				else
					local unified_shape = UnifiedType.Shape[instance.Shape]
					local size = instance.Size
					
					pushProperty(
						mesh, "size", 
						if unified_shape == UnifiedType.Shape.Sphere then
							size:Min()
						elseif unified_shape == UnifiedType.Shape.Cylinder then
							Vector3.new(size.X, math.min(size.Y, size.Z), math.min(size.Y, size.Z))
						else 
							instance.Size
					)
				end
				
				return instance, mesh
			end
		end,
	},
	{
		from="Part",to="MeshPart",at="editProperties",
		run = function ()			
			return function (old : Part, new : MeshPart)
				new.Size = popProperty(new, "size") 
				return old, new
			end
		end,
	},
	
	-------------------------------------------------------------------------------
	
	{
		from="MeshPart", to="Part", at="replaceInstance",
		run = function ()
			local meshid_to_shape = {
				[6914995538] 	= Enum.PartType.Ball,
				[15636311856] 	= Enum.PartType.Block,
				[9095618661]	= Enum.PartType.Cylinder,
				[4729450112]	= Enum.PartType.Wedge,
				[699163794]		= Enum.PartType.CornerWedge,
			}
			
			return function (instance : MeshPart, new_instance : Part)
				local surface_appearance = instance:FindFirstChildWhichIsA("SurfaceAppearance")
				
				local mesh_id = tonumber(instance.MeshId:match("%d+"))
				local shape = UnifiedType.Id[UnifiedType.Shape[mesh_id]].PartType
				pushProperty(new_instance, "shape", shape)
				
				local hasColorMap = surface_appearance and surface_appearance.ColorMap ~= ""
				
				if not shape then 	
					local special_mesh = Instance.new("SpecialMesh")
					special_mesh.MeshId = instance.MeshId
					special_mesh.TextureId = hasColorMap and surface_appearance.ColorMap or instance.TextureID
					if surface_appearance and surface_appearance.Color then 
						special_mesh.VertexColor = Vector3.new(
							surface_appearance.Color.R,
							surface_appearance.Color.G,
							surface_appearance.Color.B
						) 
					end
					special_mesh.Scale = instance.Size/instance.MeshSize
					special_mesh.Parent = new_instance
				else
					
					if hasColorMap then
						local textures = {}
						for _, face in Enum.NormalId:GetEnumItems() do
							local texture = Instance.new("Texture")
							texture.Texture = surface_appearance.ColorMap
							texture.Parent = new_instance
							table.insert(textures, texture)
						end
						if surface_appearance.Color then
							for _, texture in textures do
								texture.Color3 = surface_appearance.Color
							end
						end
					end
					
				end
				
				if surface_appearance then surface_appearance:Remove() end
				
				return instance, new_instance
				
			end
		end,
	},
	
	{
		from="MeshPart", to="Part", at="editParent",
		run = function ()
			return function (instance : MeshPart, new_instance : Part)
				local shape = popProperty(new_instance, "shape")
				if shape then 	
					new_instance.Shape = shape
				end
			end
		end,
	},
	
	-------------------------------------------------------------------------------

	{
		from="Decal", to="Texture", at="editProperties",
		run = function ()
			return function(instance: Decal, new_instance: Texture) 
				local parent = instance.Parent
				if not parent:IsA("BasePart") then return instance, new_instance end

				local u,v = face_to_2dSize[instance.Face](parent.Size)

				new_instance.StudsPerTileU = u
				new_instance.StudsPerTileV = v

				return instance, new_instance
			end
		end
	},
	
	-------------------------------------------------------------------------------

	{
		from="Attachment", to="Part", at="editProperties",
		run = function ()
			return function(old: Attachment, new: Part) 
				new.Position = old.WorldPosition
				new.Size = Vector3.new(0.3,0.3,0.3)
				new.Material = Enum.Material.Neon
				new.Color = BrickColor.Green().Color
				new.Shape = Enum.PartType.Ball

				local weld = Instance.new("WeldConstraint")
				weld.Parent = new
				weld.Part0 = new
				weld.Part1 = old.Parent

				return old, new
			end
		end
	},
	
	-------------------------------------------------------------------------------
	
	{
		from="Part", to="Attachment", at="editProperties",
		run = function ()
			return function(old: Attachment, new: Part)
				if not old.Parent:IsA("BasePart") then 
					warn(string.format("Conversion of %s may fail: %s requires BasePart as Parent", old:GetFullName(), new.ClassName)) 
				end
				new.WorldPosition = old.Position
				return old, new
			end
		end
	},
	
	-------------------------------------------------------------------------------
	
	{
		from="MeshPart", to="Attachment", at="editProperties",
		run = function ()
			return function(old: Attachment, new: Part)
				if not old.Parent:IsA("BasePart") then 
					warn(string.format("Conversion of %s may fail: %s requires BasePart as Parent", old:GetFullName(), new.ClassName)) 
				end
				
				new.WorldPosition = old.Position
				return old, new
			end
		end
	},
	
	-------------------------------------------------------------------------------

	{
		from="Attachment", to="MeshPart", at="replaceInstance",
		run = function ()
			return function(old: Attachment) 
				return 
					old, 
					InsertService:CreateMeshPartAsync( 
						UnifiedType.MeshId[UnifiedType.Shape[Enum.PartType.Ball]],
						Enum.CollisionFidelity.Default,
						Enum.RenderFidelity.Automatic
					)
			end
		end
	},

	{
		from="Attachment", to="MeshPart", at="editProperties",
		run = function ()
			return function(old: Attachment, new: Part)
				new.Position = old.WorldPosition
				new.Size = Vector3.new(0.3,0.3,0.3)
				new.Material = Enum.Material.Neon
				new.Color = BrickColor.Green().Color

				local weld = Instance.new("WeldConstraint")
				weld.Parent = new
				weld.Part0 = new
				weld.Part1 = old.Parent

				return old, new
			end
		end
	},
	
	-------------------------------------------------------------------------------
	
	-- this is more a tech demo of what is possible using special operations
	-- only works for (decals on) block parts atm
	-- not possible for (decals on) meshparts without using editable meshes
	{
		from="Decal", to="MeshPart",at="replaceInstance",
		run = function ()
			local d90, d180 = math.rad(90), math.rad(180)
			local face_to_3d = {
				[Enum.NormalId.Top] 	= {
					Rotation = CFrame.Angles(0,0,0),
					Offset = Vector3.new(0,0.5,0),
				},
				[Enum.NormalId.Bottom] 	= {
					Rotation = CFrame.Angles(d180,0,0),
					Offset = Vector3.new(0,-0.5,0),
				},
				[Enum.NormalId.Back] 	= {
					Rotation = CFrame.Angles(d90,d180,0),
					Offset = Vector3.new(0,0,0.5),
				},
				[Enum.NormalId.Front] 	= {
					Rotation = CFrame.Angles(-d90,0,0),
					Offset = Vector3.new(0,0,-0.5),
				},
				[Enum.NormalId.Left] 	= {
					Rotation = CFrame.Angles(-d90,0,d90),
					Offset = Vector3.new(-0.5,0,0),
				},
				[Enum.NormalId.Right] 	= {
					Rotation = CFrame.Angles(-d90,0,-d90),
					Offset = Vector3.new(0.5,0,0),
				},
			}

			return function (instance : Decal, new_instance : MeshPart)
				local plane = InsertService:CreateMeshPartAsync(
					string.format("rbxassetid://8586054326"),
					Enum.CollisionFidelity.Box,
					Enum.RenderFidelity.Automatic
				)

				local surfaceAppearance = Instance.new("SurfaceAppearance")
				pcall(function() 
					surfaceAppearance.ColorMap = instance.Texture
					surfaceAppearance.AlphaMode = Enum.AlphaMode.Transparency
				end)
				surfaceAppearance.Parent = plane

				local parent = instance.Parent
				if parent:IsA("BasePart") then
					plane.Anchored = parent.Anchored
					local sx, sy = face_to_2dSize[instance.Face](parent.Size)
					plane.Size = Vector3.new(sx, 0, sy)
					plane:PivotTo(
						instance.Parent.CFrame  -- base position & orientation
							* CFrame.new(
								face_to_3d[instance.Face].Offset * parent.Size + -- offset from part center
								face_to_3d[instance.Face].Offset * Vector3.new(0.005, 0.005, 0.005)  -- pevent Z-Fighting (only works if there is up to one per side)
							)
							* face_to_3d[instance.Face].Rotation
					)
					plane:SetAttribute("Face", instance.Face)
				end 

				return instance, plane
			end
		end
	},
	
	{
		from="Decal", to="MeshPart", at="editParent",
		run = function ()
			return function (instance : Decal, new_instance : MeshPart)
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = new_instance.Parent
				weld.Part1 = new_instance
				weld.Parent = new_instance.Parent
			end
		end,

	},
	
	-------------------------------------------------------------------------------
	
	{
		from="LocalScript", to="Script", at="editParent",
		run = function ()
			return function (instance : LocalScript, new_instance : Script)
				new_instance.RunContext = Enum.RunContext.Client
			end
		end,

	},
	
	-------------------------------------------------------------------------------
	
	{
		from="SpecialMesh", to="MeshPart", at="changeHierarchy",
		run = function() return function () warn("Convert parent Part instead of SpecialMesh") end end,
	},
	
	-------------------------------------------------------------------------------
	
	{
		from="FileMesh", to="MeshPart", at="changeHierarchy",
		run = function() return function () warn("Convert parent Part instead of SpecialMesh") end end,
	},
	
	-------------------------------------------------------------------------------
	
	{
		from="MeshPart", to="MeshPart", at="replaceInstance",
		run = function ()
			
			local prompt = require(script.Parent.Parent.MarketPlaceView)
			
			return function(old: MeshPart, new: MeshPart)
				local meshid = prompt:open()
				if not meshid then return old, old end
				
				local mesh = InsertService:CreateMeshPartAsync(
					meshid,
					old.CollisionFidelity,
					old.RenderFidelity
				)
				return old, mesh
			end
		end
	},
	
	-------------------------------------------------------------------------------
	
	{
		from="Decal", to="SurfaceAppearance", at="editParent",
		run = function()
			return function (instance : Decal, new_instance : SurfaceAppearance)
				new_instance.ColorMap = instance.Texture
			end
		end,
	},
	{
		from="Texture", to="SurfaceAppearance", at="editParent",
		run = function()
			return function (instance : Texture, new_instance : SurfaceAppearance)
				new_instance.ColorMap = instance.Texture
			end
		end,
	},

}

return SpecialOperations

