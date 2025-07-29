--!strict
--!optimize 2
--@version conveyor-6.0.0
--@creator aamo_s

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

type ConveyorData = {
	conveyor: BasePart,
	beams: { Beam },
	speed: number,
}

type ConveyorCache = { [any]: ConveyorData }

local function setConveyorSpeed(conveyor: BasePart, beams: { Beam }, speed: number)
	conveyor.AssemblyLinearVelocity = conveyor.CFrame.LookVector * speed

	for _, beam in beams do
		beam.TextureSpeed = math.min(speed / beam.TextureLength, 20)
	end
end

return function(scope: _T.Scope)
	local utility = scope:utility()
	local conveyorConfig = scope.instance
	if not conveyorConfig then
		return
	end

	local conveyor = conveyorConfig.Parent
	if not conveyor or not conveyor:IsA("BasePart") then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, conveyorConfig, {
		Speed = 10,
	}):CheckForChanges()

	local conveyorCache = utility.Scope.getCached(scope, "conveyorCache", function()
		local conveyorCache = {} :: ConveyorCache
		scope.rootScope:add(RunService.PreSimulation:Connect(function()
			for id, data in conveyorCache do
				if not data.conveyor:IsDescendantOf(workspace) or data.conveyor.Anchored then
					conveyorCache[id] = nil
					continue
				end

				setConveyorSpeed(data.conveyor, data.beams, data.speed)
			end
		end))

		return conveyorCache
	end)

	local beams = {}
	for _, v in conveyor:GetChildren() do
		if not v:IsA("Beam") then
			continue
		end

		table.insert(beams, v)
	end

	local function updateConveyor()
		conveyorCache[conveyor] = {
			conveyor = conveyor,
			beams = beams,
			speed = configuration.Speed,
		}
	end

	local anchoredScope = scope:inherit()
	anchoredScope:attach(conveyor, true)
	anchoredScope:add(conveyor:GetPropertyChangedSignal("Anchored"):Connect(function()
		if conveyor.Anchored then
			setConveyorSpeed(conveyor, beams, configuration.Speed)
		else
			updateConveyor()
		end
	end))

	setConveyorSpeed(conveyor, beams, configuration.Speed)
	updateConveyor()
end
