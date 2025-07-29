--!strict
--!optimize 2
--@version propertychanger-6.0.1
--@creator synnwave
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 

PLEASE, **DO NOT** make any script edits to this script.
To make a script edit, please read the following:
https://etohgame.github.io/kit/docs/misc#writingediting-repository-scripts

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local _TDefs = require(script.TypeDefs)
local SequencerSupport = require(script.SequencerSupport)

local TWEENABLE_TYPES = {
	number = true,
	CFrame = true,
	Rect = true,
	Color3 = true,
	UDim = true,
	UDim2 = true,
	Vector2 = true,
	Vector2int16 = true,
	Vector3 = true,
	boolean = false, -- booleans can be tweened but i'm not including that here
}

-- DO NOT CHANGE THIS VARIABLE AT ALL --
local BLACKLISTED_CLASSES = {
	ClickDetector = true,
	DragDetector = true,
	DataModel = true,
	Workspace = true,
	ReplicatedStorage = true,
}

local PropertyChanger = {
	CanQueue = true,
	RunOnStart = false,
}

local CHANGER_CONFIG_TEMPLATE = {
	Throttle = 50,
	Cooldown = 0.5,
	ConditionalEnabled = false,
	ConditionalBreakSequence = false,
	ConditionalYield = false,
}

local function handleCache(rootScope: _T.Scope, utility: _T.Utility): _TDefs.Cache
	local cache = { tagged = {}, changers = {} }
	local shared = rootScope.shared
	local clientObjects = rootScope.clientObjects
	local characterInstances = utility.Character.getCharacter()
	local function tagFilter(instance: Instance)
		if BLACKLISTED_CLASSES[instance.ClassName] then
			return false
		end

		if
			instance:IsDescendantOf(clientObjects)
			or (characterInstances and instance:IsDescendantOf(characterInstances.character))
		then
			return true
		end
		if typeof(shared.GuiContainer) == "Instance" and instance:IsDescendantOf(shared.GuiContainer) then
			return true
		end

		return false
	end

	cache.filter = tagFilter
	function cache.getTagged(tag: string)
		local tagged = cache.tagged[tag]
		if tagged then
			return tagged
		end

		tagged = utility.Table.Filter(CollectionService:GetTagged(tag), tagFilter)
		cache.tagged[tag] = tagged
		rootScope:add(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
			local index = table.find(tagged, instance)
			if index then
				table.remove(tagged, index)
			end
		end))
		rootScope:add(CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			if tagFilter(instance) and not table.find(tagged, instance) then
				table.insert(tagged, instance)
			end
		end))

		return tagged
	end

	rootScope:add(function()
		table.clear(cache.tagged)
		cache = nil :: any
	end)

	SequencerSupport(rootScope, utility, cache)
	return cache
end

local hierarchyMethods = _TDefs.Methods
function PropertyChanger.Run(scope: _T.Scope, utility: _T.Utility)
	local changerConfig = scope.instance
	if not changerConfig or not changerConfig.Parent then
		return
	end

	--> Get config module
	local Config = utility.Config
	local propertyPointer = utility.Instance.getPointer(changerConfig:FindFirstChild("Properties"))
	if not propertyPointer or not propertyPointer:IsA("ModuleScript") then
		scope:log({
			"Property Changer is missing its 'Properties' module.",
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	--> Check for any misconfigurations
	local changer = changerConfig.Parent
	if not changer:IsA("BasePart") then
		scope:log({
			"Changer must be a BasePart",
			`Path: {changer:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local propertyMap = require(propertyPointer) :: any
	if typeof(propertyMap) ~= "table" then
		scope:log({
			`Property Changer's property module returned "{typeof(propertyMap)}", expected table`,
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
	end

	--> Get Changer Configurations
	local changerConfiguration = Config.GetConfig(scope, changerConfig, CHANGER_CONFIG_TEMPLATE):ObserveChanges()

	--> Property Fetcher Functions
	local tagCache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	local function resolveHierarchy(instance: Instance?, hierarchy: { { [string]: any } }?): Instance?
		if not hierarchy then
			return instance
		end

		for _, value in hierarchy do
			if not instance then
				break
			elseif value.name then
				instance = instance:FindFirstChild(value.name, value.descendant)
			elseif value.class then
				instance = instance:FindFirstChildWhichIsA(value.class, value.descendant)
			elseif value.ancestor then
				instance = instance:FindFirstAncestor(value.ancestor)
			elseif value.classAncestor then
				instance = instance:FindFirstAncestorWhichIsA(value.classAncestor)
			elseif value.parent then
				instance = instance.Parent
			end
		end

		if instance and not tagCache.filter(instance) then
			--> Make sure that the instance doesn't go outside of the client
			--> objects folder or the GUIs folder
			--> DO NOT REMOVE THIS CHECK!!
			instance = nil
		end

		return instance
	end

	--> Extra property values
	local function variableNotFound(variable: string)
		scope:log({
			`Could not find the sequencer variable "{variable}".`,
			`Path: {changer:GetFullName()}`,
			type = "warn",
		})
	end

	local selectedInstance: Instance?
	local currentVariables: { [string]: any }?
	local characterInstances = utility.Character.getCharacter()
	local localPlayer = Players.LocalPlayer

	local PlayerModule = require(localPlayer.PlayerScripts:WaitForChild("PlayerModule"))
	local ControlModule = PlayerModule:GetControls()
	local CameraModule = PlayerModule:GetCameras()

	local function isFirstPerson(): boolean
		if not characterInstances.primaryPart then
			return false
		end

		return characterInstances.primaryPart.LocalTransparencyModifier > 0.5
	end

	--> Preset Values
	local valueMap = {
		PlayerName = localPlayer.Name,
		PlayerDisplayName = localPlayer.DisplayName,
		UserId = localPlayer.UserId,
		CharacterPosition = function()
			return localPlayer.Character:GetPivot().Position
		end,
		CharacterCFrame = function()
			return localPlayer.Character:GetPivot()
		end,
		Distance = function(position: Vector3)
			return localPlayer:DistanceFromCharacter(position)
		end,
		PlayerHealth = function()
			local health = 0
			local humanoid = characterInstances.humanoid
			if humanoid then
				health = humanoid.Health
			end

			return health
		end,
		HumanoidState = function()
			local state = nil
			local humanoid = characterInstances.humanoid
			if humanoid then
				state = humanoid:GetState()
			end

			return state
		end,
		CameraCFrame = function()
			return Workspace.CurrentCamera.CFrame
		end,
		FormatTimer = function(text: string, decimalPlaces: number, timer: number)
			return utility.ClientObjects.formatTimerText(text, decimalPlaces, timer)
		end,
		SequencerVariable = function(variable: string)
			if not currentVariables then
				variableNotFound(variable)
				return
			end

			local evaluated = currentVariables[variable]
			if evaluated == nil or typeof(evaluated) == "Instance" then
				variableNotFound(variable)
				return
			end

			return evaluated
		end,
		MoveVector = function()
			return ControlModule:GetMoveVector()
		end,
		IsShiftLocked = function(checkFirstPerson: boolean?)
			local shiftlocked = CameraModule.activeMouseLockController.isMouseLocked
			local firstPerson = checkFirstPerson and isFirstPerson()

			return shiftlocked or firstPerson
		end,
		IsJumping = function()
			return utility.JumpButton.IsDown()
		end,
	}
	local eventMap = {
		JumpRequest = function()
			return utility.JumpButton.JumpEvent.Event
		end,
	}

	--> Instance to hash to prevent the modules from accessing any instances
	local instanceHashMap = {
		hashed = {} :: { [Instance]: string },
		map = {} :: { [string]: Instance? },
	}
	local generateUID = utility.Functions.generateUID
	local function getHash(instance: Instance): string
		local hash = instanceHashMap.hashed[instance]
		if hash then
			return hash
		end

		local newHash = generateUID()
		instanceHashMap.hashed[instance] = newHash
		instanceHashMap.map[newHash] = instance
		return newHash
	end

	--> Get Property
	local mergeTable = utility.Table.Merge
	local propertyMethods
	propertyMethods = {
		Event = function(self: any, eventName: string)
			local instance = resolveHierarchy(instanceHashMap.map[self.hash], self.hierarchy)
			setmetatable(self, nil)
			if not instance then
				return
			end

			local event, success = utility.Property.getPropertySafe(instance, eventName)
			if not success then
				--> Fallback to GetPropertyChangedSignal if we couldn't get the
				--> signal
				success, event = pcall(function()
					return instance:GetPropertyChangedSignal(eventName)
				end)
			end

			if not success or typeof(event) ~= "RBXScriptSignal" then
				scope:log({
					`Could not find an event named "{eventName}".`,
					`Path: {changer:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				return
			end

			return event
		end,
		Property = function(self: any, property: string)
			local instance = resolveHierarchy(instanceHashMap.map[self.hash], self.hierarchy)
			setmetatable(self, nil)
			if not instance then
				return
			end

			local value, success = utility.Property.getPropertySafe(instance, property)
			if not success then
				--> Fallback to attributes if we couldn't get the property
				value = instance:GetAttribute(property)
			end

			if value == nil or typeof(value) == "RBXScriptSignal" or typeof(value) == "function" then
				scope:log({
					`Could not find any property or attribute named "{property}".`,
					`Path: {changer:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				return
			elseif typeof(value) == "Instance" then
				if not tagCache.filter(value) then
					return
				end
				return setmetatable({ hash = getHash(value) }, propertyMethods)
			end

			return value
		end,
	}
	propertyMethods.__index = propertyMethods
	propertyMethods = mergeTable(propertyMethods, hierarchyMethods)

	local evaluatorMethods = {
		Tagged = function(tag: string)
			local firstTagged = tagCache.getTagged(tag)[1]
			if not firstTagged then
				scope:log({
					`Could not find any tagged objects with the tag "{tag}".`,
					`Path: {changer:GetFullName()}`,
					type = "error",
				})
				return
			end

			return setmetatable({ hash = getHash(firstTagged) }, propertyMethods)
		end,
		Changer = function()
			return setmetatable({ hash = getHash(changer) }, propertyMethods)
		end,
		Instance = function()
			if not selectedInstance then
				return
			end
			return setmetatable({ hash = getHash(selectedInstance) }, propertyMethods)
		end,
		Character = function()
			local character = characterInstances.character
			if not character then
				return
			end
			return setmetatable({ hash = getHash(character) }, propertyMethods)
		end,
		SequenceInstance = function(variable: string)
			if not currentVariables then
				variableNotFound(variable)
				return
			end

			local evaluated = currentVariables[variable]
			if typeof(evaluated) ~= "Instance" then
				variableNotFound(variable)
				return
			end

			return setmetatable({ hash = getHash(evaluated) }, propertyMethods)
		end,
		Value = function(value, ...)
			local value = valueMap[value]
			if typeof(value) == "function" then
				return value(...)
			end

			return value
		end,
		Event = function(value, ...)
			local value = eventMap[value]
			if typeof(value) == "function" then
				return value(...)
			end

			return value
		end,
	}

	--> Property Queuing
	local propertiesToSet = {}
	local function createList(instance: Instance)
		local newList = {
			instance = instance,
			attributes = {} :: { [string]: any },
			properties = {} :: { [string]: any },
			tweens = {} :: { [TweenInfo]: { [string]: any } },
		}
		table.insert(propertiesToSet, newList)
		return newList
	end

	local function addToList(
		list: {},
		type: "tweens" | "attributes" | "properties",
		property: string,
		value: any,
		tweenInfo: TweenInfo?
	)
		local targetTable = list[type]
		if tweenInfo and type == "tweens" then
			-- tween types are grouped by tweeninfos
			if not targetTable[tweenInfo] then
				targetTable[tweenInfo] = {}
			end
			targetTable = targetTable[tweenInfo]
		end
		targetTable[property] = value
	end

	--> Main Functionality
	local cooldown = false
	local function changeProperty(touchingPart: BasePart?, variables: { [string]: any })
		if cooldown then
			currentVariables = nil
			return
		end
		if changerConfiguration.Cooldown > 0 and not changerConfiguration.ConditionalEnabled then
			cooldown = true
			task.delay(changerConfiguration.Cooldown, function()
				cooldown = false
			end)
		end

		currentVariables = variables
		local finalCondition = true
		local longestTweenTime = -1
		for _, chunk in propertyMap do
			local instances = chunk.Instance
			local hierarchy = if typeof(instances) == "table" then instances.hierarchy else nil

			if typeof(instances) == "table" and instances.toucher or instances.changer then
				--> Touching Part or the Changer part itself
				local thisInstance: Instance? = if instances.changer then changer else touchingPart
				instances = { thisInstance }
			elseif typeof(instances) == "table" and typeof(instances.tag) == "string" then
				--> Tagged part
				instances = table.clone(tagCache.getTagged(instances.tag))
			elseif typeof(instances) == "table" and instances.character then
				--> Character
				instances = { characterInstances.character }
			elseif typeof(instances) == "table" and typeof(instances.variable) == "string" then
				--> Sequencer Variable
				local evaluated = variables[instances.variable]
				if typeof(evaluated) == "string" then --> Tag Variable
					instances = tagCache.getTagged(evaluated)
				elseif typeof(evaluated) == "Instance" then --> Instance
					instances = { evaluated }
				else
					variableNotFound(instances.variable)
					instances = nil
				end
			else
				instances = nil
			end

			if hierarchy and typeof(instances) == "table" then
				--> Resolve Hierarchy
				for i = #instances, 1, -1 do
					local instance: Instance? = resolveHierarchy(instances[i], hierarchy)
					if not instance then
						table.remove(instances, i)
					else
						instances[i] = instance
					end
				end
			end

			if typeof(instances) ~= "table" or #instances <= 0 then
				scope:log({
					`No target instance(s) found.`,
					`Path: {changerConfig:GetFullName()}`,
					type = "warn",
				})
				continue
			end

			local blockCondition = true
			if typeof(chunk.BlockCondition) == "function" then
				selectedInstance = nil
				if not chunk.BlockCondition(evaluatorMethods) then
					blockCondition = false
					finalCondition = false
				end
			end

			local conditionFn
			if typeof(chunk.Condition) == "function" then
				conditionFn = chunk.Condition
			end

			local checkRate = 1 / 60
			local conditionalYield = changerConfiguration.ConditionalYield
			local tween = chunk.Tween
			for property, value in chunk do
				local destroyedInstance = false
				if
					property == "Instance"
					or property == "Tween"
					or property == "BlockCondition"
					or not blockCondition
					or destroyedInstance
				then
					continue
				end

				for i, instance: Instance in instances do
					selectedInstance = instance
					if conditionFn then
						local conditionPassed
						-- the below only runs once if ConditionalYield is
						-- disabled
						repeat
							conditionPassed = conditionFn(evaluatorMethods)
							if conditionalYield and not conditionPassed then
								task.wait(checkRate)
							end
						until (not conditionalYield) or conditionPassed

						if not conditionPassed then
							finalCondition = false
							selectedInstance = nil
							continue
						end
					end

					if property == "Condition" then
						--> if this is the condition function itself, skip the
						--> rest of the loop
						selectedInstance = nil
						continue
					end

					local thisValue = if typeof(value) == "function" then value(evaluatorMethods) else value
					selectedInstance = nil

					if property == "Event" and typeof(thisValue) == "RBXScriptSignal" then
						--> Wait for signals and skip the rest of the loop
						thisValue:Wait()
						continue
					end

					if changerConfiguration.ConditionalEnabled then
						--> Skip changing properties conditional mode is enabled
						continue
					end

					local currentValue, isProperty = utility.Property.getPropertySafe(instance, property)
					local currentType = typeof(currentValue)
					local thisType = typeof(thisValue)
					if typeof(thisValue) == "table" and thisValue.hash then
						--> If we have an instance hash, get the actual instance
						--> from the hash
						thisValue = resolveHierarchy(instanceHashMap.map[thisValue.hash], thisValue.hierarchy)
						thisType = typeof(thisValue)
					end

					if currentType == "Instance" and thisType == "nil" then
						if property == "Parent" then
							-- instead of setting the parent to nil just destroy
							-- we don't want the instance lingering in memory
							-- and there wouldve been no way to access it if it
							-- was in nil either way
							instance:Destroy()
							destroyedInstance = true
							continue
						end

						-- Instances can be set to nil so just force the type
						-- check to be true
						thisType = "Instance"
					end

					local thisList = createList(instance)
					if isProperty and thisType ~= currentType then
						scope:log({
							`Property Type Check failed (setting '{property}' expects '{currentType}', got '{thisType}')`,
							`Path: {changerConfig:GetFullName()}`,
							type = "warn",
						})
					elseif isProperty and thisType == currentType then
						if typeof(tween) == "TweenInfo" and tween.Time > 0 and TWEENABLE_TYPES[thisType] then
							addToList(thisList, "tweens", property, thisValue, tween)
							if tween.Time > longestTweenTime then
								longestTweenTime = tween.Time
							end
						else
							addToList(thisList, "properties", property, thisValue)
						end
					else
						-- TODO: attribute tweening?? (probably expensive)
						addToList(thisList, "attributes", property, thisValue)
					end
				end
			end
		end

		--> Clear variables & hash
		selectedInstance = nil
		currentVariables = nil
		table.clear(instanceHashMap.map)
		table.clear(instanceHashMap.hashed)

		if changerConfiguration.ConditionalEnabled then
			--> Sequencer Property Checker Conditionals
			--> Also skips setting any properties if this is enabled
			local code = if changerConfiguration.ConditionalBreakSequence then "BREAK_LOOP" else "STOP_SEQUENCE"
			return if finalCondition then true else code
		end

		--> Set Values
		local throttleCount = changerConfiguration.Throttle
		local totalSet = 0
		for _, data in propertiesToSet do
			local instance = data.instance
			for property, value in data.attributes do
				instance:SetAttribute(property, value)
			end
			for property, value in data.properties do
				utility.Property.setPropertySafe(instance, property, value)
			end
			for info, goal in data.tweens do
				utility.Functions.tween(instance, info.Time, goal, info.EasingStyle, info.EasingDirection)
			end

			--> Throttle
			totalSet += 1
			if totalSet % throttleCount == 0 then
				task.wait()
			end
		end
		table.clear(propertiesToSet)

		if longestTweenTime > 0 then
			task.wait(longestTweenTime)
		end
	end

	--> Activation
	local touchConfiguration =
		Config.GetConfig(scope, changerConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	scope:attach(changer)
	scope:add(changer.Touched:Connect(function(toucher)
		if
			cooldown
			or changer:GetAttribute("Activated") == false
			or (not utility.ClientObjects.evaluateToucher(changer, toucher, touchConfiguration))
		then
			return
		end

		changeProperty(toucher, {})
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(changer, function(rootPart)
			if cooldown or changer:GetAttribute("Activated") == false then
				return
			end
			changeProperty(rootPart, {})
		end))
	end

	--> Sequencer cache support
	tagCache.changers[changer] = {
		forceAwait = changerConfiguration.ConditionalEnabled,
		change = changeProperty,
	}
	scope:add(function()
		tagCache.changers[changer] = nil
		tagCache = nil :: any
	end)
end

return PropertyChanger
