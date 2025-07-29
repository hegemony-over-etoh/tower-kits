--!strict
--!optimize 2
--@version elevator-6.0.0
--@creator synnwave

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local ALLOWED_CFRAME_COMPONENTS = {
	"UpVector",
	"RightVector",
	"LookVector",
	"ZVector",
}

local UPDATE_INTERVAL = 1 / 60

return function(scope: _T.Scope)
	local utility = scope:utility()
	local elevatorConfig = scope.instance
	if not elevatorConfig then
		return
	end

	local elevator = elevatorConfig.Parent
	if not elevator or not elevator:IsA("BasePart") then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, elevatorConfig, {
		MaxForce = math.huge,
		Speed = 40,
		Vector = Config.Type.Some(table.unpack(ALLOWED_CFRAME_COMPONENTS)),
		HitboxMode = Config.Type.Some(table.unpack(utility.Character.HitboxModes)),
		ContinuousUpdates = false,
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, elevatorConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

	local localPlayer = Players.LocalPlayer
	local touchingParts = {}

	scope:attach(elevator)
	scope:add(elevator.Touched:Connect(function(touchingPart: BasePart)
		if
			elevator:GetAttribute("Activated") == false
			or not utility.ClientObjects.evaluateToucher(elevator, touchingPart, touchConfiguration)
		then
			return
		end

		local part: BasePart
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.CollisionGroup = ""

		local character = localPlayer.Character
		if character and touchingPart:IsDescendantOf(character) then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if not (rootPart and rootPart:IsA("BasePart")) then
				return
			end

			part = rootPart
			local hitbox = utility.Character.getHitbox(configuration.HitboxMode or "StaticWholeBody", params)
			if not table.find(hitbox, touchingPart) then
				return
			end
		elseif utility.ClientObjects.isPushbox(touchingPart) then
			part = touchingPart
			params:AddToFilter(touchingPart)
		end

		if not part then
			return
		end
		if touchingParts[part] then
			return
		end

		local faceVector: Vector3 =
			utility.Property.getPropertySafe(elevator.CFrame, configuration.Vector or ALLOWED_CFRAME_COMPONENTS[1])
		if not faceVector then
			return
		end

		-- Pro Tip : don't do Vector3.yAxis * math.huge
		local currentMaxForce = Vector3.new(0, configuration.MaxForce, 0)
		if faceVector.X ~= 0 then
			currentMaxForce = Vector3.new(configuration.MaxForce, currentMaxForce.Y, currentMaxForce.Z)
		end
		if faceVector.Z ~= 0 then
			currentMaxForce = Vector3.new(currentMaxForce.X, currentMaxForce.Y, configuration.MaxForce)
		end

		local velocityAttachment = Instance.new("Attachment")
		velocityAttachment.Parent = part

		local velocity = Instance.new("LinearVelocity")
		velocity.Name = "ElevatorVelocity"
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		velocity.Attachment0 = velocityAttachment
		velocity.ForceLimitsEnabled = true
		velocity.MaxAxesForce = currentMaxForce
		velocity.VectorVelocity = faceVector * configuration.Speed
		velocity.Parent = part

		touchingParts[part] = true
		while touchingParts[part] do
			if not elevator.CanTouch or not elevator.CanQuery then
				break
			end
			if elevator:GetAttribute("Activated") == false then
				break
			end
			local zoneParts = workspace:GetPartsInPart(elevator, params)
			if #zoneParts <= 0 then
				break
			end

			if configuration.ContinuousUpdates then
				faceVector = utility.Property.getPropertySafe(
					elevator.CFrame,
					configuration.Vector or ALLOWED_CFRAME_COMPONENTS[1]
				)
				velocity.VectorVelocity = faceVector * configuration.Speed
			end

			task.wait(UPDATE_INTERVAL)
		end

		touchingParts[part] = nil
		velocity:Destroy()
		velocityAttachment:Destroy()
	end))
end
