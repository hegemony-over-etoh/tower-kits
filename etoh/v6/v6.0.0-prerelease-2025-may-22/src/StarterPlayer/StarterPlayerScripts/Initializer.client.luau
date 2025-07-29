--!strict

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

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Framework = ReplicatedStorage.Framework
local Remotes = Framework.Remotes
local RequestCOFolder = Remotes.Towers.Objects.RequestCOFolder
local Kit = ReplicatedStorage.Framework.Kit

--> Disable some stuff
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

--> Initializing
local CharacterManager = require(Kit.Managers.CharacterManager):Init()
local FlipManager = require(Kit.Managers.FlipManager):Init()
local LightingManager = require(Kit.Managers.LightingManager):Init()
local EffectGuiManager = require(Kit.Managers.EffectGuiManager):Init()
local ClientObjectManager = require(Kit.Managers.ClientObjectManager):Init()

--> Load Client Objects
local ClientParts = workspace:FindFirstChild("ClientParts")
	or (function()
		local newFolder = Instance.new("Folder")
		newFolder.Name = "ClientParts"
		newFolder.Parent = workspace
		return newFolder
	end)()

--> Request server for objects
local customRepository = ReplicatedStorage:FindFirstChild("RepositoryScripts")

local currentlyLoading = false
local objectScope
local function requestObjects()
	if currentlyLoading then
		return
	end
	currentlyLoading = true

	local recievedObjects = RequestCOFolder:InvokeServer("request")
	local objects = recievedObjects:Clone()
	recievedObjects:Destroy()
	objectScope = ClientObjectManager:LoadClientObjects(objects, ClientParts, customRepository)
	-- Tell server to clean up objects since they have already been replicated
	RequestCOFolder:InvokeServer("cleanup")
	currentlyLoading = false
end

if not Players.LocalPlayer.Character then
	Players.LocalPlayer.CharacterAdded:Wait()
end
requestObjects()

--> Reset objects on respawn
-- PLEASE DO NOT REMOVE THE FOLLOWING CODE!!
Players.LocalPlayer.CharacterAdded:Connect(function()
	if objectScope then
		objectScope:cleanup(false, true)
		objectScope = nil :: any
	end

    LightingManager:ResetLighting()
	ClientParts:ClearAllChildren()
	task.defer(requestObjects)
end)
