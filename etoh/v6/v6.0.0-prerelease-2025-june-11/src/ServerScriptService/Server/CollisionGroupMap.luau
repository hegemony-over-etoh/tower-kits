--!strict

local COLLISION_MAP = {
	ClientObjects = {},
	OnlyCollideWithPlayers2 = {
		"Default",
		"DoNotCollideWithPlayers",
		"ClientObjects",
		"NeverCollide",
		"OnlyCollideWithDefault",
		"DoNotCollideWithSelf",
	},
	AlwaysCollide = {},
	DoNotCollideWithPlayers = {},
	OnlyCollideWithDefault = { "NeverCollide", "ClientObjects", "DoNotCollideWithPlayers", "DoNotCollideWithSelf" },
	Player = { "OtherPlayers", "DoNotCollideWithPlayers", "NeverCollide", "OnlyCollideWithDefault" },
	NeverCollide = {
		"NeverCollide",
		"Default",
		"ClientObjects",
		"DoNotCollideWithPlayers",
		"DoNotCollideWithSelf",
		"AlwaysCollide",
	},
	DoNotCollideWithSelf = { "DoNotCollideWithSelf" },
	OnlyCollideWithPlayers = {
		"OnlyCollideWithPlayers",
		"Default",
		"DoNotCollideWithPlayers",
		"ClientObjects",
		"OnlyCollideWithPlayers2",
		"NeverCollide",
		"OnlyCollideWithDefault",
		"DoNotCollideWithSelf",
	},
	OtherPlayers = {
		"ClientObjects",
		"DoNotCollideWithPlayers",
		"OnlyCollideWithPlayers",
		"OnlyCollideWithPlayers2",
		"NeverCollide",
		"AlwaysCollide",
		"OnlyCollideWithDefault",
		"DoNotCollideWithSelf",
	},
} :: { [string]: { string } }

return COLLISION_MAP
