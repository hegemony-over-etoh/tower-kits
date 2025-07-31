--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local LemonSignal = require(Libraries.LemonSignal)
local Utility = require(Kit.Utility)

local TriggerBase = script.Parent.Parent
local TriggerFunctions = require(TriggerBase.TriggerFunctions)

local Types = require(Kit.Types)
local TriggerTypes = require(TriggerBase.TriggerTypes)

type NumericValue = TriggerTypes.NumericValue
type NumericOrVariable = ObjectValue | NumericValue

return {
	behavior = function(object, arguments: {Duration: NumericOrVariable})
		local duration = TriggerFunctions.getVariableValueOrSelf(arguments.Duration) :: NumericValue
		
		-- literally just wait lol
		task.wait(duration.Value)
		
		return TriggerFunctions.getDefaultChainList(object)
	end,
	connections = function(object)
		return {
			{signal = object.signals["trigger"]}
		}
	end,
} :: TriggerTypes.TriggerInfo