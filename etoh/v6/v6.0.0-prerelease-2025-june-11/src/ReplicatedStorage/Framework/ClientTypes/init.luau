--!strict

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
