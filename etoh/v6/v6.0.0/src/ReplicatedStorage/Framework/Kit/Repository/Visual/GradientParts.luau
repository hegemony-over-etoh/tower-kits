--!strict
--!optimize 2
--@version gradientparts-6.0.0
--@creator mario_123456, synnwave
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 

PLEASE, **DO NOT** make any script edits to this script.
To make a script edit, please read the following:
https://etohgame.github.io/kit/docs/misc#writingediting-repository-scripts

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local PART_THROTTLE = 64

local localPlayer = Players.LocalPlayer

local GradientParts = {
	CanQueue = true,
	RunOnStart = false,
}

local GRADIENT_CONFIG_TEMPLATE = {
	MaxDistance = 100,
	RefreshRate = 30,
	Throttle = PART_THROTTLE,
	TickOffset = 0,
}

local function evaluateColorSequence(sequence: ColorSequence, time: number, tweenInfo: TweenInfo)
	if time <= 0 then
		return sequence.Keypoints[1].Value
	elseif time >= 1 then
		return sequence.Keypoints[#sequence.Keypoints].Value
	end

	for i = 1, #sequence.Keypoints - 1 do
		local thisKeypoint = sequence.Keypoints[i]
		local nextKeypoint = sequence.Keypoints[i + 1]
		if time >= thisKeypoint.Time and time < nextKeypoint.Time then
			local alpha = (time - thisKeypoint.Time) / (nextKeypoint.Time - thisKeypoint.Time)
			local thisColor = thisKeypoint.Value
			local nextColor = nextKeypoint.Value
			return Color3.new(
				math.lerp(thisColor.R, nextColor.R, alpha),
				math.lerp(thisColor.G, nextColor.G, alpha),
				math.lerp(thisColor.B, nextColor.B, alpha)
			)
		end
	end

	return Color3.new()
end

function GradientParts.Run(scope: _T.Scope, utility: _T.Utility)
	local gradientPartsConfig = scope.instance
	if not gradientPartsConfig then
		return
	end

	local folder = gradientPartsConfig.Parent
	if not folder then
		return
	end

	--> Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, gradientPartsConfig, GRADIENT_CONFIG_TEMPLATE):ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, gradientPartsConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()

	--> Get Parts
	local gradientParts: { BasePart } = {}
	local tag = "GradientPart"
	for _, part in folder:GetDescendants() do
		if not (part:IsA("BasePart") and (part.Name == tag or part:HasTag(tag))) then
			continue
		end

		table.insert(gradientParts, part)
	end

	--> Get Distance Pivot
	local distancePivot = folder:FindFirstChild("DistancePivot")
	if not (distancePivot and distancePivot:IsA("BasePart")) then
		scope:log({
			"GradientParts is missing its DistancePivot and cannot function correctly.",
			`Path: {folder:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Get Gradient
	local gradient = gradientPartsConfig:FindFirstChildWhichIsA("UIGradient")
	if not gradient then
		scope:log({
			"GradientParts is missing its Gradient and cannot function correctly.",
			`Path: {folder:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Main Loop
	scope:spawn(function()
		while task.wait(1 / math.clamp(configuration.RefreshRate, 0.5, 120)) do
			if localPlayer:DistanceFromCharacter(distancePivot.Position) > configuration.MaxDistance then
				continue
			end

			local tweenInfo =
				TweenInfo.new(tweenConfiguration.Time, tweenConfiguration.Style, tweenConfiguration.Direction)
			local alpha = ((os.clock() + configuration.TickOffset) % tweenInfo.Time) / tweenInfo.Time
			alpha = TweenService:GetValue(alpha, tweenInfo.EasingStyle, tweenInfo.EasingDirection)

			local color = evaluateColorSequence(gradient.Color, alpha, tweenInfo)
			local throttle = configuration.Throttle
			for i, part in gradientParts do
				if i % throttle == 0 then
					task.wait()
				end

				part.Color = color
			end
		end
	end)
end

return GradientParts
