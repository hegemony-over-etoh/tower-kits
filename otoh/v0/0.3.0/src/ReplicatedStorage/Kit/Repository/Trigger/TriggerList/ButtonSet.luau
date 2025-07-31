--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local LemonSignal = require(Libraries.LemonSignal)
local Utility = require(Kit.Utility)

local TriggerBase = script.Parent.Parent
local TriggerFunctions = require(TriggerBase.TriggerFunctions)

local Types = require(Kit.Types)
local TriggerTypes = require(TriggerBase.TriggerTypes)

return {
	behavior = function(object, arguments: {Pressed: BoolValue | ObjectValue})
		local pressed: boolean = TriggerFunctions.getVariableValueOrSelf(arguments.Pressed, true).Value :: boolean
		
		local buttonValues = object.instance:FindFirstChild("Buttons")
		for _, value: any in buttonValues:GetChildren() do
			local button = TriggerFunctions.getVariableValueOrSelf(value).Value
			if typeof(button) == "Instance" then
				button:SetAttribute("Pressed", pressed)
			elseif typeof(button) == "string" then
				for _, button in CollectionService:GetTagged(`Button_{button}`) do
					button:SetAttribute("Pressed", pressed)
				end
			end
		end
		
		return TriggerFunctions.getDefaultChainList(object)
	end,
	connections = function(object)
		return {
			{signal = object.signals["trigger"]}
		}
	end,
} :: TriggerTypes.TriggerInfo