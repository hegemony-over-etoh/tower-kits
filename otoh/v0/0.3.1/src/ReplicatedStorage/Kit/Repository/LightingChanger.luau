--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local LemonSignal = require(Libraries.LemonSignal)

local Types = require(Kit.Types)

local CONFIGURABLE_PROPERTIES: {[string]: {string}} = {
	["ColorCorrectionEffect"] = {"Brightness", "Contrast", "Saturation", "TintColor"},  
	["BlurEffect"] = {"Size"},
	["Lighting"] = {"Ambient", "OutdoorAmbient", "FogEnd", "FogStart", "FogColor", "ClockTime", "Brightness"},
	["BloomEffect"] = {"Intensity", "Size", "Threshold"},
	["DepthOfFieldEffect"] = {"FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
}

local defaultProperties = {}
for objectName, properties in CONFIGURABLE_PROPERTIES do
	local object = if objectName == "Lighting" then Lighting else Lighting:FindFirstChild(`LightingChanger_{objectName}`)
	if not object then
		object = Instance.new(objectName) :: Instance
		if object:IsA("BlurEffect") then
			object.Size = 0
		elseif object:IsA("DepthOfFieldEffect") then
			object.FarIntensity = 0
			object.NearIntensity = 0
		elseif object:IsA("BloomEffect") then
			object.Intensity = 1
			object.Size = 24
			object.Threshold = 2
		end
		object.Name = `LightingChanger_{objectName}`
		object.Parent = Lighting
	end
	
	defaultProperties[objectName] = {}
	for _, property in properties do
		defaultProperties[objectName][property] = object[property]
	end
end

-- reset lighting to original state on reset to prevent respawning with wonky lighting
Players.LocalPlayer.CharacterAdded:Connect(function()
	for objectName, properties in defaultProperties do
		local object = if objectName == "Lighting" then Lighting else Lighting:FindFirstChild(`LightingChanger_{objectName}`)
		for property, value in properties do
			object[property] = value
		end
	end
end)

local activeTweens: {[string]: Tween} = {}
return function(object: Types.ClientObject)
	local changer = object.instance :: BasePart
	
	local function changeLighting()
		local changerType = changer:GetAttribute("Type")
		if activeTweens[changerType] then
			activeTweens[changerType]:Cancel()
		end
		
		local object = if changerType == "Lighting" then Lighting else Lighting:FindFirstChild(`LightingChanger_{changerType}`)
		local editableProperties = CONFIGURABLE_PROPERTIES[changerType]

		local tweenProperties = {}
		for _, property in editableProperties do
			tweenProperties[property] = changer:GetAttribute(`Property_{property}`) or defaultProperties[changerType][property]
		end

		local tweenTime = changer:GetAttribute("TransitionTime")
		local tweenStyle = changer:GetAttribute("TransitionEasingStyle")
		local tweenDirection = changer:GetAttribute("TransitionEasingDirection")
		activeTweens[changerType] = TweenService:Create(object, TweenInfo.new(tweenTime, tweenStyle, tweenDirection), tweenProperties)
		activeTweens[changerType]:Play()
	end
	
	object.trove:Connect(changer.Touched, function(otherPart: BasePart)
		if not changer:GetAttribute("_Active") or not Utility.ClientObjects.isTouchValid(changer, otherPart) then
			return
		end
		
		changeLighting()
	end)
	
	object.trove:Connect(object.signals.onTrigger :: any, changeLighting)
end