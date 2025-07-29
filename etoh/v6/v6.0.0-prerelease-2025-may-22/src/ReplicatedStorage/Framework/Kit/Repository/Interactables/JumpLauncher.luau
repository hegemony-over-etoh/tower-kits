--!strict
--!optimize 2
--@version jumplauncher-6.0.0
--@creator Gammattor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local UPDATE_INTERVAL = 1 / 60

return function(scope: _T.Scope)
	local utility = scope:utility()
	local launcherConfig = scope.instance
	if not launcherConfig then
		return
	end

	local jumpLauncher = launcherConfig.Parent
	if not jumpLauncher or not jumpLauncher:IsA("BasePart") then
		return
	end

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	local cache: any = scope.shared[scope.scriptPath]
	if not cache then
		cache = {
			playerBuffering = false,
			boxBuffering = false,
			playerOccupied = false,
			occupiedBlocks = {},
		}
		scope.shared[scope.scriptPath] = cache

		scope.rootScope:add(utility.JumpButton.JumpEvent.Event:Connect(function(jumpState: boolean)
			cache.boxBuffering = jumpState
			if jumpState then
				if humanoid:GetState() == Enum.HumanoidStateType.Freefall or cache.playerOccupied then
					cache.playerBuffering = true
				end
			else
				cache.playerBuffering = false
			end
		end))

		scope.rootScope:add(humanoid.StateChanged:Connect(function(oldState, newState)
			if cache.playerBuffering and newState ~= Enum.HumanoidStateType.Freefall and not cache.playerOccupied then
				cache.playerBuffering = false
			end
		end))
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, launcherConfig, {
		Cooldown = 0.25,
		Force = 60,
		SizeReduction = Vector3.one,
		Transparency = jumpLauncher.Transparency,
	}):CheckForChanges()

	local touchConfiguration =
		Config.GetConfig(scope, launcherConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

	local soundsFolder = jumpLauncher:FindFirstChild("Sounds")
		or (function()
			local sounds = Instance.new("Folder")
			sounds.Parent = jumpLauncher
			return sounds
		end)()

	local bounceParticle: ParticleEmitter?
	local particleAttachment = jumpLauncher:FindFirstChild("Particles")
	if particleAttachment then
		bounceParticle = particleAttachment:FindFirstChild("BounceParticle") :: ParticleEmitter
	end

	local jumpGroup = Instance.new("Model")
	jumpGroup.Parent = jumpLauncher.Parent
	jumpLauncher.Parent = jumpGroup

	local hitbox = jumpLauncher:Clone()
	hitbox.Parent = jumpGroup
	hitbox.Transparency = 0.95
	hitbox.Material = Enum.Material.Neon
	hitbox.CanCollide = false
	hitbox.Name = "JumpLauncherHitbox"
	hitbox:ClearAllChildren()

	local hitboxWeld = Instance.new("WeldConstraint")
	hitboxWeld.Part0 = hitbox
	hitboxWeld.Part1 = jumpLauncher
	hitboxWeld.Parent = hitbox
	hitbox.Anchored = false

	jumpLauncher.Size -= configuration.SizeReduction

	local jumpCooldown = false
	scope:attach(jumpLauncher)
	local touchScope = scope:inherit()
	local function enterJumpLauncher(touch)
		if cache.occupiedBlocks[jumpLauncher] or jumpCooldown or jumpLauncher:GetAttribute("Activated") == false then
			return
		end

		if not utility.ClientObjects.evaluateToucher(jumpLauncher, touch, touchConfiguration) then
			return
		end

		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.CollisionGroup = ""

		local isPlayer = false
		local isBox = false
		if touch:IsDescendantOf(character) then
			local hitbox = utility.Character.getHitbox("StaticWholeBody", overlapParams)
			if not table.find(hitbox, touch) then
				return
			end

			isPlayer = true
			cache.playerOccupied = true
		elseif utility.ClientObjects.isPushbox(touch) then
			isBox = true
			overlapParams:AddToFilter(touch)
		end

		if not (isPlayer or isBox) then
			return
		end

		local launchPart = if isPlayer then humanoid.RootPart else touch
		cache.occupiedBlocks[jumpLauncher] = true

		utility.Functions.playSoundFromInstance(jumpLauncher, soundsFolder, "Tick")
		utility.Functions.tween(
			jumpLauncher,
			0.1,
			{ Size = hitbox.Size - (configuration.SizeReduction / 8) },
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		)

		touchScope:add(task.spawn(function()
			while true do
				debug.profilebegin("Jump Launcher Query")
				if (isPlayer and cache.playerBuffering) or (isBox and cache.boxBuffering) and not jumpCooldown then
					if isPlayer then
						cache.playerBuffering = false
					elseif isBox then
						cache.boxBuffering = false
					end
					jumpCooldown = true

					utility.Functions.playSoundFromInstance(jumpLauncher, soundsFolder, "Bounce")
					jumpLauncher.Transparency = configuration.Transparency / 4
					utility.Functions.tween(jumpLauncher, 0.5, { Transparency = configuration.Transparency })
					if bounceParticle then
						bounceParticle:Emit(1)
					end

					local maxForce = Vector3.one * 40000
					local upVector = jumpLauncher.CFrame.UpVector
					if math.abs(upVector.X) < 0.1 and math.abs(upVector.Z) < 0.1 then
						maxForce = Vector3.yAxis * 40000
					end

					local velocityAttachment = Instance.new("Attachment")
					local linearVelocity = Instance.new("LinearVelocity")
					linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
					linearVelocity.MaxAxesForce = maxForce
					linearVelocity.VectorVelocity = upVector * configuration.Force
					linearVelocity.Attachment0 = velocityAttachment

					velocityAttachment.Parent = launchPart
					linearVelocity.Parent = launchPart
					task.delay(0.125, function()
						linearVelocity:Destroy()
						velocityAttachment:Destroy()
					end)
					task.delay(configuration.Cooldown, function()
						jumpCooldown = false
						local overlapParts = workspace:GetPartsInPart(hitbox, overlapParams)
						if #overlapParts >= 1 then
							enterJumpLauncher(touch)
						end
					end)

					debug.profileend()
					break
				else
					local overlapParts = workspace:GetPartsInPart(hitbox, overlapParams)
					if #overlapParts < 1 then
						debug.profileend()
						break
					end
				end
				debug.profileend()
				task.wait(UPDATE_INTERVAL)
			end

			utility.Functions.tween(
				jumpLauncher,
				0.1,
				{ Size = hitbox.Size - configuration.SizeReduction },
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)

			cache.occupiedBlocks[jumpLauncher] = nil
			if isPlayer then
				cache.playerOccupied = false
			end

			touchScope:cleanup(true)
		end))
	end
	scope:add(hitbox.Touched:Connect(enterJumpLauncher))
end
