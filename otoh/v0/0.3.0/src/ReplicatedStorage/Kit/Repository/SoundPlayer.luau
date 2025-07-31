--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local soundPlayer = object.instance :: BasePart
	local sound = soundPlayer:FindFirstChild("Sound") :: Sound
	if sound.TimeLength > 6 then
		warn(`Sound Player {soundPlayer} using sound effect longer than 6 seconds. `
			.. `If you wish to submit this to OToH, you must provide the audio file in your submission.`)
	end
	
	local function playSound()
		Utility.General.cloneAndPlay(sound, if soundPlayer:GetAttribute("GlobalEmission") then soundPlayer else nil)
		if soundPlayer:GetAttribute("OneTimeUse") then
			object.trove:Destroy()
		end
	end

	local debounce = false
	object.trove:Connect(soundPlayer.Touched, function(otherPart: BasePart)
		if not soundPlayer:GetAttribute("_Active") or debounce or not Utility.ClientObjects.isTouchValid(soundPlayer, otherPart) then
			return
		end
		
		debounce = true
		
		playSound()
		
		task.delay(soundPlayer:GetAttribute("Cooldown"), function()
			debounce = false
		end)
	end)
	
	object.trove:Connect(object.signals.onTrigger :: any, playSound)
end