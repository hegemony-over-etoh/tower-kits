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

	local debounce = false
	object.trove:Connect(mainPart.Touched, function(otherPart: BasePart)
		debounce = true
		
		local character = Players.LocalPlayer.Character
		if not character or not Utility.Character.isLimb(otherPart) or not mainPart:GetAttribute("_Active") then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
		if humanoid then
			humanoid.Sit = true
		end
		
		task.delay(mainPart:GetAttribute("TripCooldown"), function()
			debounce = false
		end)
	end)
end