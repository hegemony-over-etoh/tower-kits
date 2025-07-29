--!strict
--!optimize 2
--@version vanisher-6.0.0
--@creator aamo_s

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

-- Constants
local ALLOWED_VANISH_MODES = {"Fade", "Blink", "Constant", "Shrink"}

local ALLOWED_SHRINK_DIRECTIONS = {
	"Center", "Top", "Bottom", "Front", "Back", "Left", "Right"
}

local SHRINK_DIRECTION_OFFSETS = {
	Center = Vector3.zero,
	Top = Vector3.yAxis,
	Bottom = -Vector3.yAxis,
	Front = Vector3.zAxis,
	Back = -Vector3.zAxis,
	Left = Vector3.xAxis,
	Right = -Vector3.xAxis,
}

return function(scope: _T.Scope)
	local utility = scope:utility()
	local vanisherConfig = scope.instance
	if not vanisherConfig then return end

	local vanisher = vanisherConfig.Parent
	if not vanisher or not vanisher:IsA("BasePart") then return end

	-- Configuration setup
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, vanisherConfig, {
		BlinkCount = 3,
		ConstantNoRecovery = false,
		Invert = false,
		RespawnFade = false,
		RespawnTime = 2,
		FadeDirection = Enum.EasingDirection.Out,
		VanishMode = Config.Type.Some(table.unpack(ALLOWED_VANISH_MODES)),
		ShrinkDirection = Config.Type.Some(table.unpack(ALLOWED_SHRINK_DIRECTIONS)),
	}):CheckForChanges()

	local touchConfiguration = Config.GetConfig(
		scope, vanisherConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):CheckForChanges()
	local tweenConfiguration = Config.GetConfig(
		scope, vanisherConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG):CheckForChanges()

	local selectionBox = vanisher:FindFirstChild("VanisherSelectionBox")

	if selectionBox and not selectionBox:IsA("SelectionBox") then
		return
	end

	local defaultLineThickness = if selectionBox then selectionBox.LineThickness else 0.1
	local defaultCanCollide = not configuration.Invert
	local defaultTransparency = if configuration.Invert then 1 else 0
	local touchedCanCollide = not defaultCanCollide
	local touchedTransparency = 1 - defaultTransparency

	local active = false
	local touchingParts: {[BasePart]: boolean} = {}
	local touchTime = 0
	local totalFadeTime = tweenConfiguration.Time

	local activeTweens: {Tween} = {}
	local activeThreads: {thread} = {}

	-- Helper functions
	local function stopAllProcesses()
		for _, tween in activeTweens do
			tween:Cancel()
			
			task.defer(function()
				tween:Destroy()
			end)
		end
		activeTweens = {}

		for _, thread in activeThreads do
			task.cancel(thread)
		end
		activeThreads = {}
	end

	local function updateSelectionBox(color: Color3, thickness: number?)
		if selectionBox then
			selectionBox.Color3 = color
			if thickness then
				selectionBox.LineThickness = thickness
			end
		end
	end

	local function startTween(instance: Instance, properties: {[string]: any})
		local tween = utility.Functions.tween(instance, tweenConfiguration, properties)
		table.insert(activeTweens, tween)
		return tween
	end
	
	local function updateConfigurationVariables()
		defaultLineThickness = if selectionBox then selectionBox.LineThickness else 0.1
		defaultCanCollide = not configuration.Invert
		defaultTransparency = if configuration.Invert then 1 else 0
		touchedCanCollide = not defaultCanCollide
		touchedTransparency = 1 - defaultTransparency
	end
	
	-- Core functionality
	local function respawn()
		stopAllProcesses()
		touchingParts = {}
		touchTime = 0

		vanisher.CanCollide = defaultCanCollide
		vanisher.CanTouch = true
		active = false

		if configuration.RespawnFade then
			startTween(vanisher, {Transparency = defaultTransparency})
		else
			vanisher.Transparency = defaultTransparency
		end

		updateSelectionBox(Color3.new(0, 0, 0))
	end

	local function vanish()
		active = true
		vanisher.CanCollide = touchedCanCollide
		vanisher.CanTouch = false
		vanisher.Transparency = touchedTransparency
		updateSelectionBox(Color3.new(1, 0, 0))
		task.delay(configuration.RespawnTime, respawn)
	end

	-- Vanish mode implementations
	local function handleConstantMode()
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = {}
		params.CollisionGroup = ""

		while true do
			local deltaTime = task.wait(1/60)

			-- Get current touching parts
			for part in touchingParts do
				params:AddToFilter(part)
			end

			local currentParts = workspace:GetPartBoundsInBox(vanisher.CFrame, vanisher.Size + Vector3.one * 0.1, params)
			local currentPartsSet = {}
			for _, part in currentParts do
				currentPartsSet[part] = true
			end

			-- Update touching parts
			for part in touchingParts do
				if not currentPartsSet[part] then
					touchingParts[part] = nil
				end
			end
			
			for _, part in currentParts do
				if not touchingParts[part] then
					touchingParts[part] = true
				end
			end
			
			-- Update fade time
			if next(currentParts) ~= nil then
				touchTime = math.min(touchTime + deltaTime, totalFadeTime)
			elseif not configuration.ConstantNoRecovery then
				touchTime = math.max(touchTime - (deltaTime * totalFadeTime/configuration.RespawnTime), 0)
			end

			vanisher.Transparency = defaultTransparency + (touchedTransparency - defaultTransparency) * (touchTime / totalFadeTime)

			if touchTime >= totalFadeTime then
				vanish()
				break
			end
		end
	end
	
	local function handleBlinkMode()
		local blinkSound = vanisher:FindFirstChild("BlinkSound") or script.DefaultBlinkSound:Clone()
		blinkSound.Parent = vanisher

		for i = 1, configuration.BlinkCount do
			blinkSound:Play()

			if selectionBox then
				selectionBox.LineThickness = defaultLineThickness * 3
				startTween(selectionBox, {LineThickness = 0.1}).Completed:Wait()
			else
				startTween(vanisher, {Transparency = (defaultTransparency + touchedTransparency)/2}).Completed:Wait()
			end
		end

		blinkSound.PlaybackSpeed = 1.2
		blinkSound:Play()
		vanish()
	end

	local RunService = game:GetService("RunService")

	local function handleShrinkMode()
		local shrinkPart = Instance.fromExisting(vanisher)

		local originalRotation = vanisher.CFrame - vanisher.Position

		vanisher.Transparency = 1
		vanisher.CanCollide = false

		shrinkPart.Transparency = 0
		shrinkPart.CanCollide = true
		shrinkPart.Anchored = true
		shrinkPart.Parent = vanisher

		local direction = SHRINK_DIRECTION_OFFSETS[configuration.ShrinkDirection]
		local startSize = vanisher.Size
		local endSize = startSize
		local relativeOffset = CFrame.new(0, 0, 0)

		if configuration.ShrinkDirection ~= "Center" then
			local offset = 0.5 * startSize * direction
			relativeOffset = CFrame.new(offset)

			if direction.X ~= 0 then
				endSize = Vector3.new(0, startSize.Y, startSize.Z)
			elseif direction.Y ~= 0 then
				endSize = Vector3.new(startSize.X, 0, startSize.Z)
			elseif direction.Z ~= 0 then
				endSize = Vector3.new(startSize.X, startSize.Y, 0)
			end
		end

		if configuration.Invert then
			shrinkPart.Size = endSize
			endSize = startSize
		else
			shrinkPart.Size = startSize
		end

		-- To support moving, unanchored objects
		local vanisherConnection = scope:add(RunService.PreRender:Connect(function(_, _)
			shrinkPart.CFrame = vanisher.CFrame 
				* relativeOffset 
			- (shrinkPart.Size / 2) * direction
		end))

		local tween = startTween(shrinkPart, {
			Size = endSize
		})
		
		tween.Completed:Wait()
		
		shrinkPart.Size -= Vector3.one * 1e-2
		
		vanish()
		
		if configuration.RespawnFade then
			shrinkPart.CanCollide = false
			startTween(shrinkPart, {Transparency = 1})
		end
		
		vanisherConnection:Disconnect()
		shrinkPart:Destroy()
	end

	local VANISH_HANDLERS = {
		Constant = function()
			return handleConstantMode
		end,

		Blink = function()
			active = true

			return handleBlinkMode
		end,

		Fade = function()
			active = true

			return function()
				startTween(vanisher, {Transparency = touchedTransparency}).Completed:Wait()
				vanish()
			end
		end,

		Shrink = function()
			active = true

			return handleShrinkMode
		end
	}
	
	vanisher.Transparency = defaultTransparency
	vanisher.CanCollide = defaultCanCollide
	updateSelectionBox(Color3.new(0, 0, 0))

	scope:attach(vanisher)
	
	scope:add(vanisher:GetAttributeChangedSignal("Activated"):Connect(function()
		local activated = vanisher:GetAttribute("Activated")
		stopAllProcesses()
		vanisher.CanCollide = activated and defaultCanCollide or touchedCanCollide
		vanisher.CanTouch = activated
		updateSelectionBox(activated and Color3.new(0, 0, 0) or Color3.new(1, 0, 0))
	end))
	
	scope:add(vanisher.Touched:Connect(function(hitPart: BasePart)
		if not utility.ClientObjects.evaluateToucher(vanisher, hitPart, touchConfiguration) then return end
		if active or vanisher:GetAttribute("Activated") == false then return end
		
		updateConfigurationVariables()
		stopAllProcesses()
		
		local modeHandler = VANISH_HANDLERS[configuration.VanishMode]

		if modeHandler then
			if configuration.VanishMode == "Constant" then
				touchingParts[hitPart] = true
			end

			local handler = modeHandler()
			table.insert(activeThreads, task.spawn(handler))
		end
	end))
end