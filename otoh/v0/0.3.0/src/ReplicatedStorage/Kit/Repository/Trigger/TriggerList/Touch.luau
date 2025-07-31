--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
		-- the entire purpose of a touch trigger is to just fire the next chain objects so do that
		return TriggerFunctions.getDefaultChainList(object)
	end,
	connections = function(object)
		local touchPart = object.instance :: BasePart
		local debounce = false
		return {
			{
				signal = LemonSignal.wrap(touchPart.Touched), 
				clause = function(otherPart: BasePart)
					if debounce or not touchPart:GetAttribute("_Active") then return false end
					
					local canBeActivated = Utility.ClientObjects.isTouchValid(touchPart, otherPart)
					if canBeActivated then
						debounce = true
						
						local output = touchPart:FindFirstChild("Output")
						if output and output:IsA("ObjectValue") and TriggerFunctions.isPointingToVariableTrigger(output) then
							output = TriggerFunctions.getVariableValueOrSelf(output)
							if output:IsA("ObjectValue") then
								output.Value = otherPart
							end
						end
						
						task.delay(object.instance:GetAttribute("Cooldown"), function()
							debounce = false
						end)
					end
					
					return canBeActivated
				end
			}
		}
	end,
} :: TriggerTypes.TriggerInfo