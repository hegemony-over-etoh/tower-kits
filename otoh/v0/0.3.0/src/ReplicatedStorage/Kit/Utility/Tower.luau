--!strict
-- junekept 2025
-- this script was originally made for OToH

--[==[
	This module contains all logic for loading / unloading towers into the game.
]==]

-- I hate these line breaks but idk how else to format this loool
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Repository = Kit.Repository

local LemonSignal = require(Libraries.LemonSignal)
local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local Tower = {}

local clientObjects = ReplicatedStorage.ClientObjects

Tower.loadedTower = (nil :: any) :: Types.Tower
Tower.loadedClientObjects = (nil :: any) :: {[Instance]: Types.ClientObject}

Tower.towerLoaded = LemonSignal.new()

-- Load a tower into the game.
-- This function only loads the client objects, as the rest of the tower is server-sided and does not need to be replicated on an individual basis.
function Tower.loadTower(towerName: string)
	local clientObjectFolder: Folder = clientObjects:FindFirstChild(towerName)
	assert(clientObjectFolder and clientObjectFolder:IsA("Folder"), `Attempted to load tower {towerName} which does not exist!`)
	
	local towerTrove = Trove.new()
	
	local loadedClientObjects = towerTrove:Clone(clientObjectFolder)
	loadedClientObjects.Parent = workspace
	loadedClientObjects.Name = "LoadedClientObjects"
	
	local config: Types.TowerConfig = {
		debug = clientObjectFolder:GetAttribute("Debug"),
		
		poisonBrickDamage = clientObjectFolder:GetAttribute("PoisonBrickDamage"),
		poisonDecrementRate = clientObjectFolder:GetAttribute("PoisonDecrementRate"),
		posionDamageThreshold = clientObjectFolder:GetAttribute("PoisonDamageThreshold")
	}

	Tower.loadedTower = {
		config = config,
		clientObjectFolder = loadedClientObjects,
		trove = towerTrove
	}
	
	Tower.loadedClientObjects = setmetatable({}, {__mode = "k"}) :: any
	
	local function loadIfClientObject(instance: Instance)
		-- do this first just in case so that we don't have weird messups with defaults
		if instance:GetAttribute("LoadTransparency") and instance:IsA("BasePart") then
			instance.Transparency = instance:GetAttribute("LoadTransparency")
		end
		
		if instance:GetAttribute("_Script") then
			local scriptName = instance:GetAttribute("_Script")
			local clientObjectScript = Repository:FindFirstChild(scriptName)
			if clientObjectScript then
				local clientObject: Types.ClientObject = {
					instance = instance,
					trove = towerTrove:Extend(),
					signals = {
						onTrigger = LemonSignal.new()
					}
				}

				-- spawn a thread to prevent the main script hanging due to continuous client object loops
				-- after all, the main thread should not be responsible for managing client objects lol
				-- `nil` is counted as zero in regards to task.delay, so there's no need for a fallback
				task.delay(instance:GetAttribute("LoadDelay"), require(clientObjectScript) :: Types.ClientObjectFunction, clientObject)
				Tower.loadedClientObjects[instance] = clientObject
			else
				warn(`Object {instance.Name} requested client object script {instance:GetAttribute("_Script")}, which does not exist. Object will load but will be missing functionality.`)
			end
		end

		for _, tag: string in instance:GetTags() do
			if tag:sub(1, #"ButtonGroup_") == "ButtonGroup_" then
				-- In order to reduce the performance impact due to tags taking from more than just workspace,
				-- loaded towers have their button tags changed to start with "Loaded"
				instance:RemoveTag(tag)
				instance:AddTag(`Loaded{tag}`)
				--[[
				if instance:GetAttribute("_Active") == nil then
					instance:SetAttribute("_Active", false)
				end ]]
			end
		end
	end
	
	-- TODO: potentially cache location of client objects to make loading quicker
	for _, instance in loadedClientObjects:GetDescendants() do
		loadIfClientObject(instance)
	end
	
	-- load any new client objects
	towerTrove:Connect(loadedClientObjects.DescendantAdded, loadIfClientObject)
	
	-- Only tag music zones when loaded as it reduces strain on the client to not need to do checks for music zones unrelated to the tower they are playing
	local towerMusicZones = SoundService.MusicZones[towerName] :: Folder
	for _, zone in towerMusicZones:GetChildren() do
		zone:AddTag("LoadedMusicZone")
	end
	
	-- It's kinda lame when music syncing messes up because the audio wasn't loaded so let's load them beforehand !
	ContentProvider:PreloadAsync({towerMusicZones})
	
	-- Auto cleanup of loaded music zones in case the tower gets destroyed some other way (also lets us still use trove:Destroy() just fine)
	towerTrove:Add(function()
		for _, zone in towerMusicZones:GetChildren() do
			zone:RemoveTag("LoadedMusicZone")
		end
	end)
	
	-- hi singular trigger that requires this
	Tower.towerLoaded:Fire()
end

-- Unload a tower from the workspace.
-- Essentially deletes the loaded client objects from the workspace and nothing else.
function Tower.unloadTower()
	if Tower.loadedTower then
		Tower.loadedTower.trove:Destroy()
	end
end

return Tower