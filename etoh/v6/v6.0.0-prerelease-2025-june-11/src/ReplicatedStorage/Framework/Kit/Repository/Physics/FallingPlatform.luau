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
		ActivateConnectedParts = true,
	}):ObserveChanges()

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

	--> Setup platform part and connected parts
	local oldPhysicalProperties = platform.CustomPhysicalProperties or platform.CurrentPhysicalProperties
	platform.CustomPhysicalProperties = PhysicalProperties.new(
		(1 / (platform.Mass * oldPhysicalProperties.Density)) * configuration.BaseMass,
		oldPhysicalProperties.Friction,
		oldPhysicalProperties.Elasticity,
		oldPhysicalProperties.FrictionWeight,
		oldPhysicalProperties.ElasticityWeight
	)
	
	alignPosition.MaxAxesForce = Vector3.yAxis * ((workspace.Gravity * platform.Mass) + 58)
	alignPosition.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	alignPosition.ForceRelativeTo = Enum.ActuatorRelativeTo.World
	alignPosition.Position = platform.Position
	--platform.Position = platform.Position - (platform.CFrame.UpVector * 2)
	platform.Anchored = false
	
	local connectedParts = platform:GetConnectedParts(true)
	local partTable = {}
	
	for _, part in connectedParts do
		if part ~= platform then
			part.Massless = true
			
			if not configuration.ActivateConnectedParts then
				continue
			end
		end
		
		table.insert(partTable, {
			part = part,
			transparency = part.Transparency,
			canCollide = part.CanCollide,
		})
	end
	
	--print(partTable)

	--> Functions
	local oldForce = alignPosition.MaxAxesForce
	local oldVelocity = alignPosition.MaxVelocity
	local function activate(activeTime: number)
		active = true
		
		for _, part in partTable do
			part.part.CanCollide = false
			part.part.Transparency = configuration.ActiveTransparency
		end
		
		alignPosition.MaxAxesForce = RELEASE_FORCE
		alignPosition.MaxVelocity = RELEASE_VELOCITY

		task.wait(activeTime)
		
		for _, part in partTable do
			part.part.CanCollide = part.canCollide
			part.part.Transparency = part.transparency
		end
		
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
