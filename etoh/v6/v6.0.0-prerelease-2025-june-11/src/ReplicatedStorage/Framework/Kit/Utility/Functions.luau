--!strict

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--[=[
    @class Functions
    @client
    A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.
    
]=]
local Functions = {}
local Config = require(script.Parent.Config)

--[=[
	@within Functions
	@tag shorthand
	
	Shorthand for [HttpService:GenerateGUID()](https://create.roblox.com/docs/reference/engine/classes/HttpService#GenerateGUID). 
	```lua
	utility.generateUID()
	--> 4BA80F4637244B4BBA957E28B9443DE9
	```
]=]
function Functions.generateUID(curlyBraces: boolean?): string
	return HttpService:GenerateGUID(curlyBraces or false):gsub("-", "")
end

--[=[
    @within Functions
    @tag shorthand
    @param easingStyle Enum.EasingStyle? --[EasingStyle](https://create.roblox.com/docs/reference/engine/enums/EasingStyle)
    @param easingDirection Enum.EasingDirection? --[EasingDirection](https://create.roblox.com/docs/reference/engine/enums/EasingDirection)
    
    Simple tween function that handles garbage collection properly.
    
    ```lua
    utility.tween(part, 0.5, {
        Color = Color3.fromRGB(255, 0, 0)
    })
    ```
]=]
function Functions.tween(
	instance: Instance,
	config: number | typeof(Config.TWEEN_CONFIG),
	goal: { [string]: any },
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?,
	...: any
): Tween
	local tweenObject = TweenService:Create(
		instance,
		if typeof(config) == "number"
			then TweenInfo.new(
				config,
				(if typeof(easingStyle) == "EnumItem" then easingStyle else Enum.EasingStyle.Linear),
				(if typeof(easingDirection) == "EnumItem" then easingDirection else Enum.EasingDirection.Out),
				...
			)
			else TweenInfo.new(config.Time, config.Style, config.Direction),
		goal
	)
	tweenObject.Completed:Once(function()
		tweenObject:Destroy()
	end)
	tweenObject:Play()
	return tweenObject
end

--[=[
    @within Functions
    
    Plays a sound with the given `soundName` from the given `container`
    at the `instance`'s location. If the sound doesn't exist, `fallbackSound`
    will be used instead if set.
]=]
function Functions.playSoundFromInstance(
	instance: Instance,
	container: Instance,
	soundName: string,
	fallbackSound: Sound?
): Sound?
    local sound = container:FindFirstChild(soundName) or fallbackSound
	if instance and sound and sound:IsA("Sound") then
		local newSound = sound:Clone()
		newSound.Parent = instance
        newSound:Play()
        Debris:AddItem(newSound, (newSound.TimeLength / newSound.PlaybackSpeed) + 1)
		return newSound
	end

	return
end

--[=[
    @within Functions
    @tag shorthand
    
    Rounds the provided `color` to remedy rounding errors that cause issues
    on some devices when comparing two `Color3` values.
]=]
function Functions.roundColor(color: Color3): Color3
	return Color3.fromRGB(math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

--[=[
    @within Functions
    
    Runs a function, and cancels it after the specified timeout duration if it
    hasn't finished by then.
]=]
function Functions.yieldTimeout<A..., T...>(timeout: number, fn: (A...) -> T..., ...: A...): T...
	local runningThread = coroutine.running()
	local thread = task.defer(function(...)
		task.spawn(runningThread, fn(...))
	end, ...)

	task.delay(timeout, function()
		if coroutine.status(thread) ~= "dead" and coroutine.status(runningThread) == "suspended" then
			warn("Function timed out")
			task.cancel(thread)
			task.spawn(runningThread)
		end
	end)

	return coroutine.yield()
end

return table.freeze(Functions)
