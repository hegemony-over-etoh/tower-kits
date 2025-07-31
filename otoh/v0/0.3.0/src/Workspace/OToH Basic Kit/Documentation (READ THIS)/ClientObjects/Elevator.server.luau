--[==[
	Elevators apply a constant velocity to a player (with a specified max force) or pushbox while they are inside it.
	
	Compared to the JToH/EToH elevators (as of v5.5), there's a few added benefits:
		- The direction of the elevator can be changed to be independent of the elevator's orientation
		- The hitbox of the elevator can be changed to effect the root part exclusively, preventing hitting the elevator through walls if desired.
		- The elevator velocity should update whenever it's rotated, so it should work fine on moving objects!!! yay!!!
	
	**This is a touch activated object. Please read the "Touch Activated Objects" documentation in General Info for additional attributes.**
	The attributes are as follows:
		- MaxForce: The maximum applicable force the elevator can use to move the player.
		- PlayerHitBoxMode: Set to `RootPart` to only apply to the root part, otherwise `WholeBody`.*
		- PushDirection: The direction affected parts are pushed in if `UseUpVector` is set to false.
		- Speed: The velocity at which the elevator moves affected parts at
		- UseUpVector: When true, parts will be moved in the direction of the elevator's up vector.**
		
	* `Legs` is technically a valid hitbox but that is mostly for boost pads and I would refrain from messing with it much.
	** The direction is indicated by the hinge on the default elevator part.
]==]