--!strict
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

--[=[
	@class Gui
	@client
	A table of utility functions for working with GUIs that can be used to speed up the process of writing repository scripts for client objects.
	
	Currently, this is only used by Keys
]=]
local Gui = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers

local GuiManager = require(Managers.GuiManager):Init()
local GuiManager_Types = require(Managers.GuiManager.TypeDefs)

Gui.EffectGui = GuiManager.Gui

-- Expose EffectGui Manager methods

--[=[
	@within Gui
	
	Binds the given `cache` to the key cache.
]=]
function Gui.bindKeyCache(cache: GuiManager_Types.KeyCache)
	return GuiManager:BindKeyCache(cache)
end

--[=[
	@within Gui
	
	Unbinds the given `cache` from the key cache.
]=]
function Gui.unbindKeyCache(cache: GuiManager_Types.KeyCache)
	return GuiManager:UnbindKeyCache(cache)
end

return table.freeze(Gui)
