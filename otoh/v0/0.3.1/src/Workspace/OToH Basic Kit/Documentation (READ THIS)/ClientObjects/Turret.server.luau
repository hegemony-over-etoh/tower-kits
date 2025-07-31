--[==[
	Turrets shoot "bullets" that damage players on contact, hit buttons, or act as a moving platform.
	
	Attributes:
	- Hit{Bullets/Parts/Players}: Determines what will delete the bullet when collided with. 
		Will only damage the player if the player was touched.
	- AutoScaleBullet: If true, the turret bullet will be scaled relative to the size of the turret itself.
	- Damage: The damage the turret applies on contact with the player, assuming `HitPlayers` is true.
	- Delay: The time between turret fires.
	- Distance: The radius around the turret the player must be in order for the turret to fire.
	- Speed: The velocity of bullets fired by the turret.
]==]