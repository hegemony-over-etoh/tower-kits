local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = ReplicatedStorage.Kit

local Utility = require(Kit.Utility)

local player = Players.LocalPlayer

-- make sure the player exists juuust in case
if not player.Character then
	player.CharacterAdded:Wait()
end

local preLoadTime = os.clock()
Utility.Tower.loadTower("OToH Basic Kit")
print(`Client loaded tower in {os.clock() - preLoadTime} seconds.`)