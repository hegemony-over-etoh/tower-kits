--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local turretModel = object.instance :: Model
	local turret = turretModel:FindFirstChild("Turret") :: BasePart
	local bullet = turretModel:FindFirstChild("Bullet") :: BasePart
	
	bullet.Parent = nil
	bullet.Anchored = false
	turret.FrontSurface = Enum.SurfaceType.Smooth
	
	local holeSize = math.max(turret.Size.X, turret.Size.Y) * 0.9
	
	local turretHole = Instance.new('Part')
	turretHole.Name = "TurretHole"
	turretHole.CanCollide = false
	turretHole.Color = Color3.fromHex("#000")
	turretHole.Material = Enum.Material.Neon
	turretHole.Shape = Enum.PartType.Cylinder
	turretHole.Size = Vector3.new(0.1, holeSize, holeSize)
	turretHole.CFrame = (turret.CFrame + turret.CFrame.LookVector * (turret.Size.Z / 2)) * CFrame.Angles(0, math.pi / 2, 0)
	turretHole.CastShadow = false
	turretHole.Transparency = turret.Transparency
	turretHole.Parent = turret

	Utility.General.weld(turret, turretHole, true)
	
	while true do
		task.wait(turretModel:GetAttribute("Delay"))
		local character = Players.LocalPlayer.Character :: Types.Character
		if not turretModel:GetAttribute("_Active") 
			or (character.HumanoidRootPart.Position - turret.Position).Magnitude > turretModel:GetAttribute("Distance") 
		then
			continue
		end
		
		local newBullet = bullet:Clone()
		local attachment = Instance.new("Attachment")
		local linearVelocity = Instance.new("LinearVelocity")
		
		linearVelocity.Attachment0 = attachment
		linearVelocity.ForceLimitsEnabled = false
		linearVelocity.VectorVelocity = turret.CFrame.LookVector * turretModel:GetAttribute("Speed")
		
		if turretModel:GetAttribute("AutoScaleBullet") then
			newBullet.Size = Vector3.one * holeSize
		end
		
		attachment.Parent = newBullet
		linearVelocity.Parent = newBullet
		
		Debris:AddItem(newBullet, 15)
		newBullet:AddTag("Bullet")
		newBullet.Parent = turretModel
		
		if turretModel:GetAttribute("PlaySound") then
			Utility.General.cloneAndPlay(turretModel:FindFirstChild("Fire") :: Sound)
		end
		
		newBullet.Touched:Connect(function(otherPart: BasePart)
			local isPlayer = Utility.Character.isLimb(otherPart)
			local isBullet = otherPart:HasTag("Bullet")
			
			local shouldHit = turretModel:GetAttribute("HitBullets") or not isBullet
				and turretModel:GetAttribute("HitPlayers") or not isPlayer
				and turretModel:GetAttribute("HitParts") or not (isPlayer or isBullet)
			
			if shouldHit then
				if isPlayer then
					Kit.SelfDamage:FireServer(turretModel:GetAttribute("Damage"))
				end
				
				newBullet:Destroy()
			end
		end)
	end
end