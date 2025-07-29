--!strict
--!optimize 2
--@version boostremover-6.0.0
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local BoostRemover = {
	CanQueue = true,
	RunOnStart = false,
}

local REMOVER_CONFIG_TEMPLATE
function BoostRemover.Init(utility: _T.Utility)
	local Config = utility.Config
	REMOVER_CONFIG_TEMPLATE = {
		Type = Config.Type.Some("Speed", "Jump", Config.Type.none),
	}
end

local SequencerSupport = require(script.SequencerSupport)
local function setupCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [BasePart]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

function BoostRemover.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local boostRemoverConfig = scope.instance
	if not boostRemoverConfig then
		return
	end

	local boostRemover = boostRemoverConfig.Parent
	if not boostRemover or not boostRemover:IsA("BasePart") then
		return
	end

	local CharacterUtil = utility.Character
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, boostRemoverConfig, REMOVER_CONFIG_TEMPLATE):ObserveChanges()
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
		if boostRemover:GetAttribute("Activated") == false then
			return
		end

		local activeBoost = CharacterUtil.getActiveBoost(configuration.Type, false)
		if activeBoost then
			CharacterUtil.removeBoost(activeBoost)
		end
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, setupCache)
	cache[boostRemover] = removeBoost
	scope:add(function()
		cache[boostRemover] = nil
		cache = nil :: any
	end)

	--> Activation
	scope:add(boostRemover.Touched:Connect(function(toucher)
		if not utility.ClientObjects.evaluateToucher(boostRemover, toucher, touchConfiguration) then
			return
		end

		removeBoost()
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(boostRemover, removeBoost))
	end
end

return BoostRemover
