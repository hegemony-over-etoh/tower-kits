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

local balloonTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

return function(object: Types.ClientObject)
	local dispenser = object.instance :: BasePart; assert(dispenser and dispenser:IsA("BasePart"))
	local sounds = dispenser:FindFirstChild("Sounds") :: Folder; assert(sounds and sounds:IsA("Folder"))
	
	object.signals.dismount = LemonSignal.new()
	
	local function updateDecalColors()
		if not dispenser:GetAttribute("RecolorDecals") then
			return
		end
		
		for _, instance in dispenser:GetChildren() do
			if instance:IsA("Decal") then
				instance.Color3 = dispenser.Color
			end
		end
	end
	
	object.trove:Connect(dispenser:GetPropertyChangedSignal("Color"), updateDecalColors)
	
	local debounce = false
	object.trove:Connect(dispenser.Touched, function(otherPart: BasePart)
		local character = Players.LocalPlayer.Character :: Types.Character
		if not dispenser:GetAttribute("_Active") or not Utility.Character.isLimb(otherPart) or debounce or Utility.Character.isAttachedToConstraint() then
			return
		end
		
		local rootPart = character.HumanoidRootPart
		local humanoid = character.Humanoid
		
		debounce = true
		Utility.Character.mountConstraintObject(object)
		
		local constraintTrove = object.trove:Extend()
		local notPoppedTrove = constraintTrove:Extend()
		local balloon = constraintTrove:Clone(script.Balloon)
		balloon.Color = dispenser.Color
		balloon.CFrame = dispenser.CFrame

		local bar = constraintTrove:Clone(script.Bar)
		bar.Color = dispenser.Color
		bar.CFrame = rootPart.CFrame * CFrame.new(0,2.6,0) -- magic jtoh number AGAIN!!! ooooo
		
		local ropeConstraint = constraintTrove:Construct(Instance, "RopeConstraint")
		ropeConstraint.Length = dispenser:GetAttribute("RopeLength")
		ropeConstraint.Visible = true
		ropeConstraint.Color = BrickColor.new("Really black")
		do
			local attachment0, attachment1 = Utility.General.populateConstraintAttachments(ropeConstraint)
			constraintTrove:Add(attachment0)
			constraintTrove:Add(attachment1)
			attachment0.Parent = bar
			attachment1.Parent = balloon
		end
		ropeConstraint.Parent = bar
		
		bar.Parent = dispenser
		balloon.Parent = dispenser
		
		notPoppedTrove:Add(Utility.General.weld(rootPart, bar))
		notPoppedTrove:Add(function()
			balloon.Transparency = 1
			balloon.Size = Vector3.zero
			
			balloon.CanCollide = true
			bar.CanCollide = true
			
			if dispenser:GetAttribute("PlaySound") then
				Utility.General.cloneAndPlay(sounds:FindFirstChild("Pop") :: Sound)
			end
			task.delay(0.5, function()
				debounce = false
			end)
			
			task.wait(7)
			local barTween = TweenService:Create(bar, TweenInfo.new(5, Enum.EasingStyle.Linear), {Transparency = 1})
			barTween:Play()
			barTween.Completed:Wait()
			
			constraintTrove:Destroy()
		end)
		
		-- balloon inflation "animation"
		TweenService:Create(balloon.Mesh, balloonTweenInfo, {Scale=Vector3.new(1, 1.25, 1)}):Play()
		if dispenser:GetAttribute("PlaySound") then
			Utility.General.cloneAndPlay(sounds:FindFirstChild("Inflate") :: Sound)
		end
		
		local linearVelocity = balloon.LinearVelocity
		notPoppedTrove:Add(linearVelocity)
		
		linearVelocity.VectorVelocity = Vector3.yAxis * dispenser:GetAttribute("UpwardsVelocity")
		
		local function dismount()
			notPoppedTrove:Destroy()
		end
		
		object.signals.dismount:Once(dismount)
		notPoppedTrove:Connect(dispenser:GetAttributeChangedSignal("_Active"), Utility.Character.dismountConstraintObject)
		if dispenser:GetAttribute("AllowJumpDismount") then
			notPoppedTrove:Connect(UserInputService.JumpRequest, Utility.Character.dismountConstraintObject)
		end
		
		local maxHeight = dispenser:GetAttribute("MaxHeight")
		if maxHeight > 0 then
			notPoppedTrove:Connect(RunService.RenderStepped, function()
				if math.abs(balloon.CFrame.Y - dispenser.CFrame.Y) > maxHeight then
					Utility.Character.dismountConstraintObject()
				end
			end)
		end
		
		local maxTime = dispenser:GetAttribute("MaxTime")
		if maxTime > 0 then
			notPoppedTrove:Add(task.delay(maxTime, Utility.Character.dismountConstraintObject))
		end
	end)
end