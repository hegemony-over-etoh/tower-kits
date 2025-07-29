--!strict
--!optimize 2
--@version turret-6.0.0
--@creator Camille

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

type TurretHitData = {
	valid: boolean,
	hitPlayer: boolean?,
}

local HIT_TYPES: { [string]: TurretHitData } = {
	INVALID = { valid = false },
	VALID = { valid = true },
	VALID_PLAYER = { valid = true, hitPlayer = true },
}

return function(scope: _T.Scope)
	local utility = scope:utility()

	local turretConfig = scope.instance
	if not turretConfig then
		return
	end

	local turretModel = turretConfig.Parent
	if not turretModel then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, turretConfig, {
		FireRate = 0.2,
		Damage = 5,
		Range = 50,
		Speed = 50,
		MaxLifetime = 15,
		DestroyOnTouch = true,
		BulletOffset = CFrame.new(),
	}):CheckForChanges()

	local player = Players.LocalPlayer

	--> Get objects and check for problems
	local turret = turretModel:FindFirstChild("Turret")
	if not turret or not turret:IsA("BasePart") then
		scope:log({
			"Turret is either missing its Turret part or has it set up incorrectly.",
			`Path: {turretModel:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local bulletTemplate = turretModel:FindFirstChild("Bullet")
    if not bulletTemplate or not bulletTemplate:IsA("Model") or not bulletTemplate:HasTag("SkipObjectLoad") then
		scope:log({
			"Turret is either missing its Bullet model or has it set up incorrectly.",
			`Path: {turretModel:GetFullName()}`,
			type = "warn",
		})
		return
	end
    
    scope:add(bulletTemplate)
	bulletTemplate.Parent = nil
    bulletTemplate:RemoveTag("SkipObjectLoad")

	local fireSoundTemplate = turret:FindFirstChild("Fire")
	if not fireSoundTemplate or not fireSoundTemplate:IsA("Sound") then
		scope:log({
			"Turret is either missing its Fire sound or has it set up incorrectly.",
			`Path: {turretModel:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Variables
	local player = Players.LocalPlayer

	--> Functions
	local function isValidHit(bullet: BasePart, hitPart: BasePart): TurretHitData
		if hitPart == turret then
			return HIT_TYPES.INVALID
		end

		local hitPlayer = Players:GetPlayerFromCharacter(hitPart.Parent)
		if hitPlayer then
			if hitPlayer == player then
				return HIT_TYPES.VALID_PLAYER
			else
				return HIT_TYPES.INVALID
			end
		elseif not hitPart.CanCollide then
			return HIT_TYPES.INVALID
		end

		return HIT_TYPES.VALID
	end

	local function fireBullet()
		local bulletScope = scope:inherit()

		local bulletModel = bulletScope:add(bulletTemplate:Clone())
		local mainPart = bulletModel.PrimaryPart or bulletModel:FindFirstChild("Bullet")
			or (function()
				local baseBullet = script.Bullet:Clone()
				baseBullet.Parent = bulletModel
				return baseBullet
			end)()
		
		local spawnPos = turret.CFrame * configuration.BulletOffset
		bulletModel:PivotTo(spawnPos)
		
		local mainAttachment = mainPart:FindFirstChildOfClass("Attachment")
			or (function()
				local attachment = Instance.new("Attachment")
				attachment.Parent = mainPart
				return attachment
			end)()

		local linearVelocity = mainPart:FindFirstChildOfClass("LinearVelocity") 
			or (function()
				local velocity = Instance.new("LinearVelocity")
				velocity.ForceLimitsEnabled = false
				velocity.Parent = mainPart
				return velocity
			end)()
		
		linearVelocity.Attachment0 = mainAttachment
		linearVelocity.VectorVelocity = turret.CFrame.LookVector * configuration.Speed
		
		local alignOrientation = mainPart:FindFirstChildOfClass("AlignOrientation") 
			or (function()
				local aligner = Instance.new("AlignOrientation")
				aligner.Mode = Enum.OrientationAlignmentMode.OneAttachment
				aligner.RigidityEnabled = true
				aligner.Parent = mainPart
				return aligner
			end)()
		
		alignOrientation.Attachment0 = mainAttachment
		alignOrientation.CFrame = CFrame.new() * turret.CFrame.Rotation
		
		local fireSound = fireSoundTemplate:Clone()
		fireSound.Parent = turret
		fireSound:Play()
		Debris:AddItem(fireSound, fireSound.TimeLength / fireSound.PlaybackSpeed)
			
		mainPart.Anchored = false
		bulletModel.Parent = turretModel
		utility.ClientObjects.scanFolder(bulletScope, bulletModel, false)

		--- damage handling ---
		local function cleanup()
			bulletScope:cleanup(true, true)
		end
		
		-- is there a better way to do this? GetDescendants is awful
		if configuration.DestroyOnTouch then
			for _, bulletPart in bulletModel:GetDescendants() do
				if not bulletPart:IsA("BasePart") then
					continue
				end
				
				bulletScope:add(bulletPart.Touched:Connect(function(hitPart: BasePart)
					local hitResult = isValidHit(bulletPart, hitPart)

					if hitResult.valid then
						cleanup()

						if hitResult.hitPlayer and bulletPart.Name == "Bullet" then
							utility.Character.takeDamage(configuration.Damage)
						end
					end
				end))
			end
		end
		
		bulletScope:add(task.delay(configuration.MaxLifetime, cleanup))
	end
	
	--> Main functionality
	scope:add(task.defer(function()
        while task.wait(1 / configuration.FireRate) do
			if turret:GetAttribute("Activated") == false then
				continue
			end

            local distance = player:DistanceFromCharacter(turret.Position)
			if distance < configuration.Range then
				fireBullet()
            end
		end
	end))
end