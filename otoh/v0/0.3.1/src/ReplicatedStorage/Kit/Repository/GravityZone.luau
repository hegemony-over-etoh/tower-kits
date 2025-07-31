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

local LemonSignal = require(Libraries.LemonSignal)

-- trying to be 100% sure that no memory leak will happen here
local monitoredParts = setmetatable({}, {__mode = "k"})
return function(object: Types.ClientObject)
	local gravityZone = object.instance :: BasePart
	gravityZone:AddTag("GravityZone")
	
	object.trove:Connect(gravityZone.Touched, function(otherPart: BasePart)
		if not gravityZone:GetAttribute("_Active") or not Utility.ClientObjects.isTouchValid(gravityZone, otherPart) or monitoredParts[otherPart]
			or (otherPart.Massless and otherPart.AssemblyRootPart ~= otherPart) or otherPart.Anchored	
		then
			return
		end
		
		monitoredParts[otherPart] = RunService.PreSimulation:Connect(function(deltaTimeSim: number)
			local overlapParams = OverlapParams.new()
			overlapParams.FilterType = Enum.RaycastFilterType.Include
			overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("GravityZone")
			
			local function removePart()
				monitoredParts[otherPart]:Disconnect()
				monitoredParts[otherPart] = nil -- is this necessary?
			end
			
			local intersectingParts = workspace:GetPartsInPart(otherPart, overlapParams)
			if #intersectingParts == 0 then
				removePart()
			else
				local currentPriority = -math.huge
				local targetPart: BasePart = nil
				for _, part in intersectingParts do
					local priority = part:GetAttribute("Priority")
					if priority > currentPriority and Utility.ClientObjects.isTouchValid(part, otherPart) then
						currentPriority = priority
						targetPart = part
					end
				end
				if targetPart then
					local gravityCoefficient = Vector3.yAxis * otherPart.Mass * deltaTimeSim
					-- gravity is positive to counteract workspace gravity, zoneGravity is negative because it's applying downwards
					otherPart:ApplyImpulse(gravityCoefficient * workspace.Gravity - gravityCoefficient * targetPart:GetAttribute("Gravity"))
				else
					removePart()
				end
			end
		end)
	end)

	--[[
	object.trove:Connect(RunService.PreSimulation, function(deltaTimeSim: number)
		local gravity = workspace.Gravity
		local zoneGravity = gravityZone:GetAttribute("Gravity")
		-- why does roblox make functions always return `Instance` instead of what they actually return lol???
		-- like this is 100% guarunteed to return BaseParts but noo
		for _, part: BasePart in workspace:GetPartsInPart(gravityZone) :: any do
			-- parts that are their own root part cannot be made massless
			if not (part.Massless and part.AssemblyRootPart ~= part) and not part.Anchored then
				local gravityCoefficient = Vector3.yAxis * part.Mass * deltaTimeSim
				-- gravity is positive to counteract workspace gravity, zoneGravity is negative because it's applying downwards
				part:ApplyImpulse(gravityCoefficient * gravity - gravityCoefficient * zoneGravity)
			end
		end
	end) ]]
end