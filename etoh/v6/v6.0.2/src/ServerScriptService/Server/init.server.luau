--!strict
-- By @synnwave (29/11/24 DD/MM/YY)
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local COLLISION_MAP = require(script.CollisionGroupMap)
local KitSettings = require(ReplicatedStorage.KitSettings)

local Framework = ReplicatedStorage.Framework
local Remotes = Framework.Remotes

local VERSION_NUMBER = "6.0.2"

--------------------------------------------------------------------------------

do --> Collision Groups
	-- first iteration: register collision groups from the map
	for groupName in COLLISION_MAP do
		PhysicsService:RegisterCollisionGroup(groupName)
	end

	-- second iteration: set groups collidable
	for groupName, map in COLLISION_MAP do
		for _, doesNotCollideWith in map do
			PhysicsService:CollisionGroupSetCollidable(groupName, doesNotCollideWith, false)
		end
	end
end

--------------------------------------------------------------------------------

do --> Damage Event
	local debounceArray = {} :: { [Player]: boolean? }
	Remotes.Towers.Objects.DamageEvent.OnServerEvent:Connect(function(player: Player, type: string | number)
		if debounceArray[player] then
			return
		end

		local character = player.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		local damageValue = if typeof(type) == "number" then type else 5
		if type == "Heals" then
			damageValue = -(humanoid.MaxHealth - humanoid.Health)
		end

		if damageValue > 0 then -- no debounce for healing
			debounceArray[player] = true
			task.delay(0.1, function()
				debounceArray[player] = nil
			end)
		end

		humanoid:TakeDamage(damageValue)
		if humanoid.Health > humanoid.MaxHealth then
			humanoid.Health = humanoid.MaxHealth
		end
	end)
end

--------------------------------------------------------------------------------

do --> Rejoin Event
	Remotes.Rejoin.OnServerEvent:Connect(function(player: Player)
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)
end

--------------------------------------------------------------------------------

do --> Create Player Configuration Folder
	local function onPlayerAdded(player: Player)
		local configurationFolder = Instance.new("Configuration")
		configurationFolder.Name = "KitConfiguration"
		configurationFolder.Parent = player
	end

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
end

--------------------------------------------------------------------------------

do --> Handle Tower Client Objects
	--> Move client objects folder to where they need to go
	local kitFolder = Workspace:FindFirstChild("TowerKit")
	local clientObjectsFolder = kitFolder:FindFirstChild("ClientSidedObjects")
	clientObjectsFolder.Parent = ServerStorage

	--> Make ModuleScript pointers
	-- this is to help reduce memory usage when requiring modules !
	-- i'm still keeping repository scripts the way they are though because
	-- this is meant for much smaller modules like lighting configurations
	local pointerTemplate = Instance.new("ObjectValue")
	pointerTemplate:AddTag("OBJ_POINTER")

	local pointerContainer = Instance.new("Folder")
	pointerContainer.Name = "__POINTER_STORAGE"
	pointerContainer.Parent = ReplicatedStorage

	local warnings = {}
	local version = clientObjectsFolder:GetAttribute("KitVersion")
	if version ~= VERSION_NUMBER then
		table.insert(warnings, {
			"ClientObjects folder is missing its KitVersion Attribute or is outdated",
			`Current version is: {VERSION_NUMBER}`,
		})
	end

	local descendantCount = 0
	local partCount = 0
	for _, instance in clientObjectsFolder:GetDescendants() do
		descendantCount += 1
		if instance:IsA("ModuleScript") then
			if instance.Name == "ClientObjectScript" then
				table.insert(warnings, {
					"ClientObjectScripts are no longer supported in this kit version.",
					`Path: {instance:GetFullName()}`,
				})
				continue
			end

			local thisPointer = pointerTemplate:Clone()
			thisPointer.Value = instance
			thisPointer.Name = instance.Name
			thisPointer.Parent = instance.Parent
			instance.Name = instance:GetFullName():gsub("ServerStorage%.", "")
			instance.Parent = pointerContainer

			-- copy tags to pointer
			for _, tag in instance:GetTags() do
				thisPointer:AddTag(tag)
				instance:RemoveTag(tag) -- dunno if i should keep this line
			end
		elseif instance:IsA("BasePart") then
			partCount += 1
			if instance.CollisionGroup == "Default" then
				instance.CollisionGroup = "ClientObjects"
			end
		elseif instance:IsA("NoCollisionConstraint") then
			table.insert(warnings, {
				"NoCollisionConstraints cause problems when inserting ingame, please use CollisionGroups instead.",
				`Path: {instance:GetFullName()}`,
			})
		end
	end

	ReplicatedStorage.KitSettings:SetAttribute("COPartCount", partCount)
	ReplicatedStorage.KitSettings:SetAttribute("COInstanceCount", descendantCount)

	--> Listen to client requests
	local clones = {} :: { [Player]: Instance? }
	function Remotes.Towers.Objects.RequestCOFolder.OnServerInvoke(player: Player, type: string)
		if type == "request" then
			local playerGui = player:WaitForChild("PlayerGui")

			local clonedFolder = clientObjectsFolder:Clone()
			clonedFolder.Parent = playerGui
			clones[player] = clonedFolder
			return clonedFolder, warnings
		elseif type == "cleanup" then
			local clone = clones[player]
			if clone then
				clone:Destroy()
			end
			clones[player] = nil
		end
	end
end
