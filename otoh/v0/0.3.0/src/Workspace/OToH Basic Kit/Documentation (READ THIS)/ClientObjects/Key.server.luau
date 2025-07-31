--[==[
	!! This object can be activated by triggers!
	Keys are collectible objects that can be used to open Key Doors.
	
	Keys are assigned a `KeyId` by the model and will only open Key Doors with a corresponding `KeyId`.
	To create custom key models, simply name an *anchored* model to `KeyModel` and place it as a child of the Key object model.
	`KeyHitbox` is the hitbox that the player must touch to collect the key.
	
	Since the key is mostly visual and rigid in said visuals for technical reasons, the only real attribute is the `KeyId`.
	
	**This is a touch activated object. Please read the "Touch Activated Objects" documentation in General Info for additional attributes.**
]==]