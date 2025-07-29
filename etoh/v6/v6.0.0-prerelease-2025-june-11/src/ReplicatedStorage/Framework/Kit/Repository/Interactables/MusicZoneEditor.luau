--!strict
--!optimize 2
--@version musiczoneeditor-6.0.0
--@creator Camille

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

type PropertyTable = { [string]: any } | "Default"

type ZoneConfiguration = {
	ZonePriority: number,
	SoundConfiguration: PropertyTable,
	EffectConfiguration: { [string]: PropertyTable },
	ExtraConfiguration: {[string]: any},
}

local DEFAULTS_SET_KEY = "_DEFAULTS_SET"
local DEFAULTS_TEMPLATE = "_DEFAULT_"
local DEFAULTS_TEMPLATE_LENGTH = string.len(DEFAULTS_TEMPLATE)

return function(scope: _T.Scope)
    local musicManager = require(ReplicatedStorage:WaitForChild("Background Music").MusicSystemManager)
    
	--> Setup
	local utility = scope:utility()
	local musicZoneEditorConfig = scope.instance
	if not musicZoneEditorConfig then
		return
	end

	local musicZoneEditor = musicZoneEditorConfig.Parent
	if not musicZoneEditor or not musicZoneEditor:IsA("BasePart") then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, musicZoneEditorConfig, {
		ZoneName = "",
		OneTimeUse = false,
		Cooldown = 1,
	}):ObserveChanges()

	local touchConfiguration =
		Config.GetConfig(scope, musicZoneEditorConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, musicZoneEditorConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()

	scope:attach(musicZoneEditor)

	--> Get music zone data, configuration module, and check for problems
	local musicZonesContainer = ReplicatedStorage:WaitForChild("Background Music"):WaitForChild("BackgroundMusicZones")
	local musicZone = musicZonesContainer:FindFirstChild(configuration.ZoneName, true)

	if not musicZone then
		scope:log({
			`MusicZoneEditor was unable to find a music zone called "{configuration.ZoneName}" and cannot function.`,
			`Path: {musicZoneEditor:GetFullName()}`,
			type = "warn",
		})
		return
	end
	
	local musicZonePriorityIsAttribute = false
	local musicZonePriorityValue = musicZone:FindFirstChild("Priority")
	if not musicZonePriorityValue or not musicZonePriorityValue:IsA("IntValue") then
		musicZonePriorityIsAttribute = true
		return
	end

	local musicZoneMusicFolder = musicZone:FindFirstChild("Music")
	if not musicZoneMusicFolder then
		scope:log({
			`Music zone {musicZone.Name} does not have a Music folder.`,
			`Path: {musicZone:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local musicZoneSoundObjects = {}
	local musicZoneSoundEffectObjects = {}
	for _, object in musicZoneMusicFolder:GetDescendants() do
		if object:IsA("Sound") then
			table.insert(musicZoneSoundObjects, object)
		elseif object:IsA("SoundEffect") then
			musicZoneSoundEffectObjects[object.Name] = object
		end
	end

	if #musicZoneSoundObjects <= 0 then
		scope:log({
			`Music zone {musicZone.Name} has no songs inside of it.`,
			`Path: {musicZone:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local zoneConfigPointer = utility.Instance.getPointer(musicZoneEditorConfig:FindFirstChild("ZoneConfiguration"))
	if not zoneConfigPointer or not zoneConfigPointer:IsA("ModuleScript") then
		scope:log({
			`MusicZoneEditor is missing it's "ZoneConfiguraton" module and cannot function.`,
			`Path: {musicZoneEditorConfig:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local zoneConfigData = require(zoneConfigPointer) :: ZoneConfiguration
	if typeof(zoneConfigData) ~= "table" then
		scope:log({
			`MusicZoneEditor's ZoneConfiguration is formatted incorrectly (expected a table, but received a {typeof(
				zoneConfigData
			)})`,
			`Path: {zoneConfigPointer:GetFullName()}`,
			type = "warn",
		})
	end

	--> Functions
	local function getDefaultProperties(object: Instance)
		local properties = {}
		local attributes = object:GetAttributes()

		for attributeName, attributeValue in attributes do
			if attributeName:sub(1, DEFAULTS_TEMPLATE_LENGTH) == DEFAULTS_TEMPLATE then
				local propertyName = attributeName:sub(DEFAULTS_TEMPLATE_LENGTH + 1)
				properties[propertyName] = attributeValue
			end
		end

		return properties
	end

	local function tweenProperties(object: Instance, properties: PropertyTable)
		if properties == "Default" then
			local defaultProperties = getDefaultProperties(object)
			utility.Functions.tween(object, tweenConfiguration, defaultProperties)
			return
		end
		
		-- set defaults
		if not object:HasTag(DEFAULTS_SET_KEY) then
			object:AddTag(DEFAULTS_SET_KEY)

			for property, _ in properties do
				if object:IsA("Sound") and property == "Volume" then
					object:SetAttribute(`{DEFAULTS_TEMPLATE}{property}`, object:GetAttribute("OriginalVolume"))
				else
					local value = utility.Property.getPropertySafe(object, property)
					object:SetAttribute(`{DEFAULTS_TEMPLATE}{property}`, value)
				end
			end
		end

		-- tween properties
		utility.Functions.tween(object, tweenConfiguration, properties)
	end

	local function resetProperties(object: Instance)
		local attributes = object:GetAttributes()

		for attributeName, attributeValue in attributes do
			if attributeName:sub(1, DEFAULTS_TEMPLATE_LENGTH) == DEFAULTS_TEMPLATE then
				local propertyName = attributeName:sub(DEFAULTS_TEMPLATE_LENGTH + 1)
				utility.Property.setPropertySafe(object, propertyName, attributeValue)
			end
		end
	end

	local function editMusicZone()
		local currentSong = musicManager.CurrentSong
		
		-- set priority
		if zoneConfigData.ZonePriority then
			if musicZonePriorityIsAttribute then
				musicZone:SetAttribute("Priority", zoneConfigData.ZonePriority)
			else
				musicZonePriorityValue.Value = zoneConfigData.ZonePriority
			end
		end
		
		-- do extra stuff (this is first due to properties changing)
		if zoneConfigData.ExtraConfiguration then
			local keepTimePosition = zoneConfigData.ExtraConfiguration.KeepTimePosition
			if keepTimePosition and keepTimePosition.Enabled and currentSong then
				for _, sound in musicZoneSoundObjects do
					sound.TimePosition = currentSong.song.TimePosition + keepTimePosition.Offset
				end
			end
		end

		-- set sound properties
		if zoneConfigData.SoundConfiguration then
			for _, sound in musicZoneSoundObjects do
				tweenProperties(sound, zoneConfigData.SoundConfiguration)
			end
		end

		-- set effect properties
		if zoneConfigData.EffectConfiguration then
			for effectName, effect in musicZoneSoundEffectObjects do
				local effectConfig = zoneConfigData.EffectConfiguration[effectName]
				if effectConfig then
					-- cast is used due to roblox not recognising the type correctly
					-- when functionality for Default is added
					tweenProperties(effect, effectConfig :: PropertyTable)
				end
			end
		end
	end

	--> Functionality

	-- reset properties previously changed
	for _, sound in musicZoneSoundObjects do
		resetProperties(sound)
	end
	for _, soundEffect in musicZoneSoundEffectObjects do
		resetProperties(soundEffect)
	end

	-- variables
	local cooldownActive = false
	local oneTimeUseActivated = false

	-- touch functionality
	scope:add(musicZoneEditor.Touched:Connect(function(toucher)
		if not utility.ClientObjects.evaluateToucher(musicZoneEditor, toucher, touchConfiguration) then
			return
		end
		if musicZoneEditor:GetAttribute("Activated") == false then
			return
		end

		-- handle cooldown
		if configuration.Cooldown > 0 then
			if cooldownActive then
				return
			end
			cooldownActive = true
			task.delay(configuration.Cooldown, function()
				cooldownActive = false
			end)
		end

		-- handle one time use
		if configuration.OneTimeUse then
			if oneTimeUseActivated then
				return
			end
			oneTimeUseActivated = true
		end

		editMusicZone()
	end))
end
