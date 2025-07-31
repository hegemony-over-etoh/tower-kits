--[==[
	All client objects that activate on touch share the same set of attributes.
	For brevity, they will only be listed here rather than each individual object:
		- SupportBalloons: When true, object will respond to touching balloons.
		- SupportPlayers: When true, object will respond to touching player limbs.
		- SupportPushboxes: When true, object will respond to touching pushboxes.
		- SupportTurrets: When true, object will respond to touching turret bullets.
		- PushboxRequireMatchingId: When true, pushboxes interacting with this object will require an id matching the `Id` attribute.
		- Id: Id of the object used for the above attribute condition.
]==]