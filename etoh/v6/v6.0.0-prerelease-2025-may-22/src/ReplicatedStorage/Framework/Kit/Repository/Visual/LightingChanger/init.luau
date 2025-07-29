--!strict
--!optimize 2
--@version lightingchanger-6.0.0
--@creator synnwave

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local VALID_CHANGER_PREFIXES = {
	PlaceDefault = true,
	TowerDefault = true,
}

return function(scope: _T.Scope)
	local changerConfig = scope.instance
	if not changerConfig or not changerConfig.Parent then
		return
	end

	local utility = scope:utility()
	local Config = utility.Config
	local lightingPointer = utility.Instance.getPointer(changerConfig:FindFirstChild("Lighting"))
	if not lightingPointer or not lightingPointer:IsA("ModuleScript") then
		scope:log({
			"Lighting Changer is missing it's 'Lighting' module.",
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local changer = changerConfig.Parent
	if not changer:IsA("BasePart") then
		scope:log({
			"Changer must be a BasePart",
			`Path: {changer:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local lightingData = require(lightingPointer) :: any
	if typeof(lightingData) ~= "table" then
		scope:log({
			`Lighting Changer's lighting module returned "{typeof(lightingData)}", expected table`,
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
	end

	if lightingData[1] == nil then
		-- To make things a little easier later on, wrap the config in a table
		lightingData = { lightingData }
	end
	if #lightingData > 0 then
		-- Validate multi lighting changer config
		local tweenInfo = lightingData.TweenInfo
		local useDefault = lightingData.UseDefault
		local setDefault = lightingData.SetDefault

		for i, changer in lightingData do
			if typeof(i) ~= "number" then
				lightingData[i] = nil -- Not a lighting config, remove
				continue
			end

			-- Validate the lighting config
			if typeof(changer) ~= "table" or typeof(changer.Type) ~= "string" then
				scope:log({
					"Malformed lighting changer config",
					`Path: {changerConfig:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				lightingData[i] = nil
				continue
			end

			-- Set Properties
			if tweenInfo ~= nil and changer.TweenInfo == nil then
				changer.TweenInfo = tweenInfo
			end
			if useDefault ~= nil and changer.UseDefault == nil then
				changer.UseDefault = useDefault
			end
			if setDefault ~= nil and changer.SetDefault == nil then
				changer.SetDefault = setDefault
			end

			if changer.UseDefault and not VALID_CHANGER_PREFIXES[changer.UseDefault:sub(1, 12)] then
				scope:log({
					`Malformed lighting changer config (UseDefault = {changer.UseDefault})`,
					`Path: {changerConfig:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				lightingData[i] = nil
				continue
			end
			if changer.SetDefault and not VALID_CHANGER_PREFIXES[changer.SetDefault:sub(1, 12)] then
				scope:log({
					`Malformed lighting changer config (SetDefault = {changer.SetDefault})`,
					`Path: {changerConfig:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				lightingData[i] = nil
				continue
			end
		end
	end

	local function changeLighting()
		for _, lighting in lightingData do
			utility.Lighting.changeLighting(lighting, scope)
		end

		local lightingTween = if lightingData[1] then lightingData[1].TweenInfo else nil
		task.wait(if lightingTween then lightingTween.Time else 1)
	end

	local touchConfiguration =
		Config.GetConfig(scope, changerConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:CheckForChanges()

	scope:attach(changer)
	local debounce = false
	scope:add(changer.Touched:Connect(function(toucher: BasePart)
		if debounce or changer:GetAttribute("Activated") == false then
			return
		end
		if not utility.ClientObjects.evaluateToucher(changer, toucher, touchConfiguration) then
			return
		end
		debounce = true
		task.delay(0.25, function()
			debounce = false
		end)

		changeLighting()
	end))
end
