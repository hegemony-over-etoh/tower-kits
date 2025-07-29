--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local APIDump = require(ReplicatedStorage.Framework.ClientTypes.APIDump)

--[=[
	@interface LightingConfiguration
	@within LightingManager
	.Type string
	.Configuration Default | { [string]: any }
	.TweenInfo TweenInfo?
	.UseDefault string?
	.SetDefault string?
]=]
export type LightingConfiguration = {
	Type: string,
	Configuration: "Default" | { [string]: any },
	TweenInfo: TweenInfo?,
	UseDefault: string?,
	SetDefault: string?,
}

export type LightingManager = {
	--> BaseController
	Init: (self: LightingManager) -> LightingManager,
	__initialized: boolean,

	--> LightingManager
	Templates: { [string]: { [string]: any } },
	ChangeLighting: (self: LightingManager, config: LightingConfiguration) -> (),
	ResetLighting: (self: LightingManager) -> (),
	DeregisterPreset: (self: LightingManager, preset: string) -> (),
}

return nil
