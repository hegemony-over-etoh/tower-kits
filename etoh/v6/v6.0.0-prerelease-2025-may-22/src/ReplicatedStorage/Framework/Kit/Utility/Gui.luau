--!strict

--[=[
@class Gui
@client
A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.

]=]
local Gui = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers

local EffectGuiManager = require(Managers.EffectGuiManager):Init()
local EffectGuiManager_Types = require(Managers.EffectGuiManager.TypeDefs)

Gui.EffectGui = EffectGuiManager.Gui

return table.freeze(Gui)
