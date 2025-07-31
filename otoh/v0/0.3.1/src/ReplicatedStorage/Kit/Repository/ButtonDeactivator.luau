--!strict
-- junekept 2025
-- this script was originally made for OToH

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local LemonSignal = require(Libraries.LemonSignal)
local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local deactivator = object.instance :: BasePart
	
	local function deactivate()
		for _, button in CollectionService:GetTagged("Button_" .. deactivator:GetAttribute("ButtonGroupId")) do
			button:SetAttribute("Pressed", false)
		end
	end

	object.trove:Connect(deactivator.Touched, function(otherPart: BasePart) 
		if not deactivator:GetAttribute("_Active") or not Utility.ClientObjects.isTouchValid(deactivator, otherPart) then
			return
		end

		deactivate()
	end)
	
	object.trove:Connect(object.signals.onTrigger :: any, deactivate)
end