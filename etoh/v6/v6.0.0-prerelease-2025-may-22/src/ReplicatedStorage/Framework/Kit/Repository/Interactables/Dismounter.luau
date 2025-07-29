--!strict
--!optimize 2
--@version dismounter-6.0.0
--@creator Gammattor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local mountPartNames = {
	["Zipline"] = "MountPart",
	["Balloon"] = "Dispenser",
	["Vine"] = "VinePart",
	["Swing"] = "Handle",
	["Attacher"] = "Trigger",
}

return function(scope: _T.Scope)
	local utility = scope:utility()
	local dismounterConfig = scope.instance
	if not dismounterConfig or not dismounterConfig.Parent or not dismounterConfig.Parent:IsA("BasePart") then
		return
	end

	local dismounter = dismounterConfig.Parent

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	if not rootPart then
		return
	end

	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, dismounterConfig, {
		Cooldown = 0,
		MountColorSpecific = false,
		DismountAttachers = true,
		DismountBalloons = true,
		DismountSeats = true,
		DismountSwings = true,
		DismountVines = true,
		DismountZiplines = true,
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, dismounterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

	local dismounterDebounce = false
	scope:add(dismounter.Touched:Connect(function(touch)
		if
			dismounterDebounce
			or dismounter:GetAttribute("Activated") == false
			or not utility.ClientObjects.evaluateToucher(dismounter, touch, touchConfiguration)
		then
			return
		end

		if utility.ClientObjects.isBalloon(touch) then
			local attachedToValue = touch:FindFirstChild("_AttachedTo") :: ObjectValue
			if attachedToValue and attachedToValue.Value and attachedToValue.Value:IsA("BasePart") then
				touch = attachedToValue.Value
			else
				return
			end
		end

		local setDebounce = false
		local isBox = utility.ClientObjects.isPushbox(touch)
		local attachedRoot = if isBox then touch else rootPart

		if not mountedCOs[attachedRoot] then
			return
		end

		for model, name in mountedCOs[attachedRoot] do
			if not configuration[`Dismount{name}s`] then
				continue
			end

			if configuration.MountColorSpecific then
				local mountPartName = mountPartNames[name]
				local mountPart = if model:IsA("BasePart")
					then model
					else model:FindFirstChild(mountPartName) :: BasePart

				if mountPart and mountPart.Color ~= dismounter.Color then
					continue
				end
			end

			setDebounce = true
			mountedCOs[attachedRoot][model] = nil
			if #mountedCOs[attachedRoot] < 1 then
				mountedCOs[attachedRoot] = nil
				break
			end
		end

		if setDebounce then
			dismounterDebounce = true
			task.delay(configuration.Cooldown, function()
				dismounterDebounce = false
			end)
		end
	end))
end
