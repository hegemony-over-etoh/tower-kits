--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local LemonSignal = require(Libraries.LemonSignal)
local Utility = require(Kit.Utility)

local TriggerBase = script.Parent.Parent
local TriggerFunctions = require(TriggerBase.TriggerFunctions)

local Types = require(Kit.Types)
local TriggerTypes = require(TriggerBase.TriggerTypes)

-- easiest way to get a completely unique value
local IGNORE_DEFAULT_SET = newproxy()

local initialHumanoid: Humanoid = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
if not initialHumanoid then
	initialHumanoid = Players.LocalPlayer.CharacterAdded:Wait():FindFirstChild("Humanoid")
end

local defaultSettings: {[string]: any} = {
	CameraOffset = initialHumanoid.CameraOffset,
	HipHeight = initialHumanoid.HipHeight,
	MaxHealth = initialHumanoid.MaxHealth,
	PlatformStand = initialHumanoid.PlatformStand,
	RequiresNeck = initialHumanoid.RequiresNeck,
	Sit = initialHumanoid.Sit
}

local tweenableProperties = {
	CameraOffset = true,
	HipHeight = true,
	MaxHealth = true,
}

return {
	behavior = function(object, arguments: {Tween: BoolValue, TweenDuration: NumberValue, TweenEasingStyle: StringValue, TweenEasingDirection: StringValue})
		local targets = object.instance:FindFirstChild("Targets")
		local properties = object.instance:FindFirstChild("Properties")
		local attributes = object.instance:FindFirstChild("Attributes")
		local tags = object.instance:FindFirstChild("Tags")
		
		local humanoid = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
		
		local tweenInfo: TweenInfo? = nil
		if TriggerFunctions.getVariableValueOrSelf(arguments.Tween, true).Value then
			tweenInfo = TweenInfo.new(
				TriggerFunctions.getVariableValueOrSelf(arguments.TweenDuration).Value :: number,
				Enum.EasingStyle:FromName(TriggerFunctions.getVariableValueOrSelf(arguments.TweenEasingStyle).Value :: string),
				Enum.EasingDirection:FromName(TriggerFunctions.getVariableValueOrSelf(arguments.TweenEasingDirection).Value :: string)
			)
		end
		
		local tweenTable = {}
		for property, value in defaultSettings do
			-- I <3 REAL ESTATE
			local propertyValue = properties:FindFirstChild(property) :: TriggerTypes.ActualValueBase
			if propertyValue then
				local value = propertyValue.Value
				if typeof(humanoid[property]) == "Enum" then
					value = humanoid[property].EnumType:FromName(value)
				end
				
				if tweenInfo and tweenableProperties[property] then
					tweenTable[property] = value
				else
					humanoid[property] = value
				end
			elseif value ~= IGNORE_DEFAULT_SET then
				if tweenInfo and tweenableProperties[property] then
					tweenTable[property] = value
				else
					humanoid[property] = value
				end
			end
		end
		if tweenInfo then
			TweenService:Create(humanoid, tweenInfo, tweenTable):Play()
		end
		
		return TriggerFunctions.getDefaultChainList(object)
	end,
	connections = function(object)
		return {
			{signal = object.signals["trigger"]}
		}
	end,
} :: TriggerTypes.TriggerInfo