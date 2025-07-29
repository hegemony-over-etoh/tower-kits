--!strict
--!optimize 2
--@version booster-6.0.0
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

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local CharacterManager_Types = require(ReplicatedStorage.Framework.Kit.Managers.CharacterManager.TypeDefs)
local SequencerSupport = require(script.SequencerSupport)

type Booster = {
	part: BasePart,
	configuration: { [string]: any },
	startTweenConfig: { [string]: any },
	endTweenConfig: { [string]: any },
	id: string,
}

type BoosterZoneCache = {
	activators: { [BasePart]: () -> () },
	boosters: { Booster },
	activeBoosters: { [string]: Booster? },
}

local Booster = {
	CanQueue = true,
	RunOnStart = false,
}

local BOOSTER_CONFIG_TEMPLATE
function Booster.Init(utility: _T.Utility)
	local Config = utility.Config
	BOOSTER_CONFIG_TEMPLATE = {
		Mode = Config.Type.Some("Default", "Zone", Config.Type.none),
		Type = Config.Type.Some("Speed", "Jump", Config.Type.none),
		Duration = 5,
		Power = 50,
		TimerDecimals = 1,
		HideGUI = false,
	}
end

function Booster.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local boosterConfig = scope.instance
	if not boosterConfig then
		return
	end

	local booster = boosterConfig.Parent
	if not booster or not booster:IsA("BasePart") then
		return
	end

	local CharacterUtil = utility.Character
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, boosterConfig, BOOSTER_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, boosterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()
	local startTweenConfiguration =
		Config.GetConfig(scope, boosterConfig:FindFirstChild("StartTweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()
	local endTweenConfiguration =
		Config.GetConfig(scope, boosterConfig:FindFirstChild("EndTweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()

	--> Functions
	local function getBoostData(booster: Booster): CharacterManager_Types.BoostData
		return {
			isPad = false,
			startTime = os.clock(),

			mode = booster.configuration.Mode,
			type = booster.configuration.Type,
			power = booster.configuration.Power,
			duration = booster.configuration.Duration,
			timerDecimals = booster.configuration.TimerDecimals,
			hideGUI = booster.configuration.HideGUI,
			startTweenInfo = TweenInfo.new(
				booster.startTweenConfig.Time,
				booster.startTweenConfig.Style,
				booster.startTweenConfig.Direction
			),
			endTweenInfo = TweenInfo.new(
				booster.endTweenConfig.Time,
				booster.endTweenConfig.Style,
				booster.endTweenConfig.Direction
			),

			-- these will get filled in later, required to be placeholders here
			-- due to type checker
			infinite = false,
			multiplier = 1,
			timeLeft = 0,
		}
	end

	--> Cache system and main loop for zone boosters
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.CollisionGroup = ""
	CharacterUtil.getHitbox("StaticWholeBody", overlapParams)

	local cache = utility.Scope.getCached(scope, scope.scriptPath, function()
		local cache: BoosterZoneCache = {
			activators = {},
			boosters = {},
			activeBoosters = {
				Speed = nil,
				Jump = nil,
			},
		}

		local lastTick = os.clock()
		local fpsCap = 1 / 60

		local isTableEmpty = utility.Table.IsEmpty
		scope.rootScope:add(RunService.Heartbeat:Connect(function(deltaTime: number)
			debug.profilebegin("Booster -> Update Zones")
			if isTableEmpty(cache.boosters) then
				return
			end

			--> Cap loop to 60fps
			local currentTick = os.clock()
			if currentTick - lastTick < fpsCap then
				return
			end
			lastTick = currentTick

			--> Get touching parts and determine if any zone boosters are being touched
			local touchingBoosters: { Booster } = {}
			for _, booster in cache.boosters do
				if
					#Workspace:GetPartsInPart(booster.part, overlapParams) > 0
					and booster.part:GetAttribute("Activated") ~= false
				then
					table.insert(touchingBoosters, booster)
				end
			end

			--> Activate boost if touching
			local boostTypesFound = {}

			for _, touchedBooster in touchingBoosters do
				boostTypesFound[touchedBooster.configuration.Type] = true

				local activeBooster = cache.activeBoosters[touchedBooster.configuration.Type]
				if activeBooster and activeBooster.id ~= touchedBooster.id or not activeBooster then
					cache.activeBoosters[touchedBooster.configuration.Type] = touchedBooster

					local boostData = getBoostData(touchedBooster)
					CharacterUtil.startBoost(boostData)
				end
			end

			--> If not touching, deactivate boost
			for boostType, activeBooster in cache.activeBoosters do
				if activeBooster and not boostTypesFound[boostType] then
					cache.activeBoosters[boostType] = nil

					local activeBoost = CharacterUtil.getActiveBoost(boostType, false)
					if activeBoost then
						CharacterUtil.removeBoost(activeBoost)
					end
				end
			end

			debug.profileend()
		end))

		SequencerSupport(scope.rootScope, utility, cache)
		return cache
	end)

	--> Setting up this booster now
	scope:attach(booster)

	--> Check for problems
	if not configuration.Mode then
		scope:log({
			"Booster has an unknown Mode and cannot function.",
			`Path: {booster:GetFullName()}`,
			type = "warn",
		})
		return
	end

	if not configuration.Type then
		scope:log({
			"Booster has an unknown Type and cannot function.",
			`Path: {booster:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Main functionality
	local boosterData: Booster = {
		part = booster,
		configuration = configuration,
		startTweenConfig = startTweenConfiguration,
		endTweenConfig = endTweenConfiguration,
		id = HttpService:GenerateGUID(),
	}
	if configuration.Mode == "Default" then
		local function activateBoost()
			if booster:GetAttribute("Activated") == false then
				return
			end

			local boostData = getBoostData(boosterData)
			CharacterUtil.startBoost(boostData)
		end
		cache.activators[booster] = activateBoost
		scope:add(function()
			cache.activators[booster] = nil
		end)

		scope:add(booster.Touched:Connect(function(toucher)
			if not utility.ClientObjects.evaluateToucher(booster, toucher, touchConfiguration) then
				return
			end

			activateBoost()
		end))

		if touchConfiguration.canFlip then
			scope:add(utility.ClientObjects.bindToFlip(booster, activateBoost))
		end
	elseif configuration.Mode == "Zone" then
		table.insert(cache.boosters, boosterData)
	else
		scope:log({
			"Booster has an unknown Mode and cannot function.",
			`Path: {booster:GetFullName()}`,
			type = "warn",
		})
		return
	end
end

return Booster
