--!strict
-- junekept 2025
-- this script was originally made for OToH

--[==[
	This module contains all the logic and storage for the player's character.
]==]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries

local LemonSignal = require(Libraries.LemonSignal)
local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

local Config = require(script.Parent.Config)
local General = require(script.Parent.General)
local Interface = require(script.Parent.Interface)

local Character = {}

local localPlayer = Players.LocalPlayer
local currentCharacter: Types.Character = localPlayer.Character

local mainGui = localPlayer.PlayerGui.MainTowerGui
local playerInfoFrame = mainGui.PlayerInformation
local speedLabel = playerInfoFrame.SpeedStatus.Value
local speedTimerLabel = playerInfoFrame.SpeedStatus.Time
local jumpLabel = playerInfoFrame.JumpStatus.Value
local jumpTimerLabel = playerInfoFrame.JumpStatus.Time
local healthBar = playerInfoFrame.HealthBar.ChangingBar
local healthLabel = playerInfoFrame.HealthLabel


--[[ 
	WalkSpeed and JumpPower work on a "priority" system where the highest priority is what sets the *humanoid* value.
	unless modified, the priorities should correlate as follows (based on index):
		1 = default
		2 = gears/coils
		3 = speed/jump changers
		4 = speed/jump boost pads
	boost pads have their own seperate priority value, if you're attempting to change that look in their attributes instead of here lolz
]]
local UNIQUE_PRIORITY_COUNT = 4

local jumpPowerActivePriority = 1
local jumpPowers = {
	50
}

local walkSpeedActivePriority = 1
local walkSpeeds = {
	16
}

-- nil means there is no active timer
local boostTimers: {walkSpeed: {number?}, jumpPower: {number?}} = {
	walkSpeed = {},
	jumpPower = {}
}

local function getHighestPriorityFromTable(tbl: {any}, uniquePriorityCount: number): number
	local highest = 0
	for i = 1, uniquePriorityCount do
		if tbl[i] then
			highest = i
		end
	end
	return highest
end

local function updateWalkSpeed()
	local newPriority = getHighestPriorityFromTable(walkSpeeds, UNIQUE_PRIORITY_COUNT)
	walkSpeedActivePriority = newPriority
	currentCharacter.Humanoid.WalkSpeed = walkSpeeds[newPriority]
	speedLabel.Text = walkSpeeds[newPriority]
end

local function updateJumpPower()
	local newPriority = getHighestPriorityFromTable(jumpPowers, UNIQUE_PRIORITY_COUNT)
	jumpPowerActivePriority = newPriority
	currentCharacter.Humanoid.JumpPower = jumpPowers[newPriority]
	jumpLabel.Text = jumpPowers[newPriority]
end

function Character.setWalkSpeedAtPriority(speed: number, priority: number, duration: number?)
	walkSpeeds[priority] = speed
	boostTimers.walkSpeed[priority] = duration
	updateWalkSpeed()
end

function Character.removeWalkSpeedAtPriority(priority: number)
	walkSpeeds[priority] = nil
	boostTimers.walkSpeed[priority] = nil
	updateWalkSpeed()
end

function Character.setJumpPowerAtPriority(power: number, priority: number, duration: number?)
	jumpPowers[priority] = power
	boostTimers.jumpPower[priority] = duration
	updateJumpPower()
end

function Character.removeJumpPowerAtPriority(priority: number)
	jumpPowers[priority] = nil
	boostTimers.jumpPower[priority] = nil
	updateJumpPower()
end

local activeConstraintObject: Types.ClientObject? = nil
function Character.mountConstraintObject(object: Types.ClientObject)
	Character.dismountConstraintObject()
	activeConstraintObject = object
end

function Character.dismountConstraintObject(noJump: boolean?)
	if activeConstraintObject and activeConstraintObject.signals.dismount then
		activeConstraintObject.signals.dismount:Fire(noJump)
	end
	
	activeConstraintObject = nil
end

function Character.getDismountScript(): string?
	if activeConstraintObject then
		return activeConstraintObject.instance:GetAttribute("_Script")
	else
		return nil
	end
end

type KeyNode = Types.DoubleLinkedListNode<Types.Key>

local firstKeyNode = nil :: KeyNode?
local lastKeyNode = nil :: KeyNode?
local keyNodeCount = 0

function Character.getFirstKeyNode(): KeyNode?
	return firstKeyNode 
end

function Character.getLastKeyNode(): KeyNode?
	return lastKeyNode
end

function Character.getNodeCount(): number
	return keyNodeCount
end

local function shouldKeyBeRendered(node: KeyNode): boolean
	if keyNodeCount > Config.keyRenderLimit then
		local subsequentNodes = 0
		while node.next do
			subsequentNodes += 1
			node = node.next
		end

		local unrenderedKeyNodePosition = keyNodeCount - subsequentNodes - 5
		
		return unrenderedKeyNodePosition <= 0 
	else
		return true
	end
end

function Character.addKeyToNodeList(key: Types.Key, previousNode: KeyNode?, nextNode: KeyNode?)
	local node = {
		last = previousNode,
		next = nextNode,
		value = key
	}
	
	if previousNode then
		previousNode.next = node
	else
		firstKeyNode = node
	end
	
	if nextNode then
		nextNode.last = node
	else
		lastKeyNode = node
	end
	
	keyNodeCount += 1
	
	if not shouldKeyBeRendered(node) then
		Interface.addKey(node.value)
	end
end

function Character.removeKeyFromNodeList(keyNode: KeyNode)
	local keyToRemoveFromInterface = keyNode
	while shouldKeyBeRendered(keyToRemoveFromInterface) and keyToRemoveFromInterface.next do
		keyToRemoveFromInterface = keyToRemoveFromInterface.next
	end
	
	if not shouldKeyBeRendered(keyToRemoveFromInterface) then
		Interface.removeKey(keyToRemoveFromInterface.value)
	end
	
	if keyNode.next then
		keyNode.next.last = keyNode.last
	else
		lastKeyNode = keyNode.last
	end

	if keyNode.last then
		keyNode.last.next = keyNode.next
	else
		firstKeyNode = keyNode.next
	end
	
	keyNodeCount -= 1
end

function Character.isAttachedToConstraint(): boolean
	return activeConstraintObject ~= nil
end

function Character.getHitbox(hitbox: "RootPart" | "WholeBody" | "Legs"): {BasePart}
	if hitbox == "RootPart" then
		return {currentCharacter.HumanoidRootPart}
	elseif hitbox == "Legs" then
		return {currentCharacter["Left Leg"], currentCharacter["Right Leg"]}
	elseif hitbox == "WholeBody" then
		local filter = {}
		for _, part in currentCharacter:GetChildren() do
			if part:IsA("BasePart") then
				table.insert(filter, part)
			end
		end

		return filter
	end

	return {}
end

-- Checks if the given part is a limb of the current character.
function Character.isLimb(part: BasePart): boolean
	-- equivalence checks do not error under any circumstance afaik
	-- even then, `nil` is a valid parent so idk why Instance? is not considered fine already
	return part.Parent == (currentCharacter :: any) and currentCharacter.Humanoid:GetLimb(part) ~= Enum.Limb.Unknown
end

-- Loops or active routines go below here --
local BOOST_TIMER_TWEEN_OFFSET = 0.2
local BOOST_TIMER_TWEEN_TIME = 0.5

local function easeOutQuart(a: number): number
	return 1 - (1 - a)^4
end

local function easeInQuart(a: number): number
	return a^4
end

local function getOffsetAtTime(a: number, easeOut: boolean)
	local func: (number) -> number = if easeOut then easeOutQuart else easeInQuart
	return func(a / BOOST_TIMER_TWEEN_TIME) * BOOST_TIMER_TWEEN_OFFSET
end

local speedLabelTweenProgress = 0
local originalSpeedLabelOffset = speedLabel.Position
local originalSpeedTimerLabelOffset = speedTimerLabel.Position

local jumpLabelTweenProgress = 0
local originalJumpLabelOffset = jumpLabel.Position
local originalJumpTimerLabelOffset = jumpTimerLabel.Position
RunService.PreRender:Connect(function(deltaTimeRender: number) 
	for _, boostTimer in boostTimers :: {[string]: {number}} do
		for i = 1, UNIQUE_PRIORITY_COUNT do
			if boostTimer[i] ~= nil then
				boostTimer[i] -= deltaTimeRender
			end
		end
	end
	
	local showSpeedBoostTimer = false
	local highestPrioritySpeedTimer = 0
	for priority, speedBoost in boostTimers.walkSpeed do
		if speedBoost and speedBoost <= 0 then
			Character.removeWalkSpeedAtPriority(priority)
		else
			showSpeedBoostTimer = true
			highestPrioritySpeedTimer = priority
		end
	end
	
	local showJumpBoostTimer = false
	local highestPriorityJumpTimer = 0
	for priority, jumpBoost in boostTimers.jumpPower do
		if jumpBoost and jumpBoost <= 0 then
			Character.removeJumpPowerAtPriority(priority)
		else
			showJumpBoostTimer = true
			highestPriorityJumpTimer = priority
		end
	end
	
	speedTimerLabel.Visible = showSpeedBoostTimer
	jumpTimerLabel.Visible = showJumpBoostTimer
	
	local speedTweenThisFrame = 0
	if showSpeedBoostTimer then
		speedTimerLabel.Text = General.beautifyTimerCount(boostTimers.walkSpeed[highestPrioritySpeedTimer] :: number, false)
		speedTweenThisFrame = deltaTimeRender
	else
		speedTweenThisFrame = -deltaTimeRender
	end
	
	local jumpTweenThisFrame = 0
	if showJumpBoostTimer then
		jumpTimerLabel.Text = General.beautifyTimerCount(boostTimers.jumpPower[highestPriorityJumpTimer] :: number, false)
		jumpTweenThisFrame = deltaTimeRender
	else
		jumpTweenThisFrame = -deltaTimeRender
	end
	
	speedLabelTweenProgress = math.clamp(speedLabelTweenProgress + speedTweenThisFrame, 0, BOOST_TIMER_TWEEN_TIME)
	jumpLabelTweenProgress = math.clamp(jumpLabelTweenProgress + jumpTweenThisFrame, 0, BOOST_TIMER_TWEEN_TIME)
	
	speedLabel.Position = originalSpeedLabelOffset + UDim2.fromScale(0, getOffsetAtTime(speedLabelTweenProgress, showSpeedBoostTimer))
	speedTimerLabel.Position = originalSpeedTimerLabelOffset + UDim2.fromScale(0, getOffsetAtTime(speedLabelTweenProgress, showSpeedBoostTimer))
	jumpLabel.Position = originalJumpLabelOffset + UDim2.fromScale(0, getOffsetAtTime(jumpLabelTweenProgress, showJumpBoostTimer))
	jumpTimerLabel.Position = originalJumpTimerLabelOffset + UDim2.fromScale(0, getOffsetAtTime(jumpLabelTweenProgress, showJumpBoostTimer))
	
	local health = currentCharacter.Humanoid.Health
	local maxHealth = currentCharacter.Humanoid.MaxHealth
	healthBar.Size = UDim2.fromScale((health / maxHealth) * 0.99, healthBar.Size.Y.Scale)
	healthLabel.Text = string.format("%d/%d", health, maxHealth)
end)

localPlayer.CharacterAdded:Connect(function(character: Model)
	currentCharacter = character :: Types.Character
	Character.dismountConstraintObject()
end)

return Character