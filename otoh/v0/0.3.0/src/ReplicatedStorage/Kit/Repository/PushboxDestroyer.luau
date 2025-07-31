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
	local destroyer = object.instance :: BasePart
	
	object.trove:Connect(destroyer.Touched, function(otherPart: BasePart)
		if destroyer:GetAttribute("_Active") and otherPart:HasTag("Pushbox") then
			if not destroyer:GetAttribute("PushboxRequireMatchingId") or destroyer:GetAttribute("Id") == otherPart:GetAttribute("Id") then
				otherPart:Destroy()
			end
		end
	end)
end