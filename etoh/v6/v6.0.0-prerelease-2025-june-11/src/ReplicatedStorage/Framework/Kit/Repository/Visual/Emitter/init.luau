--!strict
--!optimize 2
--@version emitter-6.0.0
--@creator Camille, synnwave

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local SequencerSupport = require(script.SequencerSupport)

return function(scope: _T.Scope)
	--> Setup
	local utility = scope:utility()
	local emitterConfig = scope.instance
	if not emitterConfig then
		return
	end

	local emitter = emitterConfig.Parent
	if not emitter or not emitter:IsA("BasePart") then
		return
	end

	local cache = utility.Scope.getCached(scope, scope.scriptPath, function()
		local cache = {} :: { [BasePart]: () -> () }
		SequencerSupport(scope.rootScope, cache)
		return cache
	end)

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, emitterConfig, {
		GlobalSound = true,
		Uses = math.huge, -- refreshes when changed
		Cooldown = 1,
	}):ObserveChanges()

	local touchConfiguration =
		Config.GetConfig(scope, emitterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	scope:attach(emitter)

	--> Variables
	local cooldownActive = false
	local infiniteUses = configuration.Uses <= 0 -- if set to 0 at first, can be used infinite times

	--> Functions
	local function checkUses()
		if infiniteUses then
			return true
		end
		if configuration.Uses <= 0 then
			return false
		end

		configuration.Uses -= 1
		return true
	end

	local emitObjects = {} :: { ParticleEmitter | Sound }
	for _, descendant in emitter:GetDescendants() do
		if descendant:IsA("ParticleEmitter") or descendant:IsA("Sound") then
			table.insert(emitObjects, descendant)
		end
	end

	if #emitObjects <= 0 then
		scope:log({
			"Emitter has no objects to emit.",
			`Path: {emitter:GetFullName()}`,
			type = "warn",
			traceback = 3,
		})
		return
	end

	local random = Random.new()
	local function emit()
		for _, object in emitObjects do
			local delay = utility.Property.assureConfig(object, "EmitDelay", 0)
			task.delay(delay, function()
				if object:IsA("ParticleEmitter") then
					local emitCount = object:GetAttribute("EmitCount")
					if typeof(emitCount) == "NumberRange" then
						emitCount = random:NextInteger(emitCount.Min, emitCount.Max)
                    elseif typeof(emitCount) ~= "number" then
						emitCount = 0
					end

					object:Emit(emitCount)
				elseif object:IsA("Sound") then
					local sound = object:Clone()
					sound.Parent = if configuration.GlobalSound then script else emitter
					sound:Play()
					Debris:AddItem(sound, sound.TimeLength / sound.PlaybackSpeed)
				end
			end)
		end

		if configuration.Cooldown > 0 then
			cooldownActive = true
			task.delay(configuration.Cooldown, function()
				cooldownActive = false
			end)
		end
	end

	cache[emitter] = emit
	scope:add(function()
		cache[emitter] = nil
	end)

	--> Main functionality
	scope:add(emitter.Touched:Connect(function(toucher)
		if
			(not utility.ClientObjects.evaluateToucher(emitter, toucher, touchConfiguration))
			or emitter:GetAttribute("Activated") == false
			or cooldownActive
			or not checkUses()
		then
			return
		end

		emit()
	end))
end
