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

export type hitboxModes = "StaticWholeBody" | "StaticCenter" | "StaticArms" | "RootPart" | "WholeBody" | "Center"
Character.HitboxModes =
	table.freeze({ "StaticWholeBody", "StaticCenter", "StaticArms", "RootPart", "WholeBody", "Center" })

local function _addToListAndFilter(part, list, params: OverlapParams?)
	table.insert(list, part)
	if typeof(params) == "OverlapParams" then
		params:AddToFilter(part)
	end
end

function Character.getHitbox(mode: hitboxModes, params: OverlapParams?): { BasePart }
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
function Character.getHumanoid(): Humanoid?
	return CharacterManager:GetHumanoid(Players.LocalPlayer)
end
function Character.startBoost(boostData: CharacterManager_Types.__BOOST_DATA)
	return CharacterManager:StartBoost(boostData)
end
function Character.removeBoost(boostType: string)
	return CharacterManager:RemoveBoost(boostType)
end
function Character.updateBoost(boostData: CharacterManager_Types.__BOOST_DATA, boostEnded: boolean?)
	return CharacterManager:UpdateBoost(boostData, boostEnded)
end
function Character.getActiveBoosts(): { [string]: CharacterManager_Types.__BOOST_DATA? }
	return CharacterManager:GetActiveBoosts()
end
function Character.activateBoostPad(boostType: string, power: number)
	return CharacterManager:ActivateBoostPad(boostType, power)
end
function Character.updateBoostPad(boostType: string, power: number)
	return CharacterManager:UpdateBoostPad(boostType, power)
end
function Character.deactivateBoostPad(boostType: string)
	return CharacterManager:DeactivateBoostPad(boostType)
end
function Character.getActiveBoostPads(): { [string]: number? }
	return CharacterManager:GetActiveBoostPads()
end

local rootWelds: { [Instance]: WeldConstraint? } = {}
local destroyingConnections: { [Instance]: RBXScriptConnection } = {}
local weldedShoulders = {}
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
