--!strict
-- junekept 2025
-- this script was originally made for OToH

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local killbrickDebounceTime = Utility.Config.killbrickDebounceTime

local isTouching = false
return function(object: Types.ClientObject)
	local pushingPlatformModel = object.instance
	local pushPart = pushingPlatformModel:FindFirstChild("PushPart"); assert(pushPart and pushPart:IsA("BasePart"))
	local forcePart = pushingPlatformModel:FindFirstChild("ForcePart"); assert(forcePart and forcePart:IsA("BasePart"))
	local constraintPart = pushingPlatformModel:FindFirstChild("ConstraintPart"); assert(constraintPart and constraintPart:IsA("BasePart"))
	local vectorForce = forcePart:FindFirstChild("VectorForce"); assert(vectorForce and vectorForce:IsA("VectorForce"))
	local prismaticConstraint = constraintPart:FindFirstChild("PrismaticConstraint"); assert(prismaticConstraint and prismaticConstraint:IsA("PrismaticConstraint"))
	
	local totalMass = 0
	for _, part in forcePart:GetConnectedParts(true) do
		if not part:IsA("BasePart") or part.Anchored then
			return
		end
		
		totalMass += (part.Size.X * part.Size.Y * part.Size.Z) * part.CustomPhysicalProperties.Density * workspace.Gravity
	end
	
	local upwardsForce = Vector3.zAxis * totalMass + vectorForce.Force
	object.trove:Connect(RunService.PreSimulation, function()
		if prismaticConstraint.CurrentPosition > prismaticConstraint.UpperLimit - 0.2 then
			vectorForce.Force = upwardsForce * pushingPlatformModel:GetAttribute("ReboundForceMultiplier")
		elseif prismaticConstraint.CurrentPosition < 0.2 then
			vectorForce.Force = upwardsForce
		end
	end)
end