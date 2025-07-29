--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)
local _TDefs = require(script.Parent.TypeDefs)

return function(rootScope: _T.Scope, cache: _TDefs.Cache)
	local utility = rootScope:utility()
	local clientObjectUtil = utility.ClientObjects
	local sequencerScript = rootScope.repository["Interactables/Sequencer"]
	if typeof(sequencerScript) ~= "table" or not sequencerScript.Communicator then
		return
	end

	local SequencerCommunicator = sequencerScript.Communicator
	local sequencerRequest = rootScope:getCommunicator("request", SequencerCommunicator.KEY)
	task.spawn(utility.Functions.yieldTimeout, 5, function()
        sequencerRequest:request(SequencerCommunicator.REGISTER_OBJECT, "PropertyChanger", {
			check = function(sequenceData, optimize)
				if not sequenceData.instance:IsA("BasePart") then
					return false
				end
				local isChanger = cache.changers[sequenceData.instance] ~= nil
                if isChanger then
					optimize(sequenceData.instance)
				end

                return isChanger
			end,
			activate = function(sequenceData)
                local changerFn = cache.changers[sequenceData.instance]
				if typeof(changerFn) == "function" then
					changerFn(nil, sequenceData.variables)
				end
			end,
		})

		--> Cleanup
		sequencerScript = nil :: any
		sequencerRequest = nil :: any
		SequencerCommunicator = nil :: any
	end)
end
