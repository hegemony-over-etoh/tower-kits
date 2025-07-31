--[==[
	Beat Blocks are groups of parts that alternate between each other on a set interval.
	
	To create groups, add folders to the BeatBlocks folder corresponding to each number in the series.
	In the default kit object templates, for example, there are folders labelled from 1-4. These will activate in sequential order.
	The names of the parts *do not* matter.
	
	Beatblocks *alternate* their collision when enabled/disabled, meaning that to create a beatblock that isn't collideable *when active*
	you would set it's `CanCollide` property to `true` in studio.
	
	Attributes:
		- IndicationDuration: The time (in seconds) prior to switching beatblocks that will be indicated by scale/transparency changes.
		- Interval: The time (in seconds) between beatblock switches.
		- OffScale: The scale of the beatblock as a multiplier to it's original size that the beatblock will be when off.
		- OffTransparency: The transparency of a beatblock when inactive.
		- OnTransparency: The transparency of a beatblock when active.
		- PlaySound: When true, the beatblock will run checks to determine whether to play the `Ding` sound or not.
			note that this incurs a slight performance cost and should be disabled if indication is unnecessary.
		- IndicateWithScale: When true, edit scale to indicate imminent beatblock changes
		- IndicateWithTransparency: When true, edit transparency to indicate beatblock changes
		- IndicationScaleOffset: The offset from the target scale the scale indication switches to. 
			(adds for next beatblock, subtracts for current beatblock)
		- IndicationTransparencyOffset: The offset from the target transparency the transparency indication switches to.
			(subtracts for next beatblock, adds for current beatblock)*
		- KeepCollision: When true, beatblocks will not have their collision modified on transition. Useful for purely visual beatblock effects.
			
	`OffScale`, `OffTransparency`, and `OnTransparency` can additionally be set as attributes on individual parts or folders
	to override the values set by the model.
	
	* Inverted because the next beatblock should become more opaque/less transparent
]==]