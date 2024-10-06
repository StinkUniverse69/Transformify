-- used by multiple
local InsertService = game:GetService("InsertService")
local face_to_2dSize = {
	[Enum.NormalId.Top] = function (size : Vector3) return size.X, size.Z end,
	[Enum.NormalId.Bottom] = function (size : Vector3) return size.X, size.Z end,
	[Enum.NormalId.Back] = function (size : Vector3) return size.X, size.Y end,
	[Enum.NormalId.Front] = function (size : Vector3) return size.X, size.Y end,
	[Enum.NormalId.Left] = function (size : Vector3) return size.Z, size.Y end,
	[Enum.NormalId.Right] = function (size : Vector3) return size.Z, size.Y end,
}

local shapeToMeshId : (shape : Enum.PartType | Enum.MeshType) -> string; 
do
	local unified_shape_id = {
		[Enum.PartType.Ball]			= 0,
		[Enum.MeshType.Sphere]			= 0,
		
		[Enum.PartType.Block]			= 1,
		[Enum.MeshType.Brick]			= 1,
		
		[Enum.PartType.Cylinder]		= 2,
		[Enum.MeshType.Cylinder]		= 2,
		
		[Enum.PartType.Wedge]			= 3,
		[Enum.MeshType.Wedge]			= 3,
		
		[Enum.PartType.CornerWedge]		= 4,
		[Enum.MeshType.CornerWedge]		= 4,
		
		[Enum.MeshType.Head]			= 5,
		[Enum.MeshType.Torso]			= 6,
		[Enum.MeshType.Prism]			= 7,
		[Enum.MeshType.Pyramid]			= 8,
		[Enum.MeshType.ParallelRamp]	= 9,
		[Enum.MeshType.RightAngleRamp]	= 10,
	}
	
	local unified_to_meshid = {
		[0]	= 6914995538,
		[1]	= 15636311856,
		[2]	= 9095618661,
		[3]	= 4729450112,
		[4]	= 699163794,
	}
	shapeToMeshId = function (shape)
		print(shape)
		return string.format("rbxassetid://%d", unified_to_meshid[unified_shape_id[shape]])
	end
end


--[[
	from : Class name of the instance that you're converting
	to   : Class name you want to convert it to
	at
		- start  : Before any properties have been set.
		- finish : After properties have been set, but before parent is set.
		- final  : After parent has been set. No returns accepted.
	
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
	an instance at final isn't prossible and at finish will discard all 
	automatically transfered properties.
	
	Class hierarchy will be ignored for the execution of these operations. I.e. an 
	operation set for BasePart will not execute for Part or MeshPart.
]]
export type Operation = {
	from : string,
	to : string,
	at :   "final" | "finish" | "start",
	run : () -> ( (instance: Instance, new_instance: Instance) -> (Instance, Instance) )
}

local SpecialOperations : {Operation}  = {

	{
		from="Part",to="MeshPart",at="start",
		run = function ()			
			return function (instance : Part, new_instance : MeshPart)
				local special_mesh = instance:FindFirstChildWhichIsA("SpecialMesh")
				
				local mesh_id = 
					special_mesh and ( 
						shapeToMeshId(special_mesh.MeshType)
						or special_mesh.MeshId
					) or shapeToMeshId(instance.Shape)
				
				local mesh = InsertService:CreateMeshPartAsync(
					mesh_id,
					Enum.CollisionFidelity.Default,
					Enum.RenderFidelity.Automatic
				)
				
				return instance, mesh
			end
		end,
	},
	
	{
		from="Part",to="MeshPart",at="finish",
		run = function ()			
			return function (instance : Part, new_instance : MeshPart)
				local special_mesh = instance:FindFirstChildWhichIsA("SpecialMesh")
				if special_mesh then new_instance.Size *= special_mesh.Scale end
				return 
					instance, 
					new_instance
			end
		end,
	},
	
	{
		from="MeshPart", to="Part", at="final",
		run = function ()
			local meshid_to_shape = {
				[6914995538] 	= Enum.PartType.Ball,
				[15636311856] 	= Enum.PartType.Block,
				[9095618661]	= Enum.PartType.Cylinder,
				[4729450112]	= Enum.PartType.Wedge,
				[699163794]		= Enum.PartType.CornerWedge,
			}
			
			return function (instance : MeshPart, new_instance : Part)
				local id = tonumber(instance.MeshId:match("%d+"))
				local shape = meshid_to_shape[id]
				
				if not shape then 	
					local special_mesh = Instance.new("SpecialMesh")
					special_mesh.MeshId = instance.MeshId
					special_mesh.TextureId = instance.TextureID
					special_mesh.Scale = instance.Size/instance.MeshSize
					special_mesh.Parent = new_instance
				else
					new_instance.Shape = shape
				end
			end
		end,
	},

	{
		from="Decal", to="Texture", at="finish",
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

	{
		from="Attachment", to="Part", at="finish",
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
	
	{
		from="Part", to="Attachment", at="finish",
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
	
	{
		from="MeshPart", to="Attachment", at="finish",
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

	{
		from="Attachment", to="MeshPart", at="start",
		run = function ()
			return function(old: Attachment) 
				return 
					old, 
					InsertService:CreateMeshPartAsync( 
						shapeToMeshId(Enum.PartType.Ball),
						Enum.CollisionFidelity.Default,
						Enum.RenderFidelity.Automatic
					)
			end
		end
	},

	{
		from="Attachment", to="MeshPart", at="finish",
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
	
	
	-- only works for (decals on) block parts atm
	-- not possible for (decals on) meshparts without using editable meshes
	{
		from="Decal", to="MeshPart",at="start",
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
		from="Decal", to="MeshPart", at="final",
		run = function ()
			return function (instance : Decal, new_instance : MeshPart)
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = new_instance.Parent
				weld.Part1 = new_instance
				weld.Parent = new_instance.Parent
			end
		end,

	},
	
	{
		from="LocalScript", to="Script", at="final",
		run = function ()
			return function (instance : LocalScript, new_instance : Script)
				new_instance.RunContext = Enum.RunContext.Client
			end
		end,

	},
	
	{
		from="SpecialMesh", to="MeshPart", at="finish",
		run = function()
			return function (instance : MeshPart, new_instance : MeshPart)
				warn("TODO")
				return instance, new_instance
			end
		end,
	},
	
	{
		from="MeshPart", to="MeshPart", at="start",
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

}

return SpecialOperations

