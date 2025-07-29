--!strict
--!optimize 2
--@version shovingplatform-6.0.0
--@creator mario_123456

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local utility = scope:utility()
	local shovingPlatformConfig = scope.instance
	if not shovingPlatformConfig then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, shovingPlatformConfig, {
		Distance = 5,
		OutDelay = 1,
		InDelay = 1,
		InSpeed = 20,
		OutSpeed = 40,
	}):CheckForChanges()

	local shovingPlatform = shovingPlatformConfig.Parent
	if not shovingPlatform or not shovingPlatform:IsA("BasePart") then
		return
	end

	local model = shovingPlatform.Parent
	if not model then
		return
	end
	local prismaticConstraint = shovingPlatform:FindFirstChildWhichIsA("PrismaticConstraint")
	if not prismaticConstraint then
		return
	end

	prismaticConstraint.UpperLimit = configuration.Distance
	local function updateShover(mode: boolean)
		prismaticConstraint.LinearResponsiveness = if mode then configuration.OutSpeed else configuration.InSpeed
		prismaticConstraint.Speed = if mode then configuration.OutSpeed else configuration.InSpeed
		prismaticConstraint.TargetPosition = if mode then configuration.Distance else 0
	end

	local mainLoop: thread
	mainLoop = task.spawn(function()
		while true do
			updateShover(true)
			task.wait(1)
			updateShover(false)
			task.wait(1)
		end
	end)
end
