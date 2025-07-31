--[==[
	!! This object can be activated by triggers!
	A Morpher is a set of buttons that modify the size, position, and material of a group of parts via tweens.
	
	The morpher parts themselves must be placed inside a folder named `MorphParts`. 
	Ensure each part has a unique name to avoid undefined behavior.
	
	To create new morph targets, create a new folder in `MorphTargets` with the name of your target group.
	Then, place a part corresponding to each morph part in this folder. Ensure the names match up correctly.
	(i.e. MorphParts.Foo will inherit the properties of MorphTargets.Example1.Foo)
	Set the properties you wish to set, excluding transparency. 
	Transparency is not a currently supported property, so keep your parts invisible when done.
	Then, create a new button in the `Buttons` folder with the name of the group it is targeting.
	You can see a visual layout of this structure in the kit morpher template.
	
	**This is a touch activated object. Please read the "Touch Activated Objects" documentation in General Info for additional attributes.**
	Attributes for morphers are set by the buttons themselves, and are as follows:
		- MorphDuration: The time, in seconds, the morph is active before resetting to the original morph locations. Set to -1 to disable.
		- MorphSpeed: The time it takes, in seconds, for the morph parts to tween to the target.
		- OnColor: The color of the morph button while active.
		- ReturnSpeed: The time, in seconds, it takes for timed morph parts to "retract" back to the original morph locations.
		- EasingStyle/EasingDirection: Tween styling for the movement of the morpher parts.
		- ReturnEasingStyle/ReturnEasingDirection: Ditto but for the retract rather than activation.
]==]