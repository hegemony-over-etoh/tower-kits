--!strict

--[=[
    @class Lighting
    @client
    A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.
    
]=]
local Lighting = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers

local LightingManager = require(Managers.LightingManager)
local LightingManager_Types = require(Managers.LightingManager.TypeDefs)

local ScopeUtil = require(script.Parent.InternalScopeUtil)
type Scope = ScopeUtil.Scope

local PREFIX = "TowerDefault"
function Lighting.changeLighting(config: LightingManager_Types.LightingConfiguration, scope: Scope?)
	config = table.clone(config)
	if
		(typeof(config.SetDefault) == "string" and config.SetDefault:sub(1, PREFIX:len()) == PREFIX)
		or (typeof(config.UseDefault) == "string" and config.UseDefault:sub(1, PREFIX:len()) == PREFIX)
	then
		ScopeUtil.assertScope(scope, "Lighting.changeLighting()")
		if scope then
			if config.SetDefault then
				config.SetDefault = config.SetDefault:gsub(PREFIX, scope.tower)
			end
			if config.UseDefault then
				config.UseDefault = config.UseDefault:gsub(PREFIX, scope.tower)
			end
		end
	end

	LightingManager:ChangeLighting(config)
end

function Lighting.resetLighting()
	LightingManager:ResetLighting()
end

return table.freeze(Lighting)
