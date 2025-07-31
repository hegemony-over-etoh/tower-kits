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

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local mainPart = object.instance :: BasePart

	local function setGravity()
		workspace.Gravity = mainPart:GetAttribute("Gravity")
	end

	object.trove:Connect(mainPart.Touched, function(otherPart: BasePart)
		if not mainPart:GetAttribute("_Active") or not Utility.ClientObjects.isTouchValid(mainPart, otherPart) then
			return
		end

		setGravity()
	end)
	
	object.trove:Connect(object.signals.onTrigger :: any, setGravity)
end