--!strict
--!optimize 2
--@version bouncepad-6.0.0
--@creator Camille

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	--> Setup
	local utility = scope:utility()
	local bouncePadConfig = scope.instance
	if not bouncePadConfig then
		return
	end

	local bouncePad = bouncePadConfig.Parent
	if not bouncePad or not bouncePad:IsA("BasePart") then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, bouncePadConfig, {
		Power = 100,
		Cooldown = 0.05,
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, bouncePadConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, bouncePadConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:CheckForChanges()

	scope:attach(bouncePad)

	--> Get objects and check for problems
	local particleAttachment = bouncePad:FindFirstChild("ParticleAtt")
	if not particleAttachment or not particleAttachment:IsA("Attachment") then
		scope:log({
			"BouncePad is either missing its ParticleAtt attachment or has it set up incorrectly.",
			`Path: {bouncePad:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local bounceParticle = particleAttachment:FindFirstChild("BounceParticle")
	if not bounceParticle or not bounceParticle:IsA("ParticleEmitter") then
		scope:log({
			"BouncePad is either missing its BounceParticle or has it set up incorrectly.",
			`Path: {bouncePad:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local boingSound = bouncePadConfig:FindFirstChild("BoingSound")
	if not boingSound or not boingSound:IsA("Sound") then
		scope:log({
			"BouncePad is either missing its Boing sound or has it set up incorrectly.",
			`Path: {bouncePad:GetFullName()}`,
			type = "warn",
		})
		return
	end

	boingSound.Parent = bouncePad

	--> Variables
	local player = Players.LocalPlayer
	local character = player.Character
	local bouncePadColor = bouncePad.Color
	local cooldownActive = false

	--> Functions
	local function bounce(part: BasePart)
		-- bounce
		boingSound:Play()

		if Players:GetPlayerFromCharacter(part.Parent) == player then
			part = character.PrimaryPart

			-- fix velocity sometimes being weird
			local humanoid = utility.Character.getHumanoid()
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end

		local oldVel = part.AssemblyLinearVelocity
		part.AssemblyLinearVelocity = Vector3.new(oldVel.X, configuration.Power, oldVel.Z)

		-- visuals
		bounceParticle:Emit(1)

		local h, s, v = bouncePadColor:ToHSV()
		bouncePad.Color = Color3.fromHSV(h, math.clamp(s + 0.125, 0, 1), math.clamp(v + 0.25, 0, 1))
		utility.Functions.tween(bouncePad, tweenConfiguration, { Color = bouncePadColor })
	end

	--> Main functionality
	scope:add(bouncePad.Touched:Connect(function(toucher)
		if not utility.ClientObjects.evaluateToucher(bouncePad, toucher, touchConfiguration) then
			return
		end
		if cooldownActive or toucher.Anchored then
			return
		end
		if bouncePad:GetAttribute("Activated") == false then
			return
		end

		cooldownActive = true
		task.delay(configuration.Cooldown, function()
			cooldownActive = false
		end)

		bounce(toucher)
	end))
end
