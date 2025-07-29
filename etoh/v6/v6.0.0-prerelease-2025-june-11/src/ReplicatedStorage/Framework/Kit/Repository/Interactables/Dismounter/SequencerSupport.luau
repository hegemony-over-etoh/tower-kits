--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(rootScope: _T.Scope, cache: { [BasePart]: (touch: BasePart) -> () })
	local utility = rootScope:utility()
	local clientObjectUtil = utility.ClientObjects
	local sequencerScript = rootScope.repository["Interactables/Sequencer"]
	if typeof(sequencerScript) ~= "table" or not sequencerScript.Communicator then
		return
	end

	local localPlayer = Players.LocalPlayer

	local SequencerCommunicator = sequencerScript.Communicator
	local sequencerRequest = rootScope:getCommunicator("request", SequencerCommunicator.KEY)
	task.spawn(utility.Functions.yieldTimeout, 5, function()
		sequencerRequest:request(SequencerCommunicator.REGISTER_OBJECT, "Dismounter", {
			check = function(sequenceData, optimize)
				if not sequenceData.instance:IsA("BasePart") then
					return false
				end

				return cache[sequenceData.instance] ~= nil
			end,
			activate = function(sequenceData)
				local character = localPlayer.Character
				if not character then
					return
				end
				local humanoid = character:FindFirstChildWhichIsA("Humanoid")
				if not humanoid or not humanoid.RootPart then
					return
				end

				local dismountFn = cache[sequenceData.instance]
				if typeof(dismountFn) == "function" then
					dismountFn(humanoid.RootPart)
				end
			end,
		})

		--> Cleanup
		sequencerScript = nil :: any
		sequencerRequest = nil :: any
		SequencerCommunicator = nil :: any
	end)
end
