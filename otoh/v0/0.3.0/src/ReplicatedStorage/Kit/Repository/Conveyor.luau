--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Utility = require(Kit.Utility)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local mainPart = object.instance :: BasePart
	local beam = mainPart:FindFirstChild("BeamAttachment"):FindFirstChild("Beam") :: Beam
	
	local function updateVelocity()
		mainPart.AssemblyLinearVelocity = mainPart.CFrame.LookVector * mainPart:GetAttribute("Speed")
	end
	local function updateSpeed()
		-- do some math to make the beam move at the exact speed the player would assuming no external force
		beam.TextureSpeed = mainPart:GetAttribute("Speed") / beam.TextureLength
		if mainPart.Anchored then
			updateVelocity()
		end
	end
	
	local conveyorHitboxOverlapParams = OverlapParams.new()
	conveyorHitboxOverlapParams.CollisionGroup = mainPart.CollisionGroup
	conveyorHitboxOverlapParams.Tolerance = 0.05
	conveyorHitboxOverlapParams:AddToFilter(mainPart)

	local connection = nil
	local function updateAnchoredStatus()
		if mainPart.Anchored then
			if connection then connection:Disconnect() end
			updateSpeed()
		else
			connection = object.trove:Connect(RunService.PostSimulation, function()
				updateVelocity()
				-- TODO: make this work the same as when it's anchored
				--[[
				local hits = workspace:GetPartsInPart(mainPart, conveyorHitboxOverlapParams)
				for _, hit: BasePart in hits do
					-- thanks roblox for only letting you filter descendants of instances and not the instance itself genius work
					if hit.Anchored then continue end
					
					hit.AssemblyLinearVelocity = mainPart.CFrame.LookVector * mainPart:GetAttribute("Speed")
				end ]]
			end)
		end
	end
	
	object.trove:Connect(mainPart:GetAttributeChangedSignal("Speed"), updateSpeed)
	object.trove:Connect(mainPart:GetPropertyChangedSignal("Anchored"), updateAnchoredStatus)
	object.trove:Connect(mainPart:GetPropertyChangedSignal("CollisionGroup"), function()
		conveyorHitboxOverlapParams.CollisionGroup = mainPart.CollisionGroup
	end)
	updateAnchoredStatus()
end