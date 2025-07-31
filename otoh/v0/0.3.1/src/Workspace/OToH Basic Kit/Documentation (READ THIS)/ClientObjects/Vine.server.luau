--[==[
	Vines are constraint objects that attach a player to a part via a "vine" (RopeConstraint).
	Players cannot go further than the vine allows, and are able to move midair while attached.
	
	Attributes:
		- AllowJumpDismount: When true, the player may dismount the vine by jumping.
		- EndJump: When true, the player will jump when dismounting the vine
		- KeepVelocity: When true, the player will maintain their velocity when dismounting the vine. 
			Note that carrying momentum can result in jumps longer or higher than what is normally possible.
		- RepsawnTime: The time it takes for the vine to respawn after dismounting.
		- RopeLength: The length of the vine/rope constraining the player.
]==]