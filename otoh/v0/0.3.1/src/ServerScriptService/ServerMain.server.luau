--!strict
-- junekept 2025
-- this script was originally written for OToH.

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local Kit = ReplicatedStorage.Kit

local clientObjectsFolder = ReplicatedStorage:FindFirstChild("ClientObjects")
if not clientObjectsFolder then
	clientObjectsFolder = Instance.new("Folder")
	clientObjectsFolder.Name = "ClientObjects"
	clientObjectsFolder.Parent = ReplicatedStorage
end

local musicZonesFolder = SoundService.MusicZones
musicZonesFolder.Global:SetAttribute("OriginalVolume", musicZonesFolder.Global.Volume)

if StarterGui.ScreenOrientation ~= Enum.ScreenOrientation.LandscapeSensor then
	StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	warn(`Setting screen orientation to Landscape to prevent portrait mode.`)
end

if StarterPlayer.AutoJumpEnabled then
	StarterPlayer.AutoJumpEnabled = false
	warn(`Disabling auto jump to align with OToH settings.`)
end

if not StarterPlayer.CharacterUseJumpPower then
	StarterPlayer.CharacterUseJumpPower = true
	warn(`Making characters use Jump Power instead of Jump Height to allow jump modifications from kit objects to work.`)
end

Kit.SelfDamage.OnServerEvent:Connect(function(player: Player, damage: number)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid 
		local healthDiff = humanoid.MaxHealth - humanoid.Health
		-- clamp "healing" damage because roblox doesn't do that for you lool
		humanoid:TakeDamage(math.max(-healthDiff, damage))
	end
end)

local function moveIfExists(parent: Instance, instanceName: string, to: Instance, name: string): Instance?
	local instance = parent:FindFirstChild(instanceName)
	if not instance then return to:FindFirstChild(name) end

	instance.Parent = to
	instance.Name = name

	return instance
end

local function moveObjects(towerFolder: Folder)
	moveIfExists(towerFolder, "ClientObjects", clientObjectsFolder, towerFolder.Name)
	local musicZones = moveIfExists(towerFolder, "MusicZones", musicZonesFolder, towerFolder.Name)
	if musicZones then
		for _, zone in musicZones:GetChildren() do
			local sound = zone:FindFirstChild("Sound") :: Sound
			sound:SetAttribute("OriginalVolume", sound.Volume)
			sound.Volume = 0
		end
	end
end

moveObjects(workspace["OToH Basic Kit"])

-- the really awesome text wall of collision group registration
PhysicsService:RegisterCollisionGroup("Player")
PhysicsService:RegisterCollisionGroup("OtherPlayers")
PhysicsService:RegisterCollisionGroup("OnlyCollideWithPlayers")
PhysicsService:RegisterCollisionGroup("OnlyCollideWithPlayers2")
PhysicsService:RegisterCollisionGroup("DoNotCollideWithPlayers")
PhysicsService:RegisterCollisionGroup("NeverCollide")
PhysicsService:RegisterCollisionGroup("AlwaysCollide")
PhysicsService:RegisterCollisionGroup("DoNotCollideWithSelf")

PhysicsService:CollisionGroupSetCollidable("Player","OtherPlayers",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers","OtherPlayers",false)
PhysicsService:CollisionGroupSetCollidable("DoNotCollideWithPlayers","OtherPlayers",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers","Default",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers","DoNotCollideWithPlayers",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers","OtherPlayers",false)
PhysicsService:CollisionGroupSetCollidable("Player","DoNotCollideWithPlayers",false)
PhysicsService:CollisionGroupSetCollidable("DoNotCollideWithSelf","DoNotCollideWithSelf",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers2","Default",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers2","DoNotCollideWithPlayers",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers2","OtherPlayers",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers2","OnlyCollideWithPlayers",false)
PhysicsService:CollisionGroupSetCollidable("Default","DoNotCollideWithSelf",true)
PhysicsService:CollisionGroupSetCollidable("Player","DoNotCollideWithSelf",true)
PhysicsService:CollisionGroupSetCollidable("Default","NeverCollide",false)
PhysicsService:CollisionGroupSetCollidable("Default","OtherPlayers",false)
PhysicsService:CollisionGroupSetCollidable("Player","NeverCollide",false)
PhysicsService:CollisionGroupSetCollidable("OtherPlayers","NeverCollide",false)
PhysicsService:CollisionGroupSetCollidable("DoNotCollideWithPlayers","NeverCollide",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers","NeverCollide",false)
PhysicsService:CollisionGroupSetCollidable("OnlyCollideWithPlayers2","NeverCollide",false)
PhysicsService:CollisionGroupSetCollidable("NeverCollide","NeverCollide",false)
PhysicsService:CollisionGroupSetCollidable("DoNotCollideWithSelf","NeverCollide",false)
PhysicsService:CollisionGroupSetCollidable("AlwaysCollide","OtherPlayers",false)
PhysicsService:CollisionGroupSetCollidable("AlwaysCollide","NeverCollide",false)