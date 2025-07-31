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

local LemonSignal = require(Libraries.LemonSignal)
local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local DEFAULT_ACTIVE_TRANSPARENCY = 0
local DEFAULT_INACTIVE_TRANSPARENCY = 0.6

local function updateGraphics(instance: Instance, transparency: number, active: boolean, tweenInfo: TweenInfo)
	if instance:IsA("Decal") or instance:IsA("GuiObject") then
		TweenService:Create(instance, tweenInfo, {Transparency = transparency}):Play()
	elseif instance:IsA("ParticleEmitter") then
		instance.Enabled = active
	end
end

local pressedButtonsPerId: {[string]: number} = {}
return function(object: Types.ClientObject)
	local buttonModel = object.instance :: Model
	local buttonPart = buttonModel:FindFirstChild("ButtonPart") :: BasePart
	local basePart = buttonModel:FindFirstChild("ButtonBase") :: BasePart
	
	local rigidConstraint = Instance.new("RigidConstraint")
	local buttonPartAttachment, buttonBaseAttachment = Utility.General.populateConstraintAttachments(rigidConstraint)
	
	do
		rigidConstraint.Enabled = false
		
		buttonPartAttachment.Parent = buttonPart
		buttonBaseAttachment.Parent = basePart
		rigidConstraint.Parent = basePart
		
		-- I have been trying for SO LONG to understand why the Y axis of the attachment is inverted 
		-- but I cannot for the life of me figure it out so have this awful code instead
		buttonPartAttachment.CFrame = CFrame.new(-basePart.CFrame:PointToObjectSpace(buttonPart.CFrame.Position))
		
		rigidConstraint.Enabled = true
	end
	
	object.signals.setPressed = LemonSignal.new()
	
	local currentButtonGroupTag = "Button_" .. buttonModel:GetAttribute("ButtonGroupId")
	buttonModel:AddTag(currentButtonGroupTag)
	object.trove:Connect(buttonModel:GetAttributeChangedSignal("ButtonGroupId"), function()
		buttonModel:RemoveTag(currentButtonGroupTag)
		currentButtonGroupTag = "Button_" .. buttonModel:GetAttribute("ButtonGroupId")
		buttonModel:AddTag(currentButtonGroupTag)
	end)
	
	local function tweenInfo(): TweenInfo
		return TweenInfo.new(buttonModel:GetAttribute("TransitionDuration"), Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	end
	
	local function toggleVisibilityAndCollision(instance: BasePart, active: boolean)
		local nextState = if active then "Active" else "Inactive"
		local currentState = if active then "Inactive" else "Active"
		local defaultTransparency = if active then DEFAULT_ACTIVE_TRANSPARENCY else DEFAULT_INACTIVE_TRANSPARENCY
		
		if not instance:GetAttribute(`{currentState}Transparency`) then
			instance:SetAttribute(`{currentState}Transparency`, instance.Transparency)
		end
		
		if not instance:GetAttribute(`{nextState}Transparency`) then
			instance:SetAttribute(`{nextState}Transparency`, defaultTransparency)
		end

		if not instance:GetAttribute("KeepCollision") then
			instance.CanCollide = not instance.CanCollide
		end

		local transparency = instance:GetAttribute(`{nextState}Transparency`)
		local tweenInfo = tweenInfo()

		local tweenParameters = {}
		tweenParameters.Transparency = transparency

		TweenService:Create(instance, tweenInfo, tweenParameters):Play()
		for _, descendant in instance:GetDescendants() do
			updateGraphics(descendant, transparency, active, tweenInfo)
		end
	end
	
	local unpressedCFrame = buttonPartAttachment.CFrame
	buttonPart.Anchored = false -- AHHHHH!
	
	object.trove:Connect(buttonModel:GetAttributeChangedSignal("Pressed"), function()
		local pressed = buttonModel:GetAttribute("Pressed")
		local buttonGroupId = buttonModel:GetAttribute("ButtonGroupId")
		local taggedInstances = CollectionService:GetTagged("LoadedButtonGroup_" .. buttonGroupId)
		
		local cFrameOffset = unpressedCFrame
		-- offset not inverted because the y axis of the attachment's offset is inverted for some reason ??????
		if pressed then cFrameOffset += unpressedCFrame.UpVector * buttonModel:GetAttribute("PressOffset") end
		
		TweenService:Create(buttonPartAttachment, tweenInfo(), {CFrame = cFrameOffset}):Play()
		
		buttonPart.Material = if pressed then Enum.Material.Neon else Enum.Material.Metal
		
		local pressedButtons = pressedButtonsPerId[buttonGroupId]
		if pressed then
			pressedButtonsPerId[buttonGroupId] = (pressedButtons or 0) + 1
		else
			pressedButtonsPerId[buttonGroupId] = (pressedButtons or 0) - 1
		end
		
		-- only deactivate if pressed buttons are 0, only activate if pressed buttons are 1
		if not pressed and pressedButtonsPerId[buttonGroupId] ~= 0 or pressed and pressedButtonsPerId[buttonGroupId] ~= 1 then
			return
		end
		
		for _, instance in taggedInstances do
			if instance:GetAttribute("_Active") == pressed then
				--continue
			end
			
			instance:SetAttribute("_Active", not instance:GetAttribute("_Active"))
			local clientObjectType = instance:GetAttribute("_Script")
			-- hey this is kinda like that one developer
			-- intention is to have a list of "override" options first before doing generic options
			-- since _Active gets set to false, most client objects already have behavior disabled
			-- if you want to do behaviors other than transparency + cancollide false from the button end you can put it here
			if clientObjectType == "PutOtherStuffHereFirst" then
			elseif instance:IsA("BasePart") then
				-- Default behavior that also applies to any BasePart type that does not have overriden behavior
				toggleVisibilityAndCollision(instance, instance:GetAttribute("_Active"))
			end
		end
	end)
	
	local holdButton = buttonModel:GetAttribute("HoldButton")
	local holdButtonHitbox: BasePart = nil
	if holdButton then
		holdButtonHitbox = object.trove:Clone(buttonPart)
		holdButtonHitbox.Size += Vector3.one * 0.5 -- half a stud of tolerance
		holdButtonHitbox.Transparency = 1
		holdButtonHitbox.CanCollide = false
		holdButtonHitbox.Name = "HoldButtonHitbox"
		for _, instance in holdButtonHitbox:GetChildren() do
			instance:Destroy()
		end
		
		holdButtonHitbox.Parent = buttonPart
		Utility.General.weld(buttonPart, holdButtonHitbox, true)
	end
	
	local touchingParts = 0
	object.trove:Connect(buttonPart.Touched, function(otherPart: BasePart)
		if 
			not buttonModel:GetAttribute("_Active") 
			or (buttonModel:GetAttribute("Pressed") and not holdButton) 
			or not Utility.ClientObjects.isTouchValid(buttonModel, otherPart)
		then
			return
		end

		buttonModel:SetAttribute("Pressed", true)
		if buttonPart:FindFirstChildOfClass("Sound") and buttonModel:GetAttribute("PlaySound") then
			Utility.General.cloneAndPlay(buttonPart:FindFirstChildOfClass("Sound") :: Sound)
		end
		
		if not holdButton then
			local timer = buttonModel:GetAttribute("Timer")
			if timer and timer > 0 then
				Utility.Interface.createButtonTimer(buttonModel, buttonModel:GetAttribute("TimerFormatString"))
				task.delay(timer, function()
					buttonModel:SetAttribute("Pressed", false)
				end)
			end
		else
			local overlapParams = OverlapParams.new()
			overlapParams.FilterType = Enum.RaycastFilterType.Include
			overlapParams.Tolerance = 0.05
			overlapParams:AddToFilter(otherPart)
			touchingParts += 1
			
			local connection: RBXScriptConnection
			connection = RunService.PreRender:Connect(function()
				if #workspace:GetPartsInPart(holdButtonHitbox, overlapParams) == 0 then
					touchingParts -= 1
					connection:Disconnect()
					if touchingParts == 0 then
						buttonModel:SetAttribute("Pressed", false)
					end
				end
			end)
		end
	end)
end