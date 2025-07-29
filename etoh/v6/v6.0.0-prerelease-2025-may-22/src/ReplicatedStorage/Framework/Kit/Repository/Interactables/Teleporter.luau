--!strict
--!optimize 2
--@version teleporter-6.0.0
--@creator mario_123456

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

-- TODO: refactor code, add seamless teleport mode

return function(scope: _T.Scope)
	local utility = scope:utility()
	local teleporterConfig = scope.instance
	if not teleporterConfig then
		return
	end

	local teleporter = teleporterConfig.Parent
	if not teleporter then
		return
	end

	local teleporterParts: { BasePart } = {}
	local destinationParts: { BasePart } = {}
	for _, part in teleporter:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		if part.Name == "Destination" then
			table.insert(destinationParts, part)
		elseif part.Name == "Teleporter" then
			table.insert(teleporterParts, part)
		end
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, teleporterConfig, {
		EasingDirection = Enum.EasingDirection.In,
		EasingStyle = Enum.EasingStyle.Linear,
		Instant = true,
		KeepVelocity = true,
		Offset = Vector3.new(0, 3, 0),
		TweenTime = 1,
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, teleporterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

	local function reduceVelocity(model: Instance)
		for _, part in model:GetDescendants() do
			if not part:IsA("BasePart") then
				continue
			end
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local localPlayer = Players.LocalPlayer

	scope:attach(teleporter)
	for _, teleporter in teleporterParts do
		local teleportBool: boolean = false
		scope:add(teleporter.Touched:Connect(function(touchingPart: BasePart)
			if not utility.ClientObjects.evaluateToucher(teleporter, touchingPart, touchConfiguration) then
				return
			end
			if teleportBool then
				return
			end

			local part: BasePart?
			local character = localPlayer.Character
			if character and touchingPart:IsDescendantOf(character) then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if not (rootPart and rootPart:IsA("BasePart")) then
					return
				end

				part = rootPart
			elseif utility.ClientObjects.isPushbox(touchingPart) then
				part = touchingPart
			end

			if not (part and part.Parent) then
				return
			end
			teleportBool = true

			local easingStyle: Enum.EasingStyle, easingDirection: Enum.EasingDirection
			if typeof(configuration.EasingStyle) == "string" then
				easingStyle = Enum.EasingStyle[configuration.EasingStyle]
			else
				easingStyle = configuration.EasingStyle
			end
			if typeof(configuration.EasingDirection) == "string" then
				easingDirection = Enum.EasingDirection[configuration.EasingDirection]
			else
				easingDirection = configuration.EasingDirection
			end

			local chosenDestination = destinationParts[math.random(1, #destinationParts)] :: BasePart
			if configuration.Instant then
				part.CFrame = chosenDestination.CFrame * CFrame.new(configuration.Offset)
				utility.Functions.playSoundFromInstance(chosenDestination, chosenDestination, "Teleport")

				if (not utility.ClientObjects.isPushbox(part)) and not configuration.KeepVelocity then
					reduceVelocity(part.Parent)
				elseif (not configuration.KeepVelocity) and utility.ClientObjects.isPushbox(part) then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
				teleportBool = false
			else
				part.Anchored = true
				local tween = utility.Functions.tween(
					part,
					configuration.TweenTime,
					{ CFrame = chosenDestination.CFrame * CFrame.new(configuration.Offset) },
					easingStyle,
					easingDirection
				)

				utility.Functions.playSoundFromInstance(chosenDestination, chosenDestination, "Teleport")
				tween:Play()
				tween.Completed:Once(function()
					tween:Destroy()
					teleportBool = false
					part.Anchored = false
				end)
			end
		end))
	end
end
