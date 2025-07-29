--!strict
--!optimize 2
--@version booster-6.0.0
--@creator Camille

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

type Booster = {
	part: BasePart,
	configuration: { [string]: any },
	startTweenConfig: { [string]: any },
	endTweenConfig: { [string]: any },
	id: string,
}

type BoosterZoneCache = {
	boosters: { Booster },
	activeBoosters: { [string]: Booster? },
}

return function(scope: _T.Scope)
	--> Setup
	local utility = scope:utility()
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
	local configuration = Config.GetConfig(scope, boosterConfig, {
		Mode = Config.Type.Some("Default", "Zone", Config.Type.none),
		Type = Config.Type.Some("Speed", "Jump", Config.Type.none),
		Duration = 5,
		Power = 50,
		TimerDecimals = 1,
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, boosterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

	local startTweenConfiguration =
		Config.GetConfig(scope, boosterConfig:FindFirstChild("StartTweenConfiguration"), Config.TWEEN_CONFIG)
			:CheckForChanges()
	local endTweenConfiguration =
		Config.GetConfig(scope, boosterConfig:FindFirstChild("EndTweenConfiguration"), Config.TWEEN_CONFIG)
			:CheckForChanges()

	--> Functions
	local function getBoostData(booster: Booster)
		return {
			startTime = os.clock(),

			mode = booster.configuration.Mode,
			type = booster.configuration.Type,
			power = booster.configuration.Power,
			duration = booster.configuration.Duration,
			timerDecimals = booster.configuration.TimerDecimals,
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
		}
	end

	--> Cache system and main loop for zone boosters
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.CollisionGroup = ""
	CharacterUtil.getHitbox("StaticWholeBody", overlapParams)

	local cache = utility.Scope.getCached(scope, scope.scriptPath, function()
		local cache: BoosterZoneCache = {
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

			-- cap loop to 60fps
			local currentTick = os.clock()
			if currentTick - lastTick < fpsCap then
				return
			end
			lastTick = currentTick

			if isTableEmpty(cache.boosters) then
				return
			end

			-- get touching parts and determine if a boost pad is being touched
			local touchingBoosters: { Booster } = {}
			for _, booster in cache.boosters do
				if
					#workspace:GetPartsInPart(booster.part, overlapParams) > 0
					and booster.part:GetAttribute("Activated") ~= false
				then
					table.insert(touchingBoosters, booster)
				end
			end

			-- activate boost if touching
			local boostTypesFound = {}

			for _, pad in touchingBoosters do
				boostTypesFound[pad.configuration.Type] = true

				local activeBooster = cache.activeBoosters[pad.configuration.Type]
				if activeBooster and activeBooster.id ~= pad.id or not activeBooster then
					cache.activeBoosters[pad.configuration.Type] = pad

					local boostData = getBoostData(pad)
					CharacterUtil.startBoost(boostData)
				end
			end

			--if not touching, deactivate boost
			for padType, pad in cache.activeBoosters do
				if pad and not boostTypesFound[padType] then
					cache.activeBoosters[padType] = nil
					CharacterUtil.removeBoost(padType)
				end
			end

			debug.profileend()
		end))

		return cache
	end)

	--> setting up this booster now
	scope:attach(booster)

	-- check for problems
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
		scope:add(booster.Touched:Connect(function(toucher)
			if not utility.ClientObjects.evaluateToucher(booster, toucher, touchConfiguration) then
				return
			end
			if booster:GetAttribute("Activated") == false then
				return
			end

			local boostData = getBoostData(boosterData)
			CharacterUtil.startBoost(boostData)
		end))
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
