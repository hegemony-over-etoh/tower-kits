--!strict
--!optimize 2
--@version beatblock-6.0.0
--@creator mario_123456

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local utility = scope:utility()
	local beatblockConfig = scope.instance
	if not beatblockConfig then
		return
	end

	local folder = beatblockConfig.Parent
	if not folder or not folder:IsA("Folder") then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, beatblockConfig, {
		ChangeCanTouch = true,
		Indicator = true,
		MaterialIndicator = Config.Type.Enum(Enum.Material.SmoothPlastic),

		OffCanCollide = false,
		OffTransparency = 0.5,
		OffCanTouch = false,

		OnCanCollide = true,
		OnTransparency = 1,
		OnCanTouch = true,
		TimeDelay = 1,
	}):CheckForChanges()

	--> Set up the parts
	local beatblockTable: { [number]: { BasePart } } = {}
	local tableList = 0
	for _, part in folder:GetDescendants() do
		if not (part:IsA("BasePart") and not (tonumber(part.Name) == nil)) then
			continue
		end

		part.CanCollide = configuration.OffCanCollide

		part.Transparency = configuration.OffTransparency

		local number = tonumber(part.Name)
		if not (number or typeof(number) == "number") then
			continue
		end

		if not beatblockTable[number] then
			beatblockTable[number] = {}
			tableList += 1
		end
		table.insert(beatblockTable[number], part)
	end

	--> Player stuff
	local localPlayer = Players.LocalPlayer

	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	local humanoidRootPart = humanoid.RootPart :: BasePart

	--> Play sound
	local sound: Sound = script.DefaultDingSound
	local function playSound(partList: { BasePart })
		local newSound = Instance.fromExisting(sound) :: Sound

		local fastestDistance: {} = {}
		for _, part in partList do
			local distance = localPlayer:DistanceFromCharacter(part.Position)
			if distance < (fastestDistance[2] or math.huge) then
				fastestDistance[2] = distance
				fastestDistance[1] = part
			end
		end

		newSound.Parent = fastestDistance[1]
		newSound:Play()
		newSound.Ended:Once(function()
			newSound:Destroy()
		end)
	end

	--> Update the parts
	local pointer = 1
	local lastPartList: { BasePart } = {}

	local function updateBeatBlock(activated: boolean, partList: { BasePart })
		if configuration.Indicator and activated then
			local originalMaterials: { [BasePart]: Enum.Material } = {}

			local thread: thread
			thread = scope:add(task.spawn(function()
				for _, part in partList do
					part.Size -= (part.Size * 1 / 5)
					part.CanCollide = false
					part.Transparency = configuration.OffTransparency

					if part.Material == Enum.Material.Plastic then
						originalMaterials[part] = part.Material
						part.Material = configuration.MaterialIndicator
					end
				end
			end))

			task.wait(configuration.TimeDelay / 3)
			task.cancel(thread)

			for _, part in partList do
				part.Size = part.Size * (5 / 4)
				part.CanCollide = true

				if originalMaterials[part] == nil then
					continue
				end
				part.Material = originalMaterials[part]
			end
		end
		if activated == false and configuration.Indicator then
			task.wait(configuration.TimeDelay / 3)
		end
		if activated then
			playSound(partList)
		end

		for _, part in partList do
			part.CanCollide = if activated then configuration.OnCanCollide else configuration.OffCanCollide
			part.CanTouch = if activated then configuration.OnCanTouch else configuration.OffCanTouch
			part.Transparency = if activated then configuration.OnTransparency else configuration.OffTransparency
		end
	end

	--> Main Loop
	local mainLoop: thread
	mainLoop = scope:add(task.spawn(function()
		while true do
			local currentPartList = beatblockTable[pointer]
			if not currentPartList then
				pointer += 1
				continue
			end

			local activeThread: thread, lastThread: thread
			activeThread = scope:add(task.spawn(function()
				updateBeatBlock(false, lastPartList)
			end))

			lastThread = scope:add(task.spawn(function()
				updateBeatBlock(true, currentPartList)
			end))

			lastPartList = currentPartList
			pointer += 1
			if pointer > tableList then
				pointer = 1
			end

			task.wait(configuration.TimeDelay)
			task.cancel(activeThread)
			task.cancel(lastThread)
		end
	end))
end
