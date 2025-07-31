--!strict
-- junekept 2025
-- this script was originally made for OToH

--[==[
	This module contains methods for interacting with client objects
]==]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries

local Trove = require(Libraries.Trove)

local Character = require(Kit.Utility.Character)
local General = require(Kit.Utility.General)

local ClientObjects = {}

-- Get a list of parts with `Priority` attributes intersecting with the provided hitbox parts and return the highest priority value attribute from all of them.
function ClientObjects.getHighestPriorityAttributeFromIntersectingParts(attribute: string, overlapParams: OverlapParams, hitboxes: {BasePart}, transform: ((any) -> any)?): (any, number)
	local highestPriority = 0
	local highestValue = -math.huge

	-- local hitboxes = Character.getHitbox("WholeBody")
	for _, hitbox in hitboxes do
		local intersectingParts = workspace:GetPartsInPart(hitbox, overlapParams)
		for _, part in intersectingParts do
			if transform then
				part = transform(part)
			end
			if not part:GetAttribute("_Active") then continue end
			local priority = part:GetAttribute("Priority")
			if not table.find(Character.getHitbox(part:GetAttribute("Hitbox")), hitbox) or priority < highestPriority then
				continue
			end
			highestPriority = priority
			highestValue = math.max(part:GetAttribute(attribute), highestValue)
		end
	end

	return highestValue, highestPriority
end

-- Weld player character to provided handle part.
function ClientObjects.weldCharacterToHandle(handle: BasePart, character: Model, baseTrove: Trove.Trove?): Trove.Trove
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local leftArm = character:FindFirstChild("Left Arm") :: BasePart
	local rightArm = character:FindFirstChild("Right Arm") :: BasePart

	local weldTrove = if baseTrove then baseTrove:Extend() else Trove.new()

	character:PivotTo(handle.CFrame + handle.CFrame.UpVector * -1)

	local rootWeld = weldTrove:Add(General.weld(handle, rootPart))

	local shoulders: {[BasePart]: Constraint} = {
		[leftArm] = character:FindFirstChild("Left Shoulder", true) :: Constraint,
		[rightArm] = character:FindFirstChild("Right Shoulder", true) :: Constraint
	}

	for arm, shoulder in shoulders do
		shoulder.Enabled = false
		-- this is what my reference swinger object code did so I unfortunately must say I have no idea why these numbers are being used
		arm.CFrame = handle.CFrame 
			+ handle.CFrame.UpVector * -1 
			+ handle.CFrame.RightVector * (if arm == rightArm then 0.5 else -0.5) * 2.95
		arm.CFrame *= CFrame.Angles(math.pi, 0, 0)
		weldTrove:Add(General.weld(rootPart, arm))
	end

	weldTrove:Add(function()
		for arm, shoulder in shoulders do
			shoulder.Enabled = true
		end
	end)

	return weldTrove
end

-- yield the thread until the client object is active, or do nothing if it already is
function ClientObjects.yieldForActive(model: Instance)
	if not model:GetAttribute("_Active") then
		model:GetAttributeChangedSignal("_Active"):Wait()
	end
end

function ClientObjects.respectActivityWait(model: Instance, t: number)
	local timeRemaining = t
	while true do
		ClientObjects.yieldForActive(model)

		local deltaTime = RunService.RenderStepped:Wait()
		timeRemaining -= deltaTime

		if timeRemaining <= 0 then
			break
		end
	end
end

function ClientObjects.isTouchValid(instance: Instance, otherPart: BasePart)
	local canBeActivated = if otherPart:HasTag("Balloon") then instance:GetAttribute("SupportBalloons")
		elseif otherPart:HasTag("Pushbox") then instance:GetAttribute("SupportPushboxes")
		elseif otherPart:HasTag("Bullet") then instance:GetAttribute("SupportTurrets")
		elseif Character.isLimb(otherPart) then instance:GetAttribute("SupportPlayers")
		else instance:GetAttribute("SupportOther")

	if canBeActivated 
		and otherPart:HasTag("Pushbox")
		and instance:GetAttribute("RequireMatchingPushboxId") 
		and otherPart:GetAttribute("Id") ~= instance:GetAttribute("Id") 
	then
		return false
	else
		return canBeActivated
	end
end

return ClientObjects
