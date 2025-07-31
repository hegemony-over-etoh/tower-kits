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
		local touchPart = object.instance :: BasePart
		local debounce = false
		return {
			{
				signal = LemonSignal.wrap(UserInputService.JumpRequest), 
				clause = function()
					if debounce then return false end
					
					debounce = true
					task.delay(object.instance:GetAttribute("Cooldown"), function()
						debounce = false
					end)
					
					return true
				end
			}
		}
	end,
} :: TriggerTypes.TriggerInfo