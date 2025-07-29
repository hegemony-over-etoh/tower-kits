--!strict
--!optimize 2
--@version button-6.0.0
--@creator synnwave

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local ACTIVE_KEY = "ButtonActive"
local PLATFORM_TAG = "ButtonActivated"

local COMMUNICATOR = {
	KEY = "ButtonEvent",
	UPDATE_BUTTONS = "update-button-platforms",
	SET_PRESSED = "set-pressed",
	AWAIT_CACHE = "await-cache",
}

-- every 64 button platforms activated will wait a frame to prevent *some* lag
local PART_BUFFER = 64
local TWEEN_TRANSPARENCY_PROPERTIES = {
	-- things that can have their transparency tweened
	Decal = "Transparency",
	Texture = "Transparency",
	SelectionBox = "Transparency",
	SelectionSphere = "Transparency",
	Frame = "BackgroundTransparency",
	CanvasGroup = "GroupTransparency",
	TextLabel = "TextTransparency",
	ImageLabel = "ImageTransparency",
} :: { [string]: string }
local SET_PROPERTIES_ENABLED = {
	-- these will just have their enabled property change instead
	"Beam",
	"ParticleEmitter",
	"Fire",
	"Sparkles",
	"Smoke",
	"Trail",
	"UIStroke",
	"UIGradient",
}

type Button = {
	Button: BasePart,
	Configuration: Instance,
	Color: Color3,
	ID: string,
	Pressed: boolean,
	PressedSignal: _T.ScopeCommunicator,
	TotalPresses: number,
}
type ButtonCache = {
	ButtonActivatedPlatforms: { [BasePart]: boolean? },
	Buttons: { [Button]: boolean? },
}

local function handleButtonCache(rootScope: _T.Scope): ButtonCache
	local cache: ButtonCache = { ButtonActivatedPlatforms = {}, Buttons = {} }
	local buttonEvent = rootScope:getCommunicator("event", COMMUNICATOR.KEY)
	local buttonRequest = rootScope:getCommunicator("request", COMMUNICATOR.KEY)

	local utility = rootScope:utility()

	--> Button Functionality
	local propertyUtil = utility.Property
	local functionUtil = utility.Functions
	local clientObjectUtil = utility.ClientObjects

	local tween = functionUtil.tween
	local roundColor = functionUtil.roundColor
	local setPropertySafe = propertyUtil.setPropertySafe
	local setInstanceActive = clientObjectUtil.setInstanceActive

	local function hasTimer(currentButton: Button)
		return propertyUtil.assureConfig(currentButton.Configuration, "Timer", 0) > 0
	end
	local function getTransparency(platform: Instance, isActivated: boolean)
		local enabledTransparency = propertyUtil.assureConfig(platform, "SetTransparency", 0)
		local disabledTransparency = if platform:HasTag("FullHidePlatform") then 1 else 0.6
		return if isActivated then enabledTransparency else disabledTransparency
	end

	local function activatePlatform(platform: BasePart, isPressed: boolean, targetButton: Button?)
		local isActivated = isPressed
		if platform:HasTag("InvertPlatform") then
			isActivated = not isActivated
		end

		local currentColor = roundColor(propertyUtil.assureConfig(platform, "ColorOverride", platform.Color))
		if targetButton and currentColor ~= targetButton.Color then
			return
		end
		setInstanceActive(rootScope, platform, ACTIVE_KEY, isActivated)

		for _, descendant in platform:GetDescendants() do
			if descendant:HasTag("IgnoreAll") then
				continue
			end
			for objectType, property in TWEEN_TRANSPARENCY_PROPERTIES do
				if descendant:IsA(objectType) and not descendant:HasTag("IgnoreTransparency") then
					tween(descendant, 0.3, { [property] = getTransparency(descendant, isActivated) })
				end
			end

			for _, objectType in SET_PROPERTIES_ENABLED do
				if descendant:IsA(objectType) and not descendant:HasTag("IgnoreEnabled") then
					setPropertySafe(descendant, "Enabled", isActivated)
				end
			end
		end

		local ignoreAll = platform:HasTag("IgnoreAll")
		if not (platform:HasTag("IgnoreCanCollide") or ignoreAll) then
			platform.CanCollide = isActivated
		end
		if not (platform:HasTag("IgnoreTransparency") or platform:HasTag("Invisible") or ignoreAll) then
			tween(platform, 0.3, { Transparency = getTransparency(platform, isActivated) })
		end
	end

	--> Platform Caching
	local clientObjects = rootScope.clientObjects
	local function tagFilter(instance: Instance)
		return instance:IsA("BasePart") and instance:IsDescendantOf(clientObjects)
	end
	local function handleNewPlatform(platform: BasePart)
		cache.ButtonActivatedPlatforms[platform] = true
		if not platform:HasTag("IgnoreInitialActivate") then
			activatePlatform(platform, false)
		end
	end

	for _, platform in CollectionService:GetTagged(PLATFORM_TAG) do
		if not tagFilter(platform) then
			continue
		end
		handleNewPlatform(platform)
	end
	rootScope:add(CollectionService:GetInstanceAddedSignal(PLATFORM_TAG):Connect(function(instance)
		if not tagFilter(instance) or not instance:IsA("BasePart") then
			return
		end
		handleNewPlatform(instance)
	end))
	rootScope:add(CollectionService:GetInstanceRemovedSignal(PLATFORM_TAG):Connect(function(instance)
		cache.ButtonActivatedPlatforms[instance] = nil
	end))

	--> Listen to events
	buttonEvent:listen(function(type: string, ...)
		if type == COMMUNICATOR.UPDATE_BUTTONS then
			local targetButton: Button, isPressed: boolean = ...
			if
				typeof(isPressed) ~= "boolean"
				or not (typeof(targetButton) == "table" and typeof(targetButton.ID) == "string")
			then
				return
			end

			local doNotContinue = false
			local valuesToChange: { Button } = {}

			local targetButtonHasTimer = hasTimer(targetButton)
			for currentButton in cache.Buttons do
				if currentButton.ID == targetButton.ID or currentButton.Color ~= targetButton.Color then
					-- Same button or button with a different color, skip
					continue
				end

				local timerInvolved = targetButtonHasTimer or hasTimer(currentButton)
				local pressed = currentButton.Pressed
				if (timerInvolved and pressed) or ((not timerInvolved) and pressed == isPressed) then
					doNotContinue = true
				elseif not timerInvolved then
					table.insert(valuesToChange, targetButton)
				end
			end

			if doNotContinue then
				return
			end
			for _, button in valuesToChange do
				buttonEvent:fire(COMMUNICATOR.SET_PRESSED, button, isPressed)
			end

			local partsActivated = 0
			for platform in cache.ButtonActivatedPlatforms do
				activatePlatform(platform, isPressed, targetButton)
				partsActivated += 1
				if (partsActivated % PART_BUFFER) == 0 then
					task.wait()
				end
			end
		end

		if type == COMMUNICATOR.SET_PRESSED then
			local targetButton, isPressed = ...
			if
				typeof(isPressed) ~= "boolean"
				or not (typeof(targetButton) == "table" and typeof(targetButton.ID) == "string")
			then
				return
			end
			targetButton.Pressed = isPressed
			targetButton.PressedSignal:fire(isPressed)
		end
	end)

	buttonRequest:listen(function(type: string, ...)
		if type == COMMUNICATOR.AWAIT_CACHE then
			return cache
		end
	end)

	return cache
end

local Button = {
	CanQueue = true,
	RunOnStart = false,

	Communicator = COMMUNICATOR,
}

function Button.Run(scope: _T.Scope)
	local buttonConfig = scope.instance
	if not buttonConfig or not buttonConfig.Parent then
		return
	end

	local buttonPart = buttonConfig.Parent:FindFirstChild("ButtonPart")
	if not buttonPart or not buttonPart:IsA("BasePart") then
		return
	end

	local utility = scope:utility()
	local cache = utility.Scope.getCached(scope, "button_cache", handleButtonCache)
	-- ^ To get this cache from an external script, please do the following:
	-- `scope:getCommunicator("request", "ButtonEvent"):request("await-cache")`

	local buttonEvent = scope:getCommunicator("event", COMMUNICATOR.KEY)
	scope:attach(buttonPart, true)

	local thisID = utility.Functions.generateUID()
	local thisButton: Button = {
		Button = buttonPart,
		Configuration = buttonConfig,
		Color = utility.Functions.roundColor(buttonPart.Color),
		Pressed = false,
		ID = thisID,
		TotalPresses = 0,
		PressedSignal = scope:add(scope:getCommunicator("event", thisID .. "Pressed")),
	}
	cache.Buttons[thisButton] = true
	scope:add(function()
		cache.Buttons[thisButton] = nil
	end)

	--> Configurations
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, buttonConfig, {
		Timer = 0,
		TimerDecimalPlaces = 1,
		TimerText = "{T}",
		PressOffset = CFrame.new(Vector3.yAxis * 0.75),
		PressedMaterial = Config.Type.Enum(Enum.Material.Neon),
		HideGUI = false,
	}):CheckForChanges()
	local touchConfiguration =
		Config.GetConfig(scope, buttonConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, buttonConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:CheckForChanges()

	local timerLabel = buttonConfig:FindFirstChildWhichIsA("TextLabel")

	local function updatePlatforms(pressed: boolean?)
		buttonEvent:fire(
			COMMUNICATOR.UPDATE_BUTTONS,
			thisButton,
			if pressed ~= nil then pressed else thisButton.Pressed
		)
	end

	local debounce = false
	local originalCFrame = buttonPart.CFrame
	local originalMaterial = buttonPart.Material

	--> Detect Button updates
	scope:add(thisButton.PressedSignal:listen(function(isPressed: boolean)
		thisButton.TotalPresses += 1
		buttonPart.Material = if isPressed then configuration.PressedMaterial else originalMaterial
		if buttonPart.Anchored then
			utility.Functions.tween(
				buttonPart,
				tweenConfiguration,
				{ CFrame = if isPressed then originalCFrame * configuration.PressOffset else originalCFrame }
			)
		end

		updatePlatforms(isPressed)

		--> Timer functionality
		if configuration.Timer > 0 and isPressed then
			local pressId = thisButton.TotalPresses
			local labels = {} :: { TextLabel }
			local text = configuration.TimerText
			local timerScope = scope:inherit()
			local startTime = os.clock()
			local timerFinished = timerScope:add(Instance.new("BindableEvent"))
			timerScope:add(function()
				-- in the case that the scope is cleaning up but the timer
				-- hasn't finished
				timerFinished:Fire()
			end)

			if not configuration.HideGUI and timerLabel then
				local screenText = timerScope:add(timerLabel:Clone())
				screenText.Visible = false
				if not screenText:HasTag("UseSpecialColor") then
					local buttonColor = buttonPart.Color
					screenText.TextColor3 = buttonColor
					screenText.TextStrokeColor3 = Color3.new(1 - buttonColor.R, 1 - buttonColor.G, 1 - buttonColor.B)
				end

				local partText = timerScope:add(screenText:Clone())
				local surfaceGui = timerScope:add(Instance.new("SurfaceGui"))
				surfaceGui.Face = Enum.NormalId.Top
				surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				surfaceGui.PixelsPerStud = 50
				surfaceGui.Parent = buttonPart

				screenText.Parent = utility.Gui.EffectGui.TimerList
				partText.Parent = surfaceGui
				table.insert(labels, screenText)
				table.insert(labels, partText)
				timerScope:attach(screenText, true)
				timerScope:attach(surfaceGui, true)
			end

			local timeAmount = configuration.Timer
			local decimalPlaces = `%.{configuration.TimerDecimalPlaces}f`
			timerScope:add(RunService.Heartbeat:Connect(function()
				if thisButton.TotalPresses ~= pressId then
					timerFinished:Fire()
					return
				end

				local actualTime = timeAmount - (os.clock() - startTime)
				if actualTime <= 0 then
					timerFinished:Fire()
					return
				end

				local displayTime = if configuration.TimerDecimalPlaces == 0
					then tostring(math.ceil(actualTime)) -- off by 0.5s otherwise
					else string.format(decimalPlaces, actualTime)

				local timerText = text:gsub("{T}", displayTime)
					:gsub("{S}", if displayTime == "1" then "" else "s")
					:gsub("{pn}", string.lower(player.Name))
					:gsub("{Pn}", player.Name)
					:gsub("{PN}", string.upper(player.Name))
					:gsub("{dn}", string.lower(player.DisplayName))
					:gsub("{Dn}", player.DisplayName)
					:gsub("{DN}", string.upper(player.DisplayName))
					:gsub("{UID}", player.UserId)

				for _, label in labels do
					if label.Text ~= timerText then
						label.Text = timerText
					end

					if not label.Visible then
						label.Visible = true
					end
				end
			end))

			timerFinished.Event:Wait()
			timerScope:cleanup(false, true)
			if thisButton.TotalPresses == pressId then
				buttonEvent:fire(COMMUNICATOR.SET_PRESSED, thisButton, false)
			end
		end
	end))

	-->
	local function activateButton()
		if debounce or thisButton.Pressed then
			return
		end

		debounce = true
		buttonEvent:fire(COMMUNICATOR.SET_PRESSED, thisButton, true)
		task.delay(0.15, function()
			debounce = false
		end)
	end

	scope:add(buttonPart.Touched:Connect(function(toucher: BasePart)
		if buttonPart:GetAttribute("Activated") == false then
			return
		end
		if not utility.ClientObjects.evaluateToucher(buttonPart, toucher, touchConfiguration) then
			return
		end

		activateButton()
	end))
end

return Button
