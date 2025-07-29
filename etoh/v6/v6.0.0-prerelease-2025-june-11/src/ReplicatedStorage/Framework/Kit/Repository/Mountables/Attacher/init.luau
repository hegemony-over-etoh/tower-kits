--!strict
--!optimize 2
--@version attacher-6.0.0
--@creator aamo_s

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local Module = {
	CanQueue = true,
	RunOnStart = false,
}

local map = {
	[Enum.Limb.Torso] = "HumanoidRootPart",
	[Enum.Limb.LeftArm] = "Left Arm",
	[Enum.Limb.RightArm] = "Right Arm",
	[Enum.Limb.LeftLeg] = "Left Leg",
	[Enum.Limb.RightLeg] = "Right Leg",
	[Enum.Limb.Head] = "Head",
}

local enumHST = Enum.HumanoidStateType

local bannedStates = {
	[enumHST.Ragdoll] = true,
	[enumHST.Dead] = true,
	[enumHST.StrafingNoPhysics] = true,
	[enumHST.RunningNoPhysics] = true,
}

local function getLimb(character: Instance?, hitPart: BasePart, limb: Enum.Limb): BasePart?
	if not character then
		return
	end

	if limb == Enum.Limb.Unknown then
		return hitPart
	end
	if not limb then
		return
	end

	local limbName = map[limb]
	local limbPart = character:FindFirstChild(limbName)
	if not limbPart or not limbPart:IsA("BasePart") then
		return
	end
	return limbPart
end

function Module.Run(scope: _T.Scope)
	local utility = scope:utility()
	local JumpButton = utility.JumpButton

	local attacherConfig = scope.instance
	if not attacherConfig then
		return
	end

	local model = attacherConfig.Parent
	if not model then
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

	local baseModel = model:FindFirstChild("WeldModel")
	local trigger = model:FindFirstChild("Trigger")

	if not trigger or not trigger:IsA("BasePart") then
		scope:log({
			"Attacher is missing the Trigger part.",
			`Path: {model:GetFullName()}`,
			type = "warn",
		})

		return
	end

	if not baseModel or not baseModel:IsA("Model") then
		scope:log({
			"Attacher is missing the WeldModel.",
			`Path: {model:GetFullName()}`,
			type = "warn",
		})

		return
	end

	if not baseModel:HasTag("SkipObjectLoad") then
		scope:log({
			"Attacher is missing it's 'SkipObjectLoad' tag.",
			`Path: {model:GetFullName()}`,
			type = "warn",
		})
		return
	end
	scope:add(baseModel)
	baseModel.Parent = nil
	baseModel:RemoveTag("SkipObjectLoad")

	if not baseModel.PrimaryPart then
		scope:log({
			"Attacher is missing the PrimaryPart on WeldModel.",
			`Path: {baseModel:GetFullName()}`,
			type = "warn",
		})

		return
	end

	local Config = utility.Config

	local configuration = Config.GetConfig(scope, attacherConfig, {
		AttachUsingAlign = false,
		CleanDelay = 3,
		Cooldown = 0.5,
		DismountState = Config.Type.Enum(enumHST.Jumping),
		DismountStateEnabled = true,
		Offset = CFrame.new(0, 0, -5),
		WeldToLimb = Config.Type.Enum(Enum.Limb.Torso),
	}):ObserveChanges()

	if bannedStates[configuration.DismountState] then
		scope:log({
			"Attacher is using a banned state type.",
			`Path: {attacherConfig:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local touchConfiguration =
		Config.GetConfig(scope, attacherConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	local touchDebounce = {}

	local function attach(hitPart)
		if not humanoid or humanoid.Health <= 0 or touchDebounce[trigger] then
			return
		end

		local isPlayer = hitPart:IsDescendantOf(character)
		local attachTo = nil

		if isPlayer and table.find(utility.Character.getHitbox("StaticWholeBody"), hitPart) then
			attachTo = getLimb(character, hitPart, configuration.WeldToLimb)
		elseif not isPlayer then
			attachTo = hitPart
		end

		if not attachTo then
			return
		end

		local attachScope = scope:inherit()

		touchDebounce[trigger] = true

		if not mountedCOs[attachTo] then
			mountedCOs[attachTo] = {}
		end
		mountedCOs[attachTo][model] = "Attacher"

		local weldModel = attachScope:add(baseModel:Clone())

		local primaryPart = weldModel.PrimaryPart :: BasePart
		local connection: RBXScriptConnection? = nil

		if not configuration.AttachUsingAlign then
			local weldConstraint = Instance.new("WeldConstraint")
			weldConstraint.Part0 = attachTo
			weldConstraint.Part1 = primaryPart
			weldConstraint.Parent = primaryPart

			weldModel:PivotTo(attachTo.CFrame * configuration.Offset)
		else
			local bodyAttachment = attachScope:add(Instance.new("Attachment"))
			bodyAttachment.CFrame = configuration.Offset
			bodyAttachment.Name = "AttacherAttachment"
			bodyAttachment.Parent = attachTo

			local primaryPartAttachment = attachScope:add(Instance.new("Attachment"))
			primaryPartAttachment.Parent = primaryPart

			local positionExists = trigger:FindFirstChildOfClass("AlignPosition")
			local orientationExists = trigger:FindFirstChildOfClass("AlignOrientation")

			local alignPosition = Instance.fromExisting(positionExists or script.DefaultAlignPosition)
			local alignOrientation = Instance.fromExisting(orientationExists or script.DefaultAlignOrientation)

			alignPosition.Attachment0 = primaryPartAttachment
			alignPosition.Attachment1 = bodyAttachment
			alignOrientation.Attachment0 = primaryPartAttachment
			alignOrientation.Attachment1 = bodyAttachment

			alignPosition.Parent = primaryPartAttachment
			alignOrientation.Parent = primaryPartAttachment

			weldModel:PivotTo(bodyAttachment.WorldCFrame)
		end

		primaryPart.Anchored = false
		weldModel.Parent = model
		utility.ClientObjects.scanFolder(attachScope, weldModel, true)

		local function dismount(reason: any)
			if mountedCOs[attachTo] and mountedCOs[attachTo][model] then
				mountedCOs[attachTo][model] = nil
				if #mountedCOs[attachTo] < 1 then
					mountedCOs[attachTo] = nil
				end
			end

			if connection then
				connection:Disconnect()
				connection = nil
			end

			attachScope:cleanup(true)

			scope:add(task.delay(configuration.Cooldown, function()
				touchDebounce[trigger] = nil
			end))
		end

		if configuration.DismountStateEnabled then
			connection = humanoid.StateChanged:Connect(function(_, new)
				if new ~= configuration.DismountState then
					return
				end

				dismount("state")
			end)
		end

		--TODO consider making this cached: not *really* required? since this'll
		--only be active while the object is actually mounted
		attachScope:add(task.spawn(function()
			while true do
				debug.profilebegin("Attacher Checking")

				if not attachTo or not attachTo.Parent then
					dismount("no attachto or parent")
					break
				elseif not (mountedCOs[attachTo] and mountedCOs[attachTo][model]) then
					dismount("not mounted")
					break
				end

				debug.profileend()

				task.wait()
			end
		end))
	end

	scope:attach(trigger)
	scope:add(trigger.Touched:Connect(function(hitPart)
		if
			trigger:GetAttribute("Activated") == false
			or not utility.ClientObjects.evaluateToucher(trigger, hitPart, touchConfiguration)
		then
			return
		end
		attach(hitPart)
	end))
end

return Module
