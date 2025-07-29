--!strict
--!optimize 2
--@version balloon-6.0.0
--@creator Gammattor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local TOUCH_COOLDOWN = 0.1

return function(scope: _T.Scope)
	local utility = scope:utility()
	local JumpButton = utility.JumpButton

	local balloonConfig = scope.instance
	if not balloonConfig then
		return
	end

	local balloonDispenser = balloonConfig.Parent
	local dispenser = balloonDispenser and balloonDispenser:FindFirstChild("Dispenser") :: BasePart
	local balloonTemplate = balloonDispenser and balloonDispenser:FindFirstChild("BalloonModel") :: Model
	local barTemplate = script:FindFirstChild("RopeBar")
	if not (balloonDispenser and dispenser and balloonTemplate and barTemplate) then
		local errorName = if balloonDispenser then balloonDispenser.Name else script.Name
		scope:log({ errorName .. " is missing one or more critical parts and cannot function.", type = "warn" })
		return
	end

	local templateContainer = ReplicatedStorage:FindFirstChild("_BalloonTemplates")
	if not templateContainer then
		templateContainer = Instance.new("Folder")
		templateContainer.Name = "_BalloonTemplates"
		templateContainer.Parent = ReplicatedStorage
	end
	balloonTemplate.Parent = templateContainer

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
	local configuration = Config.GetConfig(scope, balloonConfig, {
		AllowJumpDismount = true,
		DestroyWhenExpired = true,
		KeepMomentum = true,
		Force = 5,
		MaxHeight = 0,
		RopeLength = 5,
		Timer = 0,
	}):ObserveChanges()

	local touchConfiguration =
		Config.GetConfig(scope, balloonConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, balloonConfig:FindFirstChild("InflateTweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()
	local timerGuiTemplate = balloonConfig:FindFirstChild("TimerGui") :: BillboardGui

	local soundsFolder = balloonDispenser:FindFirstChild("Sounds")
		or (function()
			local newSounds = Instance.new("Folder")
			newSounds.Parent = balloonDispenser
			return newSounds
		end)()

	scope:attach(balloonDispenser)
	----------------------------------------------------------------------------
	--> Dispense balloon
	local rideDebounce = {}
	local rideScope = scope:inherit()
	scope:add(dispenser.Touched:Connect(function(touch)
		if
			dispenser:GetAttribute("Activated") == false
			or not utility.ClientObjects.evaluateToucher(dispenser, touch, touchConfiguration)
		then
			return
		end

		local isPlayer = table.find(utility.Character.getHitbox("StaticWholeBody"), touch)
		local isBox = utility.ClientObjects.isPushbox(touch, true)

		if not (isPlayer or isBox) then
			return
		end
	
		local attachTo = if isPlayer then rootPart else touch
		if rideDebounce[attachTo] then
			return
		end
		
		rideDebounce[attachTo] = true
		if not mountedCOs[attachTo] then
			mountedCOs[attachTo] = {}
		end
		mountedCOs[attachTo][balloonDispenser] = "Balloon"

		------------------------------------------------------------------------
		--> Create balloon model
		local ropeBar = barTemplate:Clone()
		rideScope:attach(ropeBar)
		ropeBar.Color = dispenser.Color
		ropeBar.CFrame = attachTo.CFrame + attachTo.CFrame.UpVector * (attachTo.Size.Y / 2)
		ropeBar.Parent = balloonDispenser
		if isPlayer then
			utility.Character.carryPart(true, ropeBar)
		else
			local barWeld = Instance.new("WeldConstraint")
			barWeld.Part0 = ropeBar
			barWeld.Part1 = attachTo
			barWeld.Parent = ropeBar
		end

		local balloon = balloonTemplate:Clone()
		rideScope:attach(balloon)
		balloon.Parent = balloonDispenser

		local main = balloon:FindFirstChild("Main") :: BasePart
			or (function()
				local blankMain = Instance.new("Part")
				blankMain.Size = Vector3.zero
				blankMain.Transparency = 1
				blankMain.CanCollide = false
				blankMain.CFrame = balloon:GetPivot()
				blankMain.Parent = balloon
				return blankMain :: BasePart
			end)()
		main.Anchored = false

		local balloonAtt = main:FindFirstChild("BalloonAttachment") :: Attachment
			or (function()
				local newAtt = Instance.new("Attachment")
				newAtt.Parent = main
				return newAtt
			end)()

		local alignOrientation = main:FindFirstChildOfClass("AlignOrientation")
		if alignOrientation then
			alignOrientation.CFrame = main.CFrame
		end
		if main:IsA("Part") and main.TopSurface == Enum.SurfaceType.Hinge then
			main.TopSurface = Enum.SurfaceType.Smooth
		end

		if configuration.RopeLength > 0 then
			local ropeConstraint = ropeBar:FindFirstChildOfClass("RopeConstraint")
			if not (ropeConstraint and ropeConstraint.Attachment0) then
				scope:log({ `The {script.Name} script's rope constraint is not set up properly.`, type = "warn" })
				rideScope:cleanup()
				return
			end

			balloon:PivotTo(CFrame.new(dispenser.Position) * balloon:GetPivot().Rotation)
			ropeConstraint.Color = dispenser.BrickColor
			ropeConstraint.Length = configuration.RopeLength
			ropeConstraint.Attachment1 = balloonAtt
		else
			local zeroLengthConstraint = ropeBar:FindFirstChild("ZeroLengthConstraint")
			if not (zeroLengthConstraint and zeroLengthConstraint.Part0) then
				scope:log({ `The {script.Name} script's zero length constraint is not set up properly.`, type = "warn" })
				rideScope:cleanup()
				return
			end

			local pivotPosition = ropeBar.Position + Vector3.yAxis * (main.Size.Y / 2)
			balloon:PivotTo(CFrame.new(pivotPosition) * balloon:GetPivot().Rotation)
			zeroLengthConstraint.Part1 = main
			zeroLengthConstraint.Enabled = true
		end

		local attachedToValue = Instance.new("ObjectValue")
		attachedToValue.Name = "_AttachedTo"
		attachedToValue.Value = attachTo
		attachedToValue.Parent = main

		utility.ClientObjects.scanFolder(rideScope, balloon, true)

		------------------------------------------------------------------------
		--> Inflate balloon
		utility.Functions.playSoundFromInstance(main, soundsFolder, "Inflate")
		for _, balloonPart in balloon:GetDescendants() do
			if not (balloonPart:IsA("BasePart") and balloonPart:GetAttribute("Inflate")) then
				continue
			end
			local originalSize = balloonPart.Size
			balloonPart.Size = Vector3.zero
			utility.Functions.tween(balloonPart, tweenConfiguration, { Size = originalSize })
		end

		------------------------------------------------------------------------
		--> Dismount function
		local function dismountBalloon()
			rideScope:cleanup(true)

			if attachTo and not configuration.KeepMomentum then
				attachTo.AssemblyLinearVelocity = Vector3.zero
			end
			if isPlayer then
				utility.Character.carryPart(false, ropeBar)
				humanoid.PlatformStand = false
				humanoid:ChangeState("Jumping")
			end
			utility.Functions.playSoundFromInstance(attachTo, soundsFolder, "Pop")

			if mountedCOs[attachTo] and mountedCOs[attachTo][balloonDispenser] then
				mountedCOs[attachTo][balloonDispenser] = nil
				if #mountedCOs[attachTo] < 1 then
					mountedCOs[attachTo] = nil
				end
			end

			task.delay(TOUCH_COOLDOWN, function()
				rideDebounce[attachTo] = nil
			end)
		end

		------------------------------------------------------------------------
		--> Move balloon
		local maxForce = Vector3.one * 10000000
		local upVector = main.CFrame.UpVector
		if math.abs(upVector.X) < 0.1 and math.abs(upVector.Z) < 0.1 then
			maxForce = Vector3.yAxis * 10000000
		end

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		linearVelocity.MaxAxesForce = maxForce
		linearVelocity.VectorVelocity = upVector * configuration.Force
		linearVelocity.Attachment0 = balloonAtt
		linearVelocity.Parent = main

		------------------------------------------------------------------------
		--> Pop conditions
		if configuration.AllowJumpDismount then
			rideScope:add(JumpButton.JumpEvent.Event:Connect(function(isPressed: boolean)
				if not isPressed then
					return
				end
				dismountBalloon()
			end))
		end

		local startTime = os.clock()
		local useTimer = configuration.Timer > 0
		local useMaxHeight = configuration.MaxHeight ~= 0
		
		local timerLabel
		if timerGuiTemplate and useTimer then
			local timerGui = timerGuiTemplate:Clone()
			timerGui.Parent = main
			timerGui.Enabled = true

			timerLabel = timerGui:FindFirstChild("TimerLabel") :: TextLabel
			if timerLabel then
				timerLabel.TextColor3 = main.Color
				timerLabel.Text = tostring(configuration.Timer)
			end
		end

		rideScope:add(task.spawn(function()
			while task.wait() do
				debug.profilebegin("Balloon Checking")
				if not attachTo or not attachTo.Parent then
					dismountBalloon()
					break
				elseif not (mountedCOs[attachTo] and mountedCOs[attachTo][balloonDispenser]) then
					dismountBalloon()
					break
				end

				if not (configuration.DestroyWhenExpired or linearVelocity.VectorVelocity ~= Vector3.zero) then
					debug.profileend()
					continue
				end

				if useTimer then
					if timerLabel then
						local displayTime = math.ceil(configuration.Timer - (os.clock() - startTime))
						if tostring(displayTime) ~= timerLabel.Text then
							timerLabel.Visible = displayTime > 0
							timerLabel.Text = tostring(displayTime)
							utility.Functions.playSoundFromInstance(main, soundsFolder, "TimerTick")
						end
					end

					if os.clock() - startTime > configuration.Timer then
						if configuration.DestroyWhenExpired then
							dismountBalloon()
							break
						else
							linearVelocity.VectorVelocity = Vector3.zero
						end
					end
				end
				
				local isAbove = configuration.Force > 0 and main.Position.Y > dispenser.Position.Y + configuration.MaxHeight
				local isBelow = configuration.Force < 0 and main.Position.Y < dispenser.Position.Y + configuration.MaxHeight

				if useMaxHeight and (isAbove or isBelow) then
					if configuration.DestroyWhenExpired then
						dismountBalloon()
						break
					else
						linearVelocity.VectorVelocity = Vector3.zero
					end
				end

				debug.profileend()
			end
		end))
	end))
end
