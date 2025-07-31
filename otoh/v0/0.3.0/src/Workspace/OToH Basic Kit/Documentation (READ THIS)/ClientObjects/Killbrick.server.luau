--[==[
	Killbricks are a little different in OToH compared to other tower games.
	To encourage killbricks to be used as an actual danger source, killbricks now deal *consistent* damage every 0.5 seconds instead of 0.1.*
	To compensate, the "default" damage of killbricks are set to be substantially higher than normal. 
	Following the 1x->2x->4x trend of other games, the damage is as follows:
		- Default: 20
		- DoubleDamage: 40
		- Ouch: 80
	Of course, you are free to change the exact amount of damage the killbrick does by editing the `Damage` attribute.
	You can even set it to a negative number to create a "heal" brick if you wish.
	
	The killbricks "Poison" property changes the killbrick into a posion brick instead. 
	Poison bricks, instead of dealing damage directly, increment a "posion" value by the damage instead, up to 100.
	When at 100 (by default), the poison begins to deal damage, as set by the `PosionBrickDamage` in the ClientObjects folder.
	You may modify the threshold at which posion begins to deal damage via the `PoisonDamageThreshold` attribute.
	Additionally, posion decrements at the `PoisonDecrementRate` attribute when not touching a poison brick.
	These properties are modifiable for the purpose of allowing more/less punishing killbrick gameplay.
	
	When the `SyncParticleColor` attribute of the killbrick is true, the particle colour will automatically update to the killbrick's colour,
	preventing the need to manually recolour killbrick particles if desired.
	
	* This means that standing still or using animation items will *not* reduce the damage taken.
]==]