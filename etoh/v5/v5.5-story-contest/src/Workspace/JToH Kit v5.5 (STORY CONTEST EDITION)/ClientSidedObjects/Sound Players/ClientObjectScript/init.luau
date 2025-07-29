
return function()
	local localPlayer: Player = game.Players.LocalPlayer
	local contentProvider: ContentProvider = game:GetService("ContentProvider")

	local function displayError(info, parent)
		local billboard = script.BillboardGui:Clone()
		billboard.Enabled = true
		billboard.info.Text = info
		billboard.Parent = parent
		warn(`[Sound Player CO]: {info} (`, parent, `)`)
	end

	local function roundColor(color: Color3): Color3
		return Color3.fromRGB(math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
	end

	local function evaluateToucher(part: BasePart, soundPlayer: BasePart, config: Configuration): boolean
		local parent: Instance = part.Parent :: Instance
		if not parent then return false end

		local allowPlayers: BoolValue = config:FindFirstChild("SupportPlayers") :: BoolValue
		local allowPushbox: BoolValue = config:FindFirstChild("SupportPushboxes") :: BoolValue
		local allowTurrets: BoolValue = config:FindFirstChild("SupportTurrets") :: BoolValue
		local allowBallons: BoolValue = config:FindFirstChild("SupportBalloons") :: BoolValue
		local isColorSpecific: boolean = config:FindFirstChild("ColorSpecific") and config.ColorSpecific.Value

		local ancestor: Instance = parent.Parent :: Instance
		local humanoid: Humanoid = (
			parent:FindFirstChildWhichIsA("Humanoid") or ancestor:FindFirstChildWhichIsA("Humanoid")
		) :: Humanoid
		local playerTouched: Player? = game.Players:GetPlayerFromCharacter(humanoid and humanoid.Parent)

		local colorSpecificCheck: boolean = not (isColorSpecific and (roundColor(part.Color) ~= roundColor(soundPlayer.Color)))
		local playerCheck: boolean = allowPlayers and allowPlayers.Value and (humanoid ~= nil and playerTouched == localPlayer)
		local pushboxCheck: boolean = allowPushbox
			and allowPushbox.Value
			and (string.lower(part.Name) == "pushbox" or part:FindFirstChild("IsBox") ~= nil)
			and colorSpecificCheck
		local balloonCheck: boolean = allowBallons
			and allowBallons.Value
			and part.Material == Enum.Material.Neon
			and part:FindFirstChild("BodyVelocity")
			and colorSpecificCheck
		local turretCheck: boolean = allowTurrets and allowTurrets.Value and string.lower(part.Name) == "bullet" and colorSpecificCheck

		return (playerCheck or pushboxCheck or balloonCheck or turretCheck)
	end

	local soundPlayers = {}
	for i, soundPlayer: Instance in script.Parent:GetChildren() do
		if soundPlayer:IsA("BasePart") then
			task.spawn(function()
				local Config: Configuration = soundPlayer:WaitForChild("Configuration", 60) :: Configuration
				if not Config then
					displayError("No configuration found.", soundPlayer)
					return
				end

				local sound: Sound = soundPlayer:FindFirstChildWhichIsA("Sound") :: Sound

				local hasFailed: boolean
				local success: boolean = pcall(function()
					contentProvider:PreloadAsync(
						{ sound },
						function(id: string, fetchStatus: Enum.AssetFetchStatus)
							hasFailed = fetchStatus ~= Enum.AssetFetchStatus.Success
						end
					)
				end)

				if not success then hasFailed = true end

				if not (sound and not hasFailed) then
					displayError("No sound to play.", soundPlayer)
					return
				end

				if sound.TimeLength > 6 then
                    displayError(`This sound is longer than 6 seconds and will not be able to play in JToH, please use a shorter sound.`, soundPlayer)
				else
					if Config:FindFirstChild("Invisible") and Config.Invisible.Value then soundPlayer.Transparency = 1 end
				end

				local debounceTime: NumberValue = Config:FindFirstChild("DebounceTime") :: NumberValue
				local debounce: boolean = false

				local function activate()
					if debounce then return end
					debounce = true
					sound:Play()
					task.wait(debounceTime and debounceTime.Value or sound.TimeLength)
					debounce = false
				end

				local function deactivate() sound:Stop() end

				soundPlayer.Touched:Connect(function(toucher: BasePart)
					if not evaluateToucher(toucher, soundPlayer, Config) then return end
					activate()
				end)

				soundPlayers[soundPlayer] = { activate = activate, deactivate = deactivate }
			end)
		end
	end

	local event: BindableEvent = script:WaitForChild("PlaySoundEvent")
	event.Event:Connect(function(player, type)
		type = type or "activate"
		if typeof(player) == "Color3" then
			for part, activateFunction in soundPlayers do
				if roundColor(part.Color) ~= roundColor(player) then continue end
				task.spawn(activateFunction[type])
			end
		end

		if typeof(player) == "Instance" and soundPlayers[player] ~= nil then soundPlayers[player][type]() end
	end)
end
