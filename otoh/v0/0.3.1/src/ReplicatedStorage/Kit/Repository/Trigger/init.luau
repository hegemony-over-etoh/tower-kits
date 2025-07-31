--!strict
-- junekept 2025

-- btw VariableTriggers are a basepart still so they are easier to visually work with
-- I'm trying to not make non-programmers have their head explode but it's a tough world out there

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local LemonSignal = require(Libraries.LemonSignal)
local Utility = require(Kit.Utility)

local Types = require(Kit.Types)

local TriggerList = require(script.TriggerList)
local TriggerTypes = require(script.TriggerTypes)
local TriggerFunctions = require(script.TriggerFunctions)

return function(object: Types.ClientObject)
	local trigger = object.instance
	local triggerType = trigger:GetAttribute("Type")
	
	-- sorry this genuinely sucks LOL
	if TriggerList[triggerType] then
		local triggerInfo = TriggerList[triggerType]
		
		if triggerInfo.setup then
			triggerInfo.setup(object)
		end
		
		object.signals.trigger = LemonSignal.new()
		
		if Utility.Tower.loadedTower.config.debug then
			TriggerFunctions.createDebugBeams(object)
			
			object.signals.activated = LemonSignal.new()
			object.signals.activated:Connect(function()
				for _, beam in object.instance:GetChildren() do
					if beam:IsA("Beam") and beam.Attachment1 and beam.Attachment0 and beam.Attachment0:IsDescendantOf(object.instance) then
						beam.Color = ColorSequence.new(Color3.new(0, 1, 0))
						task.delay(1, function()
							beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
						end)
					end
				end
			end)
		end
		
		for _, connectionInfo in triggerInfo.connections(object) do
			-- genuinely at a loss for words on how to possibly make this not stupid
			(connectionInfo.signal :: any):Connect(function(...: any)
				if not connectionInfo.clause or connectionInfo.clause(...) then
					local chainLinks = triggerInfo.behavior(object, TriggerFunctions.getArguments(object))
					TriggerFunctions.fireNextChain(object, chainLinks)
				end
			end)
		end
	end
end