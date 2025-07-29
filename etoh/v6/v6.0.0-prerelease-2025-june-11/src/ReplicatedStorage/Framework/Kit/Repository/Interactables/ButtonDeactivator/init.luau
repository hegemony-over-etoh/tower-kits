--!strict
--!optimize 2
--@version buttondeactivator-6.0.0
--@creator synnwave

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local SequencerSupport = require(script.SequencerSupport)

return function(scope: _T.Scope)
	local deactivatorConfig = scope.instance
	if not deactivatorConfig or not deactivatorConfig.Parent or not deactivatorConfig.Parent:IsA("BasePart") then
		return
	end

	local deactivatorPart = deactivatorConfig.Parent
    scope:attach(deactivatorPart)
    
	local buttonScript = scope.repository["Interactables/Button"]
	if typeof(buttonScript) ~= "table" then
		return -- Button script not used here
	end

	local Communicator = buttonScript.Communicator
	local buttonEvent = scope:getCommunicator("event", Communicator.KEY)
	local buttonRequest = scope:getCommunicator("request", Communicator.KEY)
	local buttonCache = buttonRequest:request(Communicator.AWAIT_CACHE)

	local utility = scope:utility()
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, deactivatorConfig, {
		ColorSpecific = true,
	}):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, deactivatorConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	local debounce = false
	local functionUtility = utility.Functions

	local cache = utility.Scope.getCached(scope, scope.scriptPath, function()
		local cache = {} :: { [BasePart]: () -> () }
		SequencerSupport(scope.rootScope, cache)
		return cache
	end)

	local function deactivate()
		local deactivatorColor = functionUtility.roundColor(deactivatorPart.Color)
		for _, button in buttonCache.Buttons do
			if not (configuration.ColorSpecific and functionUtility.roundColor(button.Color) ~= deactivatorColor) then
				button.Pressed.Value = false
			end
		end
	end

	cache[deactivatorPart] = deactivate
	scope:add(function()
		cache[deactivatorPart] = nil
	end)

	scope:add(deactivatorPart.Touched:Connect(function(toucher: BasePart)
		if
			debounce
			or deactivatorPart:GetAttribute("Activated") == false
			or not utility.ClientObjects.evaluateToucher(deactivatorPart, toucher, touchConfiguration)
		then
			return
		end

		debounce = true
		task.delay(0.25, function()
			debounce = false
		end)
		deactivate()
	end))
end
