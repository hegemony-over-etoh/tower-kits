local RS = game:GetService("RunService")

local char = game:GetService("Players").LocalPlayer.Character
local rootPart = char:WaitForChild("Torso")

function clip()
	local SelectedClipPart
	
	for _, part in pairs(rootPart:GetTouchingParts()) do
		if part:FindFirstChild("Clippable") then
			SelectedClipPart = part
			break
		end
	end
	
	if SelectedClipPart then
		-- get what corner of the part the player is touching.		
		local CornerPartsFolder = Instance.new("Folder", workspace)
		CornerPartsFolder.Name = "TEMP_CC_CornerParts"
		
		local function createCorner(pos)
			local CornerPart = Instance.new("Part", CornerPartsFolder)
			CornerPart.Anchored = true
			CornerPart.CanCollide = false
			CornerPart.Transparency = 1
			CornerPart.Color = Color3.new(1,0,0)
			CornerPart.CFrame = pos 
			CornerPart.Size = Vector3.new(.1, SelectedClipPart.Size.Y, .1)
			CornerPart.Touched:Connect(function() end)
			return CornerPart
		end
		
		local Corners = {
			createCorner( 
				SelectedClipPart.CFrame * CFrame.new(
					SelectedClipPart.Size.X/-2 - 0.05,
					0,
					SelectedClipPart.Size.Z/2 + 0.05
				)
			),
		
			createCorner(
				SelectedClipPart.CFrame * CFrame.new(
					SelectedClipPart.Size.X/2 + 0.05,
					0,
					SelectedClipPart.Size.Z/2 + 0.05 
				)* CFrame.Angles(0, 0, math.rad(180)) 
				
		),
			
			createCorner(
				SelectedClipPart.CFrame * CFrame.new(
					SelectedClipPart.Size.X/2 + 0.05,
					0,
					SelectedClipPart.Size.Z/-2 - 0.05
				)* CFrame.Angles(0, math.rad(180), 0) 
		),
	
		 	createCorner(
				SelectedClipPart.CFrame * CFrame.new(
					SelectedClipPart.Size.X/-2 - 0.05,
					0,
					SelectedClipPart.Size.Z/-2 - 0.05
				)* CFrame.Angles(math.rad(180), 0, 0) 	
			)
		}
		
		local SelectedCorner
		
		for _, part in pairs(rootPart:GetTouchingParts()) do
			for _, corner in pairs(Corners) do
				if part == corner then
					SelectedCorner = part
					break
				end
			end
		end
					
		if SelectedCorner then
			-- find which side of the corner the player is closer to 
			local LV = createCorner(SelectedCorner.CFrame - SelectedCorner.CFrame.LookVector * 0.3)
			local RV = createCorner(SelectedCorner.CFrame - SelectedCorner.CFrame.RightVector * 0.3)

			local ZDistance = SelectedClipPart.Clippable:FindFirstChild("Custom_Z_Distance")
			local XDistance = SelectedClipPart.Clippable:FindFirstChild("Custom_X_Distance")

			local function roundTransformation(partSize)
				if partSize > 5 then
					--[[ parts that are longer than 5 studs are given the 'glitch wrap behaviour', 
					meaning players will only be transformed 3/4 through the wall instead of all the way.
					]]
					return math.max(partSize*0.75, 5)
				else
					return partSize + 1
				end
			end

			if (LV.Position - rootPart.Position).Magnitude <= (RV.Position - rootPart.Position).Magnitude then
				rootPart.CFrame = rootPart.CFrame + SelectedCorner.CFrame.LookVector 
					* ((ZDistance and ZDistance.Value) or roundTransformation(SelectedClipPart.Size.Z))
			else
				rootPart.CFrame = rootPart.CFrame + SelectedCorner.CFrame.RightVector  
					* ((XDistance and XDistance.Value) or roundTransformation(SelectedClipPart.Size.X))
			end
		end
		CornerPartsFolder:Destroy()
	end 
end

local PrevAngle = rootPart.CFrame.LookVector

local Cooldown = false

RS.Stepped:Connect(function()
	if rootPart.CFrame.LookVector:Dot(PrevAngle) < -0.5 and Cooldown == false then
		Cooldown = true
		clip()
		wait(1)
		Cooldown = false
	end
	PrevAngle = rootPart.CFrame.LookVector
end)