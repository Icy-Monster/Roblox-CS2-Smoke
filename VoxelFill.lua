--!strict
export type Voxel = {
	Distance: number,
	Position: Vector3,

	LifeTime: number
}

export type VoxelModel<T> = {
	CreateVoxel: (self: VoxelModel<T>, Position: Vector3, Distance: number, CheckPosition: boolean) -> Voxel?,
	ExpandVoxel: (self: VoxelModel<T>, Voxel: Voxel) -> (),

	ShootVoxels: (self: VoxelModel<T>, StartPoint: Vector3, EndPoint: Vector3, Thickness: number) -> (),

	Clear: (self: VoxelModel<T>) -> (),

	Radius: number,

	LifeTime: Vector2,
	BurstSpeed: Vector2,

	Resolution: number,

	Model: Model,

	Voxels: {}
}

local Query = require(script.Parent.Query)
local QueryGroup = Query.New()

--Create Query Keys
local VoxelObject:Part = script.Parent.Part

local VoxelKey = QueryGroup:CreateKey(VoxelObject)
--Create Query Keys

--//PRIVATE FUNCTIONS
local function PositionOccupied(Position: Vector3, Size: number): boolean
	local Parts = workspace:GetPartBoundsInBox(
		CFrame.new(Position),
		Vector3.new(Size/2,Size/2,Size/2)
	)

	return Parts[1] ~= nil
end

local function ShootPath(Smoke: Model, StartPosition: Vector3, EndPosition: Vector3, Thickness: number)
	local OverlapParam = OverlapParams.new()
	OverlapParam.FilterDescendantsInstances = Smoke:GetChildren()
	OverlapParam.FilterType = Enum.RaycastFilterType.Include

	local Distance = (StartPosition - EndPosition).Magnitude

	local Parts = workspace:GetPartBoundsInBox(
		CFrame.new(StartPosition:Lerp(EndPosition, 0.5), EndPosition),
		Vector3.new(Thickness, Thickness, Distance),
		OverlapParam
	)

	return Parts
end

local function ShuffleTable(Table: {}): {}
	for i = #Table, 2, -1 do
		local j = math.random(i)
		Table[i], Table[j] = Table[j], Table[i]
	end

	return Table 
end

--//PRIVATE FUNCTIONS
local VoxelModel = {}
VoxelModel.__index = VoxelModel

local function CreateVoxels<T>(Radius: number, Resolution: number, LifeTime: Vector2, BurstSpeed: Vector2):VoxelModel<T>
	local self:VoxelModel<T> = (setmetatable({}, VoxelModel) :: unknown) :: VoxelModel<T>
	self.Radius = Radius
	self.Resolution = Resolution

	self.LifeTime = LifeTime
	self.BurstSpeed = BurstSpeed

	self.Voxels = {}

	local Model = Instance.new("Model", workspace)
	self.Model = Model

	return self
end


function VoxelModel:Clear()
	for _, Item in self.Model:GetChildren() do
		Item.ParticleEmitter:Clear()
		QueryGroup:AddItem(Item, VoxelKey)
	end

	self.Voxels = {}
end


function VoxelModel:CreateVoxel(Position: Vector3, Distance: number, CheckPosition: boolean):Voxel?
	if Distance > self.Radius then return end
	if CheckPosition and PositionOccupied(Position, 1/self.Resolution) then return end

	local VoxelObject = QueryGroup:RetrieveItem(VoxelKey)::BasePart
	if not VoxelObject then return end

	VoxelObject.Position = Position
	--VoxelObject.Color = Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
	VoxelObject.Size = Vector3.new(
		1/self.Resolution,
		1/self.Resolution,
		1/self.Resolution
	)

	local Smoke = VoxelObject:WaitForChild("ParticleEmitter")::ParticleEmitter
	local Sequence = NumberSequence.new{
		NumberSequenceKeypoint.new(0,1/self.Resolution - math.random(0,5)/10),
		NumberSequenceKeypoint.new(1,1/self.Resolution + math.random(0,5)/10)
	}
	Smoke.Size = Sequence

	Sequence = NumberSequence.new{
		NumberSequenceKeypoint.new(0,0),
		NumberSequenceKeypoint.new(1,0)
	}
	Smoke.Transparency = Sequence

	task.spawn(function()
		for i=0,5 do	
			if VoxelObject.Position ~= Position then return end

			task.wait(math.random(
				self.BurstSpeed.X::number/5 *100,
				self.BurstSpeed.Y::number/5 *100)
					/100 + Distance/100)

			Smoke:Emit(1)
		end
	end)

	VoxelObject.Parent = self.Model

	local Voxel:Voxel = {
		Position = Position, 
		Distance = Distance,

		LifeTime = math.random(self.LifeTime.X::number*100, self.LifeTime.Y::number*100)/100
	}

	task.delay(Voxel.LifeTime, function()
		for i = 0, 100 do
			if VoxelObject.Position ~= Position then return end

			task.wait(math.random(1,10)/100)

			local Sequence = NumberSequence.new{
				NumberSequenceKeypoint.new(0,i/100),
				NumberSequenceKeypoint.new(1,i/100)
			}
			Smoke.Transparency = Sequence
		end

		Smoke:Clear()
	end)

	table.insert(self.Voxels, Voxel)	
	return Voxel
end


function VoxelModel:ExpandVoxel(Voxel: Voxel)	
	local Positions = {
		Vector3.new(1/self.Resolution,0,0),
		Vector3.new(-1/self.Resolution,0,0),

		Vector3.new(0,0,1/self.Resolution),
		Vector3.new(0,0,-1/self.Resolution),

		Vector3.new(0,1/self.Resolution,0),
		Vector3.new(0,-1/self.Resolution,0),
	}
	Positions = ShuffleTable(Positions)


	for _, Position: Vector3 in Positions do
		local Distance = Voxel.Distance + 1

		local Voxel:Voxel = self:CreateVoxel(Voxel.Position + Position, Distance, true)

		if Voxel then
			task.wait()
			coroutine.wrap(self.ExpandVoxel)(self, Voxel)
		end
	end

end

function VoxelModel:ShootVoxels(StartPoint: Vector3, EndPoint: Vector3, Thickness: number)
	local Voxels = ShootPath(self.Model, StartPoint, EndPoint, Thickness)

	for _, Voxel:Instance in Voxels do
		local Particle = Voxel:FindFirstChild("ParticleEmitter")::ParticleEmitter
		if not Particle then continue end

		Particle:Clear()
		task.spawn(function()
			for i=0,5 do
				task.wait(math.random(25,35)/10)
				Particle:Emit(1)
			end
		end)

	end

end



return {
	New = CreateVoxels,
}