--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local LemonSignal = require(Libraries.LemonSignal)
local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local mainPart = object.instance :: BasePart
	
	object.trove:Connect(mainPart.Touched, function(otherPart: BasePart)
		print(otherPart)
		local character = Players.LocalPlayer.Character
		if not (Utility.Character.isLimb(otherPart) or otherPart:HasTag("Balloon")) or not mainPart:GetAttribute("_Active") then
			return
		end
		
		local scriptString = Utility.Character.getDismountScript()
		
		if mainPart:GetAttribute(`Dismount{scriptString}`) then
			Utility.Character.dismountConstraintObject(not mainPart:GetAttribute("JumpOnDismount"))
		end
	end)
end