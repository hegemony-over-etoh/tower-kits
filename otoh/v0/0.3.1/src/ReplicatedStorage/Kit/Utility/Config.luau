--!strict
-- junekept 2025
-- this script was originally made for OToH

--[==[
	contains global config options for kit functionality. 
	changing anything here would consitute changes that are not replicated in-game, so I'd suggest leaving this be unless you know what you're doing
]==]

return {
	-- Whether or not to use `PreRender` for continuous checks or not. If set to false, will use `updateInterval` instead.
	-- Default: false (reason: tying updates to `PreRender` may cause slightly different behavior on different framerates to advantage or disadvantage)
	updateOnPreRender = false,
	-- The interval of updates for continuous checks when `updateOnPreRender` is false.
	-- Default: 1/60 (60fps)
	updateInterval = 1/60,
	-- The amount of debounce or "i-frame" time between each hit of a killbrick.
	-- Set in here because killbricks should have consistent i-frames to avoid confusion.
	-- Default: 0.5 (seconds)
	killbrickDebounceTime = 0.5,
	-- The distance between keys (and the character, by extension)
	-- Default: 8 (studs)
	keyDistance = 8,
	-- The precision between "increments" of the keys.
	-- The higher the increment, the more interpolation the script will have to do, thus causing less precision
	-- The lower the increment, the more caching the script will have to do, thus causing more memory usage.
	-- Note: can't get the lerp to work properly so lower increments result in jittery movement
	-- Default: 0.01 (Studs)
	keyIncrement = 0.01,
	-- The maximum amount of segments that will be recorded for keys.
	-- The total distance (assuming no teleports) of the key path can be found by multiplying this value by `keyIncrement`.
	-- One cached position is ~24 bytes, so do take note of that when setting the cache size very high.
	-- Default: 10000 (100 studs assuming defaults, ~240kb)
	keyCacheSize = 10000,
	-- The rate, in radians, that keys rotate per second
	-- Default: math.pi
	keyRotateRate = math.pi,
	-- The maximum amount of keys to render
	-- Default: 5
	keyRenderLimit = 5
}