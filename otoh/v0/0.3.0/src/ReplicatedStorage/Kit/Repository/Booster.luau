--!strict
-- junekept 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local mainPart = object.instance :: BasePart

	local function applyBoost()
		local boostType = mainPart:GetAttribute("Type")
		local boostLength = mainPart:GetAttribute("BoostLength")
		if boostLength <= 0 then
			boostLength = nil
		end
		if boostType == "Speed" or boostType == "Both" then
			Utility.Character.setWalkSpeedAtPriority(mainPart:GetAttribute("WalkSpeed"), 3, boostLength)	
		end
		if boostType == "Jump" or boostType == "Both" then
			Utility.Character.setJumpPowerAtPriority(mainPart:GetAttribute("JumpPower"), 3, boostLength)
		end
	end
	
	object.trove:Connect(mainPart.Touched, function(otherPart: BasePart)
		local character = Players.LocalPlayer.Character
		if not mainPart:GetAttribute("_Active") or not Utility.Character.isLimb(otherPart) then
			return
		end

		applyBoost()
	end)
	
	object.trove:Connect(object.signals.onTrigger :: any, applyBoost)
end