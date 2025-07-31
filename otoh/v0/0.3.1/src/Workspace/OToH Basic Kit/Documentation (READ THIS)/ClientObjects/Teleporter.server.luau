--[==[
	Teleporters, well, teleport the player.
	Place parts named "Teleporter" in the model for parts you wish to be "senders."
	Place parts named "Destination" in the model for parts you wish to be "recievers."
	Teleporters are one way, so you can only go from Teleporter -> Destination, not the other way.
	If there is more than one destination, the destination will be picked at random.

	**This is a touch activated object. Please read the "Touch Activated Objects" documentation in General Info for additional attributes.**
	Attributes:
		- KeepVelocity: Determines if the player should retain the velocity they were at prior to entering the teleporter
		- Seamless: Determines if the player should keep their relative CFrame to the center of the teleporter prior to entering.
			In layman's terms the player will i.e. teleport to the top right of the destination if they entered the top right of the teleporter.
		- TeleportPlayers/TeleportPushboxes: Determines whether the teleporters will teleport either category.
		- TransitionTime: If above 0, will take `TransitionTime` seconds to "pull" the player from teleport to destination via tweening.
		- TranstionEasingDirection/TransitionEasingStyle: Modifiers to the curve and direction of the tween. Ignore these unless you know what you're doing.
		
	Teleporter and Destination parts have an attribute named "Invisible" that will make the part invisible at runtime when ticked.
	Destination parts have an addtional "Offset" attribute that determines how far from the center the teleport will be at.
]==]