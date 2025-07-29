--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Kit = ReplicatedStorage.Framework.Kit

local CharacterManager_Types = require(Kit.Managers.CharacterManager.TypeDefs)
local KeyGroup_Types = require(Kit.Repository.Interactables.KeyGroup.TypeDefs)

export type BoostTimerFrame = typeof(script.Parent.BoostFrame) -- allows autocomplete
export type KeyCache = KeyGroup_Types.Cache

export type EffectGuiManager = {
	--> BaseController
	Init: (self: EffectGuiManager) -> EffectGuiManager,
	__initialized: boolean,

	--> EffectGuiManager
	Gui: typeof(StarterGui.EffectGUI),

	KeyDisplayLimit: number,
	BindKeyCache: (self: EffectGuiManager, cache: KeyGroup_Types.Cache) -> (),
    UnbindKeyCache: (self: EffectGuiManager, cache: KeyGroup_Types.Cache) -> (),
    __updateKeyDisplay: (self: EffectGuiManager) -> (),
    __keyCaches: { [string]: KeyGroup_Types.Cache },
    
	CreateBoostFrame: (self: EffectGuiManager, boostData: CharacterManager_Types.BoostData) -> BoostTimerFrame,
	UpdateBoostFrame: (self: EffectGuiManager, boostData: CharacterManager_Types.BoostData) -> (),
	FormatBoostTimer: (self: EffectGuiManager, boostData: CharacterManager_Types.BoostData) -> string,
	DestroyBoostFrame: (self: EffectGuiManager, boostData: CharacterManager_Types.BoostData) -> (),
}

return nil
