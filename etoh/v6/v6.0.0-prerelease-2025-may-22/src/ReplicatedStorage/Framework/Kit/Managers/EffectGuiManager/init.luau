--!strict
--!optimize 2
-- By @synnwave (09/12/24 DD/MM/YY)
-- edited by Camille 25/04/2025: added support for boosters

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

local Framework = ReplicatedStorage.Framework
local _TDefs = require(script.TypeDefs)

local EffectGuiManager = {
	__initialized = false,
} :: _TDefs.EffectGuiManager

local BOOST_COLORS = {
	Speed = Color3.fromRGB(255, 255, 0),
	Jump = Color3.fromRGB(175, 255, 0),
}

--[=[
	@within EffectGuiManager
	
	Creates and returns a boost timer label for the given `boostType`.
	The color for every type is defined in the `BOOST_COLORS` table.
]=]
function EffectGuiManager:CreateBoostTimer(boostType: string): TextLabel
	local label = script.BoostTimer:Clone()
	label.Name = boostType
	label.TextColor3 = BOOST_COLORS[boostType]
	label.LayoutOrder = #EffectGuiManager.Gui.BoostTimers:GetChildren()
	label.Parent = EffectGuiManager.Gui.BoostTimers
	
	return label
end

function EffectGuiManager:Init()
	if self.__initialized then
		return EffectGuiManager
	end
	self.__initialized = true

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	EffectGuiManager.Gui = playerGui:WaitForChild("EffectGUI")

	return EffectGuiManager
end


return EffectGuiManager