--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Utility = require(Kit.Utility)

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local CatRom = require(Libraries.CatRom)
local LemonSignal = require(Libraries.LemonSignal)
local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local ControlModule = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("PlayerModule")):GetControls()

return function(object: Types.ClientObject)
	local zipline = object.instance :: Model
	local startPoint = zipline:FindFirstChild("Start") :: BasePart
	local pointsFolder = zipline:FindFirstChild("Points") :: BasePart
	local sounds = zipline:FindFirstChild("Sounds") :: Folder
	
	object.signals.dismount = LemonSignal.new()
	
	local function genFolder(name: string)
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = zipline
		return folder
	end
	
	local sphereCache = genFolder("SphereCache")
	local cylinderCache = genFolder("CylinderCache")
	local sphereSegments = genFolder("SphereSegments")
	local cylinderSegments = genFolder("CylinderSegments")
	
	local function enableWelds(instance: Instance)
		for _, child in instance:GetChildren() do
			if child:IsA("WeldConstraint") then
				child.Enabled = false
			end
		end
	end
	
	local function disableWelds(instance: Instance)
		for _, child in instance:GetChildren() do
			if child:IsA("WeldConstraint") then
				child.Enabled = false
			end
		end
	end
	
	local function getPart(partType: "Sphere" | "Cylinder"): Part
		local cache = zipline:FindFirstChild(partType.."Cache") :: Folder
		local segments = zipline:FindFirstChild(partType.."Segments") :: Folder
		
		local part = cache:FindFirstChildOfClass("Part")
		if part then
			part.Parent = segments
			return part
		else
			local templatePart = Instance.new("Part")
			templatePart.Size = Vector3.one * 0.3
			templatePart.Anchored = false
			templatePart.Material = Enum.Material.SmoothPlastic
			templatePart.CanCollide = false
			templatePart.Parent = segments
			if partType == "Cylinder" then
				templatePart.Shape = Enum.PartType.Cylinder
			else
				templatePart.Shape = Enum.PartType.Ball
			end
			
			return templatePart
		end
	end
	
	local function generateSplineFromPoints()
		local straighteningOffset = startPoint.CFrame + startPoint.CFrame.LookVector * (startPoint.Size.Z / 2 + 1)
		local points = {startPoint.CFrame, straighteningOffset}
		for _, point in pointsFolder:GetChildren() do
			if not point:IsA("BasePart") or tonumber(point.Name) == nil then
				continue
			end

			points[tonumber(point.Name) :: number + 2] = point.CFrame
		end
		points[#points + 1], points[#points] = points[#points], points[#points] - points[#points].LookVector 
		
		for index, point in points do
			points[index] = startPoint.CFrame:ToObjectSpace(point)
		end

		local spline = CatRom.new(points, zipline:GetAttribute("CurveAlpha"), zipline:GetAttribute("CurveTension"), zipline:GetAttribute("Loops"))
		
		spline:PrecomputeRMFs()
		local transportFunc = spline:GetTransportInterpolant(CFrame.new(0, 0, 0), 0, 1, true) :: any
		return spline, transportFunc
	end
	
	local spline, transportFunc = generateSplineFromPoints()
	local segmentCount = zipline:GetAttribute("Segments")
	
	-- Swizzle cache and segment folders so that we can treat all existing segments as cached segments
	sphereCache, sphereSegments = sphereSegments, sphereCache
	sphereCache.Name, sphereSegments.Name = "SphereCache", "SphereSegments"
	
	cylinderCache, cylinderSegments = cylinderSegments, cylinderCache
	cylinderCache.Name, cylinderSegments.Name = "CylinderCache", "CylinderSegments"
	
	for _, folder in {sphereCache, cylinderCache} do
		for _, part in folder:GetChildren() do
			disableWelds(part)
			local part = part :: Part
			part.Anchored = true
			part.CFrame = CFrame.new(math.huge, math.huge, math.huge)
		end
	end
	
	local parts = {}
	local cframes = {}
	local firstFrame = nil
	spline:PrecomputeUnitSpeedData("now", "accurate", 8)
	spline:SolveBulk(function(segment, t)
		local secondFrame = startPoint.CFrame:ToWorldSpace(segment:SolveCFrameLookAlong(t)) :: CFrame

		if not firstFrame then
			firstFrame = secondFrame
			return
		end

		local distance = (secondFrame.Position - firstFrame.Position).Magnitude

		local cylinder = getPart("Cylinder")
		cylinder.Shape = Enum.PartType.Cylinder
		cylinder.CFrame = CFrame.lookAt(firstFrame.Position, secondFrame.Position)
		cylinder.CFrame += cylinder.CFrame.LookVector * distance / 2
		cylinder.CFrame *= CFrame.Angles(math.pi / 2, 0, math.pi / 2)
		cylinder.Size = Vector3.new(distance, cylinder.Size.Y, cylinder.Size.Z)

		local sphere = getPart("Sphere")
		sphere.CFrame = cylinder.CFrame - cylinder.CFrame.RightVector * distance / 2

		sphere.Color = startPoint.Color
		cylinder.Color = startPoint.Color
		
		Utility.General.weld(startPoint, cylinder).Parent = cylinder
		Utility.General.weld(startPoint, sphere).Parent = sphere

		firstFrame = secondFrame
	end, segmentCount, 0, 1, true)
	
	for _, child in pointsFolder:GetChildren() do
		if child:IsA("BasePart") then
			object.trove:Add(child)
			object.trove:Add(Utility.General.weld(startPoint, child)).Parent = child
			
			child.Transparency = 1
		end
	end
	
	object.trove:Connect(startPoint:GetPropertyChangedSignal("Color"), function()
		for _, folder in {sphereSegments, cylinderSegments} do
			for _, part in folder:GetChildren() do
				(part :: Part).Color = startPoint.Color
			end
		end
	end)
	
	local debounce = false
	object.trove:Connect(startPoint.Touched, function(otherPart: BasePart)
		local character = Players.LocalPlayer.Character
		if Utility.Character.isLimb(otherPart) or not zipline:GetAttribute("_Active") or Utility.Character.isAttachedToConstraint() or debounce then
			return
		end
		
		debounce = true
		
		Utility.Character.mountConstraintObject(object)
		
		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		
		local ziplineTrove = object.trove:Extend()
		
		local guidePart = ziplineTrove:Clone(script.GuidePart)
		guidePart.CFrame = startPoint.CFrame
		guidePart.Parent = zipline
		
		local handle = ziplineTrove:Clone(script.Handle)
		handle.CFrame = startPoint.CFrame
		handle.Color = startPoint.Color
		handle.Parent = zipline
		Utility.ClientObjects.weldCharacterToHandle(handle, character, ziplineTrove)
		
		ziplineTrove:Connect(startPoint:GetPropertyChangedSignal("Color"), function()
			handle.Color = startPoint.Color
		end)
		
		local attachment0 = ziplineTrove:Construct(Instance, "Attachment") :: Attachment
		local attachment1 = ziplineTrove:Construct(Instance, "Attachment") :: Attachment
		
		attachment0.Parent = guidePart
		attachment1.Parent = handle
		
		local length = zipline:GetAttribute("RopeLength")
		
		local constraint = ziplineTrove:Construct(Instance, "RopeConstraint") :: RopeConstraint
		constraint.Attachment0 = attachment0
		constraint.Attachment1 = attachment1
		constraint.Length = zipline:GetAttribute("RopeLength")
		constraint.Restitution = zipline:GetAttribute("RopeRestitution")
		constraint.Visible = true
		
		ziplineTrove:Connect(zipline:GetAttributeChangedSignal("RopeLength"), function() constraint.Length = zipline:GetAttribute("RopeLength") end)
		ziplineTrove:Connect(zipline:GetAttributeChangedSignal("RopeRestitution"), function() constraint.Restitution = zipline:GetAttribute("RopeRestitution") end)
		constraint.Parent = guidePart
		
		local originalRotation = handle.CFrame.Rotation
		
		if zipline:GetAttribute("PlaySound") then
			Utility.General.cloneAndPlay(sounds:FindFirstChild("Grab") :: Sound)
		end
		
		ziplineTrove:Add(Utility.Character.dismountConstraintObject)
		
		local function dismount(noJump: boolean?)
			noJump = if noJump ~= nil then noJump else not zipline:GetAttribute("EndJump")

			if not noJump and humanoid then
				Utility.General.cloneAndPlay(sounds:FindFirstChild("Jump") :: Sound)
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			
			ziplineTrove:Destroy()
			
			if zipline:GetAttribute("PreserveMomentum") then
				local moveVector = ControlModule:GetMoveVector() :: Vector3
				if moveVector.Magnitude > 0 or not zipline:GetAttribute("Controllable") then
					rootPart.AssemblyLinearVelocity = guidePart.CFrame.LookVector * zipline:GetAttribute("Speed")
				end
			end
			
			humanoid.PlatformStand = false
		end
		
		local function checkAttributeDismount()
			Utility.Character.dismountConstraintObject(not zipline:GetAttribute("EndJump"))
		end
		
		ziplineTrove:Connect(object.signals.dismount :: any, dismount)
		
		ziplineTrove:Connect(zipline:GetAttributeChangedSignal("_Active"), checkAttributeDismount)
		if zipline:GetAttribute("AllowJumpDismount") then
			task.delay(0.1, function()
				ziplineTrove:Connect(UserInputService.JumpRequest, checkAttributeDismount)
			end)
		end
		
		if length <= 0 then
			ziplineTrove:Connect(RunService.PostSimulation, function()
				handle.CFrame = guidePart.CFrame.Rotation + handle.CFrame.Position
			end)
		end
		
		ziplineTrove:Add(task.spawn(function()
			humanoid.PlatformStand = true
			
			local function guardedTransportFunc(t: number)
				if t >= 1 and not zipline:GetAttribute("Loops") then
					dismount(not zipline:GetAttribute("EndJump"))
					return transportFunc(1)
				else
					return transportFunc(t % 1)
				end
			end
			
			local particleEmitter = zipline:FindFirstChild("FrictionParticles") :: ParticleEmitter
			if particleEmitter and not constraint:IsA("RopeConstraint") then
				particleEmitter = particleEmitter:Clone()
				particleEmitter.Parent = handle.EmitterPart
			end
			
			local duration = spline.length / zipline:GetAttribute("Speed")
			local currentTime = 0
			
			local function updateGuidePartCFrame()
				local cframe = startPoint.CFrame:ToWorldSpace(guardedTransportFunc(currentTime/duration))
				guidePart.CFrame = if zipline:GetAttribute("AllowRoll") then cframe else CFrame.lookAt(cframe.Position, cframe.Position + cframe.LookVector, Vector3.yAxis)
			end
			
			ziplineTrove:Connect(startPoint:GetPropertyChangedSignal("CFrame"), updateGuidePartCFrame)
			
			ziplineTrove:Connect(RunService.PreSimulation, function(deltaTime: number)
				if zipline:GetAttribute("Controllable") then
					local moveVector = ControlModule:GetMoveVector() :: Vector3

					if moveVector.Magnitude > 0 then
						if particleEmitter then particleEmitter.Enabled = true end
						currentTime += if moveVector.Z > 0 then -deltaTime else deltaTime
						if currentTime < 0 then
							currentTime = 0
						end
					else
						if particleEmitter then particleEmitter.Enabled = false end
					end
					updateGuidePartCFrame()
				else
					currentTime += deltaTime
					updateGuidePartCFrame()
				end
			end)
		end))
		
		task.delay(zipline:GetAttribute("Cooldown"), function()
			debounce = false
		end)
	end)
end