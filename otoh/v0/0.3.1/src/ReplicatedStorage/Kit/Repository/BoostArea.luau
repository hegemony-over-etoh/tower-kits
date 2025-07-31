--!strict
-- junekept 2025
-- this script was originally made for OToH

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include

local function findFirstBoostAncestor(part: Instance)
	while part:GetAttribute("_Script") ~= "BoostArea" do
		if not part then error("how") end
		part = part.Parent :: Instance
	end

	return part
end

task.spawn(function()
	while true do
		Utility.General.waitForUpdateInterval()
		if #CollectionService:GetTagged("SpeedBoostPadDescendantsFilter") == 0 then
			continue
		end

		overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("SpeedBoostPadDescendantsFilter")

		local walkSpeed, priority = Utility.ClientObjects.getHighestPriorityAttributeFromIntersectingParts("WalkSpeed", overlapParams, Utility.Character.getHitbox("WholeBody"), findFirstBoostAncestor)
		if priority == 0 then
			Utility.Character.removeWalkSpeedAtPriority(4)
		else
			Utility.Character.setWalkSpeedAtPriority(walkSpeed, 4)
		end

		overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("JumpBoostPadDescendantsFilter")
		local jumpPower, priority = Utility.ClientObjects.getHighestPriorityAttributeFromIntersectingParts("JumpPower", overlapParams, Utility.Character.getHitbox("WholeBody"), findFirstBoostAncestor)
		if priority == 0 then
			Utility.Character.removeJumpPowerAtPriority(4)
		else
			Utility.Character.setJumpPowerAtPriority(jumpPower, 4)
		end

		Utility.General.waitForUpdateInterval()
	end
end)

return function(object: Types.ClientObject)
	local mainPart: BasePart = object.instance :: BasePart; assert(mainPart:IsA("BasePart"))

	local hitbox: BasePart
	if mainPart:GetAttribute("ZoneMode") then
		mainPart:SetAttribute("Hitbox", "WholeBody")
		hitbox = mainPart
	else
		mainPart:SetAttribute("Hitbox", "Legs")
		hitbox = object.trove:Construct(Instance, "Part")
		hitbox.CanCollide = false
		hitbox.Transparency = 1
		hitbox.Anchored = true
		hitbox.Size = mainPart.Size 
			+ mainPart:GetAttribute("Tolerance")
			+ Vector3.yAxis * mainPart:GetAttribute("Distance")
		hitbox.CFrame = mainPart.CFrame + Vector3.yAxis * mainPart:GetAttribute("Distance") / 2
		hitbox.Parent = mainPart
		Utility.General.weld(mainPart, hitbox, true)
	end


	local boostType = mainPart:GetAttribute("Type")
	if boostType == "Speed" or boostType == "Both" then
		hitbox:AddTag("SpeedBoostPadDescendantsFilter")
	end

	if boostType == "Jump" or boostType == "Both" then
		hitbox:AddTag("JumpBoostPadDescendantsFilter")
	end
end