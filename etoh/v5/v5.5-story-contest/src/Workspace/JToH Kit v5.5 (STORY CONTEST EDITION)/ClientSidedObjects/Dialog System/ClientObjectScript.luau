--!strict

return function()
	local getDialog: ObjectValue = game.ReplicatedStorage:WaitForChild("DialogModuleInstance")
	local TypewriterModule = getDialog.Value :: ModuleScript
	local Typewriter = require(TypewriterModule) :: any

	local root = script.Parent
	local coRoot: Instance = root.Parent
	local soundPlayers: Instance
	local dialogParts = root:WaitForChild("Parts")
	local localPlayer: Player = game.Players.LocalPlayer
	local dialogDebounce: boolean = false

	local function roundColor(color: Color3): Color3
		return Color3.fromRGB(math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
	end

	local function evaluateToucher(toucher: BasePart, button: BasePart): boolean
		local parent: Instance? = toucher.Parent
		if not parent then return false end

		local ancestor: Instance? = parent.Parent
		local humanoid: Humanoid? = (
			parent:FindFirstChildWhichIsA("Humanoid") or (ancestor and ancestor:FindFirstChildWhichIsA("Humanoid"))
		)
		local playerTouched: Player? = game.Players:GetPlayerFromCharacter(humanoid and humanoid.Parent)

		local partAttributes: { [string]: any } = button:GetAttributes()
		local colorSpecificCheck: boolean = not (
			partAttributes.ColorSpecificCheck and (roundColor(toucher.Color) ~= roundColor(button.Color))
		)

		local playerCheck: boolean = partAttributes.PlayerTouchActivated and (humanoid ~= nil and playerTouched == localPlayer)
		local pushboxCheck: boolean = partAttributes.PushboxTouchActivated
			and (string.lower(toucher.Name) == "pushbox" or toucher:FindFirstChild("IsBox") ~= nil)
			and colorSpecificCheck

		return (playerCheck or pushboxCheck)
	end

	local buttons: { [Color3]: BoolValue } = {}
	local function activateButton(color: Color3)
		if typeof(color) == "Color3" then
			local partColor = roundColor(color)
			for color: Color3, activateValue: BoolValue in buttons do
				if color ~= partColor then continue end
				activateValue.Value = true
			end
		end
	end

	local function toggleSoundPlayer(color: Color3, doActivate: boolean)
		local activateType = if doActivate then "activate" else "deactivate"
		task.spawn(function()
			soundPlayers = soundPlayers or coRoot:WaitForChild("Sound Players", 3)
			if soundPlayers and typeof(color) == "Color3" then
				local event: Instance? = soundPlayers:FindFirstChild("PlaySoundEvent", true)
				if event and event:IsA("BindableEvent") then event:Fire(color, activateType) end
			end
		end)
	end

	for _, part: Instance in dialogParts:GetDescendants() do
		if not part:IsA("BasePart") then continue end

		local dialogConfiguration: Instance? = part:FindFirstChild("__DIALOG__")
		if not dialogConfiguration then continue end

		task.spawn(function()
			local sequences = {}
			for _, dialogSequence in dialogConfiguration:GetChildren() do
				if not dialogSequence:IsA("Configuration") then continue end

				local sequenceOrder: number? = tonumber(string.match(dialogSequence.Name, "%d+"))
				if not sequenceOrder then continue end

				local attributes: { [string]: any } = dialogSequence:GetAttributes()
				local textSequences = {}
				for _, textSequence: Instance in dialogSequence:GetChildren() do
					if not textSequence:IsA("StringValue") then continue end

					local textSequenceOrder: number? = tonumber(string.match(textSequence.Name, "%d+"))
					if not textSequenceOrder then continue end

					local text: string = textSequence.Value
					local textAttributes: { [string]: any } = textSequence:GetAttributes()
					local targetData = {
						Text = text,
						Info = textAttributes,
						Effects = {},
						TypeSound = textSequence:FindFirstChild("TypeSFX"),
					}

                    if (textSequenceOrder > 1) and (not textSequence:GetAttribute("DoNotSpace")) then 
                        targetData.Text = ` {text}` 
                    end

					local intervals = {}
					local function searchForIntervals(instance: Instance)
						local intervalValues: Instance? = instance:FindFirstChild("IntervalMultipliers")
						if intervalValues then
							for _, value: Instance in intervalValues:GetChildren() do
								if not value:IsA("NumberValue") then continue end

								local letter: string = value.Name:sub(1, 1):lower()
								intervals[letter] = value.Value
							end
						end
					end

					searchForIntervals(dialogSequence)
					searchForIntervals(textSequence)
					targetData.Intervals = intervals

					local effects: Instance? = textSequence:FindFirstChild("Effects")
					if effects then
						for _, effectValue: Instance in effects:GetChildren() do
							if not effectValue:IsA("BoolValue") then continue end
							targetData.Effects[effectValue.Name] = { effectValue.Value, effectValue:GetAttributes() :: any } -- am GOnna kill someone ohmygodd
						end
					end

					textSequences[textSequenceOrder] = targetData
				end

				sequences[sequenceOrder] = function()
					local function runDialog()
						Typewriter:Write({
							Texts = textSequences,
							TimeAfter = attributes.RemoveAfter,
							WaitUntilFade = attributes.AwaitTextFade,
							ClearInterval = attributes.ClearInterval,
							UseAlternative = attributes.UseAlternative,
						})
					end

					if typeof(attributes.ActivateButtonBeforeDialog) == "Color3" then
						activateButton(attributes.ActivateButtonBeforeDialog)
					end

					if typeof(attributes.ActivateSoundPlayerBeforeDialog) == "Color3" then
						toggleSoundPlayer(attributes.ActivateSoundPlayerBeforeDialog, true)
					end

					if attributes.AwaitFinish then
						runDialog()
					else
						task.spawn(runDialog)
					end

					task.wait(attributes.DelayAfterFinish)
					if typeof(attributes.StopSoundPlayer) == "Color3" then toggleSoundPlayer(attributes.StopSoundPlayer, false) end
					if typeof(attributes.ActivateButton) == "Color3" then activateButton(attributes.ActivateButton) end
					if typeof(attributes.ActivateSoundPlayer) == "Color3" then
						toggleSoundPlayer(attributes.ActivateSoundPlayer, true)
					end
				end
			end

			local function start()
				local uses = part:GetAttribute("Uses")
				if typeof(uses) == "number" and uses <= 0 then return end
				if dialogDebounce then return end
				dialogDebounce = true

				if typeof(uses) == "number" then
					uses -= 1
					part:SetAttribute("Uses", uses)
				end

				for sequenceOrder, sequenceFunction in sequences do
					sequenceFunction()
				end

				if typeof(uses) == "number" and uses <= 0 then part:Destroy() end
				task.delay(0.1, function() dialogDebounce = false end)
			end

			local buttonActivatedValue: BoolValue
			if part.Name == "ButtonActivatedPlatform" or part:FindFirstChild("ButtonActivated") then
				buttonActivatedValue = Instance.new("BoolValue")
				buttonActivatedValue.Name = "Activated"
				buttonActivatedValue.Parent = part
			end

			local partAttributes: { [string]: any } = part:GetAttributes()
			if partAttributes.PlayerTouchActivated or partAttributes.PushboxTouchActivated then
				part.Touched:Connect(function(toucher: BasePart)
					if buttonActivatedValue and not buttonActivatedValue.Value then return end
					local isEvaluated: boolean = evaluateToucher(toucher, part)
					if not isEvaluated then return end
					if dialogDebounce then return end
					start()
				end)
			end

			if partAttributes.ClickActivated then
				local clickDetector: ClickDetector = Instance.new("ClickDetector", part)
				local clickDistance: number = partAttributes.ClickDistance or 32

				clickDetector.MaxActivationDistance = clickDistance
				clickDetector.MouseClick:Connect(function(player: Player)
					if buttonActivatedValue and not buttonActivatedValue.Value then return end
					if player ~= localPlayer then return end
					if dialogDebounce then return end

					clickDetector.MaxActivationDistance = 0
					start()
					clickDetector.MaxActivationDistance = clickDistance
				end)
			end

			if partAttributes.ProximityActivated then
				local proximityPrompt: ProximityPrompt = Instance.new("ProximityPrompt", part)
				local clickDistance: number = partAttributes.ClickDistance or 32

				proximityPrompt.ActionText = partAttributes.ActionText or "Dialog"
				proximityPrompt.RequiresLineOfSight = false
				proximityPrompt.MaxActivationDistance = clickDistance
				proximityPrompt.Triggered:Connect(function(player: Player)
					if buttonActivatedValue and not buttonActivatedValue.Value then return end
					if player ~= localPlayer then return end
					if dialogDebounce then return end

					proximityPrompt.MaxActivationDistance = 0
					start()
					proximityPrompt.MaxActivationDistance = clickDistance
				end)

				if buttonActivatedValue ~= nil then
					proximityPrompt.Enabled = buttonActivatedValue.Value
					buttonActivatedValue.Changed:Connect(function() proximityPrompt.Enabled = buttonActivatedValue.Value end)
				end
			end
		end)
	end

	for _, part: Instance in root.Parent:GetDescendants() do -- cache all the buttons
		if part:IsA("BasePart") and part:FindFirstChild("Press") then
			local parent: Instance? = part.Parent
			if not parent then continue end

			local pressedValue: Instance? = parent:FindFirstChild("Pressed")
			if not (pressedValue and pressedValue:IsA("BoolValue")) then continue end
			buttons[roundColor(part.Color)] = pressedValue
		end
	end
end
