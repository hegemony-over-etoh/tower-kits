--[==[
	A swing is a constraint object that attaches the player to a "swing" that can only rotate around one axis.
	
	Attributes:
		- AllowJumpDismount: When true, the player can initiate a jump to dismount the swing object.
		- Boost: A force applied to the player when initially mounting the swing that will propel the player forwards.
		- Controllable: When true, the player can use directional input to manually swing the swing.
		- ControllableForce: The force the player applies when using directional input to swing.
		- ControllableMaxVelocity: The maximum velocity the player can have when manually controlling the swing.
		- Cooldown: The amount of time the player must wait after dismounting the swing before remounting.
		- DontAnchor: When true, the swing will not be anchored while the player is not on it.
		- EndJump: When true, the player will jump when dismounting the swing normally.
]==]