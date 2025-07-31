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

local COMPARISON_TABLE: {[string]: (any, any) -> boolean} = {
	["=="] = function(a, b) return a == b end,
	["~="] = function(a, b) return a ~= b end,
	[">"] = function(a, b) return a > b end,
	[">="] = function(a, b) return a >= b end,
	["<"] = function(a, b) return a < b end,
	["<="] = function(a, b) return a <= b end,
	["and"] = function(a, b) return a and b end,
	["or"] = function(a, b) return a or b end,
	["xor"] = function(a, b) return (a or b) and not (a and b) end,
	["nand"] = function(a, b) return not (a and b) end,
	["nor"] = function(a, b) return not (a or b) end,
	["xnor"] = function(a, b) return (a and b) or (not a and not b) end
}

return {
	behavior = function(object, arguments: {Left: TriggerTypes.ActualValueBase, Right: TriggerTypes.ActualValueBase})
		local left = TriggerFunctions.getVariableValueOrSelf(arguments.Left, false)
		local right = TriggerFunctions.getVariableValueOrSelf(arguments.Right, false)
		
		local comparisonType = string.lower(object.instance:GetAttribute("ComparisonType"))
		
		local resultFolderName = if COMPARISON_TABLE[comparisonType](left.Value, right.Value) then "True" else "False"
		local resultFolder = object.instance:FindFirstChild(resultFolderName):GetChildren()
		local chainFolder = object.instance:FindFirstChild("Chain"):GetChildren()
		
		table.move(resultFolder, 1, #resultFolder, #chainFolder + 1, chainFolder)
		return resultFolder :: any
	end,
	connections = function(object)
		return {
			{signal = object.signals["trigger"]}
		}
	end,
} :: TriggerTypes.TriggerInfo