--[==[
	!! This object can be activated by triggers!
	Fading parts well, fade when you touch them, additionally toggling their collision.
	
	It is important to note that fading parts *invert* their collision, not set it to false. 
	This means that a part set to be non-collideable will fade *in* to a collideable part instead of fading *out*.
	
	If you don't want faded descendants to have their collision toggled, add an attribute `KeepCollision` set to true.
	The main use case for this is if you want to disable a client object (i.e. an elevator) that is typically not collideable.
	
	**This is a touch activated object. Please read the "Touch Activated Objects" documentation in General Info for additional attributes.**
	Attributes:
		- FadeDescendants: if true, the parent fading part will also fade out all descendant BaseParts in the same fashion.
			Useful for things such as neon fading trusses where you want the inside neon to fade as well.
			Note: This will also toggle the activity of client objects parented to this
		- FadeTime: The time it takes after touching the fading part for it to fully fade and toggle it's transparency.
		- FadeTransparency: The target transparency the part will fade to. Set to 0 if you want a "fade-in" part.
		- RespawnTime: The time it takes, after fading out, for the part to return to it's original state.
		
	Additionally, child `SelectionBox` instances of fading parts have an attribute `FadedColor`,
	which determines what colour the outline will be when a part fades.
]==]