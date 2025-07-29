--!strict

-- Preset Sequencer activators . . .

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local _TDefs = require(script.Parent.TypeDefs)
type SequenceData = _TDefs.SequenceData
type ActivatorData = _TDefs.ActivatorData
type SequencerCache = _TDefs.SequencerCache

return function(register, cache: SequencerCache, scope: _T.Scope)
	local utility = scope:utility()

	-- Damage Brick Activator
	register(
		"DamageBrick",
		{
			priority = nil,
			check = function(sequenceData, optimize)
				local instance = sequenceData.instance
				if not instance:IsA("BasePart") then
					return false
				end
				local valid = utility.Character.validateDamageBrick(instance) ~= nil
				if valid then
					optimize(instance)
				end
				return valid
			end,
			activate = function(sequenceData)
				if not sequenceData.instance:IsA("BasePart") then
					return
				end
				utility.Character.takeDamage(sequenceData.instance)
			end,
		} :: ActivatorData
	)

	local function runSequence(sequence, variables): string?
		for _, activator in sequence.activators do
			local success, returned: string? = pcall(activator, sequence, variables)
			if (not success) and typeof(returned) == "string" then
				scope:log({ `sequencer error: {returned}` })
			elseif success and returned == "STOP_CURRENT" then
				break
			elseif success and returned == "STOP_SEQUENCE" then
				return returned
			end
		end

		return nil
	end

	-- Sequence Pointers
	local pointerName = "SequencePointer"
	local cachedSequenceData = {}
	register(
		pointerName,
		{
			priority = nil,
			check = function(sequenceData, optimize)
				local instance = sequenceData.instance
				local config = instance:FindFirstChild("PointerConfiguration")
				if
					not instance:IsA("BasePart")
					or not config
					or instance.Name:sub(1, pointerName:len()):lower() ~= pointerName:lower()
				then
					return false
                end
                
                optimize(instance)
				sequenceData.activatorData.pointsTo = config:GetAttribute("Pointer")
				return true
			end,
			activate = function(sequenceData, variables: { [string]: any })
				local tag = sequenceData.activatorData.pointsTo
				for match, replace in variables do
					if typeof(match) ~= "string" or typeof(replace) ~= "string" then
						continue
					end
					tag = tag:gsub(`\{{match}}`, replace)
				end

				for _, object in CollectionService:GetTagged(tag) do
					if not object:IsDescendantOf(scope.clientObjects) or not object:IsA("PVInstance") then
						continue
					end

					local thisSequenceData = cachedSequenceData[object]
					if not thisSequenceData then
						thisSequenceData = cache.makeSequenceData(object, false, true)
						thisSequenceData.activators = cache.fetchActivators(thisSequenceData)
						cachedSequenceData[object] = thisSequenceData
					end

					local result = runSequence(thisSequenceData, variables)
					if result ~= nil then
						return result
					end
				end
			end,
		} :: ActivatorData
	)

	-- Sequencers
	register(
		"Sequencers",
		{
			priority = nil,
			check = function(sequenceData)
				local instance = sequenceData.instance
				if not instance then
					return false
				end

				local activate = cache.sequencers[instance]
				if activate ~= nil then
					sequenceData.activatorData.activateSequence = activate
				end

				return activate ~= nil
			end,
			activate = function(sequenceData)
				local activate = sequenceData.activatorData.activateSequence
				if sequenceData.canAwait then
					activate()
				else
					task.spawn(activate)
				end
			end,
		} :: ActivatorData
	)

	-- Sequence Groups
	local Config = utility.Config
	local Type = Config.Type
	local configTemplate = {
		Mode = Type.Some("Random", "And", "Or"),
	}

	register(
		"SequenceGroups",
		{
			priority = nil,
			check = function(sequenceData)
				local instance = sequenceData.instance
				if instance.Name ~= "SequenceGroup" or not instance:IsA("Model") then
					return false
				end

				local groupConfig = instance:FindFirstChild("GroupConfiguration")
				if not groupConfig then
					return false
				end
				local configuration = Config.GetConfig(nil, groupConfig, configTemplate)
				if typeof(configuration.Mode) ~= "string" then
					return false
				end

				local forceAwait = configuration.Mode == "And" or configuration.Mode == "Or"
				sequenceData.canAwait = forceAwait or sequenceData.canAwait

				local groupData = {}
				for _, child: Instance in instance:GetChildren() do
					if not child:IsA("PVInstance") then
						continue
					end

					local newSequenceData = cache.makeSequenceData(child, forceAwait)
					local activators = cache.fetchActivators(newSequenceData)
					if #activators <= 0 then
						continue
					end

					newSequenceData.activators = activators
					table.insert(groupData, newSequenceData)
				end

				local canContinue = #groupData > 0
				if canContinue then
					sequenceData.activatorData.sequenceGroups = { sequences = groupData, mode = configuration.Mode }
				end
				return canContinue
			end,
			activate = function(sequenceData, variables: { [string]: any })
				local data = sequenceData.activatorData.sequenceGroups
				if not data then
					return
				end

				local sequences = data.sequences
				local mode = data.mode
				if mode == "Random" then
					local randomSequence = sequences[Random.new():NextInteger(1, #sequences)]
					local result = runSequence(randomSequence, variables)
					if result ~= nil then
						return result
					end
				elseif mode == "And" or mode == "Or" then
					local threads = {}
					for _, sequence in sequences do
						table.insert(threads, task.spawn(runSequence, sequence, variables))
					end

					local totalThreads = if mode == "And" then #threads else 1
					while true do
						local threadsFinished = 0
						for _, thread in threads do
							if coroutine.status(thread) ~= "dead" then
								continue
							end
							threadsFinished += 1
						end

						if threadsFinished >= totalThreads then
							break
						end
						task.wait()
					end

					for _, thread in threads do
						pcall(task.cancel, thread)
					end

					threads = nil :: any
				end
			end,
		} :: ActivatorData
	)
end
