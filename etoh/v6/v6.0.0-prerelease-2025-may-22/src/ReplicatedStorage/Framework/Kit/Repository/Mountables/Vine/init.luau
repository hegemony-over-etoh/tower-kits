--!strict
--!optimize 2
--@version vine-6.0.0
--@creator Gammattor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local utility = scope:utility()
	local JumpButton = utility.JumpButton

	local vineConfig = scope.instance
	if not vineConfig then
		return
	end

	local vine = vineConfig.Parent
	local vinePart = vine and vine:FindFirstChild("VinePart") :: BasePart
	local attachmentPart = vine and vine:FindFirstChild("AttachmentPart") :: BasePart
	local barTemplate = script:FindFirstChild("RopeBar")
	if not (vine and vinePart and attachmentPart and barTemplate) then
		local errorName = if vine then vine.Name else script.Name
		scope:log({ errorName .. " is missing one or more critical parts and cannot function.", type = "warn" })
		return
	end

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
	local configuration = Config.GetConfig(scope, vineConfig, {
		AllowJumpDismount = true,
		KeepMomentum = true,
		RespawnTime = 1,
		RopeLength = 8,
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, vineConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):CheckForChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, vineConfig:FindFirstChild("RespawnTweenConfiguration"), Config.TWEEN_CONFIG)
			:CheckForChanges()

	local soundsFolder = vine:FindFirstChild("Sounds")
		or (function()
			local newSounds = Instance.new("Folder")
			newSounds.Parent = vine
			return newSounds
		end)()
	local particleEmitter = vinePart:FindFirstChild("RespawnParticle") :: ParticleEmitter

	local defaultTransparency = vinePart.Transparency
	local returnDefaultTags = { "Invisible", "IgnoreTransparency", "IgnoreAll" }
	local function getDefaultTransparency()
		for _, tag in returnDefaultTags do
			if vinePart:HasTag(tag) then
				return defaultTransparency
			end
		end

		if vinePart:HasTag("ButtonActivated") then
			if vinePart:GetAttribute("Activated") then
				return utility.Property.assureConfig(vinePart, "SetTransparency", 0)
			else
				return if vinePart:HasTag("FullHidePlatform") then 1 else 0.6
			end
		else
			return defaultTransparency
		end
	end

	scope:attach(vine)

	----------------------------------------------------------------------------
	--> Mount vine
	local respawnTween
	local rideDebounce = false
	local rideScope = scope:inherit()

	scope:add(vinePart.Touched:Connect(function(touch)
		if vinePart:GetAttribute("Activated") == false or rideDebounce then
			return
		end

		if not utility.ClientObjects.evaluateToucher(vinePart, touch, touchConfiguration) then
			return
		end

		local isPlayer = table.find(utility.Character.getHitbox("StaticWholeBody"), touch)
		local isBox = utility.ClientObjects.isPushbox(touch, true)

		if not (isPlayer or isBox) then
			return
		end
		local attachedRoot = if isPlayer then rootPart else touch

		rideDebounce = true
		if not mountedCOs[attachedRoot] then
			mountedCOs[attachedRoot] = {}
		end
		mountedCOs[attachedRoot][vine] = "Vine"

		utility.Functions.playSoundFromInstance(attachedRoot, soundsFolder, "Grab")

		if respawnTween then
			respawnTween:Cancel()
		end
		vinePart.Transparency = 1

		----------------------------------------------------------------------------
		--> Attachment
		local ropeBar = barTemplate:Clone()
		rideScope:attach(ropeBar)
		ropeBar.Color = attachmentPart.Color
		ropeBar.CFrame = attachedRoot.CFrame + attachedRoot.CFrame.UpVector * (attachedRoot.Size.Y / 2)
		ropeBar.Parent = vine
		if isPlayer then
			utility.Character.carryPart(true, ropeBar)
		else
			local barWeld = Instance.new("WeldConstraint")
			barWeld.Part0 = ropeBar
			barWeld.Part1 = attachedRoot
			barWeld.Parent = ropeBar
		end

		local topAttachment = attachmentPart:FindFirstChild("VineAttachment") :: Attachment
			or (function()
				local newAtt = Instance.new("Attachment")
				newAtt.Name = "VineAttachment"
				newAtt.CFrame *= CFrame.Angles(0, 0, math.pi * 0.5)
				newAtt.Parent = attachmentPart
				return newAtt
			end)()

		if configuration.RopeLength > 0 then
			local ropeConstraint = ropeBar:FindFirstChildOfClass("RopeConstraint")
			if not (ropeConstraint and ropeConstraint.Attachment0) then
				scope:log({ `The {script.Name} script's rope constraint is not set up properly.`, type = "warn" })
				rideScope:cleanup()
				return
			end

			ropeConstraint.Color = attachmentPart.BrickColor
			ropeConstraint.Length = configuration.RopeLength
			ropeConstraint.Attachment1 = topAttachment
		else
			local zeroLengthConstraint = ropeBar:FindFirstChild("ZeroLengthConstraint")
			if not (zeroLengthConstraint and zeroLengthConstraint.Attachment0) then
				scope:log({ `The {script.Name} script's zero length constraint is not set up properly.`, type = "warn" })
				rideScope:cleanup()
				return
			end

			ropeBar:PivotTo(attachmentPart.CFrame)
			zeroLengthConstraint.Attachment1 = topAttachment
			zeroLengthConstraint.Enabled = true
		end

		------------------------------------------------------------------------
		--> Dismount function
		local function dismountVine()
			rideScope:cleanup(true)

			if attachedRoot and not configuration.KeepMomentum then
				attachedRoot.AssemblyLinearVelocity = Vector3.zero
			end
			if isPlayer then
				utility.Character.carryPart(false, ropeBar)
				humanoid.PlatformStand = false
				humanoid:ChangeState("Jumping")
				utility.Functions.playSoundFromInstance(attachedRoot, soundsFolder, "Jump")
			end

			if mountedCOs[attachedRoot] and mountedCOs[attachedRoot][vine] then
				mountedCOs[attachedRoot][vine] = nil
				if #mountedCOs[attachedRoot] < 1 then
					mountedCOs[attachedRoot] = nil
				end
			end

			task.delay(configuration.RespawnTime, function()
				respawnTween =
					utility.Functions.tween(vinePart, tweenConfiguration, { Transparency = getDefaultTransparency() })

				if particleEmitter then
					particleEmitter.Enabled = true
					respawnTween.Completed:Once(function()
						particleEmitter.Enabled = false
					end)
				end

				rideDebounce = false
			end)
		end

		if configuration.AllowJumpDismount then
			rideScope:add(JumpButton.JumpEvent.Event:Connect(function(isPressed: boolean)
				if not isPressed then
					return
				end
				dismountVine()
			end))
		end

		rideScope:add(task.spawn(function()
			while task.wait() do
				debug.profilebegin("Vine Checking")
				if not attachedRoot or not attachedRoot.Parent then
					dismountVine()
					break
				elseif not (mountedCOs[attachedRoot] and mountedCOs[attachedRoot][vine]) then
					dismountVine()
					break
				end
				debug.profileend()
			end
		end))
	end))
end
