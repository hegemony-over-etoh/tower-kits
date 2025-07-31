--[==[
	Shovers move back and forth, typically with a large amount of force, with the intent to launch the player in a direction.
	
	You can change the distance the shover moves by editing the UpperLimit of the PrismaticConstraint under Shover->PrismaticConstraint.
	Attributes:
		- InDelay: The time after extending it takes for the platform to return to it's original position
		- InSpeed: The speed the shoving platform is when retracting to it's original position
		- OutDelay: The time it takes for the shoving platform to extend forwards
		- OutSpeed: The speed at which the shoving platform extends forwards. Higher = more fling
]==]