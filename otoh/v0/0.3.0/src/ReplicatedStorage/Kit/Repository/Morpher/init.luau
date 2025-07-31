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
	local morpherModel = object.instance :: Model
	local morphParts = morpherModel:FindFirstChild("MorphParts") :: Folder
	local morphTargets = morpherModel:FindFirstChild("MorphTargets") :: Folder
	local buttons = morpherModel:FindFirstChild("Buttons") :: Folder
	local sounds = morpherModel:FindFirstChild("Sounds") :: Folder
	
	local originalProperties = {}
	for _, part in morphParts:GetDescendants() do
		if part:IsA("BasePart") then
			originalProperties[part] = {
				CFrame = part.CFrame,
				Size = part.Size,
				Color = part.Color,
				Material = part.Material
			}
		end
	end
	
	local activeButton: Instance? = nil
	local activeButtonReturnTween: Tween? = nil
	local originalButtonColors = {}
	local function activateButton(button: Model)
		if not morpherModel:GetAttribute("_Active") or activeButton == button then
			return
		end

		local buttonPart = button:FindFirstChild("Button") :: BasePart
		if activeButtonReturnTween then
			activeButtonReturnTween:Play()
		end

		-- roblox typechecker unironically makes you do this btw brilliant type coercion
		activeButton = button; assert(activeButton)
		local morphSpeed = activeButton:GetAttribute("MorphSpeed")
		local morphDuration = activeButton:GetAttribute("MorphDuration")
		local returnSpeed = activeButton:GetAttribute("ReturnSpeed")
		local onColor = activeButton:GetAttribute("OnColor")
		local playSound = morpherModel:GetAttribute("PlaySound") or button:GetAttribute("PlaySound")

		local easeStyle = Enum.EasingStyle:FromName(activeButton:GetAttribute("EasingStyle")) or Enum.EasingStyle.Quad
		local easeDirection = Enum.EasingDirection:FromName(activeButton:GetAttribute("EasingDirection")) or Enum.EasingDirection.Out

		local returnEaseStyle = Enum.EasingStyle:FromName(activeButton:GetAttribute("ReturnEasingStyle")) or Enum.EasingStyle.Quad
		local returnEaseStyle = Enum.EasingDirection:FromName(activeButton:GetAttribute("ReturnEasingDirection")) or Enum.EasingDirection.In

		local morphInfo = TweenInfo.new(morphSpeed, easeStyle, easeDirection)
		local returnInfo = TweenInfo.new(returnSpeed, easeStyle, easeDirection)
		activeButtonReturnTween = TweenService:Create(activeButton:FindFirstChild("Button"), returnInfo, {Color = originalButtonColors[activeButton]})

		local morphTarget = morphTargets:FindFirstChild(button.Name)
		assert(morphTarget, `Button {button} does not have corresponding target folder named. Expected folder MorphTargets["{button.Name}"]`)

		if playSound then
			Utility.General.cloneAndPlay(sounds:FindFirstChild("Press") :: Sound)
		end
		
		TweenService:Create(buttonPart, morphInfo, {Color = onColor}):Play()
		for _, morphPart in (morphParts:GetChildren() :: any) :: {BasePart} do
			local corresponding = morphTarget:FindFirstChild(morphPart.Name)
			if not corresponding or not corresponding:IsA("BasePart") then continue end
			TweenService:Create(morphPart, morphInfo, {
				CFrame = corresponding.CFrame,
				Size = corresponding.Size,
				Color = corresponding.Color
			}):Play()
			task.delay(morphSpeed, function()
				morphPart.Material = corresponding.Material
			end)
		end

		task.wait(morphSpeed)

		if morphDuration > 0 then
			local durationGui = script.DurationGui:Clone()
			durationGui.Parent = buttonPart

			local durationLeft = morphDuration
			local lastSecond = -1
			local connection
			connection = RunService.RenderStepped:Connect(function(deltaTime: number)
				durationLeft -= deltaTime
				if math.floor(durationLeft) ~= lastSecond and playSound then
					Utility.General.cloneAndPlay(sounds:FindFirstChild("Tick") :: Sound)
					lastSecond = math.floor(durationLeft)
				end

				if durationLeft <= 0 or activeButton ~= button then
					connection:Disconnect()
					durationGui:Destroy()
					if activeButton == button then
						for _, morphPart in (morphParts:GetChildren() :: any) :: {BasePart} do
							local corresponding = originalProperties[morphPart]
							if not corresponding then continue end

							TweenService:Create(morphPart, morphInfo, {
								CFrame = corresponding.CFrame,
								Size = corresponding.Size,
								Color = corresponding.Color
							}):Play()

							task.delay(morphSpeed, function()
								morphPart.Material = corresponding.Material
							end)
						end

						if activeButtonReturnTween then
							activeButtonReturnTween:Play()
						end

						activeButton = nil
						activeButtonReturnTween = nil
					end
				else
					durationGui.TextLabel.Text = string.format("%.1f", durationLeft)
				end
			end)
		end
	end
	
	object.trove:Connect(object.signals.onTrigger :: any, activateButton)
	
	for _, button in buttons:GetChildren() do
		local buttonPart = button:FindFirstChild("Button") :: BasePart
		originalButtonColors[button] = buttonPart.Color
		object.trove:Connect(buttonPart.Touched, function(otherPart: BasePart)
			if not Utility.ClientObjects.isTouchValid(button, otherPart) then
				return
			end
			
			activateButton(button :: Model)
		end)
	end
end