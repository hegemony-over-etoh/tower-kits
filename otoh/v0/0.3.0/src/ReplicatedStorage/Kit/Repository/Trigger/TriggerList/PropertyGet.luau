--!strict
-- yo roblox what's the lint code for dynamic instance property accessing
--!nolint
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
	behavior = function(object, arguments: {Target: ObjectValue, Property: StringValue | ObjectValue, IsAttribute: BoolValue | ObjectValue, Output: ObjectValue})
		local target = TriggerFunctions.getVariableValueOrSelf(arguments.Target) :: ObjectValue
		local property = TriggerFunctions.getVariableValueOrSelf(arguments.Property) :: StringValue
		local isAttribute = TriggerFunctions.getVariableValueOrSelf(arguments.IsAttribute) :: BoolValue
		local output = TriggerFunctions.getVariableValueOrSelf(arguments.Output) :: TriggerTypes.ActualValueBase
		
		local target = target.Value :: Instance
		
		local propertyName = property.Value
		local propertyValue = if isAttribute.Value then target:GetAttribute(propertyName) else (target :: any)[propertyName]
		
		-- jank moment
		;(output :: any).Value = propertyValue

		return TriggerFunctions.getDefaultChainList(object)
	end,
	connections = function(object)
		return {
			{signal = object.signals["trigger"]}
		}
	end,
} :: TriggerTypes.TriggerInfo