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

local ARITHMETIC_TABLE: {[string]: (number, number) -> number} = {
	add = function(a, b) return a + b end,
	subtract = function(a, b) return a - b end,
	multiply = function(a, b) return a * b end,
	divide = function(a, b) return a / b end,
	floordivide = function(a, b) return a // b end,
	exponent = function(a, b) return a ^ b end,
	modulo = function(a, b) return a % b end
}

return {
	behavior = function(object, arguments: {Left: NumericOrVariable, Right: NumericOrVariable, Output: ObjectValue})
		local left = TriggerFunctions.getVariableValueOrSelf(arguments.Left, true) :: NumericValue
		local right = TriggerFunctions.getVariableValueOrSelf(arguments.Right, true) :: NumericValue
		-- cast to NumberValue here because roblox is suuper weird about union types having their properties set lol
		local output = TriggerFunctions.getVariableValueOrSelf(arguments.Output, true) :: NumberValue
		
		local arithmeticType = string.lower(object.instance:GetAttribute("ArithmeticType"))
		output.Value = ARITHMETIC_TABLE[arithmeticType](left.Value, right.Value)
		
		return TriggerFunctions.getDefaultChainList(object)
	end,
	connections = function(object)
		return {
			{signal = object.signals["trigger"]}
		}
	end,
} :: TriggerTypes.TriggerInfo