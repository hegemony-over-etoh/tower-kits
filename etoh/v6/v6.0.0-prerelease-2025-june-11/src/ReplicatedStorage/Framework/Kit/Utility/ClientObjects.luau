--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[=[
@class ClientObjects
@client
A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.

]=]
local ClientObjects = {}

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers

local Config = require(script.Parent.Config)
local Functions = require(script.Parent.Functions)
local Character = require(script.Parent.Character)
local localPlayer = Players.LocalPlayer

local ScopeUtil = require(script.Parent.InternalScopeUtil)
type Scope = ScopeUtil.Scope

--[=[
	@within ClientObjects
	@tag shorthand

	This function is used to check if the provided `Instance`
	is a ButtonActivatedPlatform.
	
	This will return `true` if it is a `BasePart` and meets
	one of the following requirements:
		
	* Is named `ButtonActivatedPlatform`
	* Has a tag named `ButtonActivated`
]=]
function ClientObjects.isButtonActivatedPlatform(platform: Instance): boolean
	if typeof(platform) ~= "Instance" then
		return false
	end
	return platform:IsA("BasePart")
		and (platform.Name == "ButtonActivatedPlatform" or platform:HasTag("ButtonActivated"))
end

--[=[
	@within ClientObjects
	@tag shorthand

	This function is used to check if the provided `Instance` 
	is part of a dispensed Balloon.
	
	This will return `true` if it meets one of the following requirements:
		
	* Is named `BalloonModel`
	* If `doNotCheckAncestor` is not `true` and the `Instance` has an ancestor
	named `BalloonModel`
]=]
function ClientObjects.isBalloon(parent: Instance, doNotCheckAncestor: boolean?): boolean
	if typeof(parent) ~= "Instance" then
		return false
	end
	return parent.Name == "BalloonModel"
		or ((not doNotCheckAncestor) and parent:FindFirstAncestor("BalloonModel") ~= nil)
end

--[=[
	@within ClientObjects
	@tag shorthand

	This function is used to check if the provided `Instance` 
	is part of a Turret's bullet.
	
	This will return `true` if it meets one of the following requirements:
	
	* Is named `Bullet`
	* If `doNotCheckAncestor` is not `true` and the `Instance` has an ancestor
	named `Bullet`
		
]=]
function ClientObjects.isTurret(parent: Instance, doNotCheckAncestor: boolean?): boolean
	if typeof(parent) ~= "Instance" then
		return false
	end
	return parent.Name == "Bullet" or ((not doNotCheckAncestor) and parent:FindFirstAncestor("Bullet") ~= nil)
end

--[=[
	@within ClientObjects
	@tag shorthand

	This function is used to check if the provided `Instance` 
	is part of a Pushbox.
	This will return `true` if it meets one of the following requirements:
	
	* Is named `Pushbox`
	* Has a tag named `IsBox`
	* If `doNotCheckAncestor` is not `true` and the `Instance` has an ancestor
	named `Pushbox`
]=]
function ClientObjects.isPushbox(parent: Instance, doNotCheckAncestor: boolean?): boolean
	if typeof(parent) ~= "Instance" then
		return false
	end
	return (parent.Name == "Pushbox")
		or ((not doNotCheckAncestor) and parent:FindFirstAncestor("Pushbox") ~= nil)
		or parent:HasTag("IsBox")
end

--[=[
	@within ClientObjects
	
	This function checks if two `BasePart`s (`part` and `toucher`) touching
	is considered valid or not, based on the provided `config`.
	
	See [this page](/docs/global-configurations/touch-configurations) for more info.
]=]
function ClientObjects.evaluateToucher(
	part: BasePart,
	toucher: BasePart,
	config: (Instance | typeof(Config.TOUCH_CONFIG))?
): boolean
	if not ((toucher and toucher:IsA("BasePart")) and toucher.Parent) then
		return false
	end
	if not (part and part:IsA("BasePart")) then
		return false
	end

	local checks: typeof(Config.TOUCH_CONFIG)
	if typeof(config) == "Instance" then
		checks = Config.GetConfig(nil, config:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
	else
		checks = config or Config.TOUCH_CONFIG
	end

	local ancestor: Instance? = toucher.Parent.Parent
	local humanoid: Humanoid? = toucher.Parent:FindFirstChildWhichIsA("Humanoid")
		or (ancestor and ancestor:FindFirstChildWhichIsA("Humanoid"))
	local playerTouched = Players:GetPlayerFromCharacter(humanoid and humanoid.Parent) == localPlayer

	local configuration = if typeof(config) == "Instance" then config else part
	local colorSpecificColor = if typeof(checks.colorSpecific) == "Color3"
		then checks.colorSpecific
		else Functions.roundColor(part.Color)
	local isColorSpecific = not (checks.colorSpecific and (Functions.roundColor(toucher.Color) ~= colorSpecificColor))

	return (if checks.player then playerTouched else false)
		or (if checks.pushbox then ClientObjects.isPushbox(toucher) and isColorSpecific else false)
		or (if checks.balloon then ClientObjects.isBalloon(toucher) and isColorSpecific else false)
		or (if checks.turret then ClientObjects.isTurret(toucher) and isColorSpecific else false)
end

local FlipManager = require(Managers.FlipManager)

--[=[
	@within ClientObjects
	
	Binds the `callback` function to the `part`, executing the callback when
	the player performs a corner flip on it.
]=]
function ClientObjects.bindToFlip(part: BasePart, callback: () -> ()): () -> ()
	return FlipManager:BindToFlip(part, callback)
end

--[=[
	@within ClientObjects
	
	Function to format timer labels in a standardized manner, used in Buttons and Morphers.
	Below are special codes that are replaced within the string automatically.
	
	|  Code  | Replaced with: |
	|--------|---------------------------|
	| `{T}` | The time left on the timer, modified with `TimerDecimalPlaces` |
	| `{M}` | The minutes left on the timer |
	| `{S}` | The seconds left on the timer |
	| `{MS}` | The milliseconds left on the timer |
	| `{SM}` | Used for grammatical reasons. When the amount of minutes left is equal to one, this will display the letter "s", otherwise this will display nothing. e.g. "minute{SM}" will either display "minutes" or "minute". |
	| `{SS}` | Used for grammatical reasons. When the amount of seconds left is equal to one, this will display the letter "s", otherwise this will display nothing. e.g. "second{SM}" will either display "seconds" or "second". |
	| `{Pn}` | The player's username |
	| `{pn}` | The username in all lowercase |
	| `{PN}` | The username in all UPPERCASE |
	| `{Dn}` | The player's Display Name |
	| `{dn}` | The Display Name in all lowercase |
	| `{DN}` | The Display Name in all UPPERCASE |
	| `{UID}` | The player's User ID |
]=]
function ClientObjects.formatTimerText(configuration: { [string]: any }, timeRemaining: number): string
	local decimalPlaces = math.floor(configuration.TimerDecimalPlaces)
	local displayTime = if decimalPlaces == 0
		then tostring(math.ceil(timeRemaining)) -- off by 0.5s otherwise
		else string.format(`%.{decimalPlaces}f`, timeRemaining)

	local flooredSeconds = timeRemaining // 1
	local minutes = flooredSeconds // 60
	local seconds = flooredSeconds % 60
	local milliseconds = math.floor(timeRemaining * 100) % 100
	return configuration.TimerText
		:gsub("{T}", displayTime)
		:gsub("{M}", tostring(minutes))
		:gsub("{SM}", if tostring(minutes) == "1" then "" else "s")
		:gsub("{S}", string.format("%02i", seconds))
		:gsub("{MS}", string.format("%02i", milliseconds))
		:gsub("{SS}", if displayTime == "1" then "" else "s")
		:gsub("{pn}", localPlayer.Name:lower())
		:gsub("{Pn}", localPlayer.Name)
		:gsub("{PN}", localPlayer.Name:upper())
		:gsub("{dn}", localPlayer.DisplayName:lower())
		:gsub("{Dn}", localPlayer.DisplayName)
		:gsub("{DN}", localPlayer.DisplayName:upper())
		:gsub("{UID}", localPlayer.UserId)
end

--[=[
	@within ClientObjects
	
	Returns whether the provided `Instance` is active or not.
]=]
function ClientObjects.isInstanceActive(scope: Scope, instance: Instance, ignoreList: { [string]: boolean }?): boolean
	ScopeUtil.assertScope(scope, "ClientObjects.isInstanceActive()")

	local activeData = scope.shared.activeInstances
	if not activeData then
		return true
	end
	if activeData[instance] then
		for key, active in activeData[instance] do
			if ignoreList and ignoreList[key] then
				continue
			end
			if not active then
				return false
			end
		end
	end

	return true
end

local function getActiveData(scope: Scope)
	local activeData = scope.shared.activeInstances
	if not activeData then
		activeData = { __bindable = scope:getCommunicator("event", "activeInstancesChanged") }
		scope.shared.activeInstances = activeData
	end

	return activeData
end

--[=[
	@within ClientObjects
	
	Listens to the `Instance`'s activeness, executing the `callback` when
	it's activeness changes.
]=]
function ClientObjects.listenInstanceActive(
	scope: Scope,
	instance: Instance,
	ignoreList: { [string]: boolean }?,
	callback: (active: boolean) -> ()
): () -> ()
	ScopeUtil.assertScope(scope, "ClientObjects.listenInstanceActive()")

	local activeData = getActiveData(scope)
	return scope:add(activeData.__bindable:listen(function(changedInstance)
		if instance == changedInstance then
			callback(ClientObjects.isInstanceActive(scope, instance, ignoreList))
		end
	end))
end

--[=[
	@within ClientObjects
	
	Sets the `Instance`'s activeness based on `active`.
	Instances can have multiple activeness states, dictated by the `key` parameter.
]=]
function ClientObjects.setInstanceActive(scope: Scope, instance: Instance, key: string, active: boolean)
	ScopeUtil.assertScope(scope, "ClientObjects.setInstanceActive()")

	local activeData = getActiveData(scope)
	local thisInstanceData = activeData[instance]
	if not thisInstanceData then
		thisInstanceData = {}
		activeData[instance] = thisInstanceData
	end

	if thisInstanceData[key] ~= active then
		activeData[instance][key] = active
		instance:SetAttribute("Activated", ClientObjects.isInstanceActive(scope, instance))
		activeData.__bindable:fire(instance)
	end
end

--[=[
	@within ClientObjects
	
	Scans the given folder and loads any client objects within into the given scope.
	Used for client objects that can spawn other client objects, such as Pushboxes.
]=]
function ClientObjects.scanFolder(
	targetScope: Scope,
	path: Instance,
	doNotIgnoreObjects: boolean?,
	targetPath: Instance?
)
	ScopeUtil.assertScope(targetScope, "ClientObjects.scanFolder()")
	--TODO: maybe access this function in a different way
	targetScope.rootScope.data.scanFolder(targetScope, path, doNotIgnoreObjects, targetPath)
end

return table.freeze(ClientObjects)
