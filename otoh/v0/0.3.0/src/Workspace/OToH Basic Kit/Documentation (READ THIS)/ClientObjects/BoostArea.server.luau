--[==[
	Boost Areas are areas in physical space that boost either speed or jump power.

	Attributes:
		- ZoneMode: Determines whether the boost will act as a "boost pad" (standing on it provides the boost) or a "boost zone" (standing *in* it provides the boost).
		- Type: The type of boost the area provides. Either "Jump" for jump power, "Speed" for walk speed, or "Both" for both.
		- Priority: How much precedence this boost area should have over other boost areas. When intersecting two different boost areas, the highest priority area applies.
		- JumpPower/WalkSpeed: The boost that is provided when in the area.
		- Tolerance: The tolerance for the hitbox when not in zone mode.
		- Distance: The distance above the pad where the boost will be applied when not in zone mode.
]==]