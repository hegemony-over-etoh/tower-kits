--!strict
--!optimize 2
--@version zipline-6.0.0
--@creator Gammattor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local function bezier(alpha: number, pointTable: { Vector3 })
	pointTable = table.clone(pointTable)
	while #pointTable > 1 do
		for i = 1, #pointTable - 1 do
			pointTable[i] = pointTable[i]:Lerp(pointTable[i + 1], alpha)
		end
		pointTable[#pointTable] = nil
	end
	return pointTable[1]
end

local CONTROL_ACCEL_TIME = 1 / 0.25
local TOUCH_COOLDOWN = 0.1

return function(scope: _T.Scope)
	local utility = scope:utility()
	local ziplineConfig = scope.instance
	if not ziplineConfig then
		return
	end

	local zipline = ziplineConfig.Parent
	local mountPart = zipline and zipline:FindFirstChild("MountPart") :: BasePart
	local pointFolder = zipline and zipline:FindFirstChild("Points")
	local rideTemplate = script:FindFirstChild("RideModel")
	if not (zipline and mountPart and pointFolder and rideTemplate) then
		local errorName = if zipline then zipline.Name else script.Name
		scope:log({ errorName .. " is missing one or more critical parts and cannot function.", type = "warn" })
		return
	end

	for _, point in pointFolder:GetChildren() do
		if not point:IsA("BasePart") then
			continue
		end
		point.Transparency = 1
		point.CanCollide = false
		point.Size = Vector3.zero
	end

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	if not rootPart then
		return
	end

	local playerModule = player.PlayerScripts:WaitForChild("PlayerModule")
	local controls = require(playerModule.ControlModule)

	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, ziplineConfig, {
		AllowEndDismount = true,
		AllowJumpDismount = true,
		AllowUserControl = false,
		GuideColor = Color3.fromRGB(255, 255, 0),
		KeepMomentum = false,
		RopeLength = 0,
		Segments = 20,
		Speed = 5,
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, ziplineConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

	local soundsFolder = zipline:FindFirstChild("Sounds")
		or (function()
			local newSounds = Instance.new("Folder")
			newSounds.Parent = zipline
			return newSounds
		end)()
	local effectsFolder = zipline:FindFirstChild("GuideEffects")
		or (function()
			local newEffects = Instance.new("Folder")
			newEffects.Parent = zipline
			return newEffects
		end)()
	local particleEmitter = effectsFolder:FindFirstChildOfClass("ParticleEmitter")
		or (function()
			local blankParticle = Instance.new("ParticleEmitter")
			blankParticle.Parent = effectsFolder
			blankParticle.Transparency = NumberSequence.new(1)
			return blankParticle
		end)()
	local loopSound = effectsFolder:FindFirstChild("ZiplineLoop") :: Sound
		or (function()
			local blankSound = Instance.new("Sound")
			blankSound.Parent = effectsFolder
			return blankSound
		end)()

	scope:attach(zipline)
	----------------------------------------------------------------------------
	--> Set up curve
	-- enforce a 100 segment limit (to reduce lag, i promise 100 will be smooth enough)
	configuration.Segments = math.min(configuration.Segments, 100)
	
	local pointTable: { Vector3 } = { mountPart.Position }
	local segments: { BasePart } = {}

	for pointNum = 1, #pointFolder:GetChildren() do
		local point = pointFolder:FindFirstChild(tostring(pointNum))
		if not point or not point:IsA("BasePart") then
			continue
		end

		table.insert(pointTable, point.Position)
	end
	
	if #pointTable <= 2 then
		configuration.Segments = 1
	end

	local previousCurvePos = bezier(0, pointTable)
	for segmentNum = 1, configuration.Segments do
		local newSegment = Instance.new("Part")
		newSegment.CanCollide = false
		newSegment.CanTouch = false
		newSegment.CanQuery = false
		newSegment.Massless = true
		newSegment.Shape = Enum.PartType.Cylinder
		newSegment.Color = mountPart.Color
		newSegment.Material = Enum.Material.SmoothPlastic
		local segmentWeld = Instance.new("WeldConstraint")
		segmentWeld.Part0 = newSegment
		segmentWeld.Part1 = mountPart
		segmentWeld.Parent = newSegment

		local nextCurvePos = bezier(segmentNum / configuration.Segments, pointTable)
		newSegment.Size = Vector3.new((nextCurvePos - previousCurvePos).Magnitude, 0.25, 0.25)
		newSegment.CFrame = CFrame.lookAt(previousCurvePos, nextCurvePos) * CFrame.Angles(0, math.pi * 0.5, 0)
		newSegment.CFrame += newSegment.CFrame.RightVector * (newSegment.Size.X * 0.5)
		newSegment.Parent = zipline
		table.insert(segments, newSegment)

		previousCurvePos = nextCurvePos
	end

	----------------------------------------------------------------------------
	--> Zipline riding
	local JumpButton = utility.JumpButton
	local rideDebounce = {}
	local rideScope = scope:inherit()
	local touchDebounce = false
	scope:add(mountPart.Touched:Connect(function(touch)
		if
			mountPart:GetAttribute("Activated") == false
			or touchDebounce
			or not utility.ClientObjects.evaluateToucher(mountPart, touch, touchConfiguration)
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
		
		touchDebounce = true
		task.delay(0.1, function()
			touchDebounce = false
		end)

		rideDebounce[attachTo] = true
		if not mountedCOs[attachTo] then
			mountedCOs[attachTo] = {}
		end
		mountedCOs[attachTo][zipline] = "Zipline"
		utility.Functions.playSoundFromInstance(mountPart, soundsFolder, "Grab")

		------------------------------------------------------------------------
		--> Create ride model
		local segmentStartCF = segments[1].CFrame - segments[1].CFrame.RightVector * (segments[1].Size.X * 0.5)
		local rideModel = rideTemplate:Clone()
		rideModel:PivotTo(segmentStartCF * CFrame.Angles(0, -math.pi * 0.5, 0))
		rideModel.Parent = zipline
		rideScope:attach(rideModel)

		local ropeBar = rideModel:FindFirstChild("RopeBar")
		local ropeGuide = rideModel:FindFirstChild("RopeGuide")
		if not (ropeBar and ropeGuide) then
			rideModel:Destroy()
			return
		end

		local ropeConstraint = ropeBar:FindFirstChildOfClass("RopeConstraint")
		local particleClone = particleEmitter:Clone()
		local loopSoundClone = loopSound:Clone()
		if not ropeConstraint then
			rideModel:Destroy()
			scope:log({ `The {script.Name} script does not have its rope bar correctly set up.`, type = "warn" })
			return
		end

		ropeConstraint.Length = configuration.RopeLength
		ropeConstraint.Color = mountPart.BrickColor
		particleClone.Parent = ropeGuide
		particleClone.Rate = configuration.Speed
		particleClone.Enabled = true
		loopSoundClone.Parent = ropeGuide
		if not configuration.AllowUserControl then
			loopSoundClone:Play()
		end

		ropeGuide.Color = configuration.GuideColor
		ropeBar.Color = mountPart.Color

		attachTo.CFrame = mountPart.CFrame - mountPart.CFrame.UpVector * (attachTo.Size.Y / 2 + 1)
		if isPlayer then
			utility.Character.carryPart(true, ropeBar)
			humanoid.PlatformStand = true
		else
			local barWeld = Instance.new("WeldConstraint")
			barWeld.Part0 = ropeBar
			barWeld.Part1 = attachTo
			barWeld.Parent = ropeBar
		end

		------------------------------------------------------------------------
		--> Dismount function
		local function dismountZipline()
			rideScope:cleanup(true)

			if isPlayer then
				utility.Character.carryPart(false, ropeBar)
				humanoid.PlatformStand = false
				humanoid:ChangeState("Jumping")
			end
			utility.Functions.playSoundFromInstance(attachTo, soundsFolder, "Jump")

			if mountedCOs[attachTo] and mountedCOs[attachTo][zipline] then
				mountedCOs[attachTo][zipline] = nil
				if #mountedCOs[attachTo] < 1 then
					mountedCOs[attachTo] = nil
				end
			end

			task.delay(TOUCH_COOLDOWN, function()
				rideDebounce[attachTo] = nil
			end)
		end

		------------------------------------------------------------------------
		--> Move ride
		local segmentProgress = 0
		local currentSegment = 1
		local currentDirection = if configuration.AllowUserControl then 0 else 1
		-- 1 = forward, 0 = idle, -1 = backward

		local IsDown = JumpButton.IsDown
		rideScope:add(RunService.Heartbeat:Connect(function(deltaTime)
			debug.profilebegin("Zipline Movement")
			local segmentPart = segments[currentSegment]
			if not segmentPart then
				rideScope:cleanup()
				return
			end

			local goalCF = segmentPart.CFrame
				+ segmentPart.CFrame.RightVector * (segmentProgress - (segmentPart.Size.X * 0.5))
			ropeGuide.CFrame = goalCF * CFrame.Angles(0, -math.pi * 0.5, 0)

			segmentProgress += currentDirection * configuration.Speed * deltaTime
			segmentProgress = math.clamp(
				segmentProgress,
				if currentSegment <= 1 then 0 else -math.huge,
				if currentSegment >= #segments then segmentPart.Size.X else math.huge
			)
			local ziplineBlocked = (currentSegment <= 1 and segmentProgress <= 0)
				or (currentSegment >= #segments and segmentProgress >= segmentPart.Size.X)

			local finishedSegmentUpdate = false
			if currentDirection > 0 then
				repeat
					if segmentProgress > segmentPart.Size.X and currentSegment < #segments then
						currentSegment += 1
						segmentProgress -= segmentPart.Size.X

						local newSegment = segments[currentSegment]
						if not newSegment then
							rideScope:cleanup()
							return
						end
						segmentPart = newSegment
					else
						finishedSegmentUpdate = true
					end
				until finishedSegmentUpdate
			elseif currentDirection < 0 then
				repeat
					if segmentProgress < 0 and currentSegment > 1 then
						currentSegment -= 1
						segmentProgress += segmentPart.Size.X

						local newSegment = segments[currentSegment]
						if not newSegment then
							rideScope:cleanup()
							return
						end
						segmentPart = newSegment
					else
						finishedSegmentUpdate = true
					end
				until finishedSegmentUpdate
			end

			if configuration.AllowUserControl then
				local controlVector = -controls:GetMoveVector().Z

				local directionIncrement = CONTROL_ACCEL_TIME * deltaTime
				if currentDirection < controlVector then
					currentDirection = math.clamp(currentDirection + directionIncrement, -1, controlVector)
				elseif currentDirection > controlVector then
					currentDirection = math.clamp(currentDirection - directionIncrement, controlVector, 1)
				end

				if currentDirection == 0 or ziplineBlocked then
					if particleClone.Enabled then
						particleClone.Enabled = false
					end
					if loopSoundClone.Playing then
						loopSoundClone:Stop()
					end
				elseif currentDirection ~= 0 and not ziplineBlocked then
					if not particleClone.Enabled then
						particleClone.Enabled = true
					end
					if not loopSoundClone.Playing then
						loopSoundClone:Play()
					end
				end
			end

			if
				not attachTo
				or not attachTo.Parent
				or not (mountedCOs[attachTo] and mountedCOs[attachTo][zipline])
				or (configuration.AllowJumpDismount and IsDown())
			then
				dismountZipline()
				if not attachTo then
					return
				end
				if configuration.KeepMomentum and segments[currentSegment] then
					attachTo.AssemblyLinearVelocity = segments[currentSegment].CFrame.RightVector
						* configuration.Speed
						* currentDirection
				else
					attachTo.AssemblyLinearVelocity = Vector3.zero
				end
			end

			if
				currentSegment >= #segments
				and segmentProgress >= segmentPart.Size.X
				and configuration.AllowEndDismount
			then
				dismountZipline()
				if configuration.KeepMomentum then
					attachTo.AssemblyLinearVelocity = segments[#segments].CFrame.RightVector * configuration.Speed
				else
					attachTo.AssemblyLinearVelocity = Vector3.zero
				end
			end
			debug.profileend()
		end))
	end))
end
