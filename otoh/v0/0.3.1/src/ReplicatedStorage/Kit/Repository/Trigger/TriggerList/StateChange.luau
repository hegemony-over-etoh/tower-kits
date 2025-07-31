--!strict
local Players = game:GetService("Players")
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

-- reduces the need to like... edit every trigger LOL
local stateChangedEventForward = LemonSignal.new()

local function initStateChangedListener(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("wat")
		return
	end
	
	-- eughh I hate how I can't do this in a one liner :(
	humanoid.StateChanged:Connect(function(old, new)
		stateChangedEventForward:Fire(old, new)
	end)
end
if Players.LocalPlayer.Character then
	initStateChangedListener(Players.LocalPlayer.Character)
end

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
				signal = stateChangedEventForward,
				clause = function(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)
					if debounce then return false end
					
					local allowedOldStatesFolder = object.instance:FindFirstChild("OldState") :: Folder
					local allowedNewStatesFolder = object.instance:FindFirstChild("NewState") :: Folder
					
					-- unfortunately this is kinda forced to be slow :frowning:
					-- TODO: maybe I can do some weird caching magic but it shouldn't matter to that extent lol
					local function compareState(state: Enum.HumanoidStateType, stateFolder: Folder): boolean
						if stateFolder and stateFolder:IsA("Folder") and #stateFolder:GetChildren() > 0 then
							local isOk = false
							for _, value in stateFolder:GetChildren() do
								if value:IsA("ValueBase") then
									local value = TriggerFunctions.getVariableValueOrSelf(value, true) :: StringValue
									if value.Value == state.Name then
										isOk = true
										break
									end
								end
							end
							
							return isOk
						else
							return true
						end
					end
					
					local isValidStateChange = compareState(oldState, allowedOldStatesFolder) and compareState(newState, allowedNewStatesFolder)
					
					if isValidStateChange then
						debounce = true
						task.delay(object.instance:GetAttribute("Cooldown"), function()
							debounce = false
						end)
					end
					
					return isValidStateChange
				end,
			}
		}
	end,
} :: TriggerTypes.TriggerInfo