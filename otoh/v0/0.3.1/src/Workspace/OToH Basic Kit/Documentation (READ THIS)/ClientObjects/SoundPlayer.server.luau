--[==[
	!! This object can be activated by triggers!
	Sound Players play a sound when touched.
	The sound played is determined by the `Sound` child of the sound player.
	Note that if your sound effect is longer than 6 seconds, it will be unusable in OToH unless the audio file is provided.
	Even then, it's cumbersome, so try to avoid it.
	
	**This is a touch activated object. Please read the "Touch Activated Objects" documentation in General Info for additional attributes.**
	Attributes:
		- Cooldown: The time it takes for the sound player to play another sound after playing one.
		- GlobalEmission: If true, the sound will play globally. If false, the sound will be emit from the sound player.
		- OneTimeUse: If true, the sound player will remove itself after playing one sound.
]==]