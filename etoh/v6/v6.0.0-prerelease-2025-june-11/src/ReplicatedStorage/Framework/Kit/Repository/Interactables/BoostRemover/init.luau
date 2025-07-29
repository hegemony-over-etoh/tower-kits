--!strict
--!optimize 2
--@version boostremover-6.0.0
--@creator Camille

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local SequencerSupport = require(script.SequencerSupport)

return function(scope: _T.Scope)
	--> Setup
	local utility = scope:utility()
	local boostRemoverConfig = scope.instance
	if not boostRemoverConfig then
		return
	end

	local boostRemover = boostRemoverConfig.Parent
	if not boostRemover or not boostRemover:IsA("BasePart") then
		return
	end

	local cache = utility.Scope.getCached(scope, scope.scriptPath, function()
		local cache = {} :: { [BasePart]: () -> () }
		SequencerSupport(scope.rootScope, cache)
		return cache
	end)

	local CharacterUtil = utility.Character
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, boostRemoverConfig, {
		Type = Config.Type.Some("Speed", "Jump", Config.Type.none),
	}):ObserveChanges()

	local touchConfiguration =
		Config.GetConfig(scope, boostRemoverConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	scope:attach(boostRemover)

	--> Check for problems
	if not configuration.Type then
		scope:log({
			"BoostRemover has an unknown Type and cannot function.",
			`Path: {boostRemover:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Main functionality
	local function removeBoost()
		local activeBoost = CharacterUtil.getActiveBoost(configuration.Type, false)
		if activeBoost then
			CharacterUtil.removeBoost(activeBoost)
		end
	end

	cache[boostRemover] = removeBoost
	scope:add(function()
		cache[boostRemover] = nil
	end)

	scope:add(boostRemover.Touched:Connect(function(toucher)
		if
			boostRemover:GetAttribute("Activated") == false
			or not utility.ClientObjects.evaluateToucher(boostRemover, toucher, touchConfiguration)
		then
			return
		end

		removeBoost()
	end))
end
