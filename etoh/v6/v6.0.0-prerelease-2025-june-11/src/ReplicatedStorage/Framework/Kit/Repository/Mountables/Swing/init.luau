--!strict
--!optimize 2
--@version swing-6.0.0
--@creator bLockerman666, modified for v6 by Gammattor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local camera = Workspace.CurrentCamera

local UPDATE_INTERVAL = 1 / 60

return function(scope: _T.Scope)
	local utility = scope:utility()
	local JumpButton = utility.JumpButton

	local swingConfig = scope.instance
	if not swingConfig then
		return
	end

	local swing = swingConfig.Parent
	local handle = swing and swing:FindFirstChild("Handle") :: BasePart
	local top = swing and swing:FindFirstChild("Top") :: BasePart
	local platformTemplate = script:FindFirstChild("ConstraintPlatform")
	if not (swing and handle and top and platformTemplate) then
		local errorName = if swing then swing.Name else script.Name
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

	local playerModule = player.PlayerScripts:WaitForChild("PlayerModule")
	local controls = require(playerModule.ControlModule)

	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, swingConfig, {
		AllowJumpDismount = true,
		BallSocketMode = true,
		Boost = 0,
		Cooldown = 1,
		DontAnchor = false,
		JumpOff = true,
	}):ObserveChanges()
	local controlConfiguration = Config.GetConfig(scope, swingConfig:FindFirstChild("ControlConfiguration"), {
		CanControl = false,
		Force = 750,
		MaxVelocity = 75,
	}):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, swingConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):ObserveChanges()

	local soundsFolder = swing:FindFirstChild("Sounds")
		or (function()
			local newSounds = Instance.new("Folder")
			newSounds.Parent = swing
			return newSounds
		end)()

	local dontDelete = swing:FindFirstChild("DontDelete")
	if dontDelete then
		dontDelete:Destroy()
	else
		scope:log({ swing.Name .. ' needs the "DontDelete" weld to avoid desyncing!', type = "warn" })
		return
	end

	local rideDebounce = false
	local handleCFrame = handle.CFrame
	local difference = handle.CFrame:ToObjectSpace(top.CFrame):Inverse()

	scope:attach(swing)

	----------------------------------------------------------------------------
	--> Set up constraints
	local constraint: Constraint = nil
	local vectorForce = nil
	local platform = platformTemplate:Clone()
	local attachment0 = top:FindFirstChild("SwingAttachment") :: Attachment
		or (function()
			local newAtt = Instance.new("Attachment")
			newAtt.Name = "SwingAttachment"
			newAtt.Parent = top
			return newAtt
		end)()
	local attachment1 = platform:FindFirstChild("Attachment1")
	local platformWeld = platform:FindFirstChild("PlatformWeld")
	if not (platformWeld and attachment1) then
		scope:log({ `The {script.Name} script's constraint platform is not set up properly.`, type = "warn" })
		return
	end

	if configuration.BallSocketMode then
		constraint = Instance.new("BallSocketConstraint")
	else
		constraint = Instance.new("HingeConstraint")
	end
	constraint.Attachment0 = attachment0
	constraint.Attachment1 = attachment1
	constraint.Parent = top

	platform.CFrame = top.CFrame
	platformWeld.Part1 = handle
	platform.Anchored = false
	platform.Parent = swing

	local anchorWeld = Instance.new("WeldConstraint")
	anchorWeld.Part0 = top
	anchorWeld.Part1 = handle
	anchorWeld.Enabled = not configuration.DontAnchor
	anchorWeld.Parent = top
	handle.Anchored = false

	if controlConfiguration.CanControl then
		local forceAttachment = Instance.new("Attachment")
		forceAttachment.Name = "ForceAttachment"
		forceAttachment.Parent = handle

		vectorForce = Instance.new("VectorForce")
		vectorForce.Attachment0 = forceAttachment
		vectorForce.Force = Vector3.zero
		vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
		vectorForce.Parent = handle
	end

	----------------------------------------------------------------------------
	--> Mount swing
	local rideScope = scope:inherit()
    scope:add(handle.Touched:Connect(function(touch)
		if handle:GetAttribute("Activated") == false or rideDebounce then
			return
		end

		if not utility.ClientObjects.evaluateToucher(handle, touch, touchConfiguration) then
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
		mountedCOs[attachedRoot][swing] = "Swing"

		utility.Functions.playSoundFromInstance(attachedRoot, soundsFolder, "Grab")

		if not configuration.DontAnchor then
			anchorWeld.Enabled = false
		end

		if configuration.Boost == 0 then
			handle.AssemblyLinearVelocity = attachedRoot.AssemblyLinearVelocity
		else
			handle.AssemblyLinearVelocity = handle.CFrame.LookVector * configuration.Boost
		end

		attachedRoot.AssemblyLinearVelocity = Vector3.zero
		attachedRoot.CFrame = handle.CFrame - handle.CFrame.UpVector * (attachedRoot.Size.Y / 2)
		if isPlayer then
			humanoid.PlatformStand = true
			utility.Character.carryPart(true, handle)
		else
			local handleWeld = Instance.new("WeldConstraint")
			handleWeld.Part0 = handle
			handleWeld.Part1 = attachedRoot
			handleWeld.Parent = handle
			rideScope:attach(handleWeld)
		end

		----------------------------------------------------------------------------
		--> Dismount function
		local function dismountSwing()
			rideScope:cleanup(true)

			if attachedRoot then
				attachedRoot.AssemblyLinearVelocity = handle.AssemblyLinearVelocity * 2
				attachedRoot.CFrame = CFrame.new(attachedRoot.Position)
					* CFrame.Angles(0, math.rad(attachedRoot.Orientation.Y), 0)
			end

			if isPlayer then
				utility.Character.carryPart(false, handle)
				humanoid.PlatformStand = false
				if configuration.JumpOff then
					humanoid:ChangeState("Jumping")
					utility.Functions.playSoundFromInstance(attachedRoot, soundsFolder, "Jump")
				end
			end

			if controlConfiguration.CanControl then
				vectorForce.Force = Vector3.zero
			end

			if mountedCOs[attachedRoot] and mountedCOs[attachedRoot][swing] then
				mountedCOs[attachedRoot][swing] = nil
				if #mountedCOs[attachedRoot] < 1 then
					mountedCOs[attachedRoot] = nil
				end
			end

			task.delay(configuration.Cooldown, function()
				rideDebounce = false
				if not configuration.DontAnchor then
					handle.CFrame = top.CFrame * difference
					anchorWeld.Enabled = true
					handle.AssemblyLinearVelocity = Vector3.zero
					handle.AssemblyAngularVelocity = Vector3.zero
					platform.AssemblyLinearVelocity = Vector3.zero
					platform.AssemblyAngularVelocity = Vector3.zero
				end
			end)
		end

		if configuration.AllowJumpDismount then
			rideScope:add(JumpButton.JumpEvent.Event:Connect(function(isPressed: boolean)
				if not isPressed then
					return
				end
				dismountSwing()
			end))
		end

		----------------------------------------------------------------------------
		--> Swing control loop
		rideScope:add(task.spawn(function()
			while task.wait(UPDATE_INTERVAL) do
				debug.profilebegin("Swing Loop")
				if not attachedRoot or not attachedRoot.Parent then
					dismountSwing()
					break
				elseif not (mountedCOs[attachedRoot] and mountedCOs[attachedRoot][swing]) then
					dismountSwing()
					break
				end

				if isPlayer and not humanoid.PlatformStand then
					-- fixes a weird bug where platformstand disables itself
					humanoid.PlatformStand = true
				end

				if controlConfiguration.CanControl then
					local moveAmount = controls:GetMoveVector()
					local walkSpeed = humanoid.WalkSpeed
					local vector = camera.CFrame.LookVector
					local cframe = CFrame.new(Vector3.zero, Vector3.new(vector.X, 0, vector.Z))

					local force = controlConfiguration.Force
					local maxVelocity = controlConfiguration.MaxVelocity

					force = math.max(force - handle.AssemblyLinearVelocity.Magnitude * force / maxVelocity, 0)
					force *= walkSpeed / 16
					vectorForce.Force = (-cframe.LookVector * moveAmount.Z + cframe.RightVector * moveAmount.X) * force
				end
				debug.profileend()
			end
		end))
	end))
end
