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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

--> Expose Scope types
local Scope = require(Kit.Managers.ScopeConstructor.TypeDefs)
export type Scope = Scope.Scope
export type ScopeCommunicator = Scope.ScopeCommunicator

--> Expose Utility types
local Utility = require(Kit.Utility)
export type Utility = Utility.Utility

return nil
