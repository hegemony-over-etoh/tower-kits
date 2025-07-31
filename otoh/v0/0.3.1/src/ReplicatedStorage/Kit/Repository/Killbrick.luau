--!strict
-- junekept 2025
-- this script was originally made for OToH

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local killbrickDebounceTime = Utility.Config.killbrickDebounceTime
local isTouching = false

-- repeat task.wait() print(Utility.Tower.loadedTower) until Utility.Tower.loadedTower

local poison = 0
local isInPoison = false
local currentPoisonIncrement = Utility.Tower.loadedTower.config.poisonDecrementRate
RunService.RenderStepped:Connect(function(deltaTime: number) 
	-- invert magic
	if not isInPoison then deltaTime *= -1 end
	poison = math.clamp(poison + currentPoisonIncrement * deltaTime, 0, 100)

	Utility.Interface.updateHealthBarPoison(poison)
end)

task.spawn(function()
	while true do
		task.wait(Utility.Config.killbrickDebounceTime)
		
		if poison >= Utility.Tower.loadedTower.config.posionDamageThreshold then
			Kit.SelfDamage:FireServer(Utility.Tower.loadedTower.config.poisonBrickDamage)
		end
	end
end)

return function(object: Types.ClientObject)
	local killbrick = object.instance :: BasePart

	object.trove:Connect(killbrick.Touched, function(otherPart: BasePart) 
		local character: Types.Character = Players.LocalPlayer.Character
		if not Utility.Character.isLimb(otherPart) or isTouching or not killbrick:GetAttribute("_Active") then
			return
		end
		
		isTouching = true
		
		local humanoid = character.Humanoid
		local rootPart = character.HumanoidRootPart
		
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.Tolerance = 0.05
		-- shoutout roblox for not letting BasePart -> Instance type coercion happen???
		overlapParams.FilterDescendantsInstances = Utility.Character.getHitbox("WholeBody") :: {any}
		
		local function updateColor()
			if not killbrick:GetAttribute("SyncParticleColor") then
				return
			end
			
			local color = killbrick.Color
			for _, child in killbrick:GetChildren() do
				if child:IsA("ParticleEmitter") then
					child.Color = ColorSequence.new(color)
				end
			end
		end
		
		object.trove:Connect(killbrick:GetPropertyChangedSignal("Color"), updateColor)
		updateColor()
		
		if killbrick:GetAttribute("Poison") then
			currentPoisonIncrement = killbrick:GetAttribute("Damage")
			isInPoison = true
			
			repeat 
				task.wait() 
			until #workspace:GetPartsInPart(killbrick, overlapParams) == 0 or not killbrick:GetAttribute("_Active")
			
			isInPoison = false
			currentPoisonIncrement = Utility.Tower.loadedTower.config.poisonDecrementRate
		else
			while #workspace:GetPartsInPart(killbrick, overlapParams) > 0 and killbrick:GetAttribute("_Active") do
				Kit.SelfDamage:FireServer(killbrick:GetAttribute("Damage"))
				task.wait(killbrickDebounceTime)
			end
		end
		
		isTouching = false
	end)
end