--!strict
-- junekept 2025
-- this script was originally made for OToH

--[==[
	This module contains logic and helper functions for the ingame tower interface.
	The purpose of this module is to allow Client Objects to interact with certain UI elements (i.e. timers and key surplus)
]==]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries

local LemonSignal = require(Libraries.LemonSignal)
local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local Config = require(script.Parent.Config)
local Tower = require(script.Parent.Tower)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local towerGui = playerGui:WaitForChild("MainTowerGui")

local keyHolder = towerGui.KeyHolder.OutsideDecoration.Holder
local timerHolder = towerGui.TimerHolder

local keyTemplate = keyHolder.TEMPLATE
local timerTemplate = timerHolder.TEMPLATE

local playerInformation = towerGui.PlayerInformation
local healthBar = playerInformation.HealthBar

local HEALTH_BAR_DEFAULT_COLOR = Color3.fromRGB(84, 255, 84)
local HEALTH_BAR_POISON_COLOR = Color3.fromRGB(198, 84, 255)

keyTemplate.Parent = nil
timerTemplate.Parent = nil

healthBar.PoisonBar.Size = UDim2.fromScale(0, 0.2)

local Interface = {}

function Interface.createButtonTimer(button: Model, formatString: string?): LemonSignal.Signal<>
	local buttonPart = button:FindFirstChild("ButtonPart") :: BasePart
	local timeRemaining = button:GetAttribute("Timer") :: number
	
	formatString = formatString or "-%hh -%mm -%.1ss"
	assert(formatString) -- need this to shut the typechecker up
	
	local signal = LemonSignal.new()
	local timer = timerTemplate:Clone()
	timer.TextColor3 = buttonPart.Color
	
	local connection
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		timeRemaining -= deltaTime
		if timeRemaining <= 0 or not button:GetAttribute("Pressed") then
			connection:Disconnect()
			timer:Destroy()
			button:SetAttribute("Pressed", false)
			signal:Fire()
		end
		
		--[[
		local hours = timeRemaining / 3600
		local minutes = (timeRemaining % 3600) / 60
		local seconds = timeRemaining % 60
		
		local trueHours = hours
		local trueMinutes = timeRemaining / 60
		local trueSeconds = timeRemaining
		]]
		
		local times = {
			h = timeRemaining / 3600,
			H = timeRemaining / 3600,
			m = (timeRemaining % 3600) / 60,
			M = timeRemaining / 60,
			s = timeRemaining % 60,
			S = timeRemaining
		}
		
		local formatString = formatString
		
		local capture = ""
		local iters = 0
		while true do
			capture = (formatString:match("[+-]?%b()%s?") or formatString:match("[+-]?%%%S*%s?")) :: any
			if not capture then break end
			
			capture = capture:gsub("%%%%", "[ignore me formatter!!]")
			
			local removeIfZero = capture:sub(1, 1) == "-"
			local format = capture:match("%%%d*%.%d+[hHmMsS]") or capture:match("%%%d*[hHmMsS]") 
			if not format then
				-- actually don't warn here because otherwise any instance of () would trip it lol
				-- warn(`"{capture}" does not contain a pattern match, skipping which may cause errors.`)
				continue
			end
			assert(format) -- Roblox please your typechecker sucks
		
			local prefix, suffix, type = format:match("%%([0-9]*)(%.?%d*)([hHmMsS])")
			local timeToUse = times[type]
			if not timeToUse then
				warn(`"{capture}" contained pattern match type "{type}" which is not used in button timer formatting.`)
				continue
			end
			assert(timeToUse and prefix and type and suffix)
			if suffix == "" then
				suffix = ".0"
				-- floor divide by 1 so we can get the floored value instead of the rounded one.
				-- the rounded value may give you a result you don't want (i.e. 9h 30m instead of 8hr 30m because it's 8.5->9 hours)
				timeToUse //= 1
			end

			local substitutedFormat = string.format(`%{prefix}{suffix}f`, timeToUse)
			local transformedCapture
			if timeToUse > 0 or not removeIfZero then
				transformedCapture = capture:gsub("^-", ""):gsub("^%(", ""):gsub("%)$", "")
					:gsub("%%%d*%.?%d?[hHmMsS]", substitutedFormat):gsub("%%[hHmMsS]", substitutedFormat)
			else
				transformedCapture = ""
			end
			formatString = formatString:gsub(capture:gsub("([^a-zA-Z0-9])", "%%%1"), transformedCapture, 1)
		end
		
		-- replace double percent signs
		timer.Text = formatString:gsub(" $", ""):gsub("%%%%", "%%")
	end)
	
	-- make sure it updates once before being parented
	RunService.RenderStepped:Once(function()
		timer.Parent = timerHolder
	end)
	
	return signal
end

local originalKeyParents: {[Types.Key]: Instance?} = {}
local currentLastKeyIndex = 0
function Interface.addKey(key: Types.Key)
	currentLastKeyIndex += 1
	local keyViewport = keyTemplate:Clone()
	local viewportCamera = Instance.new("Camera")
	keyViewport.CurrentCamera = viewportCamera
	
	key.model:PivotTo(CFrame.new())
	originalKeyParents[key] = key.model.Parent
	key.model.Parent = keyViewport
	
	-- fun fact! if roblox enabled the method I could just do `viewportCamera:ZoomToExtents(key.model:GetBoundingBox())` instead of this!!!
	local modelCFrame, modelSize = key.model:GetBoundingBox()
	local viewportSize = keyViewport.AbsoluteSize
	
	-- clamped to only scale xfov2 if width < height
	-- kind of weird math but if width > height then xfov2 == yfov2
	local largestAxis = math.min(1, viewportSize.X / viewportSize.Y)
	local yfov2 = math.rad(viewportCamera.FieldOfView / 2)
	local xfov2 = math.atan(math.tan(yfov2) * largestAxis)
	local radius = modelSize.Magnitude / 2
	local cameraDistance = radius / math.sin(xfov2)
	
	viewportCamera.CFrame = CFrame.lookAt(modelCFrame.Position + Vector3.zAxis * cameraDistance, modelCFrame.Position)
	
	viewportCamera.Parent = keyViewport
	
	keyViewport.LayoutOrder = currentLastKeyIndex
	keyViewport.Name = tostring(currentLastKeyIndex)
	keyViewport.Parent = keyHolder
end

function Interface.removeKey(key: Types.Key)
	local keyViewport = key.model.Parent
	if not keyViewport or keyViewport.Parent ~= keyHolder or not keyViewport:IsA("ViewportFrame") then
		return
	end
	
	key.model.Parent = originalKeyParents[key]
	
	local keyIndex = keyViewport.LayoutOrder
	for i = keyIndex + 1, currentLastKeyIndex do
		local currentFrame = keyHolder:FindFirstChild(tostring(i)) :: ViewportFrame
		local previousFrame = keyHolder:FindFirstChild(tostring(i - 1)) :: ViewportFrame
		
		local keyModel = currentFrame:FindFirstChildOfClass("Model")
		if keyModel then
			keyModel.Parent = previousFrame
		end
	end
	
	keyHolder:FindFirstChild(tostring(currentLastKeyIndex)):Destroy()
	currentLastKeyIndex -= 1
end

local poisonAlpha = 0
function Interface.updateHealthBarPoison(poison: number)
	poisonAlpha = poison / Tower.loadedTower.config.posionDamageThreshold
	
	healthBar.ChangingBar.UIGradient.Offset = Vector2.new((1 - poisonAlpha) * 1.1 - 0.5, 0)
end

-- actual logic below here
local KEY_HOLDER_TWEEN_IN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local KEY_HOLDER_TWEEN_OUT_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local keyHolderPosition = towerGui.KeyHolder.Position 

local keyHolderTweenIn = TweenService:Create(towerGui.KeyHolder, KEY_HOLDER_TWEEN_IN_INFO, {Position = keyHolderPosition})
local keyHolderTweenOut = TweenService:Create(towerGui.KeyHolder, KEY_HOLDER_TWEEN_OUT_INFO, {Position = keyHolderPosition})

local keyHolderToggle = towerGui.KeyHolder.Toggle
local keyHolderTabOpen = true
local function toggleKeyHolder()
	keyHolderTabOpen = not keyHolderTabOpen

	-- we're using the fact that scale is a ratio of pixels/totalPixels here so that it stays consistent on resize too
	local keyHolderOffset = UDim2.fromScale(0, keyHolder.AbsoluteSize.Y / towerGui.AbsoluteSize.Y)

	if keyHolderTabOpen then
		keyHolderPosition -= keyHolderOffset
	else
		keyHolderPosition += keyHolderOffset
	end

	keyHolderToggle.Rotation = if keyHolderTabOpen then 0 else 180
	TweenService:Create(
		towerGui.KeyHolder,
		if keyHolderTabOpen then KEY_HOLDER_TWEEN_IN_INFO else KEY_HOLDER_TWEEN_OUT_INFO,
		{Position = keyHolderPosition}
	):Play()
end

keyHolderToggle.Activated:Connect(toggleKeyHolder)
toggleKeyHolder() -- start in closed state

return Interface