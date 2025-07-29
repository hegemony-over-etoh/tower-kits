--!strict
--!optimize 2
-- By @synnwave (09/12/24 DD/MM/YY)

--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local Framework = ReplicatedStorage.Framework
local _TDefs = require(script.TypeDefs)

local VALID_KEYCODES = { Enum.KeyCode.F, Enum.KeyCode.ButtonX }
local DEFAULT_FLIP_SOUND = script:WaitForChild("DoNotChange")

local PARAMS = OverlapParams.new()
PARAMS.CollisionGroup = "" -- disable the collisiongroup check
-- or else it won't work with collisiongroups other than Default

local FlipManager = {
	__initialized = false,
	__callbacks = {},
} :: _TDefs.FlipManager

local localPlayer = Players.LocalPlayer
function FlipManager:Flip()
	local character = localPlayer.Character
	if not character then
		return
	end
	local torso = character:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end

	for _, touchingPart: BasePart in workspace:GetPartsInPart(torso, PARAMS) do
		if
			not (
				(touchingPart:HasTag("CanFlip") or touchingPart:FindFirstChild("CanFlip"))
				or FlipManager.__callbacks[touchingPart] ~= nil
			)
		then
			continue
		end
		if touchingPart:GetAttribute("Activated") == false then
			return
		end

		local teleportPart = touchingPart
		local teleportToObject = touchingPart:FindFirstChild("TeleToObject")
		if
			typeof(teleportToObject) == "Instance"
			and teleportToObject:IsA("ObjectValue")
			and teleportToObject.Value
			and teleportToObject.Value:IsA("BasePart")
		then
			teleportPart = teleportToObject.Value
		end

		if not touchingPart:HasTag("DoNotFlipPlayer") then
			local offsetFromPart = touchingPart.CFrame:ToObjectSpace(torso.CFrame)
			torso.CFrame = (teleportPart.CFrame * CFrame.Angles(0, math.pi, 0)) * offsetFromPart
		end

		local callbacks = FlipManager.__callbacks[touchingPart]
		if callbacks then
			for _, callback in callbacks do
				if typeof(callback) == "function" then
					task.spawn(callback)
				end
			end
		end

		local sound = (touchingPart:FindFirstChild("FlipSound") or DEFAULT_FLIP_SOUND):Clone()
		sound.Parent = teleportPart
		sound:Play()
		Debris:AddItem(sound, 0.8)
	end
end

local function doNothing() end

--[=[
	@within FlipManager
	
	Binds the `callback` function to the `part`, executing the callback when
	the player performs a corner flip on the `part`.
]=]
function FlipManager:BindToFlip(part, callback)
	if not (typeof(part) == "Instance" and part:IsA("BasePart")) then
		return doNothing
	end
	if typeof(callback) ~= "function" then
		return doNothing
	end

	local callbacks = FlipManager.__callbacks
	local callbackID: any = HttpService:GenerateGUID()
	if not callbacks[part] then
		callbacks[part] = {}
	end
	callbacks[part][callbackID] = callback

	return function()
		if not callbackID then
			return
		end
		callbacks[part][callbackID] = nil
		callbackID = nil
		if next(callbacks[part]) == nil then
			callbacks[part] = nil
		end
	end
end

function FlipManager:Init()
	if self.__initialized then
		return FlipManager
	end
	self.__initialized = true

	local ChatInputBarConfiguration =
		TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration") :: ChatInputBarConfiguration
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if
			(gameProcessedEvent or ChatInputBarConfiguration.IsFocused)
			and not table.find(VALID_KEYCODES, input.KeyCode)
		then
			return
		end
		FlipManager:Flip()
	end)
	UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
		if processedByUI then
			return
		end
		FlipManager:Flip()
	end)

	return FlipManager
end

return FlipManager
