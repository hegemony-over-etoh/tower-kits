--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local LemonSignal = require(Libraries.LemonSignal)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local pushboxButtonModel = object.instance :: Model
	local pushboxButton = pushboxButtonModel:FindFirstChild("Button") :: BasePart
	local pushboxTemplate = pushboxButtonModel:FindFirstChild("Pushbox") :: Instance
	
	-- local originalPosition = pushboxTemplate.Position
	
	-- Roblox won't garbage collect the pushbox until this function goes out of scope, 
	-- which would only happen if the spawn button was unloaded.
	-- Parenting to nil lets us not pollute other environments
	pushboxTemplate.Parent = nil
	if pushboxTemplate:IsA("BasePart") then
		pushboxTemplate.Anchored = false
	elseif pushboxTemplate:IsA("Model") and pushboxTemplate.PrimaryPart then
		pushboxTemplate.PrimaryPart.Anchored = false
	end
	
	local activePushbox: Instance = nil
	local function spawnPushbox()
		if activePushbox then
			activePushbox:Destroy() 
		end
		activePushbox = pushboxTemplate:Clone()
		activePushbox.Parent = pushboxButtonModel
		
		local pushboxParts = activePushbox:GetDescendants()
		table.insert(pushboxParts, activePushbox)
		
		for _, part in pushboxParts do
			if part:IsA("BasePart") then
				part:AddTag("Pushbox")
				part:SetAttribute("Id", pushboxButtonModel:GetAttribute("PushboxId"))
				if part == activePushbox then continue end
				part.Destroying:Once(function()
					if part:IsDescendantOf(workspace) then
						activePushbox:Destroy()
					end
				end)
			end
		end
	end
	
	if pushboxButtonModel:GetAttribute("SpawnPushboxOnLoad") then
		spawnPushbox()
	end
	
	local debounce = false
	object.trove:Connect(pushboxButton.Touched, function(otherPart: BasePart)
		if not pushboxButtonModel:GetAttribute("_Active") or debounce or not Utility.ClientObjects.isTouchValid(pushboxButtonModel, otherPart) then
			return
		end
		
		debounce = true
		
		spawnPushbox()
		
		task.delay(pushboxButtonModel:GetAttribute("Cooldown"), function()
			debounce = false
		end)
	end)
	
	object.trove:Connect(object.signals.onTrigger :: any, spawnPushbox)
end