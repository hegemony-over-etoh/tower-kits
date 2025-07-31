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

local initialCamera = workspace.CurrentCamera
local defaultSettings: {[string]: any} = {
	-- don't set these two to a default, the default camera mode should update these automatically anyways
	CFrame = IGNORE_DEFAULT_SET,
	Focus = IGNORE_DEFAULT_SET,
	-- necessary for resets to not screw up (dead humnaoid = oh no now it's nil), 
	-- otherwise the "default" would just be it's current subject
	CameraSubject = function()
		return Players.LocalPlayer.Character:FindFirstChild("Humanoid")
	end,
	CameraType = initialCamera.CameraType,
	DiagonalFieldOfView = initialCamera.DiagonalFieldOfView,
	FieldOfView = initialCamera.FieldOfView,
	FieldOfViewMode = initialCamera.FieldOfViewMode,
	-- this shouldn't be reset to default since the other FOV attributes can do it instead
	MaxAxisFieldOfView = IGNORE_DEFAULT_SET
}

local tweenableProperties = {
	CFrame = true,
	Focus = true,
	DiagonalFieldOfView = true,
	FieldOfView = true,
	MaxAxisFieldOfView = true
}

return {
	behavior = function(object, arguments: {Tween: BoolValue, TweenDuration: NumberValue, TweenEasingStyle: StringValue, TweenEasingDirection: StringValue})
		local targets = object.instance:FindFirstChild("Targets")
		local properties = object.instance:FindFirstChild("Properties")
		local attributes = object.instance:FindFirstChild("Attributes")
		local tags = object.instance:FindFirstChild("Tags")
		
		local tweenInfo: TweenInfo? = nil
		if TriggerFunctions.getVariableValueOrSelf(arguments.Tween, true).Value then
			tweenInfo = TweenInfo.new(
				TriggerFunctions.getVariableValueOrSelf(arguments.TweenDuration).Value :: number,
				Enum.EasingStyle:FromName(TriggerFunctions.getVariableValueOrSelf(arguments.TweenEasingStyle).Value :: string),
				Enum.EasingDirection:FromName(TriggerFunctions.getVariableValueOrSelf(arguments.TweenEasingDirection).Value :: string)
			)
		end
		
		-- yeah this is kinda just a property changer but for the camera
		-- yeah I'm lazy
		-- nvm it was more complicated than I thought it would be LOL
		local targetFovValue = properties:FindFirstChild("CameraType") :: StringValue
		local targetFovMode = if targetFovValue then Enum.FieldOfViewMode:FromName(targetFovValue.Value) else workspace.CurrentCamera.FieldOfViewMode
		
		local tweenTable = {}
		for property, value in defaultSettings do
			-- I <3 REAL ESTATE
			local propertyValue = properties:FindFirstChild(property) :: TriggerTypes.ActualValueBase
			if propertyValue then
				local value = propertyValue.Value
				if typeof(workspace.CurrentCamera[property]) == "Enum" then
					value = workspace.CurrentCamera[property].EnumType:FromName(value)
				end
				
				if tweenInfo and tweenableProperties[property] then
					tweenTable[property] = value
				else
					workspace.CurrentCamera[property] = value
				end
			elseif value ~= IGNORE_DEFAULT_SET then
				-- this is so jank but I don't care 
				-- I can't just "set one instead of both" for defaults because otherwise it will mess up on diagonal fov mode
				if property == "FieldOfView" and targetFovMode == Enum.FieldOfViewMode.Diagonal then
					continue
				elseif property == "DiagonalFieldOfView" and targetFovMode == Enum.FieldOfViewMode.Vertical then
					continue
				end
				
				local value = if typeof(value) == "function" then value() else value
				if tweenInfo and tweenableProperties[property] then
					tweenTable[property] = value
				else
					workspace.CurrentCamera[property] = value
				end
			end
		end
		if tweenInfo then
			TweenService:Create(workspace.CurrentCamera, tweenInfo, tweenTable):Play()
		end
		
		return TriggerFunctions.getDefaultChainList(object)
	end,
	connections = function(object)
		return {
			{signal = object.signals["trigger"]}
		}
	end,
} :: TriggerTypes.TriggerInfo