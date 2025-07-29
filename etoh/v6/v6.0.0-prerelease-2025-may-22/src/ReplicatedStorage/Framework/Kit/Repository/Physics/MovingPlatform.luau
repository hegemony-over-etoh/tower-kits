--!strict
--!optimize 2
--@version movingplatform-6.0.0
--@creator aamo_s

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local utility = scope:utility()

	local movingPlatformConfig = scope.instance
	if not movingPlatformConfig then
		return
	end

	local model = movingPlatformConfig.Parent
	if not model then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, movingPlatformConfig, {
		MoveDelay = 2,
		TouchActivated = false,
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, movingPlatformConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

	local platform = nil
	do
		for _, v in model:GetChildren() do
			if not v:IsA("BasePart") or v.Name ~= "Platform" then
				continue
			end

			if platform then
				scope:log({
					`{model:GetFullName()} has multiple 'Platform' objects. There should be one.`,
					type = "error",
					printType = "warn",
					traceback = false,
				})

				return
			end

			platform = v
		end
	end

	local platformAttachment = platform:FindFirstChildOfClass("Attachment")
	local positions = model:FindFirstChild("Positions")
	local alignOrientation = platform:FindFirstChildOfClass("AlignOrientation")
	local alignPosition = platform:FindFirstChildOfClass("AlignPosition")
	if not platformAttachment or not positions or not alignOrientation or not alignPosition then
		return
	end

	local positionAttachments = {}
	for _, position in positions:GetChildren() do
		local attachment = position:FindFirstChildOfClass("Attachment")
		local positionNumber = tonumber(position.Name) -- maybe use position.Name:match("%d+") ?
		if not position:IsA("BasePart") or not attachment or not positionNumber then
			continue
		end
		
		positionAttachments[positionNumber] = attachment
	end

	if not next(positionAttachments) then
		return
	end

	alignPosition.Attachment0 = platformAttachment
	alignOrientation.Attachment0 = platformAttachment

	local currentPositionNumber = 0
	local function moveToNextPosition()
		local positionNumbers = {}
		local hasNotLooped = true

		for number in positionAttachments do
			table.insert(positionNumbers, number)
		end

		table.sort(positionNumbers)

		local nextPosition = nil
		for i, number in positionNumbers do
			if number > currentPositionNumber then
				nextPosition = number
				break
			end
		end

		if not nextPosition then
			nextPosition = positionNumbers[1]
			hasNotLooped = false
		end

		if positionAttachments[nextPosition] then
			alignPosition.Position = positionAttachments[nextPosition].WorldPosition
			alignOrientation.CFrame = positionAttachments[nextPosition].WorldCFrame
			currentPositionNumber = nextPosition
		else
			scope:log({
				`{movingPlatformConfig:GetFullName()} has no position to go to!`,
				type = "error",
				printType = "warn",
				traceback = false,
			})
		end

		return hasNotLooped
	end

	moveToNextPosition()
	platform.Anchored = false

	scope:attach(platform)
	scope:add(task.delay(configuration.MoveDelay, function()
		while platform and platform:IsDescendantOf(workspace) do
			if configuration.TouchActivated then
				break
			end

			moveToNextPosition()
			task.wait(configuration.MoveDelay)
		end
	end))

	local active = false
	scope:add(platform.Touched:Connect(function(touchingPart)
		--print("something touched me")
		if
			not utility.ClientObjects.evaluateToucher(platform, touchingPart, touchConfiguration)
			or not configuration.TouchActivated
			or active
		then
			return
		end

		local looping = true
		active = true
		repeat
			looping = moveToNextPosition()
			task.wait(configuration.MoveDelay)
		until not looping
		active = false
	end))
end
