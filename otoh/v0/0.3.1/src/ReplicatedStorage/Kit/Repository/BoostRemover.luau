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

	object.trove:Connect(mainPart.Touched, function(otherPart: BasePart)
		local character = Players.LocalPlayer.Character
		if not mainPart:GetAttribute("_Active") or not Utility.Character.isLimb(otherPart) then
			return
		end

		local boostType = mainPart:GetAttribute("Type")
		if boostType == "Speed" or boostType == "Both" then
			Utility.Character.removeWalkSpeedAtPriority(3)
		end
		if boostType == "Jump" or boostType == "Both" then
			Utility.Character.removeJumpPowerAtPriority(3)
		end
	end)
end