--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

export type Button = {
	Button: BasePart,
	Configuration: Instance,
	Color: Color3,
	ID: string,
	Pressed: BoolValue, --boolean,
	--PressedSignal: _T.ScopeCommunicator,
	TotalPresses: number,
	TimerFinished: BindableEvent,
}
export type ButtonCache<Tags> = {
	ButtonActivatedPlatforms: { [BasePart]: Tags? },
	Buttons: { [Instance]: Button? },
}

return nil
