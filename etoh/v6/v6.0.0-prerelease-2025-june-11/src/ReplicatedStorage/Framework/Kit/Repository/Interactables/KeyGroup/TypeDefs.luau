--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local _T = require(ReplicatedStorage.Framework.ClientTypes)

export type Key = {
	instance: Model?,
	originalCFrame: CFrame,
	hitbox: BasePart,
	timerBillboard: typeof(script.Parent.KeyTimer),
	timerLabel: TextLabel,
	config: {
		ViewportOffset: CFrame,
		SpinSpeed: number,
		Timer: number,
        TimerDecimalPlaces: number,
	},

	__private: {
		id: string,
		groupID: string,
		group: KeyGroup,
		isViewportDisplayed: boolean,
		targetCFrame: CFrame?,
		parent: Instance,
		active: boolean,
		cooldown: boolean,
		used: boolean,
		startTimer: number?,
		collectKey: (self: Key) -> (),
		returnKey: (self: Key) -> (),
		viewport: typeof(script.KeyViewport),
	}?,
}
export type KeyDoor = {
	instance: Model,
	hitbox: BasePart,
	doorParts: { [BasePart]: string? },
	doorSigns: { [TextLabel]: string },
	config: {
		RequiredKeys: number,
	},

	__private: {
		id: string,
		groupID: string,
		group: KeyGroup,
		unlocked: boolean,
		usedKeys: { string },
		unlockDoor: (self: KeyDoor) -> (),
		updateSigns: (self: KeyDoor) -> (),
		useKey: (self: KeyDoor, keyID: string) -> (),
	}?,
}
export type KeyGroup = {
	scope: any,
	id: string,
	keys: { [string]: Key },
	doors: { [string]: KeyDoor },
	addKey: (self: KeyGroup, Key) -> Key?,
	addDoor: (self: KeyGroup, KeyDoor) -> KeyDoor?,
}
export type Cache = {
	groups: { [string]: KeyGroup? },
	keys: { [string]: Key? },
	doors: { [string]: KeyDoor? },
	activeKeys: { string? },
	newGroup: (any) -> KeyGroup,
	id: string,
}

return nil
