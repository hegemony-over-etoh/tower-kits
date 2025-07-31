--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local LemonSignal = require(Libraries.LemonSignal)

local Types = require(Kit.Types)

local ControlModule = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("PlayerModule")):GetControls()

return function(object: Types.ClientObject)
	local swing = object.instance :: Model
	local handle = swing:FindFirstChild("Handle") :: BasePart
	local top = swing:FindFirstChild("Top") :: BasePart
	
	object.signals.dismount = LemonSignal.new()
	
	local vectorForce = handle:FindFirstChild("ForceAttachment"):FindFirstChild("VectorForce") :: VectorForce
	local anchorWeld = top:FindFirstChild("AnchorWeld") :: WeldConstraint
	anchorWeld.Enabled = not swing:GetAttribute("DontAnchor")
	
	local sounds = swing:FindFirstChild("Sounds") :: Folder
	
	local hinge = script.ConstraintHinge:Clone()
	hinge.CFrame = top.CFrame
	hinge.Parent = swing
	Utility.General.weld(hinge, handle)
	
	local constraint: Constraint do
		-- ballsocketmode currently unused because idek what it does lol
		if swing:GetAttribute("BallSocketMode") then
			constraint = Instance.new("BallSocketConstraint")
		else
			local cylindricalConstraint = Instance.new("CylindricalConstraint")
			cylindricalConstraint.LimitsEnabled = true
			cylindricalConstraint.UpperLimit = 0

			constraint = cylindricalConstraint
		end
	end
	do
		local attachment0 = Instance.new("Attachment")
		local attachment1 = Instance.new("Attachment")
		
		attachment0.Parent = hinge
		attachment1.Parent = top
		
		constraint.Attachment0 = attachment0
		constraint.Attachment1 = attachment1
		constraint.Parent = top
	end
	
	local handleCFrame = handle.CFrame
	local difference = handle.CFrame:ToObjectSpace(top.CFrame):Inverse()
	
	swing:FindFirstChild("DontDelete"):Destroy()
	
	local attached = false
	object.trove:Connect(handle.Touched, function(otherPart: BasePart)
		local character = Players.LocalPlayer.Character
		if not swing:GetAttribute("_Active") or not Utility.Character.isLimb(otherPart) or attached or Utility.Character.isAttachedToConstraint() then
			return
		end
		
		local dontAnchor = swing:GetAttribute("DontAnchor") :: boolean
		local boost = swing:GetAttribute("Boost") :: number
		local controllable = swing:GetAttribute("Controllable") :: boolean
		local controllableForce = swing:GetAttribute("ControllableForce") :: number
		local controllableMaxVelocity = swing:GetAttribute("ControllableMaxVelocity") :: number
		
		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		local leftArm = character:FindFirstChild("Left Arm") :: BasePart
		local rightArm = character:FindFirstChild("Right Arm") :: BasePart
		
		local swingConstraintTrove = object.trove:Extend()
		
		anchorWeld.Enabled = false
		
		rootPart.AssemblyLinearVelocity = Vector3.zero
		character:PivotTo(handle.CFrame + handle.CFrame.UpVector * -1)
		
		local handleWeldTrove = Utility.ClientObjects.weldCharacterToHandle(handle, character, swingConstraintTrove)

		attached = true
		Utility.Character.mountConstraintObject(object)
		
		if swing:GetAttribute("PlaySound") then
			Utility.General.cloneAndPlay(sounds:FindFirstChild("Grab") :: Sound)
		end
		
		if boost == 0 then
			handle.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity
		else
			handle.AssemblyLinearVelocity = handle.CFrame.LookVector * boost
		end
		
		if controllable then
			vectorForce.Enabled = true
		else
			vectorForce.Enabled = false
		end
		
		swingConstraintTrove:Connect(RunService.PreRender, function()
			humanoid.PlatformStand = true

			if controllable then
				local moveVector = ControlModule:GetMoveVector()
				local cameraLookVector = workspace.CurrentCamera.CFrame.LookVector
				local moveDirectionCFrame = CFrame.lookAt(Vector3.zero, cameraLookVector * (Vector3.one - Vector3.yAxis))
				
				local forceMagnitude = math.max(
					controllableForce - handle.AssemblyLinearVelocity.Magnitude * controllableForce / controllableMaxVelocity, 
					0
				) * (humanoid.WalkSpeed / 16)
				vectorForce.Force = -(moveDirectionCFrame.RightVector * moveVector.X - moveDirectionCFrame.LookVector * moveVector.Z) 
					* forceMagnitude
			end
		end)
		
		local function onRemove()
			if not dontAnchor then
				handle.CFrame = top.CFrame * difference
				anchorWeld.Enabled = true
				handle.AssemblyLinearVelocity = Vector3.zero
				handle.AssemblyAngularVelocity = Vector3.zero
			end
			
			handleWeldTrove:Destroy()
			
			task.delay(0.5, function()
				attached = false
			end)
		end
		local function dismount(noJump: boolean?)
			noJump = if noJump ~= nil then noJump else not swing:GetAttribute("EndJump")
			
			if not noJump and humanoid then
				Utility.General.cloneAndPlay(sounds:FindFirstChild("Jump") :: Sound)
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			
			swingConstraintTrove:Destroy()
			
			-- remove any orientation not on the Y axis
			local rotX, rotY, rotZ = rootPart.CFrame:ToEulerAnglesXYZ()
			rootPart.CFrame = CFrame.Angles(0, rotY + math.pi, 0) + rootPart.CFrame.Position
		end
		
		local function checkAttributeDismount()
			Utility.Character.dismountConstraintObject(not swing:GetAttribute("EndJump"))
		end
		
		swingConstraintTrove:Connect(object.signals.dismount :: any, dismount)
		
		swingConstraintTrove:Add(onRemove)
		swingConstraintTrove:Connect(swing:GetAttributeChangedSignal("_Active"), checkAttributeDismount)
		
		if swing:GetAttribute("AllowJumpDismount") then
			task.delay(0.1, function()
				swingConstraintTrove:Connect(UserInputService.JumpRequest, checkAttributeDismount)
			end)
		end
	end)
end