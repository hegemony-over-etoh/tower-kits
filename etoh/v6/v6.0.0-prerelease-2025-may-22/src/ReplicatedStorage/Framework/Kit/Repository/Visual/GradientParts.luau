--!strict
--!optimize 2
--@version gradientparts-6.0.0
--@creator mario_123456

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local utility = scope:utility()
	local gradientPartsConfig = scope.instance
	if not gradientPartsConfig then
		return
	end

	local folder = gradientPartsConfig.Parent
	if not folder then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, gradientPartsConfig, {
		Speed = 60,
		DistanceAnchor = 100,
	}):CheckForChanges()

	local gradientParts: { BasePart } = {}
	for _, part in folder:GetDescendants() do
		if not (part:IsA("BasePart") and part.Name == "GradientPart") then
			continue
		end
		table.insert(gradientParts, part)
	end

	local distancePivot = folder:FindFirstChild("DistancePivot")
	if not (distancePivot and distancePivot:IsA("BasePart")) then
		return
	end
	local localPlayer = Players.LocalPlayer
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end
	local humanoidRootPart = humanoid.RootPart :: BasePart

	local uiGradient = folder:FindFirstChildWhichIsA("UIGradient")
	if not uiGradient then
		return
	end
	local colorSequence: { ColorSequenceKeypoint } = uiGradient.Color.Keypoints

	local function loopThroughColors()
		local paused = false

		for i, keypoint in colorSequence do
			if localPlayer:DistanceFromCharacter(distancePivot.Position) > configuration.DistanceAnchor then
				paused = true
			end
			task.wait(1 / configuration.Speed)

			if paused then
				continue
			end
			for _, part in gradientParts do
				local nextValue = colorSequence[i + 1]
				if not nextValue then
					nextValue = colorSequence[1]
				end
				local tween = utility.Functions.tween(
					part,
					1 / configuration.Speed,
					{ Color = nextValue.Value },
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.In
				)
			end
		end
	end

	local mainLoop
	mainLoop = scope:add(task.spawn(function()
		while true do
			loopThroughColors()
		end
	end))
end
