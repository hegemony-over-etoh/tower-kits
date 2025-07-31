--!strict
-- junekept 2025
-- this script was originally made for OToH

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local killbrickDebounceTime = Utility.Config.killbrickDebounceTime

local isTouching = false
return function(object: Types.ClientObject)
	local platformModel = object.instance
	local platform = platformModel:FindFirstChild("Platform"); assert(platform and platform:IsA("BasePart"))
	local endPart = platformModel:FindFirstChild("End"); assert(endPart and endPart:IsA("BasePart"))
	local alignPosition = platform:FindFirstChild("AlignPosition"); assert(alignPosition and alignPosition:IsA("AlignPosition"))
	
	-- why is this not a default roblox feature LOL
	local volume = platform.Size.X * platform.Size.Y * platform.Size.Z
	platform.CustomPhysicalProperties = PhysicalProperties.new(
		(1/volume) * platformModel:GetAttribute("Mass"),
		platformModel:GetAttribute("Friction"), platformModel:GetAttribute("Elasticity"),
		platformModel:GetAttribute("FrictionWeight"), platformModel:GetAttribute("ElasticityWeight")
	)
	
	-- set connected parts to massless to not mess up the ratio
	for _, part in platform:GetConnectedParts() do
		if part ~= platform and part:IsA("BasePart") then
			part.Massless = true
		end
	end
	
	-- alignPosition.Position = platform.Position
	platform.Anchored = false
	
	local originalForce = alignPosition.MaxForce
	local debounce = false
	object.trove:Connect(endPart.Touched, function(otherPart: BasePart)
		if otherPart ~= platform or debounce then
			return
		end
		
		debounce = true
		
		local toggleCollision = platformModel:GetAttribute("ReboundToggleCollision")
		local oldTransparency = platform.Transparency
		
		alignPosition.MaxForce = platformModel:GetAttribute("ReboundForce")
		platform.Transparency = platformModel:GetAttribute("ReboundTransparency")
		if toggleCollision then
			platform.CanCollide = false
		end
		task.wait(platformModel:GetAttribute("RespawnTime"))
		alignPosition.MaxForce = math.huge
		platform.Transparency = oldTransparency
		platform.CanCollide = true
		
		debounce = false
		
		platform.Touched:Once(function()
			alignPosition.MaxForce = originalForce
		end)
	end)
end