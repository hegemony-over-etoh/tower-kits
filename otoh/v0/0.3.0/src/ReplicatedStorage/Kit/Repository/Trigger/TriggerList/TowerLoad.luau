--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local LemonSignal = require(Libraries.LemonSignal)
local Utility = require(Kit.Utility)

local TriggerBase = script.Parent.Parent
local TriggerFunctions = require(TriggerBase.TriggerFunctions)

local Types = require(Kit.Types)
local TriggerTypes = require(TriggerBase.TriggerTypes)

return {
	behavior = function(object)
		-- the entire purpose of this trigger is to just fire the next chain objects so do that
		return TriggerFunctions.getDefaultChainList(object)
	end,
	connections = function(object)
		return {
			{
				signal = Utility.Tower.towerLoaded, 
			}
		}
	end,
} :: TriggerTypes.TriggerInfo