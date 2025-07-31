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
	behavior = function(object)
		local targets = object.instance:FindFirstChild("Targets")
		local properties = object.instance:FindFirstChild("Properties")
		local attributes = object.instance:FindFirstChild("Attributes")
		local tags = object.instance:FindFirstChild("Tags")
		
		for _, targetValue: ObjectValue in targets:GetChildren() :: any do
			local target = targetValue.Value :: Instance
			-- I <3 REAL ESTATE
			for _, propertyValue: TriggerTypes.ActualValueBase in properties:GetChildren() :: any do
				local value = propertyValue.Value
				if typeof((target :: any)[propertyValue.Name]) == "Enum" then
					value = (target :: any)[propertyValue.Name].EnumType:FromName(value)
				end
				
				(target :: any)[propertyValue.Name] = value
			end
			
			for _, attributeValue: TriggerTypes.ActualValueBase in attributes:GetChildren() :: any do
				target:SetAttribute(attributeValue.Name, attributeValue.Value)
			end
			
			for _, tagValue: BoolValue in tags:GetChildren() :: any do
				if tagValue.Value then
					target:AddTag(tagValue.Name)
				else
					target:RemoveTag(tagValue.Name)
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