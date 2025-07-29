--!strict
--!optimize 2
--@version boostremover-6.0.0
--@creator Camille

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

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

	local CharacterUtil = utility.Character
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, boostRemoverConfig, {
		Type = Config.Type.Some("Speed", "Jump", Config.Type.none),
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, boostRemoverConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

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
	scope:add(boostRemover.Touched:Connect(function(toucher)
		if not utility.ClientObjects.evaluateToucher(boostRemover, toucher, touchConfiguration) then
			return
		end
		if boostRemover:GetAttribute("Activated") == false then
			return
		end

		CharacterUtil.removeBoost(configuration.Type)
	end))
end
