--[==[
	!! This object can be activated by triggers!
	Buttons! This one might be a bit of a long one, so bear with me.
	
	Each button in this framework has an atrtibute called `ButtonGroupId` which determines the group the buttons trigger. *Buttons are no longer colour reliant in any way*.
	To add a part or client object to the button group, simply add a tag with the format `ButtonGroup_{id}`. 
	For example, the default button has a button group of 1, so to add a part to the group you would add the tag `ButtonGroup_1`.
	This method is used as it is a much, much faster way to find all associated button parts, and additionally lets you organize your objects however you want.
	
	Parts can additionally override their active/inactive transparencies by adding an `ActiveTransparency` and/or `InactiveTransparency` attribute(s).
	If not set, the parts InactiveTransparency becomes the transparency it's assigned when the tower loads, and ActiveTransparency will become 0.*
	You may override the default behavior of toggling collision by adding and/or setting the attribute `KeepCollision` to true.
	Client objects will not perform their functionality when disabled, and may implement their own custom visual behavior if necessary.
	
	You may add a `_Active` attribute to non-script ccos or toggle the existing `_Active` attribute to false to invert behavior.
	
	You can change the formatting of the button's timer by changing the `TimerFormatString` attribute. This attribute is a bit complicated so bear with me!!!
	You can put text in here normally just fine, but if you want to include the time itself there's a few format strings you can put in.
	The basis of the format text is based on either a contiguous sequence of text with no whitespace or a set of parenthesis that contain one instance of %.
	You can stop the formatter from formatting a % sign by putting two in sequence (%%), which will get replaced by a single one instead.
	You may start these sequences by appending a + or - in front of them (in the case of parenthesis, put outside the parenthesis).
	A plus sign (also default when ommited) indicates no special behavior, 
	but a minus sign indicates that a formatted time that is less than or equal to zero should be ommited entirely. This is why we include additional text in the format.
	The following formats are accepted:
		- %h -> Displays hours
		- %H -> Displays hours (no differing behavior, just here for consistency)
		- %m -> Displays minutes
		- %M -> Displays ABSOLUTE minutes (counts total time instead of excess from previous divisions, i.e. 90 minutes will apear instead of (1 hour and) 30 minutes)
		- %s -> Displays seconds
		- %S -> Displays ABSOLUTE seconds
	You may modify the formats by appending certain numbers before the character and after the percent sign.
	Appending a number without anything else will designate "padding" to apply to the number to make it a constant length.
	For example, %2h will always display two digits, so 2 becomes 02, 3 becomes 03, etc...
	Appending a decimal point (.) and then a number indicates the precision you want the number to be displayed at past the decimal point.
	By default, this is 0, and the number is additionally *floored* instead of rounded. (.0 is different behavior from a simple omission as it rounds instead).
	
	Since I think this is hard topic to understand (and I believe I am poor at conveying it), here are some examples:
		- Default button: -%hh -%mm -%.1ss
		- HH:MM:SS.SS format (i.e. 01:23:45.67): (%2h):(%2m):(%2.2s)
			- Note we add the parenthesis to split up the contiguous block since we are not using spaces here.
		- Replicating EToH/JToH buttons: %.1S
	
	**This is a touch activated object. Please read the "Touch Activated Objects" documentation in General Info for additional attributes.**
	Buttons have a few extra attributes you can set in addition:
		- HoldButton: When true, button will only be active when being actively pressed.
		- Pressed: While mostly used at runtime, you can *technically* start a tower off with a pressed button instead of an unpressed one.
		- PressOffset: The amount of studs down a button goes when pressed.
		- Timer: When *above 0*, will cause the button to unpress itself after the specified amount of seconds.
		- TransitionDuration: How long it takes for part properties to tween themselves when transitioning from active<->inactive.
		
	* Technically if the button is marked `Pressed` at loadtime, the loadtime assignment is inverted and InactiveTransparency becomes 0.3
]==]