--!strict
--!optimize 2
--@version fallingplatform-6.0.0
--@creator Camille, Synnwave

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local RELEASE_FORCE = Vector3.one * math.huge
local RELEASE_VELOCITY = math.huge

local active = false

return function(scope: _T.Scope)
	local utility = scope:utility()

	local fallingPlatformConfig = scope.instance
	if not fallingPlatformConfig then
		return
	end

	local fallingPlatform = fallingPlatformConfig.Parent
	if not fallingPlatform then
		return
	end

	--> Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, fallingPlatformConfig, {
		ActiveTime = 1.5,
		ActiveTransparency = 0.75,
		InactiveTransparency = 0,
		BaseMass = 4.8,
	}):CheckForChanges()

	--> Setup and check for problems
	local platform = fallingPlatform:FindFirstChild("Platform")
	if not platform or not platform:IsA("BasePart") then
		scope:log({
			"FallingPlatform is either missing its Platform part or has it set up incorrectly.",
			`Path: {fallingPlatform:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local endPart = fallingPlatform:FindFirstChild("End")
	if not endPart or not endPart:IsA("BasePart") then
		scope:log({
			"FallingPlatform is either missing its End part or has it set up incorrectly.",
			`Path: {fallingPlatform:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local alignPosition = platform:FindFirstChild("AlignPosition")
	if not alignPosition or not alignPosition:IsA("AlignPosition") then
		scope:log({
			"FallingPlatform is either missing its AlignPlatform or has it set up incorrectly.",
			`Path: {fallingPlatform:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Setup platform part
	for _, part in platform:GetConnectedParts() do
		if part ~= platform then
			part.Massless = true
		end
	end

	local oldPhysicalProperties = platform.CustomPhysicalProperties or platform.CurrentPhysicalProperties
	platform.CustomPhysicalProperties = PhysicalProperties.new(
		(1 / (platform.Mass * oldPhysicalProperties.Density)) * configuration.BaseMass,
		oldPhysicalProperties.Friction,
		oldPhysicalProperties.Elasticity,
		oldPhysicalProperties.FrictionWeight,
		oldPhysicalProperties.ElasticityWeight
	)

	alignPosition.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	alignPosition.ForceRelativeTo = Enum.ActuatorRelativeTo.World
	alignPosition.Position = platform.Position
	platform.Position = platform.Position - (platform.CFrame.UpVector * 2)
	platform.Anchored = false

	--> Functions
	local oldForce = alignPosition.MaxAxesForce
	local oldVelocity = alignPosition.MaxVelocity
	local function activate(activeTime: number)
		active = true

		platform.CanCollide = false
		platform.Transparency = configuration.ActiveTransparency
		alignPosition.MaxAxesForce = RELEASE_FORCE
		alignPosition.MaxVelocity = RELEASE_VELOCITY

		task.wait(activeTime)

		platform.CanCollide = true
		platform.Transparency = configuration.InactiveTransparency
		alignPosition.MaxAxesForce = oldForce
		alignPosition.MaxVelocity = oldVelocity

		active = false
	end

	--> Main functionality
	scope:attach(fallingPlatform)
	task.spawn(activate, 0.5) -- fix for it getting stuck

	scope:add(endPart.Touched:Connect(function(toucher)
		if toucher == platform and not active then
			activate(configuration.ActiveTime)
		end
	end))
end
