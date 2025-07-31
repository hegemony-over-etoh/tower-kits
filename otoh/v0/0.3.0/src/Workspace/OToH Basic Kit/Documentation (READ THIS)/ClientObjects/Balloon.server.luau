--[==[
	Balloons are spawned via Balloon Dispensers and attach the player to a part (balloon) being moved at a constant velocity on the y-axis.
	Balloons typically pop at a certain height or time, removing the velocity.
	
	Attributes:
		- AllowJumpDismount: when true, the player can jump to dismount the balloon.
		- MaxHeight: the maximum height relative to the balloon dispenser the ballon can rise before popping. Set to -1 to disable.
		- MaxTime: the maximum time the balloon can be active before popping. Set to -1 to disable.
		- RecolorDecals: when true, the decals on the balloon dispenser will automatically update to the colour of the dispenser itself.
		- RopeLength: the length of the `RopeConstraint` attaching the player to the balloon.
		- UpwardsVelocity: the speed at which the balloon rises.
]==]