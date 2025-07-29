--!strict
--!optimize 2
--@version sequencer-6.0.0
--@creator synnwave

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local COMMUNICATOR = {
	KEY = "SequencerRequest",
	REGISTER_OBJECT = "register-object",
}

local STOPPED_COLOR = ColorSequence.new(Color3.fromRGB(255, 100, 100))
local PAUSED_COLOR = ColorSequence.new(Color3.fromRGB(255, 255, 100))
local PLAYING_COLOR = ColorSequence.new(Color3.fromRGB(45, 150, 255))
local LAG_THRESHOLD = 1 / 10 -- Sequencers will not run below 10 FPS

type SequenceData = {
	canAwait: boolean,
	instance: PVInstance,
	activators: { ActivatorData }?,
	hasPassed: boolean,
	activatorData: { [any]: any },
	point: CFrame,
}
type ActivatorData = {
	check: (sequenceData: SequenceData) -> (),
	activate: (sequenceData: SequenceData) -> (),
	priority: number?,
}
type SequencerCache = {
	activators: { [string]: ActivatorData },
	sequencers: { [Instance]: () -> () },
	fetchActivators: (sequenceData: SequenceData) -> { (sequenceData: SequenceData) -> () },
}
local function handleCache(scope: _T.Scope): SequencerCache
    local utility = scope:utility()
	local cache = { activators = {}, sequencers = {} } :: SequencerCache

	local communicator = scope:getCommunicator("request", COMMUNICATOR.KEY)
	communicator:listen(function(type: string, ...: any)
		if type == COMMUNICATOR.REGISTER_OBJECT then
			local name: string, data: ActivatorData = ...
			if cache.activators[name] ~= nil then
				return
			end
			if
				not (
					typeof(data) == "table"
					and typeof(data.check) == "function"
					and typeof(data.activate) == "function"
				)
			then
				return
			end

			cache.activators[name] = data
		end
	end)

	function cache.fetchActivators(sequenceData)
		local sortTable = {}
		for _, activator in cache.activators do
			if not activator.check(sequenceData) then
				continue
			end
			table.insert(sortTable, {
				activator = activator.activate,
				priority = activator.priority or math.huge,
			})
		end

		table.sort(sortTable, function(a, b)
			return a.priority < b.priority
		end)

        return utility.Table.Map(sortTable, function(value)
            return value.activator
        end)
	end

	return cache
end

local function distanceBetween(pointA: CFrame, pointB: CFrame): number
	return pointA:ToObjectSpace(CFrame.new(pointB.Position)).Position.Z
end

local Sequencer = {
	CanQueue = true,
	RunOnStart = false,

	Communicator = COMMUNICATOR,
}

function Sequencer.Run(scope: _T.Scope)
	local sequencerConfig = scope.instance
	if not sequencerConfig or not sequencerConfig.Parent then
		return
	end

	local utility = scope:utility()
	local clientObjectUtil = utility.ClientObjects
	if
		clientObjectUtil.isBalloon(sequencerConfig)
		or clientObjectUtil.isPushbox(sequencerConfig)
		or clientObjectUtil.isTurret(sequencerConfig)
	then
		scope:log({
			"Sequencer must not be parented to a Pushbox, Balloon, or a Turret.",
			`Path: {sequencerConfig.Parent:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local base = sequencerConfig.Parent:FindFirstChild("Base")
	if not base or not base:IsA("BasePart") then
		scope:log({
			"Sequencer Base either does not exist, or is not a BasePart.",
			`Path: {sequencerConfig.Parent:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local sequenceFolder = sequencerConfig.Parent:FindFirstChild("Sequence")
	if not sequenceFolder then
		scope:log({
			"Sequencer Sequence does not exist.",
			`Path: {sequencerConfig.Parent:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, sequencerConfig, {
		LoopAmount = 0,
		LoopDelay = 0,
		Cooldown = 0,
		Speed = 1,
		Visualize = false,
	}):CheckForChanges()

	base.Transparency = 1
	local beam: Beam?
	if configuration.Visualize then
		local attachment0 = Instance.new("Attachment")
		attachment0.Position = -Vector3.yAxis * (base.Size.Y / 2)
		attachment0.Orientation = Vector3.zAxis * 90
		attachment0.Parent = base

		local attachment1 = attachment0:Clone()
		attachment1.Position = -attachment1.Position
		attachment1.Parent = base

		beam = script:FindFirstChildWhichIsA("Beam"):Clone()
		if beam then
			beam.Attachment0 = attachment0
			beam.Attachment1 = attachment1
			beam.Width0, beam.Width1 = base.Size.X, base.Size.X
			beam.Color = STOPPED_COLOR
			beam.Parent = base
		end
	end

	local function setStatusColor(color: ColorSequence)
		if not configuration.Visualize or not beam or (beam.Color == color) then
			return
		end
		beam.Color = color
	end
end

return Sequencer
