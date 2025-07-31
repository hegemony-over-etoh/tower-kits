--!strict
-- junekept 2025
-- this script was originally made for OToH.

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TestService = game:GetService("TestService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

type MusicZone = {
	Sound: Sound,
	Part: BasePart
} & Folder

local player = Players.LocalPlayer
-- last time I saw this error it was because of user error so I'm keeping it to make it easier to diagnose
local mainGui = player.PlayerGui.MainTowerGui
local musicButton = mainGui.MusicButton
local currentlyPlayingFrame = musicButton.CurrentlyPlaying

local musicZoneFolder = SoundService.MusicZones
local globalSound = musicZoneFolder.Global

local character = script.Parent
local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart

-- society if I could use native codegen on the client. may as well put the attribute there if it will ever change lol
@native
local function isPointInBounds(point: CFrame, boundsCFrame: CFrame, boundsSize: Vector3): boolean
	local relativeCFrame = boundsCFrame:ToObjectSpace(point)
	
	return math.abs(relativeCFrame.X) - boundsSize.X / 2 <= 0
		and math.abs(relativeCFrame.Y) - boundsSize.Y / 2 <= 0
		and math.abs(relativeCFrame.Z) - boundsSize.Z / 2 <= 0
end

-- I *really* do not think we need to have dynamic transition times buut
-- TODO: double check if we should create a transition time attribute
local TRANSITION_TIME = 3

local standardTweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local lastPlaying: Sound? = nil
local currentlyPlaying: Sound? = nil
local toFadeOut: {[Sound]: boolean} = {} -- use a hashmap so it's easier to remove finished tweens

local function updateSongName()
	local label = currentlyPlayingFrame.TextLabel
	if currentlyPlaying then
		local id = currentlyPlaying.SoundId:gsub("rbxassetid://", "")
		local result, soundInfo = pcall(MarketplaceService.GetProductInfo, MarketplaceService, tonumber(id))
		label.Text = if result then soundInfo.Name else "song name unavailable" 
	else
		label.Text = "song name unavailable" 
	end

	local params = Instance.new("GetTextBoundsParams")
	params.Text = label.Text
	params.Font = label.FontFace
	params.Size = label.TextSize

	local textBounds = TextService:GetTextBoundsAsync(params)
	currentlyPlayingFrame.TextLabel.Size = UDim2.new(0, textBounds.X, 1, 0)
end

RunService.RenderStepped:Connect(function(deltaTime: number)
	if musicButton:GetAttribute("Muted") then 
		if currentlyPlaying then currentlyPlaying.Volume = 0 end	
	end

	local activeZones = CollectionService:GetTagged("LoadedMusicZone") :: {MusicZone}
	
	local selectedZone: MusicZone = nil
	for _, zone in activeZones do
		for _, part in zone:GetDescendants() do
			if part:IsA("BasePart") then
				-- we use a special function because we are not querying workspace and thus can't query part bounds
				if isPointInBounds(rootPart.CFrame, part.CFrame, part.Size) 
					and zone:GetAttribute("Priority") > (if selectedZone then selectedZone:GetAttribute("Priority") else -math.huge) 
				then
					selectedZone = zone
				end
			end
		end
	end
	
	local selected = if selectedZone then selectedZone.Sound else globalSound
	if currentlyPlaying and currentlyPlaying ~= selected then
		lastPlaying = currentlyPlaying
		toFadeOut[lastPlaying :: Sound] = true
	end
	currentlyPlaying = selected
	updateSongName()
	if currentlyPlaying and not currentlyPlaying.Playing then currentlyPlaying:Play() end

	for sound, _ in toFadeOut do
		local originalVolume = sound:GetAttribute("OriginalVolume")
		sound.Volume -= (originalVolume / TRANSITION_TIME) * deltaTime
		sound.Volume = math.max(0, sound.Volume)
		if sound.Volume <= 0 then 
			sound:Stop()
			toFadeOut[sound] = nil
			if lastPlaying == sound then 
				lastPlaying = nil 
			end
		end
	end

	if currentlyPlaying and not lastPlaying then
		local originalVolume = currentlyPlaying:GetAttribute("OriginalVolume")
		currentlyPlaying.Volume += (originalVolume / TRANSITION_TIME) * deltaTime
		currentlyPlaying.Volume = math.min(originalVolume, currentlyPlaying.Volume)
	end
end)

musicButton:GetAttributeChangedSignal("Muted"):Connect(function()
	if not currentlyPlaying then return end
	local muted = musicButton:GetAttribute("Muted")

	if muted then
		currentlyPlaying.Volume = 0
	else
		currentlyPlaying.Volume = currentlyPlaying:GetAttribute("OriginalVolume")
	end
end)

currentlyPlayingFrame.TextLabel.Size = UDim2.fromOffset(0, 0)

local function easeOutQuad(a: number)
	return 1 - (1 - a)^2
end

local currentProgress = 0
local function tweenLabel(diff: number)
	currentProgress = math.clamp(currentProgress + diff * 2, 0, 1)
	currentlyPlayingFrame.TextLabel.AnchorPoint = Vector2.new(easeOutQuad(currentProgress), 0)
end

local connection
musicButton.MouseEnter:Connect(function()
	if connection then
		connection:Disconnect()
	end
	
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		tweenLabel(deltaTime)
		if currentProgress >= 1 then
			connection:Disconnect()
		end
	end)
	
	musicButton.MouseLeave:Once(function()
		connection:Disconnect()
		connection = RunService.RenderStepped:Connect(function(deltaTime: number)
			tweenLabel(-deltaTime)
			if currentProgress <= 0 then
				connection:Disconnect()
			end
		end)
	end)
	
	updateSongName()
end)