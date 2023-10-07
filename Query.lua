--!strict
export type Query<T> = {
	CreateKey: (self: Query<T>,Item: Instance ) -> string,
	RetrieveItem: (self: Query<T>, Key: string) -> Instance?,
	AddItem: (self: Query<T>, Item: Instance, Key: string) -> (),
	
	Folder: Folder,
	
	Items: {}
}

--//PRIVATE FUNCTIONS

local function CreateHex(Length: number): string
	local Hex:string = ""
	
	for i = 0, Length  do
		Hex = Hex..string.char(math.random(0,255))
	end
	
	return Hex
end

--//PRIVATE FUNCTIONS


local Query = {}
Query.__index = Query

local function CreateQuery<T>():Query<T>
	local self:Query<T> = (setmetatable({}, Query) :: unknown) :: Query<T>
			
	self.Folder = Instance.new("Folder", script)
	self.Items = {}
	
	return self
end

function Query:CreateKey(Item: Instance): string
	local Name = CreateHex(16)
	if self.Items[Name] then return self:CreateKey(Item) end
	
	local Folder = Instance.new("Folder")
	Folder.Name = Name
	Folder.Parent = self.Folder
		
	local NewItem = Item:Clone()
	NewItem.Parent = Folder
	
	self.Items[Name] = {}
	table.insert(self.Items[Name], NewItem)
	return Folder.Name
end

function Query:RetrieveItem(Key: string)
	if not self.Items[Key] then return end
	
	if #self.Items[Key] <= 1  then
		return self.Items[Key][1]:Clone()
	else
		local Item = self.Items[Key][2]
		table.remove(self.Items[Key], 2)
		
		return Item
	end
end

function Query:AddItem(Item: Instance, Key: string)
	Item.Parent = self.Folder:WaitForChild(Key)
	
	table.insert(self.Items[Key], Item)
end

return {
	New = CreateQuery,
}