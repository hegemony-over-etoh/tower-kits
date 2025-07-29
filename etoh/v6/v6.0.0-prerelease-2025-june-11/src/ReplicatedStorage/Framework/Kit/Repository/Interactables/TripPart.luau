--!strict
--!optimize 2
--@version trippart-6.0.0
--@creator Gammattor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local utility = scope:utility()
	local tripPartConfig = scope.instance
	if not tripPartConfig then
		return
	end

	local tripPart = tripPartConfig.Parent
	if not tripPart or not tripPart:IsA("BasePart") then
		return
	end

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, tripPartConfig, {
		Cooldown = 1,
	}):ObserveChanges()

	local tripCooldown = false
	local function trip()
		tripCooldown = true
		humanoid.Sit = true
	end

	scope:attach(tripPart)
	scope:add(tripPart.Touched:Connect(function(touch)
		if touch.Parent == character and not tripCooldown then
			trip()
			task.delay(configuration.Cooldown, function()
				tripCooldown = false
			end)
		end
	end))
end
