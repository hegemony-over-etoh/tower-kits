--!strict

export type __VALID_DAMAGEBRICKS = {
	kills: number,
	double: number,
	ouch: number,
	instakills: number,
	damage: number,
	heals: string,
	[string]: any,
}

export type __BOOST_DATA = {
	startTime: number,
	mode: string,
	type: string,
	power: number,
	duration: number,
	timerDecimals: number,
	startTweenInfo: TweenInfo,
	endTweenInfo: TweenInfo,
}

export type CharacterManager = {
	--> BaseController
	Init: (self: CharacterManager) -> CharacterManager,
	__initialized: boolean,

	--> CharacterManager
	VALID_DAMAGEBRICKS: __VALID_DAMAGEBRICKS,
	BOOST_DATA: __BOOST_DATA,
	
	-- damage functions
	Damage: (self: CharacterManager, damage: BasePart | number | string) -> (),
	
	-- helper functions
	GetHumanoid: (self: CharacterManager, player: Player) -> Humanoid?,
	
	-- booster functions
	StartBoost: (self: CharacterManager, boostData: __BOOST_DATA) -> (),
	UpdateBoost: (self: CharacterManager, boostData: __BOOST_DATA, boostEnded: boolean?) -> (),
	RemoveBoost: (self: CharacterManager, boostType: string) -> (),
	GetActiveBoosts: (self: CharacterManager) -> {[string]: __BOOST_DATA?},
	
	-- boost pad functions
	ActivateBoostPad: (self: CharacterManager, boostType: string, power: number) -> (),
	UpdateBoostPad: (self: CharacterManager, boostType: string, power: number) -> (),
	DeactivateBoostPad: (self: CharacterManager, boostType: string) -> (),
	GetActiveBoostPads: (self: CharacterManager) -> {[string]: number?},
}

return nil