--[==[
	Flip parts flip the player when the flip key (F on Desktop, X Button on Console, screen tap on Mobile) is pressed.
	A "Flip" is a reflection across the center of the origin point (the flip part itself by default),
	done by essentially rotating the player around the part by 180 degrees.
	(This is hard to explain, just try it yourself and you'll understand!)
	
	Unfortunately, since roblox has still not implemented an object attriubute 3 years after attributes were released,
	this is the only situation where a value is used. If "TeleportTo" is set to a value other than being left empty,
	the player will instead teleport to that part instead of flipping across the flip part.
	
	Attributes:
		- IncludeOffsetWhenTeleporting: If true, the player will also flip around the part when teleporting.
		- Priority: If the player is intersecting multiple flip parts, the one with the highest priority will take precedence.
]==]