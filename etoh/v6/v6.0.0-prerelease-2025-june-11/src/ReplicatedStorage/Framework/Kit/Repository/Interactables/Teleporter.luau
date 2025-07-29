--!strict
--!optimize 2
--@version teleporter-6.0.0
--@creator mario_123456, synnwave

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local localPlayer = Players.LocalPlayer
local DISABLE_COLLISION_PROPERTIES = {
	CollisionGroup = "NeverCollide",
	CanTouch = false,
} :: { [string]: any }
type savedProperties = { [BasePart]: { [string]: any } }

return function(scope: _T.Scope)
	local utility = scope:utility()
	local teleporterConfig = scope.instance
	if not teleporterConfig then
		return
	end

	local teleporter = teleporterConfig.Parent
	if not teleporter then
		return
	end

	local teleporterParts = {} :: { BasePart }
	local destinationParts = {} :: { BasePart }
	for _, part in teleporter:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		if part.Name == "Destination" then
			table.insert(destinationParts, part)
		elseif part.Name == "Teleporter" then
			table.insert(teleporterParts, part)
		end
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, teleporterConfig, {
		Instant = true,
		KeepVelocity = true,
		SeamlessTeleport = false,
		DisableCollision = false,
		Offset = CFrame.new(0, 3, 0),
	}):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, teleporterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, teleporterConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()

	local function getActiveDestinations()
		return utility.Table.Filter(destinationParts, function(destination)
			return destination:GetAttribute("Activated") ~= false
		end)
	end

	local isTeleporting = false
	local function teleport(teleporter, part, isPlayer)
		local activeDestinations = getActiveDestinations()
		if #activeDestinations <= 0 then
			return
		end

		isTeleporting = true
		task.defer(function()
            isTeleporting = false
		end)

		local savedPartProperties = {
			[part] = { Anchored = part.Anchored },
		} :: savedProperties
		if not configuration.KeepVelocity then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
			savedPartProperties[part].AssemblyLinearVelocity = Vector3.zero
			savedPartProperties[part].AssemblyAngularVelocity = Vector3.zero
		end
		if configuration.DisableCollision then
			if isPlayer then
				for _, part in localPlayer.Character:GetChildren() do
					if not part:IsA("BasePart") or savedPartProperties[part] ~= nil then
						continue
					end
					savedPartProperties[part] = {}
				end
			end

			for part, properties in savedPartProperties do
				for property, value in DISABLE_COLLISION_PROPERTIES do
					properties[property] = utility.Property.getPropertySafe(part, property)
					utility.Property.setPropertySafe(part, property, value)
				end
			end
		end

		local transitionTime = if configuration.Instant then 0 else tweenConfiguration.Time
		local chosenDestination = activeDestinations[math.random(#activeDestinations)]
		local destinationCFrame = chosenDestination:GetPivot()
		local teleporterCFrame = teleporter:GetPivot()
        local targetCFrame = destinationCFrame * configuration.Offset
        
		local camera = Workspace.CurrentCamera
		local targetCameraCFrame
        if configuration.SeamlessTeleport then
            targetCFrame = destinationCFrame * teleporterCFrame:ToObjectSpace(part:GetPivot())
            if isPlayer then
                targetCameraCFrame = destinationCFrame * teleporterCFrame:ToObjectSpace(camera.CFrame)  
            end
        end
        
		utility.Functions.playSoundFromInstance(chosenDestination, chosenDestination, "Teleport")
		if transitionTime > 0 then
			part.Anchored = true
			local tween = utility.Functions.tween(part, tweenConfiguration, { CFrame = targetCFrame })
			local oldCameraType
			if targetCameraCFrame then
				oldCameraType = camera.CameraType
				camera.CameraType = Enum.CameraType.Scriptable
				utility.Functions.tween(camera, tweenConfiguration, { CFrame = targetCameraCFrame })
			end

			tween.Completed:Wait()
			if oldCameraType then
				camera.CameraType = oldCameraType
			end
        else
            if targetCameraCFrame then
                camera.CFrame = targetCameraCFrame
            end
			
			part:PivotTo(targetCFrame)
		end

		for part, properties in savedPartProperties do
			for property, value in properties do
				utility.Property.setPropertySafe(part, property, value)
			end
		end
	end

	scope:attach(teleporter)
	for _, teleporter in teleporterParts do
		scope:add(teleporter.Touched:Connect(function(touchingPart: BasePart)
			if
				isTeleporting
				or teleporter:GetAttribute("Activated") == false
				or not utility.ClientObjects.evaluateToucher(teleporter, touchingPart, touchConfiguration)
			then
				return
			end

			local part: BasePart?
			local character = localPlayer.Character
			local isPlayer = false
			if touchingPart.Parent == character and character.PrimaryPart then
				isPlayer = true
				part = character.PrimaryPart
			elseif utility.ClientObjects.isPushbox(touchingPart) then
				part = touchingPart
			end
			if not (part and part.Parent) then
				return
			end

			teleport(teleporter, part, isPlayer)
		end))
	end
end
