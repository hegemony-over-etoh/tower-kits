--[==[
	(sorry in advance if this hurts your brain I tried my best)
	
	Triggers are pieces of functionality that can be chained together to perform logic.
	The intent of these is to reduce the need of pushbox sequencers (lag) and custom client object scripts (accessibility).
	
	Triggers work by first being activated by a certain "activator" trigger (i.e. Touch), 
	and then firing subsequent triggers located in their `Chain` as ObjectValues pointing to the trigger itself.
	Because of this, we can consider the activation of triggers in a sequence a "chain."
	
	Because roblox doesn't support object attributes, arguments to triggers are stored as values. My condolences :(
	General configration for the trigger itself is stored in the trigger itself.
	
	Each trigger contains a `Type` and `Delay` attribute. The former dictating what kind of trigger it is,
	and the latter indicating the time it takes for the trigger to activate the next trigger(s) in the chain.
	
	There is a particularly unique trigger, the Variable trigger, that doesn't behave exactly like that other ones.
	This trigger stores exactly one item, named `Value` which is the information that it stores. 
	Variable triggers can be referenced via ObjectValue as a substitute to any argument.
	
	A NOTE ON ENUM PROPERTIES:
	Since roblox does not have an "EnumValue" for some reason (thanks again!!!),
	Enum properties are declared by a string with the name of the enum value.
	For example, Enum.CameraType.Fixed -> "Fixed"
	
	The list of triggers, their behavior, their arguments, and their configuration can be found below:

	Activate:
		- Activates one or more client objects (if able to).
		- Arguments:
			- ClientObjects: A folder of ObjectValues pointing to the **root instance** of a client object, or a StringValue indicating the tags.
				Note that roblox doesn't select the model itself if you click on it from the viewport, so you need to select it from the explorer.
	Arithmetic:
		- Performs an arithmetic operation on two values.
		- Arguments:
			- Left: The left side of the operation.
			- Right: The right side of the operation.
			- Output: The Variable trigger used to store the result of the operation.
		- Settings:
			- ArithmeticType: The type of operation being performed. The list of operations are as follows:
				- add
				- subtract
				- multiply
				- divide
				- floordivide
				- exponent
				- modulo
	ButtonSet:
		- Sets buttons or button groups to a specific state.
		- Arguments:
			- Buttons: A folder of ObjectValues pointing to the **root model** of a button, or StringValues referring to button groups.
			- Pressed: The state that the buttons will be set to / whether the buttons will be pressed or unpressed.
	Camera:
		- Sets the properites of the current camera. Can be used for cool cinematic stuff
		- Arguments:
			- Properties: List of camera properties to change. Will revert to default values if not specified in this list.
				Only some properties can be modified, which are:
					- CFrame
					- Focus
					- CameraSubject
					- CameraType
					- DiagonalFieldOfView
					- FieldOfView
					- FieldOfViewMode
					- MaxAxisFieldOfView
		- Settings:
			- Tween: When true, will tween properties that can be. 
				(just make another trigger if you want to only tween some stuff PLEASEEE I'm not making this any more complicated)
			- TweenDuration: The length of the tween.
			- TweenEasingStyle: The easing style of the tween.
			- TweenEasingDirection: The direction of the tween easing.
	Compare:
		- Compares two values. Unlike other triggers, will additionally activate triggers located in the `True` or `False` folder 
			based on comparison result.
		- Arguments:
			- Left: The left side of the operation.
			- Right: The right side of the operation.
			- Output: Optional, if existing and set, will set the defined Variable trigger to the result of the comparison.
		- Settings:
			- ComparisonType: The type of comparison being performed. The list of comparisons are as follows:
				- ==
				- ~=
				- >
				- >=
				- <
				- <=
				- and
				- or
				- xor
				- nand
				- nor
				- xnor
	Delay:
		- Does literally nothing. Intended purpose is to allow multiple delays for multiple triggers.
		- TODO: consider making this an attribute of chain values instead?
	Format:
		- Formats any number of values into a string.
		- Arguments:
			- ToFormat: A folder containing values named in numerical order to format into the string.
			- Output: Optional. If set, will output the format string to the defined Variable Trigger. 
				If not set, will print to console instead.
		- Settings:
			- FormatString: The string that will be passed for formatting. This string uses the format character (%) to determine the format.
				See https://create.roblox.com/docs/luau/strings#character-classes for more info.
	Humanoid:
		- Sets the properites of the players humanoid.
		- Arguments:
			- Properties: List of humanoid properties to change. Will revert to default values if not specified in this list.
				Only some properties can be modified, which are:
					- CameraOffset
					- HipHeight
					- MaxHealth
					- PlatformStand
					- RequiresNeck
					- Sit
		- Settings:
			- Tween: When true, will tween properties that can be. 
				(just make another trigger if you want to only tween some stuff PLEASEEE I'm not making this any more complicated)
			- TweenDuration: The length of the tween.
			- TweenEasingStyle: The easing style of the tween.
			- TweenEasingDirection: The direction of the tween easing.
	Jump:
		- Fires chain on jump *request*. Note that this will fire whenever the player *attempts* to jump, not when said jump was successful.
		- Settings:
			- Cooldown: How long it takes for the trigger to listen for jump requests again.
	PropertyGet:
		- Gets a property, attributes included, and assigns it to a variable trigger.
		- Arguments:
			- Target: Target part to get property from
			- Property: Name of property/attribute
			- IsAttribute: If true, will get attribute, if false, will get property (needed since they are gotten differently in code)
			- Output: Variable trigger to assign the value to
	PropertySet:
		- Sets the properties, attributes included, of a list of targets.
		- Arguments:
			- Targets: A folder containing a list of ObjectValues pointing to the instances to be modified.
			- Properties: A folder containing a list of Values, with the name corresponding to the property that will be set.
			- Attributes: A folder containing a list of values, with the name corresponding to the attribute name that will be set.
				Note that attribute changes may not cause a response in the client object, as some are not feasible to do realtime.
			- Tags: A folder containing a list of BoolValues. The name corresponds to the tag name,
				and the value determines whether to add or remove it from the list.
	StateChange:
		- Fires chain on humanoid state change. Can be configured to only allow certain types of transitions from or to
		- Arguments
			- OldState: A folder containing string values corresponding to state enum names. Any state change must transition from one of these values.
			- NewState: A folder containing string values corresponding to state enum names. Any state change must transition to one of these values.
	Touch:
		- Fires chain when touched. Behaves like a touch activated client object, and can thus be configured as so.
		- Arguments:
			- Output: Optional, when existing and set, the part that activated the trigger will be sent to the output variable trigger.
		- Settings:
			- Cooldown: How long it takes after a valid touch for the trigger to listen for touches again.
]==]