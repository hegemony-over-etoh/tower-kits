--[==[
	!! This object can be activated by triggers!
	Lighting changers change the game lighting or lighting effects.
	
	The list of modifiable properties that can be edited:
		Lighting -> `Ambient`, `OutdoorAmbient`, `FogEnd`, `FogStart`, `FogColor`, `ClockTime`, `Brightness`
		BloomEffect -> `Intensity`, `Size`, `Threshold`
		BlurEffect -> `Size`
		ColorCorrectionEffect -> `Brightness`, `Contrast`, `Saturation`, `TintColor`
		DepthOfFieldEffect -> `FarIntensity`, `FocusDistance`, `InFocusRadius`, `NearIntensity`
		
	**This is a touch activated object. Please read the "Touch Activated Objects" documentation in General Info for additional attributes.**
	Lighting changers are activated by touch, and the attributes are as follows:
		- Type: The type of lighting or lighting effect to change, 
			either Lighting, BloomEffect, BlurEffect, ColorCorrectionEffect, or DepthOfFieldEffect.
		- TransitionTime: The time it takes to tween the lighting to the target properties.
		- TransitionEasingStyle: The EasingStyle of the property tween. If you don't know what this does, ignore it.
		- TransitionEasingDirection: The EasingDirection of the property tween. If you don't know what this does, ignore it.
		
	To modify properties, create an attribute with the name of the property prefixed by "Property_".
	For example, `Property_Brightness` will set the brightness property.
	If a property is invalid, it will be ignored.
	If a property is not set, it will be set to the default value, which is the lighting as of tower load.
]==]