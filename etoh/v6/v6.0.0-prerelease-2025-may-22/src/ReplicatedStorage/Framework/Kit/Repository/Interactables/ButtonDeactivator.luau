--!strict
--!optimize 2
--@version buttondeactivator-6.0.0
--@creator synnwave

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local deactivatorConfig = scope.instance
	if not deactivatorConfig or not deactivatorConfig.Parent or not deactivatorConfig.Parent:IsA("BasePart") then
		return
	end

	local deactivatorPart = deactivatorConfig.Parent

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
	}):CheckForChanges()
	local touchConfiguration =
		Config.GetConfig(scope, deactivatorConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

	local debounce = false
	local functionUtility = utility.Functions
	scope:add(deactivatorPart.Touched:Connect(function(toucher: BasePart)
		if debounce or deactivatorPart:GetAttribute("Activated") == false then
			return
		end
		if not utility.ClientObjects.evaluateToucher(deactivatorPart, toucher, touchConfiguration) then
			return
		end

		debounce = true
		task.delay(0.25, function()
			debounce = false
		end)

		local deactivatorColor = functionUtility.roundColor(deactivatorPart.Color)
		for button in buttonCache.Buttons do
			if not (configuration.ColorSpecific and functionUtility.roundColor(button.Color) ~= deactivatorColor) then
				buttonEvent:fire(Communicator.SET_PRESSED, button, false)
			end
		end
	end))
end
