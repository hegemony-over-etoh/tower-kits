--!strict
--!optimize 2
-- By @synnwave, Camille (09/12/24 DD/MM/YY)

--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local Framework = ReplicatedStorage.Framework
local DamageEvent = Framework.Remotes.Towers.Objects.DamageEvent
local EffectGuiManager = require(Framework.Kit.Managers.EffectGuiManager)
local Config = require(Framework.Kit.Utility.Config)

local _TDefs = require(script.TypeDefs)

local LOCAL_PLAYER_COLLISIONGROUP = "Player"
local OTHER_PLAYER_COLLISIONGROUP = "OtherPlayers"
local VALID_DAMAGEBRICKS = table.freeze({
	kills = 5,
	double = 10,
	ouch = 20,
	instakills = math.huge,
	damage = 0, -- custom value; you can make this a number attribute
	heals = "Heals",
} :: _TDefs.__VALID_DAMAGEBRICKS)

local BOOST_DURATION_NO_TIMER = 10 ^ 10
local activeBoosts: { [string]: _TDefs.__BOOST_DATA? } = {
	Speed = nil,
	Jump = nil,
}
local activeBoostPads: { [string]: number? } = {
	Speed = nil,
	Jump = nil,
}
local defaultMovementValues = {
	Speed = StarterPlayer.CharacterWalkSpeed,
	Jump = StarterPlayer.CharacterJumpPower,
}
local affectedHumanoidProperties = {
	Speed = "WalkSpeed";
	Jump = "JumpPower"
}
local currentBoostTween = nil

local CharacterManager = {
	__initialized = false,
	VALID_DAMAGEBRICKS = VALID_DAMAGEBRICKS,
} :: _TDefs.CharacterManager

function roundDecimals(value: number, decimals: number): number
	local mult = 10 ^ decimals
	return math.round(value * mult) / mult
end

--[=[
	@within CharacterManager
	
	Fires the DamageEvent with the given `damage` value.
	`damage` can be either a `number`, or a `string` representing a key in the
	`VALID_DAMAGEBRICKS` table.
]=]
function CharacterManager:Damage(damage)
	if not self.__initialized then
		return
	end

	local damageAmount: number | string

	if typeof(damage) == "Instance" and damage:IsA("BasePart") then
		if damage:GetAttribute("Activated") == false then
			return
		end
		for identifier, value in VALID_DAMAGEBRICKS do
			if damage:HasTag(identifier) or damage:FindFirstChild(identifier) then
				damageAmount = value
				break
			end

			local hasAttribute = damage:GetAttribute(identifier)
			if hasAttribute ~= nil then
				damageAmount = (if typeof(hasAttribute) == "number" then hasAttribute else value)
				break
			end
		end
	elseif typeof(damage) == "number" then
		damageAmount = damage
	end

	if not damageAmount then
		return
	end
	DamageEvent:FireServer(damageAmount)
end

--[=[
	@within CharacterManager
	
	Returns the `player`'s `Humanoid` if it exists.
]=]
function CharacterManager:GetHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return
	end

    return character:FindFirstChildOfClass("Humanoid")
end

--[=[
	@within CharacterManager
	
	Starts a boost with the given boost data.
	If a boost with the given type is already active, the already active boost will be
	refreshed instead of a new boost being started.
	
	Currently, the valid boost types are:
	* `Speed` for WalkSpeed
	* `Jump` for JumpPower
	This list also applies to Boost Pads. -- TODO add link
]=]
function CharacterManager:StartBoost(boostData: _TDefs.__BOOST_DATA)
	-- if a boost of this type is already active, refresh it instead of starting a new one
	local activeBoost = activeBoosts[boostData.type]
	if activeBoost then
		activeBoost.startTime = os.clock()
		activeBoost.duration = boostData.duration
		activeBoost.power = boostData.power
		activeBoost.timerDecimals = boostData.timerDecimals
		activeBoost.startTweenInfo = boostData.startTweenInfo
		activeBoost.endTweenInfo = boostData.endTweenInfo

		CharacterManager:UpdateBoost(boostData)
		return
	end

	-- set up the new boost now
	activeBoosts[boostData.type] = boostData
	CharacterManager:UpdateBoost(boostData)

	-- set up boost timer if applicable
	if boostData.duration > 0 and boostData.duration < BOOST_DURATION_NO_TIMER and boostData.mode ~= "Zone" then
		local boostLabel = EffectGuiManager:CreateBoostTimer(boostData.type)
		local boostLoop
		boostLoop = RunService.Heartbeat:Connect(function()
			local activeBoostData = activeBoosts[boostData.type]

			-- if the boost data can't be found (ended by a remover), cancel the loop
			if not activeBoostData then
				boostLoop:Disconnect()
				boostLabel:Destroy()
				return
			end

			-- update the boost timer
			local timePassed = os.clock() - activeBoostData.startTime
			local timeLeft = activeBoostData.duration - timePassed

			boostLabel.Text = tostring(roundDecimals(timeLeft, boostData.timerDecimals))

			-- if time is up, end the boost
			if timeLeft <= 0 then
				boostLoop:Disconnect()
				boostLabel:Destroy()
				activeBoosts[boostData.type] = nil
				CharacterManager:UpdateBoost(boostData, true)
				return
			end
		end)
	end
end

--[=[
	@within CharacterManager
	
	Updates the currently active boost with the given type, updating the affected property.
	If `boostEnded` is `true`, the character will return to it's default properties
	rather than using the boost's power.
]=]
function CharacterManager:UpdateBoost(boostData: _TDefs.__BOOST_DATA, boostEnded: boolean?)
	local humanoid = CharacterManager:GetHumanoid(Players.LocalPlayer)
	if not humanoid then
		return
	end

	if boostEnded and activeBoostPads[boostData.type] then
		return -- don't update if the player is using a boost pad atm
	end

	local power = if boostEnded then defaultMovementValues[boostData.type] else boostData.power
	local tweenInfo = if boostEnded then boostData.endTweenInfo else boostData.startTweenInfo

	if currentBoostTween then
		currentBoostTween:Cancel()
	end
	
	local affectedProperty = affectedHumanoidProperties[boostData.type]
	
	currentBoostTween = TweenService:Create(humanoid, tweenInfo, {[affectedProperty] = power})
	currentBoostTween:Play()
end

--[=[
	@within CharacterManager
	
	Ends the currently active boost with the given type.
]=]
function CharacterManager:RemoveBoost(boostType: string)
	local activeBoost = activeBoosts[boostType]
	if activeBoost then
		CharacterManager:UpdateBoost(activeBoost, true)
		activeBoosts[boostType] = nil
	end
end

--[=[
	@within CharacterManager
	
	Returns a table containing the currently active boosts.
]=]
function CharacterManager:GetActiveBoosts(): { [string]: _TDefs.__BOOST_DATA? }
	return activeBoosts
end

--[=[
	@within CharacterManager
	
	Activates a boost pad with the given `boostType` and `power`.
]=]
function CharacterManager:ActivateBoostPad(boostType: string, power: number)
	activeBoostPads[boostType] = power
	CharacterManager:UpdateBoostPad(boostType, power)
end

--[=[
	@within CharacterManager
	
	Updates a boost pad's boost with the given `boostType` and `number`, updating
	the affected property accordingly.
]=]
function CharacterManager:UpdateBoostPad(boostType: string, power: number)
	local humanoid = CharacterManager:GetHumanoid(Players.LocalPlayer)
	if not humanoid then
		return
	end

	if currentBoostTween then
		currentBoostTween:Cancel()
	end

	if boostType == "Speed" then
		humanoid.WalkSpeed = power
	elseif boostType == "Jump" then
		humanoid.JumpPower = power
	end
end

--[=[
	@within CharacterManager
	
	Deactivates a boost pad with the given `boostType`.
	If a regular booster is currently active, the player will revert to that booster's power.
	Otherwise, the player will revert to the default power.
]=]
function CharacterManager:DeactivateBoostPad(boostType: string)
	activeBoostPads[boostType] = nil

	local activeBoost = activeBoosts[boostType]
	if activeBoost then
		CharacterManager:UpdateBoostPad(boostType, activeBoost.power)
	else
		CharacterManager:UpdateBoostPad(boostType, defaultMovementValues[boostType])
	end
end

--[=[
	@within CharacterManager
	
	Returns a table containing the currently active boost pads.
]=]
function CharacterManager:GetActiveBoostPads(): { [string]: number? }
	return activeBoostPads
end

function CharacterManager:Init()
	local localPlayer = Players.LocalPlayer
	if self.__initialized or not localPlayer then
		return CharacterManager
	end
	self.__initialized = true
	
	local function setupLocalPlayer(player: Player, character: Model)
		-- New TouchScript implementation
		local humanoid = character:WaitForChild("Humanoid")
		if not humanoid:IsA("Humanoid") then
			return
		end
		humanoid.Touched:Connect(function(touchingPart, hitPart)
			if humanoid.Health <= 0 then
				return
			end
			self:Damage(touchingPart)
		end)

		-- Enable Physics Fix (Truss Fix + Head Collision Glitch Fix)
		local fixScript = script.PhysicsFixer:Clone()
		fixScript.Parent = character
		fixScript.Enabled = true

		-- Static Hitbox for client objects
		if not humanoid.RootPart then
			return
		end
		local hitbox = script._HITBOX:Clone()
		hitbox:PivotTo(humanoid.RootPart:GetPivot())
		hitbox.RootPart.WeldConstraint.Part1 = humanoid.RootPart
		hitbox.RootPart.Anchored = false
		hitbox.Parent = character
	end
	
	local function onPlayerAdded(player: Player)
		local function onCharacterAdded(character: Model)
			if not character then
				return
			end

			local isLocalPlayer = player == localPlayer
			local currentCollisionGroup = if isLocalPlayer then LOCAL_PLAYER_COLLISIONGROUP
											else OTHER_PLAYER_COLLISIONGROUP
			for _, part in character:GetChildren() do
				if not part:IsA("BasePart") then
					continue
				end
				part.CollisionGroup = currentCollisionGroup
			end

			character.ChildAdded:Connect(function(part)
				if not part:IsA("BasePart") then
					return
				end
				part.CollisionGroup = currentCollisionGroup
			end)
			
			-- moved this into a seperate function for cleanliness
			if isLocalPlayer then
				setupLocalPlayer(player, character)
			end
		end

		pcall(onCharacterAdded, player.Character or player.CharacterAdded:Wait())
		player.CharacterAdded:Connect(onCharacterAdded)
	end

	-- Initialize players
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)

	return CharacterManager
end

return CharacterManager
