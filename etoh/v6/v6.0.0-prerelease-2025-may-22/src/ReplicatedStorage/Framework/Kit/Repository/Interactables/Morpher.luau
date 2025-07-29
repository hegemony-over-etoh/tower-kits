--!strict
--!optimize 2
--@version morpher-6.0.0
--@creator Camille

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

type MorpherButton = {
	morpherID: string,

	button: Model,
	buttonParts: { BasePart },
	newMorphParts: { BasePart },

	buttonConfiguration: { [string]: any },
	touchConfiguration: { [string]: any },

	lastTouchedButtonPart: BasePart?,

	timerData: MorpherTimer?,
}

type MorpherTimer = {
	startTime: number,
	durationBillboard: BillboardGui,
	timerLabel: TextLabel,
	lastFullSecond: number?,
}

type MorpherLerp = {
	morpherID: string,
	startTime: number,
	duration: number,
	tweenInfo: TweenInfo,
	parts: { MorpherLerpPart },
	carryObjects: boolean,
	colorOnly: boolean?,
}

type MorpherLerpPart = {
	part: BasePart,

	startCFrame: CFrame,
	endCFrame: CFrame,

	startColor: Color3,
	endColor: Color3,

	startSize: Vector3,
	endSize: Vector3,
}

type MorpherCache = {
	morpherButtons: { MorpherButton },
	morpherLerps: { MorpherLerp },
}

local COMMUNICATOR = {
	KEY = "MorpherEvent",
	TIMER_EXPIRED = "timer-expired",
	LERP_ENDED = "lerp-ended",
}

return function(scope: _T.Scope)
	local utility = scope:utility()

	local morpherConfig = scope.instance
	if not morpherConfig or not morpherConfig.Parent then
		return
	end

	local morpher = morpherConfig.Parent

	scope:attach(morpher)

	--> Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, morpherConfig, {}):CheckForChanges()

	local morpherEvent = scope:getCommunicator("event", COMMUNICATOR.KEY)
	local morpherID = utility.Functions.generateUID()

	--> Variables
	local currentButton: MorpherButton? = nil
	local morphPart = morpher:FindFirstChild("Morph")
	local cloneMorphs: { BasePart } = {}

	local pressSound = morpherConfig:FindFirstChild("Press")
	local tickSound = morpherConfig:FindFirstChild("Tick")
	local durationGui = morpherConfig:FindFirstChild("DurationGui")

	-- these need to be defined like this because the cache needs to be able to access them
	local updateMorpherTimer = nil
	local updateMorpherLerp = nil

	--> cache
	local cache = utility.Scope.getCached(scope, scope.scriptPath, function()
		local cache: MorpherCache = {
			morpherButtons = {},
			morpherLerps = {},
		}

		local isTableEmpty = utility.Table.IsEmpty
		scope.rootScope:add(RunService.Heartbeat:Connect(function(deltaTime: number)
			if isTableEmpty(cache) then
				return
			end

			debug.profilebegin("Morpher -> Update Lerps")
			for _, morpherLerp in cache.morpherLerps do
				updateMorpherLerp(morpherLerp, deltaTime)
			end
			debug.profileend()

			debug.profilebegin("Morpher -> Update Timers")
			for _, morpherButton in cache.morpherButtons do
				if morpherButton.timerData then
					updateMorpherTimer(morpherButton)
				end
			end
			debug.profileend()
		end))

		return cache
	end)

	-- check for problems
	do
		if not morphPart or not morphPart:IsA("BasePart") then
			scope:log({
				"Morpher is either missing its Morph part or has it set up incorrectly.",
				`Path: {morpher:GetFullName()}`,
				type = "warn",
			})
			return
		end

		if not pressSound or not pressSound:IsA("Sound") then
			scope:log({
				"Morpher is either missing its Press sound or has it set up incorrectly.",
				`Path: {morpher:GetFullName()}`,
				type = "warn",
			})
			return
		end

		if not tickSound or not tickSound:IsA("Sound") then
			scope:log({
				"Morpher is either missing its Tick sound or has it set up incorrectly.",
				`Path: {morpher:GetFullName()}`,
				type = "warn",
			})
			return
		end

		if not durationGui or not durationGui:IsA("BillboardGui") then
			scope:log({
				"Morpher is either missing its DurationGui BillboardGui or has it set up incorrectly.",
				`Path: {morpher:GetFullName()}`,
				type = "warn",
			})
			return
		end
	end

	-- set up default morph
	local defaultMorph = morphPart:Clone()
	defaultMorph.Name = "DefaultMorph"
	defaultMorph.Transparency = 1
	defaultMorph.CanCollide = false
	defaultMorph.Anchored = true
	defaultMorph:ClearAllChildren()
	defaultMorph.Parent = morpher

	--> Functions
	local function copyProperties(from: BasePart, to: BasePart)
		to.Color = from.Color
		to.CFrame = from.CFrame
		to.CanCollide = from.CanCollide
		to.Size = from.Size
		to.Transparency = from.Transparency
		to.Material = from.Material

		for _, object in from:GetChildren() do
			local clone = object:Clone()
			clone.Parent = to
		end
	end

	local function playPressSound(morpherButton: MorpherButton)
		local sound = pressSound:Clone()
		sound.Parent = morpherButton.lastTouchedButtonPart
		sound:Play()
		Debris:AddItem(sound, sound.TimeLength / sound.PlaybackSpeed)
	end

	local function getTweenInfo(morpherButton: MorpherButton, isReturn: boolean?): TweenInfo
		local moveTime = if isReturn
			then morpherButton.buttonConfiguration.ReturnTime
			else morpherButton.buttonConfiguration.MoveTime
		local easingStyle = morpherButton.buttonConfiguration.EasingStyle
		local easingDirection = morpherButton.buttonConfiguration.EasingDirection

		return TweenInfo.new(moveTime, easingStyle, easingDirection)
	end

	local function removeLerp(morpherLerp: MorpherLerp)
		local tableIndex = table.find(cache.morpherLerps, morpherLerp)
		if tableIndex then
			table.remove(cache.morpherLerps, tableIndex)
		end
	end

	local function createLerpPart(part: BasePart, destination: BasePart): MorpherLerpPart
		return {
			part = part,

			startCFrame = part.CFrame,
			endCFrame = destination.CFrame,

			startColor = part.Color,
			endColor = destination.Color,

			startSize = part.Size,
			endSize = destination.Size,
		}
	end

	local function createLerp(
		morpherButton: MorpherButton,
		parts: { BasePart },
		destination: BasePart,
		tweenInfo: TweenInfo,
		colorOnly: boolean?
	)
		local partTable = {}

		-- set up lerp parts
		for _, part in parts do
			table.insert(partTable, createLerpPart(part, destination))
		end

		-- only the latest main morph lerp matters, disconnect any other ones
		if #parts == 1 and parts[1] == morphPart then
			for _, morpherLerp in cache.morpherLerps do
				if #morpherLerp.parts == 1 and morpherLerp.parts[1].part == morphPart then
					removeLerp(morpherLerp)
				end
			end
		end

		local lerpTable: MorpherLerp = {
			morpherID = morpherID,
			startTime = os.clock(),
			duration = tweenInfo.Time,
			tweenInfo = tweenInfo,
			parts = partTable,
			carryObjects = morpherButton.buttonConfiguration.CarryObjects,
			colorOnly = colorOnly,
		}

		table.insert(cache.morpherLerps, lerpTable)
	end

	local function updateMainMorph(morpherButton: MorpherButton, newMorph: BasePart)
		-- button color tween
		local tweenInfo = getTweenInfo(morpherButton)

		createLerp(morpherButton, morpherButton.buttonParts, newMorph, tweenInfo, true)

		-- update morph if it's a different part type
		if morphPart.ClassName ~= newMorph.ClassName
		or (morphPart:IsA("Part") and newMorph:IsA("Part") and morphPart.Shape ~= newMorph.Shape)
		then
			local morphClone = newMorph:Clone()
			morphClone.Name = "Morph"
			copyProperties(morphPart, morphClone)
			morphClone.Parent = morpher

			morphPart:Destroy()
			morphPart = morphClone
		end

		-- move all the morphs to the new morph
		morphPart.Material = newMorph.Material
		createLerp(morpherButton, { morphPart, table.unpack(cloneMorphs) }, newMorph, tweenInfo)

		-- destroy clone morphs
		for _, cloneMorph in cloneMorphs do
			task.spawn(function()
				task.wait(morpherButton.buttonConfiguration.MoveTime)
				cloneMorph:Destroy()
			end)
		end
	end

	local function createCloneMorph(morpherButton: MorpherButton, newMorph: BasePart)
		local cloneMorph = newMorph:Clone()
		cloneMorph.Name = "CloneMorph"
		cloneMorph.Material = newMorph.Material
		copyProperties(morphPart, cloneMorph)
		cloneMorph.Parent = morpher

		local tweenInfo = getTweenInfo(morpherButton)
		createLerp(morpherButton, { cloneMorph }, newMorph, tweenInfo)

		table.insert(cloneMorphs, cloneMorph)
	end

	local function deactivateButton(morpherButton: MorpherButton)
		local tweenInfo = getTweenInfo(morpherButton)
		local tweenProperties = { Color = Color3.new() }

		for _, buttonPart in morpherButton.buttonParts do
			utility.Functions.tween(buttonPart, tweenInfo.Time, {
				Color = Color3.new(),
			}, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
		end

		-- cancel timer if one is active
		if morpherButton.timerData then
			morpherButton.timerData.durationBillboard:Destroy()
			morpherButton.timerData = nil
		end
	end

	local function resetMorphs(morpherButton: MorpherButton)
		local tweenInfo = getTweenInfo(morpherButton)

		createLerp(morpherButton, { morphPart, table.unpack(cloneMorphs) }, defaultMorph, tweenInfo)

		for _, cloneMorph in cloneMorphs do
			task.spawn(function()
				task.wait(morpherButton.buttonConfiguration.ReturnTime)
				cloneMorph:Destroy()
			end)
		end

		currentButton = nil
	end

	local function formatTimerText(morpherButton: MorpherButton, timeRemaining: number): string
		local textBase = morpherButton.buttonConfiguration.TimerText
		local decimalPlaces = morpherButton.buttonConfiguration.TimerDecimalPlaces
		local decimalPlaceString = `%.{decimalPlaces}f`

		if decimalPlaces == 0 then
			return tostring(math.ceil(timeRemaining))
		end

		local displayTime = string.format(decimalPlaceString, timeRemaining)

		local timerText = textBase:gsub("{T}", displayTime):gsub("{S}", if displayTime == "1" then "" else "s")

		return timerText
	end

	updateMorpherLerp = function(morpherLerp: MorpherLerp, deltaTime: number)
		debug.profilebegin("Morpher -> Update Lerp")

		local alpha = math.clamp((os.clock() - morpherLerp.startTime) / morpherLerp.duration, 0, 1)
		alpha = TweenService:GetValue(alpha, morpherLerp.tweenInfo.EasingStyle, morpherLerp.tweenInfo.EasingDirection)

		if alpha >= 1 then
			if morpherLerp.carryObjects then
				for _, lerpPart in morpherLerp.parts do
					lerpPart.part.AssemblyLinearVelocity = Vector3.zero
				end
			end

			morpherEvent:fire(COMMUNICATOR.LERP_ENDED, morpherLerp.morpherID, morpherLerp)
			debug.profileend()
			return
		end

		for _, lerpPart in morpherLerp.parts do
			local part = lerpPart.part

			if not morpherLerp.colorOnly then
				local newSize = lerpPart.startSize:Lerp(lerpPart.endSize, alpha)
				part.Size = newSize

				local lastCFrame = part.CFrame
				local newCFrame = lerpPart.startCFrame:Lerp(lerpPart.endCFrame, alpha)
				part.CFrame = newCFrame

				if morpherLerp.carryObjects then
					local positionDifference = newCFrame.Position - lastCFrame.Position
					part.AssemblyLinearVelocity = positionDifference / deltaTime
				end
			end

			local newColor = lerpPart.startColor:Lerp(lerpPart.endColor, alpha)
			part.Color = newColor
		end

		debug.profileend()
	end

	updateMorpherTimer = function(morpherButton: MorpherButton)
		debug.profilebegin("Morpher -> Update Timer")

		local timerData = morpherButton.timerData

		if not timerData then
			debug.profileend()
			return
		end

		local timePassed = os.clock() - timerData.startTime
		local timeRemaining = morpherButton.buttonConfiguration.Timer - timePassed

		-- deactivate if time is up
		if timeRemaining <= 0 then
			morpherEvent:fire(COMMUNICATOR.TIMER_EXPIRED, morpherButton.morpherID, morpherButton)
			debug.profileend()
			return
		end

		-- update timer label
		local timerText = formatTimerText(morpherButton, timeRemaining)
		timerData.timerLabel.Text = timerText

		-- play tick sound if applicable
		local fullSecondsLeft = math.floor(timeRemaining)
		if not timerData.lastFullSecond or timerData.lastFullSecond ~= fullSecondsLeft then
			timerData.lastFullSecond = fullSecondsLeft
			tickSound:Play()
		end

		debug.profileend()
	end

	local function setupMorpherTimer(morpherButton: MorpherButton)
		-- set up timer label
		local billboard = durationGui:Clone()
		local timerLabel = billboard:FindFirstChild("TimerLabel")

		if not timerLabel or not timerLabel:IsA("TextLabel") then
			scope:log({
				"Morpher's DurationGui is either missing its TimerLabel TextLabel or has it set up incorrectly.",
				`Path: {morpher:GetFullName()}`,
				type = "warn",
			})
			return
		end

		billboard.Parent = morpherButton.lastTouchedButtonPart
		billboard.Enabled = true

		-- set up timer table
		local timerData: MorpherTimer = {
			startTime = os.clock(),
			durationBillboard = billboard,
			timerLabel = timerLabel,
		}
		morpherButton.timerData = timerData
	end

	local function activateButton(morpherButton: MorpherButton)
		-- update current button
		local oldButton = currentButton
		currentButton = morpherButton

		-- deactivate the old button and play sound
		if oldButton then
			deactivateButton(oldButton)
		end
		playPressSound(morpherButton)

		-- update morph parts
		for index, newMorph in morpherButton.newMorphParts do
			if index == 1 then
				updateMainMorph(morpherButton, newMorph)
			else
				createCloneMorph(morpherButton, newMorph)
			end
		end

		-- set up timer if it's enabled
		if morpherButton.buttonConfiguration.Timer > 0 then
			setupMorpherTimer(morpherButton)
		end
	end

	local function onButtonTouched(morpherButton: MorpherButton, touchedButton: BasePart, touchingPart: BasePart)
		if morpherButton == currentButton then
			return
		end
		if not utility.ClientObjects.evaluateToucher(touchedButton, touchingPart, morpherButton.touchConfiguration) then
			return
		end

		morpherButton.lastTouchedButtonPart = touchedButton
		activateButton(morpherButton)
	end

	local function setupMorpherButton(morpherButton: Model)
		--> set up button
		local buttonParts: { BasePart } = {}
		local newMorphs: { BasePart } = {}
		local buttonConfigObject = morpherButton:FindFirstChild("MorpherButtonConfiguration")
		local buttonConfiguration = Config.GetConfig(scope, buttonConfigObject, {
			EasingStyle = Enum.EasingStyle.Quad,
			EasingDirection = Enum.EasingDirection.Out,
			MoveTime = 0.25,
			ReturnTime = 0.25,
			Timer = 0,
			TimerText = "{T}",
			TimerDecimalPlaces = 1,
			CarryObjects = false,
		}):CheckForChanges()
		local touchConfigObject = buttonConfigObject:FindFirstChild("TouchConfiguration")
		local touchConfiguration = Config.GetConfig(scope, touchConfigObject, Config.TOUCH_CONFIG):CheckForChanges()

		for _, object in morpherButton:GetChildren() do
			if object:IsA("BasePart") then
				if object.Name == "Button" then
					table.insert(buttonParts, object)
				elseif object.Name == "NewMorph" then
					object.Transparency = 1
					table.insert(newMorphs, object)
				end
			end
		end

		local buttonTable: MorpherButton = {
			morpherID = morpherID,
			button = morpherButton,
			buttonParts = buttonParts,
			newMorphParts = newMorphs,
			buttonConfiguration = buttonConfiguration,
			touchConfiguration = touchConfiguration,
		}

		table.insert(cache.morpherButtons, buttonTable)

		--> set up touching
		for _, buttonPart in buttonParts do
			scope:add(buttonPart.Touched:Connect(function(touchingPart)
				onButtonTouched(buttonTable, buttonPart, touchingPart)
			end))
		end
	end

	--> Set up morpher buttons
	for _, object in morpher:GetChildren() do
		if object.Name == "Button" and object:IsA("Model") then
			setupMorpherButton(object)
		end
	end

	--> set up events
	morpherEvent:listen(function(type: string, ...)
		if type == COMMUNICATOR.TIMER_EXPIRED then
			local targetMorpherID: string, morpherButton: MorpherButton = ...
			if morpherID == targetMorpherID then
				deactivateButton(morpherButton)
				resetMorphs(morpherButton)
			end
		elseif type == COMMUNICATOR.LERP_ENDED then
			local targetMorpherID: string, morpherLerp: MorpherLerp = ...
			if morpherID == targetMorpherID then
				removeLerp(morpherLerp)
			end
		end
	end)
end
