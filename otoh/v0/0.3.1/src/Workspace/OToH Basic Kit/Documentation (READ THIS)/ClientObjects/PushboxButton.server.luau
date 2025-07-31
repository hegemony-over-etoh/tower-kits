--[==[
	!! This object can be activated by triggers!
	Pushbox Buttons spawn and manage an individual pushbox.
	
	Pushboxes are unanchored parts that can be pushed by the player (hence the name) to do anything from pressing buttons to creating obstacles.
	Pushboxes are reset to their original state when respawned by pressing the button,
	making them useful for resetting physics based platforms like rope swings when they get too out of control.
	
	**This is a touch activated object. Please read the "Touch Activated Objects" documentation in General Info for additional attributes.**
	Attributes:
		- Cooldown: The time it takes for subsequent pushbox respawn requests to be recognized after respawning the pushbox.
		- PushboxId: The `Id` that the pushbox is allowed to press. 
			Note that the client object itself is responsible for determining whether or not it wants to enforce this.
		- SpawnPushboxOnLoad: When true, the pushbox will spawn on tower load without the button being pressed.
]==]