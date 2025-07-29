--!strict
--!optimize 2
--@version sequencer-6.0.0
--@creator synnwave

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local COMMUNICATOR = {
	KEY = "SequencerRequest",
	REGISTER_OBJECT = "register-object",
}

local STOPPED_COLOR = ColorSequence.new(Color3.fromRGB(255, 100, 100))
local PAUSED_COLOR = ColorSequence.new(Color3.fromRGB(255, 255, 100))
local PLAYING_COLOR = ColorSequence.new(Color3.fromRGB(45, 150, 255))
local LAG_THRESHOLD = 1 / 10 -- Sequencers will not run below 10 FPS

local SetupPresetActivators = require(script.Activators)
local _TDefs = require(script.TypeDefs)
type SequenceData = _TDefs.SequenceData
type ActivatorData = _TDefs.ActivatorData
type SequencerCache = _TDefs.SequencerCache

local function doNothing() end
local function optimizePart(part: Instance?)
	if not (part and part:IsA("BasePart")) then
		return
	end
	part.Transparency = 0
	part.CanTouch = false
	part.CanCollide = false
	part.CanQuery = false
	part.CollisionGroup = "NeverCollide"
	part.Material = Enum.Material.SmoothPlastic
	part:AddTag("IgnoreAll")
end

local function handleCache(scope: _T.Scope): SequencerCache
	local utility = scope:utility()
	local cache = { activators = {}, sequencers = {} } :: SequencerCache

	local function register(name: string, data: ActivatorData)
		if
			cache.activators[name] ~= nil
			or typeof(data) ~= "table"
			or typeof(data.check) ~= "function"
			or typeof(data.activate) ~= "function"
		then
			return
		end

		--print("Registering", name, data)
		cache.activators[name] = data
	end

	local communicator = scope:getCommunicator("request", COMMUNICATOR.KEY)
	communicator:listen(function(type: string, ...: any)
		if type == COMMUNICATOR.REGISTER_OBJECT then
			return register(...)
		end
	end)

	function cache.fetchActivators(sequenceData: SequenceData)
		local sortTable = {}
		local optimizeFn = if sequenceData.doNotOptimize then doNothing else optimizePart
		for _, activator in cache.activators do
			if not activator.check(sequenceData, optimizeFn) then
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

	function cache.makeSequenceData(instance: PVInstance, forceAwait: boolean?, doNotOptimize: boolean?)
		local currentData: SequenceData = {
			canAwait = forceAwait or instance:HasTag("YieldSequence"),
			instance = instance,
			hasPassed = false,
			point = instance:GetPivot(),
			activatorData = {},
			doNotOptimize = doNotOptimize,
		}

		if instance:IsA("Model") and not instance.PrimaryPart then
			-- fix weird pivot data
			currentData.point = (instance:GetBoundingBox())
		end

		return currentData
	end

	SetupPresetActivators(register, cache, scope)
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
	local sequenceActivators = sequencerConfig.Parent:FindFirstChild("Activators")
	if not sequenceActivators then
		scope:log({
			"Sequence Activators folder does not exist.",
			`Path: {sequencerConfig.Parent:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local cache = utility.Scope.getCached(scope, COMMUNICATOR.KEY, handleCache)
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, sequencerConfig, {
		LoopAmount = 0,
		LoopDelay = 0,
		Cooldown = 0,
		Speed = 1,
		Visualize = false,
		RunAtStart = false,
	}):ObserveChanges()

	base.Transparency = 1
	local beam: Beam?
	if configuration.Visualize then
		local attachment0 = Instance.new("Attachment")
		attachment0.Position = -Vector3.yAxis * (base.Size.Y * 0.5)
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

	local currentStatusColor = STOPPED_COLOR
	local function setStatusColor(color: ColorSequence)
		if not configuration.Visualize or not beam or currentStatusColor == color then
			return
		end
		currentStatusColor = color
		beam.Color = color
	end

	--> Fetch Sequence Data
	local sequenceData: { SequenceData } = {}
	for _, child: Instance in sequenceFolder:GetChildren() do
		if not child:IsA("PVInstance") then
			continue
		end

		local currentData = cache.makeSequenceData(child)
		table.insert(sequenceData, currentData)
	end
	table.sort(sequenceData, function(dataA, dataB)
		return dataA.point.Y < dataB.point.Y
	end)

	--> Sequencer Functionality
	local startingPosition = base:GetPivot()
	local fetchedActivators = false
	local runIndex = 0
	local function runSequence(variables: { [string]: any })
		if not scope:isAlive() then
			return
		end

		if not fetchedActivators then
			fetchedActivators = true
			for i = #sequenceData, 1, -1 do
				local sequence = sequenceData[i]
				local activators = cache.fetchActivators(sequence)
				if #activators <= 0 and sequence.instance.Name ~= "EndPoint" then
					table.remove(sequenceData, i)
				else
					sequence.activators = activators
				end
			end
		end

		runIndex += 1

		local thisIndex = runIndex
		local isPaused = false
		local delta = 0
		local currentSequenceData = utility.Table.Copy(sequenceData, true)
		local sequenceCount = #currentSequenceData
		local runningThread = coroutine.running()
		local sequenceScope = scope:inherit()
		sequenceScope:add(function()
			runIndex += 1
			setStatusColor(STOPPED_COLOR)
			base:PivotTo(startingPosition)
			currentSequenceData = nil :: any
			task.spawn(runningThread)
		end)
		sequenceScope:add(RunService.PostSimulation:Connect(function(deltaTime)
			if runIndex ~= thisIndex then
				sequenceScope:cleanup(false, true)
				return
			end
			if isPaused then
				setStatusColor(PAUSED_COLOR)
				return
			end
			if deltaTime > LAG_THRESHOLD then
				return
			end
			delta += deltaTime
			setStatusColor(PLAYING_COLOR)

			local currentPosition = startingPosition * CFrame.new(0, 0, delta * -math.abs(configuration.Speed))
			if configuration.Visualize then
				base:PivotTo(currentPosition)
			end

			local passed = 0
			for _, sequencePart in currentSequenceData do
				if sequencePart.hasPassed then
					passed += 1
					continue
				end
				if not sequencePart.activators then
					continue
				end

				local distanceFromBase = distanceBetween(currentPosition, sequencePart.point)
				if distanceFromBase < 0 then
					continue
				end

				sequencePart.hasPassed = true
				passed += 1
				if sequencePart.canAwait then
					isPaused = true
				end
				for _, activator in sequencePart.activators do
					local success, returned: string? = pcall(activator, sequencePart, variables)
					if (not success) and typeof(returned) == "string" then
						scope:log({ `sequencer error: {returned}` })
					elseif success and returned == "STOP_CURRENT" then
						break
					elseif success and returned == "STOP_SEQUENCE" then
						sequenceScope:cleanup(false, true)
						return
					end
				end
				if sequencePart.canAwait then
					isPaused = false
				end
			end

			if passed >= sequenceCount then
				sequenceScope:cleanup(false, true)
			end
		end))

		coroutine.yield()
	end

	local isPlaying = false
	local totalRuns = 0
	local function sequenceWrapper(variables)
		if isPlaying then
			return
		end
		isPlaying = true

		local loopDelay = math.max(configuration.LoopDelay, 1 / 60)
		local loopCount = configuration.LoopAmount
		if loopCount < 0 then
			loopCount = math.huge
		end

		for loop = 1, loopCount + 1 do

			totalRuns += 1
			variables.CurrentLoop = loop
			variables.RunTimes = totalRuns
			runSequence(variables)
			task.wait(loopDelay)
		end

		task.wait(configuration.Cooldown)
		isPlaying = false
	end

    scope:attach(sequencerConfig.Parent)
	cache.sequencers[sequencerConfig.Parent] = sequenceWrapper
	for _, activator in sequenceActivators:GetChildren() do
		if not activator:IsA("BasePart") then
			continue
		end

		local activatorVariables = activator:FindFirstChild("PointerVariables")
		local variables = {}
		if activatorVariables then
			variables = activatorVariables:GetAttributes()
		end

		local touchConfiguration =
			Config.GetConfig(scope, activator:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
				:ObserveChanges()

		scope:add(activator.Touched:Connect(function(toucher: BasePart)
			if
				activator:GetAttribute("Activated") == false
				or not utility.ClientObjects.evaluateToucher(activator, toucher, touchConfiguration)
			then
				return
			end

			scope:spawn(sequenceWrapper, variables)
		end))
	end

	if configuration.RunAtStart then
		scope:delay(0.1, sequenceWrapper, {})
	end
end

return Sequencer
