--!strict

local players = game:GetService("Players")
local userInput = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local debris = game:GetService("Debris")

function tween(part: Instance, twtime: number, inf: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local tweeninf:TweenInfo = TweenInfo.new(
		twtime,
		(if style then style else Enum.EasingStyle.Linear),
		(if direction then direction else Enum.EasingDirection.Out)
	)
	local tw:Tween = tweenService:Create(part, tweeninf, inf)
	tw:Play()
	tw.Completed:Connect(function()
		tw:Destroy()
	end)
end

function playSoundFromPart(part: Instance, sndname: string, customSpeed: number?)
	local snd:Sound = script:FindFirstChild(sndname)
	if snd then
		local sndc:Sound = snd:Clone()
		sndc.Parent = part
		if customSpeed then sndc.PlaybackSpeed = customSpeed end
		sndc:Play()
		
		debris:AddItem(sndc, sndc.TimeLength+1)
	end
end

local function roundColor(color: Color3)
	return Color3.fromRGB(math.floor(color.R*255 + 0.5),math.floor(color.G*255 + 0.5),math.floor(color.B*255 + 0.5))
end


return function()
	task.wait()
	
	local folder: Folder = script.Parent --change this value when used as a repo script
	local plr: Player = players.LocalPlayer
	local char = (plr.Character or plr.CharacterAdded:Wait()) :: Model
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	
	local playerBuffering: boolean = false
	local boxBuffering: boolean = false
	local playerOccupied: boolean = false
	local occupiedBlocks: {[Instance]: boolean} = {}
	
	
	for _,airJump:Instance in (folder:GetDescendants()) do
		if airJump:IsA("BasePart") and (airJump.Name == "AirJump" or airJump:FindFirstChild("IsAirJump") or airJump:GetAttribute("IsAirJump")) then
			local jumpCooldown: boolean = false
			
			local attributes: Instance = airJump:FindFirstChild("Attributes")
			local supports: Instance = airJump:FindFirstChild("Supports")
			if not attributes or not supports then continue end
			
			local cooldownVal: number = if attributes:GetAttribute("Cooldown") then attributes:GetAttribute("Cooldown") else 0.5
			local forceVal: number = if attributes:GetAttribute("Force") then attributes:GetAttribute("Force") else 50
			local soundSpeed: number = if attributes:GetAttribute("SoundPlaybackSpeed") then attributes:GetAttribute("SoundPlaybackSpeed") else 1
			local sizeReduction: Vector3 = if attributes:GetAttribute("CustomSizeReduction") then attributes:GetAttribute("CustomSizeReduction") else Vector3.one
			
			local setTransparencyVal = airJump:FindFirstChild("SetTransparency") :: NumberValue
			local blockTransparency: number = if setTransparencyVal then setTransparencyVal.Value else airJump.Transparency
			
			
			local bounceParticle
			local particleAtt = airJump:FindFirstChild("Particles") :: Attachment
			if particleAtt then
				bounceParticle = particleAtt:FindFirstChild("BounceParticle") :: ParticleEmitter
			end
			
			airJump.TopSurface = Enum.SurfaceType.Studs
			
			local jumpGroup: Model = Instance.new("Model", airJump.Parent)
			airJump.Parent = jumpGroup
			
			local hitbox: BasePart = airJump:Clone()
			hitbox.Parent = jumpGroup
			hitbox.Transparency = 0.95
			hitbox.Material = Enum.Material.Neon
			hitbox.CanCollide = false
			hitbox.Name = "AirJumpHitbox"
			hitbox:ClearAllChildren()
			
			local hitboxWeld = Instance.new("WeldConstraint", hitbox)
			hitboxWeld.Part0 = hitbox
			hitboxWeld.Part1 = airJump
			hitbox.Anchored = false
			
			airJump.Size -= sizeReduction
			
			
			hitbox.Touched:Connect(function(touch)
				if occupiedBlocks[airJump] or jumpCooldown then return end
				
				local activatedVal = airJump:FindFirstChild("Activated") :: BoolValue
				if activatedVal and not activatedVal.Value then return end
				
				local colorSpecific = not (attributes:GetAttribute("PushboxColorSpecific") and (roundColor(touch.Color) ~= roundColor(airJump.Color)))
				local isPlr = supports:GetAttribute("Players") and players:GetPlayerFromCharacter(touch.Parent) == plr and not playerOccupied
				local isBox = supports:GetAttribute("Pushboxes") and (touch.Name == "Pushbox" or touch:FindFirstChild("IsBox")) and colorSpecific and not touch:GetAttribute("AirJumpOccupied")
				
				if isPlr or isBox then
					occupiedBlocks[airJump] = true
					if isPlr then 
						playerOccupied = true 
					else 
						touch:SetAttribute("AirJumpOccupied", true) 
					end
					
					playSoundFromPart(airJump, "Tick")
					tween(airJump, 0.1, {Size = hitbox.Size - (sizeReduction/8)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					
					local launchPart: Instance = if isPlr then root else touch
					local overlapParams: OverlapParams = OverlapParams.new()
					overlapParams.FilterDescendantsInstances = if isPlr then {char} else {touch}
					overlapParams.FilterType = Enum.RaycastFilterType.Include
					
					while folder and airJump and hitbox and launchPart do
						if (isPlr and playerBuffering) or (isBox and boxBuffering) and not jumpCooldown then
							if isPlr then
								playerBuffering = false
							else
								boxBuffering = false
							end
							jumpCooldown = true
							
							playSoundFromPart(airJump, "Bounce", soundSpeed)
							airJump.Transparency = blockTransparency / 4
							tween(airJump, .5, {Transparency = blockTransparency})
							if bounceParticle then bounceParticle:Emit(1) end
							
							local maxForce: Vector3 = Vector3.one * 40000
							local upVector: Vector3 = airJump.CFrame.UpVector
							if math.abs(upVector.X) < 0.1 and math.abs(upVector.Z) < 0.1 then maxForce = Vector3.new(0, 40000, 0) end
							
							local velocityAtt: Attachment = Instance.new("Attachment", launchPart)
							local linearVelocity: LinearVelocity = Instance.new("LinearVelocity", launchPart)
							linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
							linearVelocity.MaxAxesForce = maxForce
							linearVelocity.VectorVelocity = upVector * forceVal
							linearVelocity.Attachment0 = velocityAtt
							task.delay(0.125, function()
								if linearVelocity then linearVelocity:Destroy() end
								if velocityAtt then velocityAtt:Destroy() end
							end)
							
							task.delay(cooldownVal, function() jumpCooldown = false end)
							break
						else
							local overlapParts: {Instance} = workspace:GetPartsInPart(hitbox, overlapParams)
							
							if #overlapParts < 1 then break end
						end
						task.wait()
					end
					
					tween(airJump, 0.1, {Size = hitbox.Size - sizeReduction}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					
					occupiedBlocks[airJump] = nil
					if isPlr then 
						playerOccupied = false
					else 
						touch:SetAttribute("AirJumpOccupied", nil) 
					end
				end
			end)
		end
	end
	
	
	--buffer controls below
	if userInput.TouchEnabled then
		local plrGui: Instance = plr:WaitForChild("PlayerGui")
		local jumpButton = plrGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton") :: GuiButton
		
		jumpButton.MouseButton1Down:Connect(function()
			boxBuffering = true
			if humanoid:GetState() == Enum.HumanoidStateType.Freefall or playerOccupied then
				playerBuffering = true
			end
		end)
		
		jumpButton.MouseButton1Up:Connect(function()
			playerBuffering = false
			boxBuffering = false
		end)
	else
		userInput.InputBegan:Connect(function(inputObj: InputObject)
			if (inputObj.KeyCode == Enum.KeyCode.Space or inputObj.KeyCode == Enum.KeyCode.ButtonA) then
				boxBuffering = true
				if humanoid:GetState() == Enum.HumanoidStateType.Freefall or playerOccupied then
					playerBuffering = true
				end
			end
		end)
		
		userInput.InputEnded:Connect(function(inputObj: InputObject)
			if (inputObj.KeyCode == Enum.KeyCode.Space or inputObj.KeyCode == Enum.KeyCode.ButtonA) then
				playerBuffering = false
				boxBuffering = false
			end
		end)
	end
	
	humanoid.StateChanged:Connect(function(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)
		if playerBuffering and newState ~= Enum.HumanoidStateType.Freefall and not playerOccupied then
			playerBuffering = false
		end
	end)
end