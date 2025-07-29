--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[=[
    @class Character
    @client
    A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.
]=]
local Character = {}

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers

Character.HitboxModes =
	table.freeze({ "StaticWholeBody", "StaticCenter", "StaticArms", "RootPart", "WholeBody", "Center" })

local function _addToListAndFilter(part, list, params: OverlapParams?)
	table.insert(list, part)
	if typeof(params) == "OverlapParams" then
		params:AddToFilter(part)
	end
end

--[=[
	@within Character
	Returns a static hitbox attached to the character based on the provided `mode`.
	These hitboxes ignore animations and as such should be more consistent.
	
	Supported hitbox types:
	* RootPart - HumanoidRootPart only
	* StaticWholeBody - Character's entire body
	* StaticCenter - Character's entire body, excluding arms
	* StaticArms - Arms & torso only
	
	There are more hitbox types that include the character's actual limbs,
	note that these do **not** ignore animations:
	* WholeBody - All limbs
	* Center - All limbs, excluding the arms
]=]
function Character.getHitbox(mode: string, params: OverlapParams?): { BasePart }
	local parts = {}

	local character = Players.LocalPlayer.Character
	if not character then
		return parts
	end

	if mode == "RootPart" or mode:find("Static") then
		local hitbox = character:FindFirstChild("_HITBOX")
		if not hitbox then
			return parts
		end

		if mode == "RootPart" then
			_addToListAndFilter(hitbox.RootPart, parts, params)
		elseif mode == "StaticWholeBody" then
			_addToListAndFilter(hitbox.Arms, parts, params)
			_addToListAndFilter(hitbox.Center, parts, params)
		elseif mode == "StaticCenter" then
			_addToListAndFilter(hitbox.Center, parts, params)
		elseif mode == "StaticArms" then
			_addToListAndFilter(hitbox.Arms, parts, params)
		end
	else
		for _, characterPart in character:GetChildren() do
			if not characterPart:IsA("BasePart") or characterPart.Name == "Torso" then
				continue
			end

			if mode == "WholeBody" then
				_addToListAndFilter(characterPart, parts, params)
			elseif mode == "Center" and (characterPart.Name ~= "Left Arm" and characterPart.Name ~= "Right Arm") then
				_addToListAndFilter(characterPart, parts, params)
			end
		end
	end

	return parts
end

local CharacterManager = require(Managers.CharacterManager)
local CharacterManager_Types = require(Managers.CharacterManager.TypeDefs)

-- Expose Character Manager methods
function Character.takeDamage(damage: BasePart | number | string)
	CharacterManager:Damage(damage)
end
function Character.validateDamageBrick(brick: BasePart): (string | number)?
    return CharacterManager:ValidateDamageBrick(brick)
end
function Character.getHumanoid(): Humanoid?
	return CharacterManager:GetHumanoid(Players.LocalPlayer)
end
function Character.startBoost(boostData: CharacterManager_Types.BoostData)
	return CharacterManager:StartBoost(boostData)
end
function Character.updateBoost(boostData: CharacterManager_Types.BoostData, boostEnded: boolean?)
	return CharacterManager:UpdateBoost(boostData, boostEnded)
end
function Character.removeBoost(boostData: CharacterManager_Types.BoostData)
	return CharacterManager:RemoveBoost(boostData)
end
function Character.getActiveBoosts(): { CharacterManager_Types.BoostData }
	return CharacterManager:GetActiveBoosts()
end
function Character.getActiveBoost(boostType: string, isPad: boolean?): CharacterManager_Types.BoostData?
	return CharacterManager:GetActiveBoost(boostType, isPad)
end

local rootWelds: { [Instance]: WeldConstraint? } = {}
local destroyingConnections: { [Instance]: RBXScriptConnection } = {}
local weldedShoulders = {}

--[=[
	@within Character
	
	Makes the character carry the `weldTo` part, welding it to the character
	and displaying a carry animation on the character. The carry animation
	manipulates the character's shoulders directly instead of using an
	Animation, so it should work everywhere.
	
	If `weldState` is `false`, the character will stop carrying the part and
	the carry animation will stop.
]=]
function Character.carryPart(weldState: boolean, weldTo: BasePart)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if weldState then
		local rootPart = humanoid.RootPart
		if not rootPart or not weldTo then
			return
		end

		if rootWelds[weldTo] then
			Character.carryPart(false, weldTo)
		end

		weldTo.CFrame = rootPart.CFrame + rootPart.CFrame.UpVector * (weldTo.Size.Y / 2 + 2)
		local rootWeld = Instance.new("WeldConstraint")
		rootWeld.Parent = rootPart
		rootWeld.Part0 = rootPart
		rootWeld.Part1 = weldTo
		rootWelds[weldTo] = rootWeld

		for index, arm in { character:FindFirstChild("Left Arm"), character:FindFirstChild("Right Arm") } do
			local shoulder = character:FindFirstChild(`{arm.Name:split(" ")[1]} Shoulder`, true)
			if not shoulder then
				continue
			end

			table.insert(weldedShoulders, shoulder)
			local armWeld = Instance.new("WeldConstraint")
			armWeld.Parent = rootWeld

			shoulder.Enabled = false
			arm.CFrame = weldTo.CFrame - weldTo.CFrame.UpVector + (weldTo.CFrame.RightVector * (index - 1.5) * 2.95)
			arm.CFrame *= CFrame.Angles(math.pi, 0, 0)
			armWeld.Part0 = arm
			armWeld.Part1 = weldTo
		end
		
		destroyingConnections[weldTo] = weldTo.Destroying:Once(function()
			for _, shoulder in weldedShoulders do
				shoulder.Enabled = true
			end
			
			local humanoid = Character.getHumanoid()
			if humanoid and humanoid.PlatformStand then
				humanoid.PlatformStand = false
			end
		end)
	else
		local weld = rootWelds[weldTo]
		local destroyingConnection = destroyingConnections[weldTo]
		if weld then
			weld:Destroy()
			rootWelds[weldTo] = nil
		end
		if destroyingConnection then
			destroyingConnection:Disconnect()
			destroyingConnections[weldTo] = nil
		end
		if #rootWelds <= 0 then
			for _, shoulder in weldedShoulders do
				shoulder.Enabled = true
			end
		end
		table.clear(weldedShoulders)
	end
end

return table.freeze(Character)
