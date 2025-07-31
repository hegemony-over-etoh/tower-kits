--[==[
	Client objects are the meat of the kit and likely the reason why you are using it in the first place.
	These are essentially just parts with special behavior, dubbed "Client Objects" because they are client sided (load per player).
	Compared to other tower games (as of writing this documentation), the way these are set up is different in a few key ways:
		- **Client objects no longer need a `ClientObject` value**. The entire folder gets copied with no weird rules.
		- **Client objects no longer use value objects, and instead use attributes**.
			To access attributes, simply scroll to the bottom of the property tab of a selected instance.
			
	You may delay the loading of a client object by adding a `LoadDelay` attribute, which is measured in seconds.
	You may override the transparency of an object at load time by setting the `LoadTransparency` attribute. 
	This is useful for being able to identify fully transparent parts in studio, but to have them be truly invisible ingame.
	
	Please read the `ClientObjects` documentation folder to understand how to use each object.
	
	FOR PEOPLE WHO WANT TO MAKE THEIR OWN CLIENT OBJECTS:
	Client objects in this kit **no longer hold their own scripts** instead, they point to a script name in a "Repository"
	that will return the function that dictates their behavior. On top of being better on performance, it has the added
	benefit of allowing shared state between all client objects of the same type (for example, killbricks can now have a
	global cooldown). If you want to create your own client object, or modify existing ones, you will have to create a new
	script in `ReplicatedStorage.Kit.Repository` and edit the `_Script` attribute of a client object. Objects that contain
	scripted functionality are denoted by default with the `_Script` attribute, so no further modification is necessary.
	
	Default kit objects use the `Trove` library in order to make cleanup easier, so functions are not passed the object directly.
	Instead, they are passed a table with three values, `instance`, `trove` and `signals`.
	`instance` contains the client object as an instance in the workspace itself, and is likely what you will use the most.
	`trove` is the trove object from the `Trove` library that can be used for helping with cleanup if desired. The trove
	gets destroyed with the part.
	`signal` contains a list of signals (from the `LemonSignal` library, functionally identical to BindableEvents) that can be
	used for cross-object communication. It's up to you to figure out how you want to implement said communication, though.
]==]