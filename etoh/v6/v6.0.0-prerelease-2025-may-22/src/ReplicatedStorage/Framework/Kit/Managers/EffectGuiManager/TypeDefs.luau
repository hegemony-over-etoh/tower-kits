--!strict

local StarterGui = game:GetService("StarterGui")

export type EffectGuiManager = {

	--> BaseController
	Init: (self: EffectGuiManager) -> EffectGuiManager,
	__initialized: boolean,

	--> EffectGuiManager
	Gui: typeof(StarterGui.EffectGUI),
	CreateBoostTimer: (self: EffectGuiManager, boostType: string) -> TextLabel,
}

return nil
