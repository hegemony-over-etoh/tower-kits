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
	behavior = function(object)		
		local clientObjectValues = object.instance:FindFirstChild("ClientObjects")
		for _, value: any in clientObjectValues:GetChildren() do
			local clientObject = TriggerFunctions.getVariableValueOrSelf(value).Value
			if typeof(clientObject) == "Instance" then
				if clientObject:HasTag("MorpherButton") and clientObject.Parent and clientObject.Parent.Parent then
					Utility.Tower.loadedClientObjects[clientObject.Parent.Parent].signals.onTrigger:Fire(clientObject)
				else
					Utility.Tower.loadedClientObjects[clientObject].signals.onTrigger:Fire()
				end
			elseif typeof(clientObject) == "string" then
				for _, clientObject in CollectionService:GetTagged(clientObject) do
					Utility.Tower.loadedClientObjects[clientObject].signals.onTrigger:Fire()
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