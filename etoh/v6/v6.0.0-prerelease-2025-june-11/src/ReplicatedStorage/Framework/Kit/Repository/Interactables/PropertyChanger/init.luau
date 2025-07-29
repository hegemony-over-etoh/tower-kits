--!strict
--!optimize 2
--@version propertychanger-6.0.0
--@creator synnwave

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local _TDefs = require(script.TypeDefs)
local SequencerSupport = require(script.SequencerSupport)

local PropertyChanger = {
	CanQueue = true,
	RunOnStart = false,
}

local function handleCache(rootScope: _T.Scope): _TDefs.Cache
	local cache = { tagged = {}, changers = {} }
	local utility = rootScope:utility()
	local shared = rootScope.shared
	local clientObjects = rootScope.clientObjects
	local guiLocation
	local function tagFilter(instance: Instance)
		if instance:IsDescendantOf(rootScope.clientObjects) then
			return true
		end
		if not guiLocation then
			guiLocation = shared.clientObject_guis :: Instance
		end
		if guiLocation and instance:IsDescendantOf(guiLocation) then
			return true
		end

		return false
	end

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

	SequencerSupport(rootScope, cache)
	return cache
end

function PropertyChanger.Run(scope: _T.Scope)
	local changerConfig = scope.instance
	if not changerConfig or not changerConfig.Parent then
		return
	end

	local utility = scope:utility()
	local Config = utility.Config
	local propertyPointer = utility.Instance.getPointer(changerConfig:FindFirstChild("Properties"))
	if not propertyPointer or not propertyPointer:IsA("ModuleScript") then
		scope:log({
			"Property Changer is missing it's 'Properties' module.",
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

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

	local propertyFunction = require(propertyPointer) :: any
	if typeof(propertyFunction) ~= "function" then
		scope:log({
			`Property Changer's property module returned "{typeof(propertyFunction)}", expected function`,
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
	end

	local tagCache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	local function getPropertyFromTag(tag, property)
		local firstTagged = tagCache.getTagged(tag)[1]
		if not firstTagged then
			scope:log({
				`Could not find any tagged objects with the tag "{tag}".`,
				type = "warn",
			})
			return
		end

		local value, success = utility.Property.getPropertySafe(firstTagged, property)
		if not success then
			scope:log({
				`Could not find the property "{property}" in any tagged objects with the tag "{tag}".`,
				traceback = 3,
				type = "warn",
			})
		end

		return value
	end

local function getInstanceProperty()
    
end

	local function getPropertyFromChanger(property)
		local value, success = utility.Property.getPropertySafe(changer, property)
		if not success then
			scope:log({
				`Could not find the property "{property}" in the Changer part itself.`,
				type = "warn",
			})
		end

		return value
	end

	local localPlayer = Players.LocalPlayer
	local valueMap = {
		PlayerName = localPlayer.Name,
		PlayerDisplayName = localPlayer.DisplayName,
		UserId = localPlayer.UserId,
		CharacterPosition = function()
			return localPlayer.Character:GetPivot().Position
		end,
		CharacterCFrame = function()
			return localPlayer.Character:GetPivot().CFrame
		end,
		Distance = function(position)
			return localPlayer:DistanceFromCharacter(position)
		end,
		PlayerHealth = function()
			local health = 0
			local humanoid = localPlayer.Character:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				health = humanoid.Health
			end

			return health
		end,
	}

	local function getValue(value, ...)
		local value = valueMap[value]
		if typeof(value) == "function" then
			return value(...)
		end

		return value
	end

	local function changeProperty(touchingPart: BasePart?, variables: { [string]: any })
		local evaluator = {
			Toucher = function()
				return { touchingPart }
			end,
			Tagged = function(tag)
				return tagCache.getTagged(tag)
			end,
			GetValue = getValue,
			GetPropertyFromTag = getPropertyFromTag,
			GetPropertyFromChanger = getPropertyFromChanger,
			GetSequenceVariable = function(variable)
				local variable = variables[variable]
				if variable == nil then
					scope:log({
						`Could not find the sequencer variable "{variable}".`,
						type = "warn",
					})
				end

				return variable
			end,
		}

		local evaluatedProperties = propertyFunction(evaluator)
		evaluator = nil :: any
		for _, chunk in evaluatedProperties do
			local instances = chunk.Instance
			if typeof(instances) ~= "table" or #instances <= 0 then
				scope:log({
					`No target instance(s) found.`,
					`Path: {changerConfig:GetFullName()}`,
					type = "warn",
				})
				continue
			end

			for property, value in chunk do
				if property == "Instance" or typeof(value) == "table" or typeof(value) == "userdata" then
					continue
				end

				for _, instance: Instance in instances do
					local _, isProperty = utility.Property.getPropertySafe(instance, property)
					if isProperty then
						utility.Property.setPropertySafe(instance, property, value)
					else
						instance:SetAttribute(property, value)
					end
				end
			end
		end
	end

	local touchConfiguration =
		Config.GetConfig(scope, changerConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	scope:attach(changer)
	scope:add(changer.Touched:Connect(function(toucher)
		if
			changer:GetAttribute("Activated") == false
			or (not utility.ClientObjects.evaluateToucher(changer, toucher, touchConfiguration))
		then
			return
		end
		changeProperty(toucher, {})
	end))

	tagCache.changers[changer] = changeProperty
	scope:add(function()
		tagCache.changers[changer] = nil
	end)
end

return PropertyChanger
