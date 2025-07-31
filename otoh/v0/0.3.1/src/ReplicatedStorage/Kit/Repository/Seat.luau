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

local seated = false
return function(object: Types.ClientObject)
	local seat = object.instance :: BasePart
	
	local debounce = false
	object.trove:Connect(seat.Touched, function(otherPart: BasePart)
		if not seat:GetAttribute("_Active") or not Utility.Character.isLimb(otherPart) or debounce or seated then
			return
		end
		
		local character = Players.LocalPlayer.Character :: Types.Character
		local rootPart = character.HumanoidRootPart
		local humanoid = character.Humanoid
		if humanoid.Health <= 0 then
			return
		end
		
		debounce = true
		seated = true
		
		-- magic offset oooo
		rootPart.CFrame = seat.CFrame + Vector3.new(0, seat.Size.Y / 2 + 1.5, 0)
		humanoid.Sit = true
		
		local weldTrove = object.trove:Extend()
		weldTrove:Add(Utility.General.weld(seat, rootPart))
		
		local function dismount()
			seated = false
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		
		weldTrove:Connect(UserInputService.JumpRequest, function() weldTrove:Destroy() end)
		weldTrove:Connect(humanoid.Died, function() weldTrove:Destroy() end)
		weldTrove:Add(dismount)
		
		task.delay(seat:GetAttribute("SitCooldown"), function()
			debounce = false
		end)
	end)
end