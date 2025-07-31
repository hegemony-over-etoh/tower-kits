--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local mainModel = object.instance :: BasePart

	local destinations = {}
	local oldTransparency = {}
	
	local teleporting = false
	local function teleport(part: BasePart, teleporter: BasePart?)
		teleporting = true

		local velocities = {
			linear = part.AssemblyLinearVelocity,
			angular = part.AssemblyAngularVelocity
		}

		local destination = destinations[math.random(1, #destinations)]
		local destinationCFrame = destination.CFrame
		if mainModel:GetAttribute("Seamless") then
			if teleporter then
				destinationCFrame = destination.CFrame:ToWorldSpace(teleporter.CFrame:ToObjectSpace(part.CFrame))
				workspace.CurrentCamera.CFrame = destination.CFrame:ToWorldSpace(teleporter.CFrame:ToObjectSpace(workspace.CurrentCamera.CFrame))
			else
				warn("seamless teleporting is not supported on trigger activated teleporters!")
			end
		end
		destinationCFrame += destination:GetAttribute("Offset") or Vector3.zero

		if mainModel:GetAttribute("PlaySound") then
			Utility.General.cloneAndPlay(destination:FindFirstChild("TeleportSound") :: Sound)
		end
		local transitionTime = mainModel:GetAttribute("TransitionTime") :: number
		if transitionTime > 0 then
			part.Anchored = true

			local tween = TweenService:Create(
				part, 
				TweenInfo.new(
					transitionTime, 
					Enum.EasingStyle:FromName(mainModel:GetAttribute("TransitionEasingStyle")) or Enum.EasingStyle.Quad, 
					Enum.EasingDirection:FromName(mainModel:GetAttribute("TransitionEasingStyle")) or Enum.EasingDirection.Out
				),
				{
					CFrame = destinationCFrame
				}
			)
			tween:Play()
			tween.Completed:Wait()

			part.Anchored = false
		else
			part.CFrame = destinationCFrame
		end

		if mainModel:GetAttribute("KeepVelocity") then
			part.AssemblyLinearVelocity = velocities.linear
			part.AssemblyAngularVelocity = velocities.angular
		end

		task.delay(1/10, function() teleporting = false end)
	end

	local addNewPart
	addNewPart = function(part: Instance)
		if not part:IsA("BasePart") then return end

		if part.Name == "Destination" then
			table.insert(destinations, part)
			part.AncestryChanged:Once(function() table.remove(destinations, table.find(destinations, part)) end)
		elseif part.Name == "Teleporter" then
			local teleporter = part
			local connection = teleporter.Touched:Connect(function(otherPart: BasePart) 
				if not mainModel:GetAttribute("_Active") or otherPart.Anchored or #destinations == 0 or teleporting then
					return
				end
				
				local part: BasePart
				local character = Players.LocalPlayer.Character
				if character and Utility.Character.isLimb(otherPart) and mainModel:GetAttribute("TeleportPlayers") then
					part = character:FindFirstChild("HumanoidRootPart")
				elseif otherPart:HasTag("Pushbox") then
					part = otherPart
				end
				
				if not part then return end
				
				teleport(part, teleporter)
			end)
			
			part.AncestryChanged:Once(function() connection:Disconnect() end)
		else
			return
		end

		oldTransparency[part] = part.Transparency

		if part:GetAttribute("Invisible") == nil then
			part:SetAttribute("Invisible", true)
		end

		local function changeTransparency()
			if part:GetAttribute("Invisible") then 
				part.Transparency = 1
			else
				part.Transparency = oldTransparency[part]
			end
		end

		local connection = object.trove:Connect(part:GetAttributeChangedSignal("Invisible"), changeTransparency)
		changeTransparency()

		part.AncestryChanged:Once(function()
			oldTransparency[part] = nil
			connection:Disconnect()
		end)
	end
	
	mainModel.DescendantAdded:Connect(addNewPart)
	for _, part in mainModel:GetDescendants() do
		addNewPart(part)
	end
	
	object.signals.onTrigger:Connect(function()
		local character = Players.LocalPlayer.Character :: Types.Character
		if not character then return end
		
		teleport(character.HumanoidRootPart)
	end)
end