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

return {
	behavior = function(object, arguments: {Output: (StringValue | ObjectValue)?})
		local toFormat = object.instance:FindFirstChild("ToFormat")
		local formatValues = {}
		for _, value: any in toFormat:GetChildren() do
			table.insert(formatValues, TriggerFunctions.getVariableValueOrSelf(value).Value)
		end

		local outputString = string.format(object.instance:GetAttribute("FormatString"), table.unpack(formatValues))
		if arguments.Output then
			local output = TriggerFunctions.getVariableValueOrSelf(arguments.Output) :: StringValue
			output.Value = outputString
		else
			print(outputString)
		end
		
		return TriggerFunctions.getDefaultChainList(object)
	end,
	connections = function(object)
		return {
			{signal = object.signals["trigger"]}
		}
	end,
} :: TriggerTypes.TriggerInfo