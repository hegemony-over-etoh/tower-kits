--[==[
	Falling Platforms are platforms that fall when applied adequate force, i.e. a player.
	
	If you wish to change the physics properties of the falling platform prior to it falling, 
	edit the `AlignPosition` object under `Platform`.
	
	Attributes:
		- Elasticity/ElasticityWeight/Friction/FrictionWeight/Mass: Refer to physical properties.
			If you are unaware of what CustomPhysicalProperties do, don't touch these.
		- ReboundForce: The force that's applied when the falling platform hits the bottom and returns back upwards.
		- ReboundToggleCollision: If true, the falling platform will invert it's collision when rebounding.
		- ReboundTransparency: The transparency the platform is set to when in it's rebound state.
		- RespawnTime: How long the rebound lasts for. This can technically be shorter than the time it takes to fully rebound.
]==]