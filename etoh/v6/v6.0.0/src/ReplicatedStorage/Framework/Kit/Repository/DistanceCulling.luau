--!strict
--!optimize 2
--@version distanceculling-6.0.0
--@creator Camille
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 

PLEASE, **DO NOT** make any script edits to this script.
To make a script edit, please read the following:
https://etohgame.github.io/kit/docs/misc#writingediting-repository-scripts

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

type DistanceCullingTable = {
	model: Instance,
	primaryPart: BasePart,
	customRange: number?,
}

type DistanceCullingList = {
	objects: { DistanceCullingTable },
	parent: Instance,
	updateInterval: number,
	lastUpdate: number,
	range: number,
	mode: string,
}

type DistanceCullingCache = { DistanceCullingList }

local DistanceCulling = {
	CanQueue = true,
	RunOnStart = false,
}

local DISTANCE_CONFIG_TEMPLATE
function DistanceCulling.Init(utility: _T.Utility)
	local Config = utility.Config
	DISTANCE_CONFIG_TEMPLATE = {
		UpdateInterval = 0.2,
		Range = 150,
		Mode = Config.Type.Some("Anchor", "Unload", Config.Type.none),
	}
end

local player = Players.LocalPlayer
local distanceFromCharacter = player.DistanceFromCharacter
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache: DistanceCullingCache = {}
	local function updateObjects(list: DistanceCullingList)
		for _, object in list.objects do
			local range = object.customRange or list.range
			local inRange = distanceFromCharacter(player, object.primaryPart.Position) < range

			if list.mode == "Anchor" then
				object.primaryPart.Anchored = not inRange
			elseif list.mode == "Unload" then
				object.model.Parent = if inRange then list.parent else nil
			end
		end
	end

	local function updateDistanceCullingCache()
		debug.profilebegin("DistanceCulling -> Update")

		local now = os.clock()
		for _, list in cache do
			if now - list.lastUpdate >= list.updateInterval then
				list.lastUpdate = now
				updateObjects(list)
			end
		end

		debug.profileend()
	end

	rootScope:delay(0.1, function()
		rootScope:add(RunService.Heartbeat:Connect(updateDistanceCullingCache))
	end)
	return cache
end

function DistanceCulling.Run(scope: _T.Scope, utility: _T.Utility)
	local distanceConfig = scope.instance
	if not distanceConfig then
		return
	end
	local distanceFolder = distanceConfig.Parent
	if not distanceFolder then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, distanceConfig, DISTANCE_CONFIG_TEMPLATE):ObserveChanges()

	--> Check for problems
	if not configuration.Mode then
		scope:log({
			"DistanceCulling has an unknown Mode and cannot function.",
			`Path: {distanceFolder:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Setup cache
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)

	--> Set up this distance culling folder
	local distanceList: DistanceCullingList = {
		objects = {},
		parent = distanceFolder,
		updateInterval = configuration.UpdateInterval,
		lastUpdate = os.clock(),
		range = configuration.Range,
		mode = configuration.Mode,
	}

	for _, object in distanceFolder:GetChildren() do
		if not object:IsA("Model") then
			continue
		end
		if not object.PrimaryPart then
			scope:log({
				"An object in DistanceCulling is missing a PrimaryPart and will be ignored.",
				`Path: {object:GetFullName()}`,
				type = "warn",
			})

			continue
		end

		local thisObject: DistanceCullingTable = {
			model = object,
			primaryPart = object.PrimaryPart,
			customRange = object:GetAttribute("CustomRange"),
		}

		table.insert(distanceList.objects, thisObject)
	end

	table.insert(cache, distanceList)
	scope:add(function()
		local index = table.find(cache, distanceList)
		if index then
			table.remove(cache, index)
			table.clear(distanceList)
			distanceList = nil :: any
		end
	end)
end

return DistanceCulling
