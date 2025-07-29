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
		It does so by first checking if the `Instance` is a `BasePart`, 
		then checking if the platform's name is ButtonActivatedPlatform or 
		has the ButtonActivated tag. 
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
		It does so by checking if the `Instance` is named "BalloonModel",
		performing the same check on the `Instance`'s Parent if
		`doNotCheckAncestor` is used.
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
		It does so by checking if the `Instance` is named "Turret",
		performing the same check on the `Instance`'s Parent if
		`doNotCheckAncestor` is used.
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
		It does so by checking if either:
		* the `Instance` is named "Pushbox", performing the same check
		on the `Instance`'s Parent if `doNotCheckAncestor` is used
		* the `Instance` has a tag called `IsBox`
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
	
	A touch configuration has the following settings:
	* `player`: Valid if `toucher` is part of the player's character
	* `pushbox`: Valid if `ClientObjects.isPushbox` returns `true`
	* `balloon`: Valid if `ClientObjects.isBalloon` returns `true`
	* `turret`: Valid if `ClientObjects.isTurret` returns `true`
	* `colorSpecific`: For every setting except `player`, `toucher`'s color
	must match `part`'s color for the collision to be considered valid.
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
	
	This function will bind the given `callback` to the given `part`,
	triggering the callback when the player performs a corner flip on the `part`.
]=]
function ClientObjects.bindToFlip(part: BasePart, callback: () -> ()): () -> ()
	return FlipManager:BindToFlip(part, callback)
end

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
