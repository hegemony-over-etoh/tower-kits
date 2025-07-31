--[==[
	Moving platforms move a "platform" part between a set of waypoints at a set interval.
	Note that the *initial* position of the platform at loadtime is included in the set of waypoints. Think of it as "Waypoint #0."
	
	Attributes:
		- Interval: The time the platform stays at one position before moving to the next.
		- InvisiblePositions: If true, the platform position "waypoints" will no longer be visible to the player.
	
	You may additionally set the `Interval` attribute per waypoint, which will override the default interval.
	This interval override represents the time it takes for the platform to go from the previous waypoint to the overriden waypoint.
]==]