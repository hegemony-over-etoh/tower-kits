--!strict
--!optimize 2
--@version pushingplatformtrampoline-6.0.0
--@creator Camille

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local utility = scope:utility()

	--> Setup
	local trampolineConfig = scope.instance
	if not trampolineConfig then
		return
	end

	local trampoline = trampolineConfig.Parent
	if not trampoline then
		return
	end

	local anchor = nil
	local base = nil
	local prismatic = nil
	local vectorForce = nil
	local lowerLimit = nil
	local upperLimit = nil

	local active = false

	scope:attach(trampoline)

	--> Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, trampolineConfig, {
		LaunchSpeed = 1,
	}):CheckForChanges()

	--> Get objects and check for problems
	do
		anchor = trampoline:FindFirstChild("Anchor")
		if not anchor or not anchor:IsA("BasePart") then
			scope:log({
				"PushingPlatformTrampoline is either missing its Anchor part or has it set up incorrectly.",
				`Path: {trampoline:GetFullName()}`,
				type = "warn",
			})
			return
		end

		base = trampoline:FindFirstChild("Base")
		if not base or not base:IsA("BasePart") then
			scope:log({
				"PushingPlatformTrampoline is either missing its Base part or has it set up incorrectly.",
				`Path: {trampoline:GetFullName()}`,
				type = "warn",
			})
			return
		end

		prismatic = anchor:FindFirstChildOfClass("PrismaticConstraint")
		if not prismatic then
			scope:log({
				"PushingPlatformTrampoline is missing its PrismaticConstraint and cannot function correctly.",
				`Path: {trampoline:GetFullName()}`,
				type = "warn",
			})
			return
		end

		vectorForce = base:FindFirstChildOfClass("VectorForce")
		if not vectorForce then
			scope:log({
				"PushingPlatformTrampoline is missing its VectorForce and cannot function correctly.",
				`Path: {trampoline:GetFullName()}`,
				type = "warn",
			})
			return
		end

		upperLimit = prismatic.UpperLimit - 0.2
		lowerLimit = prismatic.LowerLimit + 0.2
	end

	--> Setup total mass
	local totalMass = 0

	for _, obj in trampoline:GetDescendants() do
		if obj:IsA("BasePart") and not obj.Anchored then
			local baseMass = obj.Size.X * obj.Size.Y * obj.Size.Z
			totalMass += baseMass * obj.CustomPhysicalProperties.Density * workspace.Gravity
		end
	end

	--> Setup default force
	local defaultForce = Vector3.zAxis * totalMass + (Vector3.zAxis * 100)
	vectorForce.Force = defaultForce

	--> Functions
	local function activate()
		active = true
		vectorForce.Force = defaultForce * (3 * configuration.LaunchSpeed)

		local waitLoop
		waitLoop = scope:add(RunService.Stepped:Connect(function()
			if prismatic.CurrentPosition <= lowerLimit then
				scope:remove(waitLoop)

				vectorForce.Force = defaultForce
				active = false
			end
		end))
	end

	--> Main loop
	scope:add(RunService.Stepped:Connect(function()
		if active then
			return
		end

		if prismatic.CurrentPosition >= upperLimit then
			activate()
		end
	end))
end
