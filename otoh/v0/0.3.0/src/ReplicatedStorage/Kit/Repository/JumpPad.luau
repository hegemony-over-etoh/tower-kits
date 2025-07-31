--!strict
-- junekept 2025
-- this script was originally made for OToH

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local jumpPad = object.instance :: BasePart
	
	local debounce = false
	object.trove:Connect(jumpPad.Touched, function(otherPart: BasePart)
		if not jumpPad:GetAttribute("_Active") or debounce then
			return
		end
		
		debounce = true
		
		local character: Types.Character = Players.LocalPlayer.Character
		local partToBoost
		if jumpPad:GetAttribute("SupportPlayers") and Utility.Character.isLimb(otherPart) then
			partToBoost = character.HumanoidRootPart
		elseif jumpPad:GetAttribute("SupportPushboxes") and otherPart:HasTag("Pushbox") then
			partToBoost = otherPart
		end
		
		if partToBoost then
			partToBoost.AssemblyLinearVelocity = jumpPad.CFrame.RightVector * jumpPad:GetAttribute("Power")
			
			if jumpPad:GetAttribute("PlaySound") then 
				Utility.General.cloneAndPlay(jumpPad:FindFirstChild("Sfx") :: Sound) 
			end
			
			-- boost players on the immediate next heartbeat to prevent velocity dampening from hitting the ground
			-- the difference in height should be miniscule enough to not matter
			-- I hate this btw
			task.wait()
			partToBoost.AssemblyLinearVelocity = jumpPad.CFrame.RightVector * jumpPad:GetAttribute("Power")
		end
		
		-- stop people from bouncing upwards like 200 times
		task.delay(0.1, function()
			debounce = false
		end)
	end)
end