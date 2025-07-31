--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Types = require(Kit.Types)

local KEY_LERP_TIME = 0.25

return function(object: Types.ClientObject)
	local mainModel = object.instance :: BasePart
	local hitbox = mainModel:FindFirstChild("Hitbox") :: BasePart
	local door = mainModel:FindFirstChild("Door") :: BasePart

	hitbox.Transparency = 1

	local connection
	connection = object.trove:Connect(hitbox.Touched, function(otherPart: BasePart)
		if not Utility.Character.isLimb(otherPart) then
			return
		end
		
		local key = Utility.Character.getFirstKeyNode()
		while key and key.value.id ~= mainModel:GetAttribute("KeyId") do
			key = key.next
		end
		
		if not key then 
			return
		end
		
		Utility.Character.removeKeyFromNodeList(key)
		
		local sfx = door:FindFirstChild("Unlock") :: Sound
		if sfx and door:GetAttribute("PlaySound") then 
			sfx:Play() 
		end
		
		connection:Disconnect()
		
		local start = key.value.model:GetPivot()
		local finish = door.CFrame
		local model = key.value.model
		local originalTransparency = door.Transparency
		
		local currentTime = 0
		connection = RunService.RenderStepped:Connect(function(deltaTime)
			currentTime += deltaTime
			local progress = currentTime / KEY_LERP_TIME
			
			model:PivotTo(start:Lerp(finish, progress))
			local transparency = math.lerp(originalTransparency, 1, progress)
			door.Transparency = transparency
			for _, child in door:GetDescendants() do
				if child:IsA("BasePart") then
					child.Transparency = transparency
				end
			end
			
			if progress > 1 then
				model:Destroy()
				door.CanCollide = false
				for _, child in door:GetDescendants() do
					if child:IsA("BasePart") then
						child.CanCollide = false
					end
				end
			end
		end)
	end)
end