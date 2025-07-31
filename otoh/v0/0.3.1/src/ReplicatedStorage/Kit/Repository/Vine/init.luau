--!strict
-- junekept 2025
-- not aubrey 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local LemonSignal = require(Libraries.LemonSignal)
local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local vineRespawnTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- TODO: Clean this up my goodness
return function(object: Types.ClientObject)
	local vineModel = object.instance
	local vine = vineModel:FindFirstChild("Vine") :: BasePart; assert(vine and vine:IsA("BasePart"))
	local top = vineModel:FindFirstChild("Top") :: BasePart; assert(top and top:IsA("BasePart"))
	local particleEmitter = vine:FindFirstChildOfClass("ParticleEmitter"); assert(particleEmitter)
	local sounds = vineModel:FindFirstChild("Sounds") :: Folder; assert(sounds)
	
	object.signals.dismount = LemonSignal.new()
	
	local vineTween: Tween = nil
	local debounce = false
	
	particleEmitter.Color = ColorSequence.new(vine.Color)
	
	local oldTransparency = vine.Transparency
	object.trove:Connect(vine.Touched, function(otherPart: BasePart)
		local character = Players.LocalPlayer.Character
		if not vineModel:GetAttribute("_Active") or not Utility.Character.isLimb(otherPart) or debounce or Utility.Character.isAttachedToConstraint() then
			return
		end
		
		if vineTween then 
			vineTween:Cancel() 
			vine.Transparency = oldTransparency
		end
		
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart; assert(rootPart) -- how would this fail bru
		local originalVelocities = {
			linear = rootPart.AssemblyLinearVelocity,
			angular = rootPart.AssemblyAngularVelocity
		}
		
		local attachmentTrove = object.trove:Extend()
		
		local rope = attachmentTrove:Add(Instance.new("RopeConstraint"))
		local bar = attachmentTrove:Clone(script.BarTemplate)
		local attachment0, attachment1 = Utility.General.populateConstraintAttachments(rope)
		attachmentTrove:Add(attachment0)
		attachmentTrove:Add(attachment1)
		
		bar.Color = vine.Color
		bar.CFrame = rootPart.CFrame * CFrame.new(0,2.6,0) -- magic jtoh number ooooo
		
		attachmentTrove:Add(Utility.General.weld(bar, rootPart))
		bar.Parent = vineModel
		
		rope.Length = vineModel:GetAttribute("RopeLength")
		rope.Visible = true
		rope.Color = vine.BrickColor
		rope.Parent = top
		
		attachment0.Parent = top
		attachment1.Parent = bar
		
		oldTransparency = vine.Transparency
		vine.Transparency = 1
		
		if vineModel:GetAttribute("KeepVelocity") then
			rootPart.AssemblyLinearVelocity = originalVelocities.linear
			rootPart.AssemblyAngularVelocity = originalVelocities.angular
		end
		
		if vineModel:GetAttribute("PlaySound") then
			Utility.General.cloneAndPlay(sounds:FindFirstChild("Grab") :: Sound)
		end
		
		debounce = true
		attachmentTrove:AttachToInstance(bar)
		Utility.Character.mountConstraintObject(object)
		
		local function removeConstraint()
			particleEmitter.Enabled = true
			
			vineTween = TweenService:Create(vine, vineRespawnTweenInfo, {Transparency = oldTransparency})
			vineTween:Play()
			vineTween.Completed:Wait()
			
			debounce = false
			particleEmitter.Enabled = false
		end
		attachmentTrove:Add(removeConstraint)
		
		local function dismount(noJump: boolean?)
			attachmentTrove:Destroy()
			
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and not noJump then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				Utility.General.cloneAndPlay(sounds:FindFirstChild("Jump") :: Sound)
			end
		end
		
		local function checkAttributeDismount()
			Utility.Character.dismountConstraintObject(not vineModel:GetAttribute("EndJump"))
		end
		
		attachmentTrove:Connect(object.signals.dismount :: any, dismount)
		
		attachmentTrove:Connect(vineModel:GetAttributeChangedSignal("_Active"), checkAttributeDismount)
		
		if vineModel:GetAttribute("AllowJumpDismount") then
			attachmentTrove:Connect(UserInputService.JumpRequest, checkAttributeDismount)
		end
	end)
end
