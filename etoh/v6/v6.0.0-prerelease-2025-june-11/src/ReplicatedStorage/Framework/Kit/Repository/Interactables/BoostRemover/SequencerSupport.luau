--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(rootScope: _T.Scope, cache: { [BasePart]: () -> () })
	local utility = rootScope:utility()
	local clientObjectUtil = utility.ClientObjects
	local sequencerScript = rootScope.repository["Interactables/Sequencer"]
	if typeof(sequencerScript) ~= "table" or not sequencerScript.Communicator then
		return
	end

	local SequencerCommunicator = sequencerScript.Communicator
	local sequencerRequest = rootScope:getCommunicator("request", SequencerCommunicator.KEY)
	task.spawn(utility.Functions.yieldTimeout, 5, function()
		sequencerRequest:request(SequencerCommunicator.REGISTER_OBJECT, "BoostRemover", {
			check = function(sequenceData, optimize)
				if not sequenceData.instance:IsA("BasePart") then
					return false
				end

				return cache[sequenceData.instance] ~= nil
			end,
			activate = function(sequenceData)
				local boosterFn = cache[sequenceData.instance]
				if typeof(boosterFn) == "function" then
					boosterFn()
				end
			end,
		})

		--> Cleanup
		sequencerScript = nil :: any
		sequencerRequest = nil :: any
		SequencerCommunicator = nil :: any
	end)
end
