--!strict
-- junekept 2025
-- this script was originally made for OToH

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local elevator = object.instance :: BasePart
	
	local touchingParts = {}
	local function touched(hit: BasePart)
		if not elevator:GetAttribute("_Active") or not Utility.ClientObjects.isTouchValid(elevator, hit) then
			return
		end

		local hitboxes = Utility.Character.getHitbox(elevator:GetAttribute("PlayerHitboxMode"))

		local part: BasePart
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.CollisionGroup = ""

		local character = Players.LocalPlayer.Character
		if character and table.find(hitboxes, hit) then
			part = character:FindFirstChild("HumanoidRootPart") or error(`Character model {character.Name} somehow did not have a HumanoidRootPart??????`)
			overlapParams:AddToFilter(hitboxes)
		else
			part = hit
			overlapParams:AddToFilter(hit)
		end

		if not part or touchingParts[part] then
			return
		end

		overlapParams:AddToFilter(hit)
		touchingParts[part] = true

		local velocityConstraintTrove = object.trove:Extend()

		local velocity = velocityConstraintTrove:Clone(script.ElevatorVelocity)
		local attachment = velocityConstraintTrove:Construct(Instance, "Attachment") :: Attachment

		velocity.Attachment0 = attachment
		attachment.Parent = part
		velocity.Parent = part

		local function updateForce()
			local maxForce = elevator:GetAttribute("MaxForce")
			local maxForceVector = Vector3.zero
			if velocity.VectorVelocity.X ~= 0 then
				maxForceVector += Vector3.new(maxForce, 0, 0)
			end
			if velocity.VectorVelocity.Y ~= 0 then
				maxForceVector += Vector3.new(0, maxForce, 0)
			end
			if velocity.VectorVelocity.Z ~= 0 then
				maxForceVector += Vector3.new(0, 0, maxForce)
			end

			velocity.MaxAxesForce = maxForceVector
		end

		local function updateVelocity()
			if elevator:GetAttribute("UseUpVector") then
				velocity.VectorVelocity = elevator.CFrame.UpVector * elevator:GetAttribute("Speed")
			else
				velocity.VectorVelocity = elevator:GetAttribute("PushDirection").Unit * elevator:GetAttribute("Speed")
			end
			updateForce()
		end

		-- these connections should allow the elevator to change forces applied to objects while they are in the elevator
		velocityConstraintTrove:Connect(elevator:GetPropertyChangedSignal("Orientation"), updateVelocity)
		velocityConstraintTrove:Connect(elevator:GetAttributeChangedSignal("Speed"), updateVelocity)
		velocityConstraintTrove:Connect(elevator:GetAttributeChangedSignal("PushDirection"), updateVelocity)
		velocityConstraintTrove:Connect(elevator:GetAttributeChangedSignal("MaxForce"), updateForce)

		updateForce()
		updateVelocity()

		while touchingParts[part] do
			if not elevator:GetAttribute("_Active") or #workspace:GetPartsInPart(elevator, overlapParams) <= 0 then 
				break 
			end
			Utility.General.waitForUpdateInterval()
		end

		touchingParts[part] = nil
		velocityConstraintTrove:Destroy()
	end
	
	object.trove:Connect(elevator.Touched, touched)
	object.trove:Connect(elevator:GetAttributeChangedSignal("_Active"), function()
		if elevator:GetAttribute("_Active") then
			for _, part in workspace:GetPartsInPart(elevator) do
				touched(part)
			end
		end
	end)
end