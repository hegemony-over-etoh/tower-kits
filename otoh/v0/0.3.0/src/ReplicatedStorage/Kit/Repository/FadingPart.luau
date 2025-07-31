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
	local fadingPart = object.instance :: BasePart

	local debounce = false
	local function fade()
		-- I think in this situation it makes sense to make all sources have debounce
		if debounce then return end
		
		debounce = true
		
		local fadeTime = fadingPart:GetAttribute("FadeTime")
		local fadeTransparency = fadingPart:GetAttribute("FadeTransparency")
		local respawnTime = fadingPart:GetAttribute("RespawnTime")
		local fadeDescendants = fadingPart:GetAttribute("FadeDescendants")

		local toFade: {Instance} = if fadeDescendants then fadingPart:GetDescendants() else {}
		table.insert(toFade, fadingPart)

		local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		for _, instance in toFade do
			if instance:IsA("BasePart") or instance:IsA("GuiObject") or instance:IsA("Decal")then
				task.spawn(function()
					local selectionBox = instance:FindFirstChildOfClass("SelectionBox")
					local originalSelectionBoxColor = if selectionBox then selectionBox.Color3 else Color3.new(1, 1, 1)
					local originalTransparency = instance.Transparency

					local tween = TweenService:Create(instance, tweenInfo, {Transparency = fadeTransparency})
					tween:Play()
					tween.Completed:Wait()

					-- support noncollideable -> collideable "fade" maybe?
					if not instance:GetAttribute("KeepCollision") and instance:IsA("BasePart") then
						(instance :: BasePart).CanCollide = not instance.CanCollide
					end
					if instance:GetAttribute("_Active") ~= nil and instance ~= fadingPart then 
						instance:SetAttribute("_Active", not instance:GetAttribute("_Active")) 
					end
					if selectionBox  then
						selectionBox.Color3 = selectionBox:GetAttribute("FadedColor")
					end

					task.wait(respawnTime)

					if selectionBox then
						selectionBox.Color3 = originalSelectionBoxColor
					end
					(instance :: any).Transparency = originalTransparency
					if not instance:GetAttribute("KeepCollision") and instance:IsA("BasePart") then
						(instance :: BasePart).CanCollide = not instance.CanCollide
					end
					if instance:GetAttribute("_Active") ~= nil and instance ~= fadingPart then 
						instance:SetAttribute("_Active", not instance:GetAttribute("_Active")) 
					end
				end)
			elseif instance:IsA("ParticleEmitter") then
				task.spawn(function()
					task.wait(fadeTime)
					instance.Enabled = false

					task.wait(respawnTime)
					instance.Enabled = true
				end)
			end
		end
		
		task.wait(respawnTime + fadeTime)
		debounce = false
	end
	
	object.trove:Connect(fadingPart.Touched, function(otherPart: BasePart) 
		if not fadingPart:GetAttribute("_Active") or debounce or not Utility.ClientObjects.isTouchValid(fadingPart, otherPart) then
			return
		end
		
		fade()
	end)
	
	object.trove:Connect(object.signals.onTrigger :: any, fade)
end