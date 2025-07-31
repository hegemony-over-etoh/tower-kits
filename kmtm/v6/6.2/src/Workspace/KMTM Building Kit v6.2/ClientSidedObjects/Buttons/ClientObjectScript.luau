--yup i redid this entire script :D

--got rid of the inverted button feature because its useless and made this script much more complicated
--note that you can easily use button deactivators instead for the same effect

local tweenService = game:GetService("TweenService")
local debris = game:GetService("Debris")
local players = game:GetService("Players")
local coFolder = script.Parent:FindFirstAncestor("ClientSidedObjects") or script.Parent:FindFirstAncestor("ClientParts")

local cache = {
	ButtonActivatedPlatforms = {},
	Buttons = {},
}

local simpleTransparencyTypes = { --things that can have their transparency tweened
	Decal = "Transparency",
	Texture = "Transparency",
	SelectionBox = "Transparency",
	SelectionSphere = "Transparency",
	Frame = "BackgroundTransparency",
	CanvasGroup = "GroupTransparency",
	TextLabel = "TextTransparency",
	ImageLabel = "ImageTransparency",
	UIStroke = "Transparency",
	UIGradient = "Transparency",
}

local otherTypes = { --these will just have their enabled property change instead of being tweened
	"Beam",
	"ParticleEmitter",
	"Fire",
	"Sparkles",
	"Smoke",
	"Trail",
}

local function tween(part,twTime,inf,es,ed)
	local tweeninf=TweenInfo.new(
		twTime,
		((es ~= nil and es) or Enum.EasingStyle.Linear),
		((ed ~= nil and ed) or Enum.EasingDirection.Out)
	)
	local tw=tweenService:Create(part,tweeninf,inf)
	tw:Play()
	tw.Completed:Connect(function()
		tw:Destroy()
	end)
end

local function configCheck(config, configValue)
	local foundValue = config:FindFirstChild(configValue)
	if foundValue == nil then return false end

	return (foundValue:IsA("ValueBase") and not (foundValue:IsA("BoolValue") and foundValue.Value == false))
end

local function roundColor(color)
	return Color3.fromRGB(math.floor(color.r*255 + 0.5),math.floor(color.g*255 + 0.5),math.floor(color.b*255 + 0.5))
end

local function attachTimer(targetButton, textLabel)
	local effectGui = players.LocalPlayer.PlayerGui:FindFirstChild("EffectGUI")
	if effectGui == nil then return end

	local screenTxt=textLabel:Clone()
	local c=targetButton.ButtonPart.Color
	if textLabel:FindFirstChild("DefaultColor") then --special default color
		screenTxt.TextColor3=c
		screenTxt.TextStrokeColor3=Color3.new(1-c.r,1-c.g,1-c.b)
	end
	screenTxt.TextStrokeTransparency=0
	screenTxt.Parent=effectGui.List

	local changeFunction
	changeFunction = textLabel.Changed:Connect(function()
		if not textLabel or not textLabel.Parent then
			screenTxt:Destroy() 
			changeFunction:disconnect()
			return 
		end
		screenTxt.Text=textLabel.Text
	end)
end

local function updatePlatforms(targetButton, bool)
	local alreadyActivated = false
	
	for _,btn in pairs(cache.Buttons) do
		if btn == targetButton or roundColor(btn.ButtonPart.Color) ~= roundColor(targetButton.ButtonPart.Color) then continue end
		local targetBtnTimer = (configCheck(targetButton.Configurations,"Timer") and targetButton.Configurations.Timer.Value > 0.01)
		local btnTimer = (configCheck(btn.Configurations,"Timer") and btn.Configurations.Timer.Value > 0.01)

		local pressed = btn:FindFirstChild("Pressed")
		if pressed ~= nil then
			if pressed.Value == true then
				alreadyActivated = true
			elseif not (targetBtnTimer or btnTimer) then
				pressed.Value = bool
			end
		end
	end

	if alreadyActivated == true then return end

	local partsActivated = 0
	local partBuffer = 64

	for _,plat in pairs(cache.ButtonActivatedPlatforms) do
		local platBool = bool
		if plat:FindFirstChild("Invert") then
			platBool = not platBool
		end

		local currentColor = plat.Color
		local override = plat:FindFirstChild("ColorOverride")
		if override ~= nil then
			currentColor = override.Value
		end
		currentColor = roundColor(currentColor)
		if currentColor ~= roundColor(targetButton.ButtonPart.Color) then continue end

		local enabledTransparency = (plat:FindFirstChild("SetTransparency") and plat.SetTransparency.Value) or 0
		local disabledTransparency = (plat:FindFirstChild'FullHide' and 1 or .6)

		local newTransparency = (platBool == true and enabledTransparency) or disabledTransparency

		for _,desc in pairs(plat:GetDescendants()) do --rip "asfd", you may or may not be missed
			for objectType,property in pairs(simpleTransparencyTypes) do
				if desc:IsA(objectType) then
					tween(desc,.3,{[property]=newTransparency})
				end
			end
			for _,objectType in pairs(otherTypes) do
				if desc:IsA(objectType) then
					desc.Enabled = platBool
				end
			end
			if desc.Name == "Activated" and desc:IsA("BoolValue") then
				desc.Value = platBool
			end
		end

		if not (plat:FindFirstChild("IgnoreCanCollide") or plat:FindFirstChild("IgnoreAll")) then
			plat.CanCollide = platBool
		end

		if not (plat:FindFirstChild("IgnoreTransparency") or plat:FindFirstChild("Invisible") or plat:FindFirstChild("IgnoreAll")) then
			tween(plat,.3,{Transparency=newTransparency})
		end

		partsActivated += 1
		if (partsActivated % partBuffer) == 0 then
			task.wait()
		end
	end
end

local function evaluateToucher(targetButton, touch)
	if not touch.Parent then return false end
	
	local config = targetButton.Configurations

	local yesplr = (configCheck(config,"SupportPlayers") and players:GetPlayerFromCharacter(touch.Parent) == players.LocalPlayer)
	local colorSpecific = not (configCheck(config,"ColorSpecific") and (roundColor(touch.Color) ~= roundColor(targetButton.ButtonPart.Color)))
	local yesbox = (configCheck(config,"SupportPushboxes") and (touch.Name == "Pushbox" or touch:FindFirstChild("IsBox") ~= nil) and colorSpecific)
	local yesballoon = (configCheck(config,"SupportBalloons") and touch.Name == "Part" and touch.Material == Enum.Material.Neon and touch:FindFirstChild("BodyVelocity") and colorSpecific) --this bool is so long :(
	local yesturret = (configCheck(config,"SupportTurrets") and touch.Name == "Bullet" and colorSpecific)

	return (yesplr or yesbox or yesballoon or yesturret)
end


return function()
	for _,plat in pairs(coFolder:GetDescendants()) do --add any platforms existing before this script runs
		if plat:IsA("BasePart") and (plat.Name == "ButtonActivatedPlatform" or plat:FindFirstChild("ButtonActivated") ~= nil) then
			table.insert(cache.ButtonActivatedPlatforms,plat)
		end
	end
	
	coFolder.DescendantAdded:Connect(function(plat) --add any newly added button platforms
		if plat:IsA("BasePart") and (plat.Name == "ButtonActivatedPlatform" or plat:FindFirstChild("ButtonActivated") ~= nil) then
			table.insert(cache.ButtonActivatedPlatforms,plat)
		end
	end)
	
	coFolder.DescendantRemoving:Connect(function(plat)
		local index = table.find(cache.ButtonActivatedPlatforms,plat)
		if index ~= nil then
			table.remove(cache.ButtonActivatedPlatforms,index)
		end
	end)

	for _,btn in pairs(script.Parent:GetDescendants()) do
		if btn:IsA("Model") and (btn.Name == "Button" or btn.Name == "ClickButton") then
			local buttonPart = btn:FindFirstChild("ButtonPart")
			local pr = btn:FindFirstChild("Pressed")
			local config = btn:FindFirstChild("Configurations")
			
			if buttonPart == nil or pr == nil or config == nil then continue end
			
			table.insert(cache.Buttons,btn)
			local sound = buttonPart:FindFirstChild("Press")
			local totalPresses = 0
			local debounce = false
			local originalCF = buttonPart.CFrame
			local pressOffset = (configCheck(config, "ButtonPressOffset") == true and config.ButtonPressOffset.Value) or .75
			local pressedCF = originalCF * CFrame.new(0,-buttonPart.Size.Y*pressOffset,0)
			
			updatePlatforms(btn,false)
			pr:GetPropertyChangedSignal("Value"):Connect(function()
				totalPresses += 1
				buttonPart.Material = (pr.Value == true and 'Neon') or 'Metal'
				if buttonPart.Anchored == true then
					tween(buttonPart,1,{CFrame = (pr.Value == true and pressedCF) or originalCF})
				end
				if pr.Value == true then sound:Play() end
				updatePlatforms(btn,pr.Value)
			end)
			
			if buttonPart:FindFirstChild("ClickDetector") then
				local clrq = config.ClicksRequired.Value
				clrq -= 1
					buttonPart.ClickDetector.MouseClick:Connect(function(plr)
						
						if clrq == 0 then
							local t = plr.Character:WaitForChild("HumanoidRootPart")
							if evaluateToucher(btn, t) == true and pr.Value == false and debounce == false then
								pr.Value = true
								debounce = true
								task.delay(.15,function()
									debounce = false
								end)

								local useTimer = (configCheck(config,"Timer") == true and config.Timer.Value > 0.01)
								local useTimerText = (configCheck(config,"TimerText") == true and string.len(config.TimerText.Value) > 0)

								if useTimer then
									if btn:FindFirstChild("TimerLabel") == nil then return end

									local originalTotal = totalPresses
									
									local oct = nil
									if buttonPart:FindFirstChild("Cursor") then
										oct = buttonPart.Cursor.Cursor.ImageTransparency
										buttonPart.Cursor.Cursor.ImageTransparency = 1
									end
									
									local surfaceGui = Instance.new("SurfaceGui",buttonPart)
									surfaceGui.Face = Enum.NormalId.Top
									surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
									surfaceGui.PixelsPerStud = 25

									local label = btn.TimerLabel:Clone()
									label.Parent = surfaceGui
									if label:FindFirstChild("DefaultColor") and label.DefaultColor.Value then --special default color
										local c = buttonPart.Color
										label.TextColor3=Color3.new(1-c.r,1-c.g,1-c.b)
									end

									if useTimerText then
										label.Text = string.gsub(config.TimerText.Value,"`",config.Timer.Value) --any of these "`" characters will be reformatted as the timer value
									else
										label.Text = config.Timer.Value
									end
									surfaceGui.Parent=buttonPart
									if configCheck(config,"HideGUI") == true then
										surfaceGui.Enabled = false
									else
										attachTimer(btn,label)
									end

									local step = 1
									local stepValue = config.Timer:FindFirstChild("Step")
									if stepValue ~= nil and stepValue.Value > 0 then
										step = stepValue.Value
									end

									for i=config.Timer.Value,step,-step do
										if totalPresses ~= originalTotal then break end
										i = math.round(i * 1000) / 1000 --round to 3 decimals just in case a weird floating point error occurs
										if useTimerText then
											label.Text = string.gsub(config.TimerText.Value,"`",i)
										else
											label.Text=i
										end
										task.wait(step)
									end
									surfaceGui:Destroy()
									if totalPresses==originalTotal then pr.Value=false end
									
									if buttonPart:FindFirstChild("Cursor") then
										buttonPart.Cursor.Cursor.ImageTransparency = oct
									end
								end
							end
						else
							print(clrq)
							clrq -= 1
							print(clrq)
				end
						end)
				
				
			else
				buttonPart.Touched:Connect(function(t)
					if evaluateToucher(btn,t) == true and pr.Value == false and debounce == false then
						pr.Value = true
						debounce = true
						task.delay(.15,function()
							debounce = false
						end)

						local useTimer = (configCheck(config,"Timer") == true and config.Timer.Value > 0.01)
						local useTimerText = (configCheck(config,"TimerText") == true and string.len(config.TimerText.Value) > 0)

						if useTimer then
							if btn:FindFirstChild("TimerLabel") == nil then return end
							
							local originalTotal = totalPresses
							
							local surfaceGui = Instance.new("SurfaceGui",buttonPart)
							surfaceGui.Face = Enum.NormalId.Top
							surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
							surfaceGui.PixelsPerStud = 25
							
							local label = btn.TimerLabel:Clone()
							label.Parent = surfaceGui
							if label:FindFirstChild("DefaultColor") and label.DefaultColor.Value then --special default color
								local c = buttonPart.Color
								label.TextColor3=Color3.new(1-c.r,1-c.g,1-c.b)
							end

							if useTimerText then
								label.Text = string.gsub(config.TimerText.Value,"`",config.Timer.Value) --any of these "`" characters will be reformatted as the timer value
							else
								label.Text = config.Timer.Value
							end
							surfaceGui.Parent=buttonPart
							if configCheck(config,"HideGUI") == true then
								surfaceGui.Enabled = false
							else
								attachTimer(btn,label)
							end

							local step = 1
							local stepValue = config.Timer:FindFirstChild("Step")
							if stepValue ~= nil and stepValue.Value > 0 then
								step = stepValue.Value
							end

							for i=config.Timer.Value,step,-step do
								if totalPresses ~= originalTotal then break end
								i = math.round(i * 1000) / 1000 --round to 3 decimals just in case a weird floating point error occurs
								if useTimerText then
									label.Text = string.gsub(config.TimerText.Value,"`",i)
								else
									label.Text=i
								end
								task.wait(step)
							end
							surfaceGui:Destroy()
							if totalPresses==originalTotal then pr.Value=false end
						end
					end
				end)
			end
		elseif btn:IsA("BasePart") and btn.Name == "ButtonDeactivator" then --yeah the button deactivator script is in here now lol
			local debounce = false
			btn.Touched:Connect(function(t)
				local yesplr = configCheck(btn,"SupportPlayers") and players:GetPlayerFromCharacter(t.Parent) == players.LocalPlayer
				local yesbox = configCheck(btn,"SupportPushboxes") and (t.Name == "Pushbox" or t:FindFirstChild("IsBox") ~= nil)
				if (yesplr or yesbox) and debounce == false then
					debounce = true
					
					local colorSpecific = configCheck(btn,"ColorSpecific")
					for _,cacheBtn in pairs(cache.Buttons) do
						if not (colorSpecific and cacheBtn.ButtonPart.Color ~= btn.Color) then
							cacheBtn.Pressed.Value = false
						end
					end
					task.delay(.25,function()
						debounce = false
					end)
				end
			end)
 		end
	end
end