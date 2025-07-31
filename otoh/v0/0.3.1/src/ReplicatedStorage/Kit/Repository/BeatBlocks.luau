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

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local mainModel: Model = object.instance :: Model
	
	local function getMostPreciseAttribute(attribute: string, part: Instance, folder: Instance): any
		return part:GetAttribute(attribute) or folder:GetAttribute(attribute) or mainModel:GetAttribute(attribute)
	end
	
	local function forEachPart(folder: Folder, fn: (BasePart, SpecialMesh) -> ())
		for _, part in folder:GetDescendants() do
			if not part:IsA("BasePart") then continue end
			local mesh = part:FindFirstChildOfClass("SpecialMesh") :: SpecialMesh

			fn(part, mesh)
		end
	end
	
	local function updateGraphics(part: BasePart, active: boolean)
		for _, graphic in part:GetDescendants() do
			if graphic:IsA("Decal") or graphic:IsA("GuiObject") then
				(graphic :: any).Transparency = part.Transparency
			elseif graphic:IsA("ParticleEmitter") then
				graphic.Enabled = active
			end
		end
	end
	
	local beatFolders = {}
	do
		local i = 0
		while true do
			i += 1
			
			local folder = mainModel:FindFirstChild(tostring(i))
			if folder and folder:IsA("Folder") then
				beatFolders[i] = folder
				for _, part in folder:GetDescendants() do
					if part:IsA("BasePart") then
						if not part:FindFirstChildOfClass("SpecialMesh") then
							local mesh = Instance.new("SpecialMesh")
							mesh.MeshType = Enum.MeshType.Brick
							mesh.Scale = Vector3.one * getMostPreciseAttribute("OffScale", part, folder)
							mesh.Parent = part
						end
						part.Transparency = getMostPreciseAttribute("OffTransparency", part, folder)
						-- part.CanCollide = not part.CanCollide
					end
				end
			else
				break
			end
		end
	end
	
	
	local function yieldForActive()
		if not mainModel:GetAttribute("_Active") then
			mainModel:GetAttributeChangedSignal("_Active"):Wait()
		end
	end
	
	local function respectActivityWait(t: number)
		local timeRemaining = t
		while true do
			yieldForActive()
			
			local deltaTime = RunService.RenderStepped:Wait()
			timeRemaining -= deltaTime
			
			if timeRemaining <= 0 then
				break
			end
		end
	end
	
	local interval = mainModel:GetAttribute("Interval")
	local indicationDuration = mainModel:GetAttribute("IndicationDuration")
	local indicateWithScale = mainModel:GetAttribute("IndicateWithScale")
	local indicateWithTransparency = mainModel:GetAttribute("IndicateWithTransparency")
	local indicationScaleOffset = mainModel:GetAttribute("IndicationScaleOffset")
	local indicationTransparencyOffset = mainModel:GetAttribute("IndicationTransparencyOffset")
	while true do
		for beat, folder in beatFolders do
			local nextFolder = beatFolders[beat + 1] or beatFolders[1]
			
			local character = Players.LocalPlayer.Character :: Types.Character

			local shouldPlayDingSound = false
			forEachPart(folder, function(part: BasePart, mesh: SpecialMesh)
				part.Transparency = getMostPreciseAttribute("OnTransparency", part, folder)
				if not getMostPreciseAttribute("KeepCollision", part, folder) then
					part.CanCollide = not part.CanCollide
				end
				mesh.Scale = Vector3.one

				updateGraphics(part, true)
				if not mainModel:GetAttribute("PlaySound") then
					return
				end
				
				local magnitudeIsOk = (part.Position - character.HumanoidRootPart.Position).Magnitude < 50
				if not shouldPlayDingSound and magnitudeIsOk then
					local ray = workspace:Raycast(part.Position, CFrame.lookAt(part.Position, character.HumanoidRootPart.Position).LookVector * 50)
					if ray then
						shouldPlayDingSound = true
					end
				end
			end)

			if shouldPlayDingSound then
				Utility.General.cloneAndPlay(mainModel:FindFirstChild("Ding") :: Sound)
			end

			Utility.ClientObjects.respectActivityWait(mainModel, interval - indicationDuration)

			if indicationDuration > 0 then
				forEachPart(folder, function(part: BasePart, mesh: SpecialMesh)
					if indicateWithScale then
						mesh.Scale -= Vector3.one * indicationScaleOffset
					end
					
					if indicateWithTransparency then
						part.Transparency += indicationTransparencyOffset
					end
				end)
				
				forEachPart(nextFolder, function(part: BasePart, mesh: SpecialMesh)
					if indicateWithScale then
						mesh.Scale += Vector3.one * indicationScaleOffset
					end

					if indicateWithTransparency then
						part.Transparency -= indicationTransparencyOffset
					end
				end)
			end
			
			Utility.ClientObjects.respectActivityWait(mainModel, indicationDuration)
			
			forEachPart(folder, function(part: BasePart, mesh: SpecialMesh)
				part.Transparency = getMostPreciseAttribute("OffTransparency", part, folder)
				if not getMostPreciseAttribute("KeepCollision", part, folder) then
					part.CanCollide = not part.CanCollide
				end
				mesh.Scale = Vector3.one * getMostPreciseAttribute("OffScale", part, folder)
				
				updateGraphics(part, false)
			end)
			
			-- pause cycle 
			Utility.ClientObjects.yieldForActive(mainModel)
		end
	end
end