--[==[
	These ones are my favourite.
	Ziplines are, similar to real ziplines, a path that the player traverses across when constrained to the ziplines "handle".
	
	Similar to EToH/JToH's v6 kit, and unlike the (as of present) currently released v5.5, these ziplines can be *curved* too.
	These ziplines use what is called a "Catmull-Rom spline," which in laymans terms is basically "curved line that goes through points."
	You can create these points by setting numbered parts in the "Points" folder. 
	
	If you want your zipline to be straight, simply create only one point, set the `Segments` attribute to 2,
	and set the `CurveTension` to as close to 1 as possible. (Setting tension to exactly 1 causes extremely strange bugs for some reason)
	
	The longer your zipline is, the more segments it will need. 
	Note that these segments are purely visual and the curve itself has functionally infinite segments.
	
	Note that *each segment* requires 2 parts to create, so be extremely careful with setting it to very high numbers 
	if you are concerned about part count. Try to strike a good balance.
	
	Attributes:
		- AllowJumpDismount: When true, the player can dismount the zipline at any time by jumping.
		- AllowRoll: when true, the player is able to roll *around* the zipline while traversing it.
			the algorith to determine roll is designed to take the least amount of torque as possible,
			so you may not end up at the end right side up if you use this, but it's there for fun!
		- Controllable: When true, the zipline is controlled via W and S rather than automatically.
			Note that a non-controllable zipline is functionally the same as a controllable one where the player holds W constantly.
		- Cooldown: The time it takes (after jumping on the zipline) for the zipline to allow you to remount it.
			Setting this to 0 will cause a lot of jank.
		- CurveAlpha: The alpha of the curve. This number looseley affects curvature. 
			Change if you're not satisfied with your existing curve.
		- CurveTension: The tension of the curve. Higher tension results in straighter lines (like an elastic band).
		- EndJump: When true, the player will jump when dismounting the zipline automatically.
		- Loops: When true, the zipline will loop on itself and the player will ride along it until dismounted.
		- PreserveMomentum: When true, the player will preseve their momentum when dismounting the zipline.
		- RopeLength: The length of the rope attaching the handle to the zipline. 
			Set to 0 for the handle to be directly on the zipline instead.
		- RopeRestitution: The restitution (elastic recoil) of the rope.
		- Segments: The number of visual segments the zipline has. One segment is equivalent to 2 parts (one cylinder and one sphere).
		- Speed: The speed, in studs/s, that the player traverses across the zipline at.
]==]