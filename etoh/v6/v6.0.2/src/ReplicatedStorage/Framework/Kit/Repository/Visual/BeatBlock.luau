--!strict
--!optimize 2
--@version beatblock-6.0.1
--@creator mario_123456, synnwave
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 

PLEASE, **DO NOT** make any script edits to this script.
To make a script edit, please read the following:
https://etohgame.github.io/kit/docs/misc#writingediting-repository-scripts

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local BeatBlock = {
	CanQueue = true,
	RunOnStart = false,
}

local BEATBLOCK_CONFIG_TEMPLATE
local MUSIC_SYNC_CONFIG_TEMPLATE
function BeatBlock.Init(utility: _T.Utility)
	local Config = utility.Config
	BEATBLOCK_CONFIG_TEMPLATE = {
		ChangeCanTouch = true,
		Indicator = true,
		IndicatorSize = Vector3.new(3, 3, 3),
		MaterialIndicator = Config.Type.Enum(Enum.Material.SmoothPlastic),

		OffCanCollide = false,
		OffTransparency = 0.5,
		OffCanTouch = false,

		OnCanCollide = true,
		OnTransparency = 1,
		OnCanTouch = true,

		Interval = 1,
		IndicatorInterval = 0.5,
	}
	MUSIC_SYNC_CONFIG_TEMPLATE = {
		ZoneName = Config.Type.string,
		SyncEnabled = false,
	}
end

local REFRESH_RATE = 1 / 60

type block = { part: BasePart, size: Vector3, material: Enum.Material }

local musicManager
local localPlayer = Players.LocalPlayer
function BeatBlock.Run(scope: _T.Scope, utility: _T.Utility)
	local beatblockConfig = scope.instance
	if not beatblockConfig then
		return
	end

	local folder = beatblockConfig.Parent
	if not folder or not folder:IsA("Folder") then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, beatblockConfig, BEATBLOCK_CONFIG_TEMPLATE):ObserveChanges()
	local musicSyncConfig = beatblockConfig:FindFirstChild("MusicSyncConfiguration")
	local syncConfiguration = Config.GetConfig(scope, musicSyncConfig, MUSIC_SYNC_CONFIG_TEMPLATE):ObserveChanges()

	local syncData
	if syncConfiguration.SyncEnabled and syncConfiguration.ZoneName then
		local syncPointer = utility.Instance.getPointer(musicSyncConfig:FindFirstChild("Sync"))
		if syncPointer then
			syncData = utility.SongTime.BuildSyncCache(require(syncPointer) :: any)
		end
	end

	local beatblockTable: { [number]: { block } } = {}
	local tableList = 0
	for _, part in folder:GetDescendants() do
		local positionNumber = tonumber(part.Name:match("%d+"))
		if not (part:IsA("BasePart") and not (positionNumber == nil)) then
			continue
		end

		part.CanCollide = configuration.OffCanCollide
		part.Transparency = configuration.OffTransparency

		if not beatblockTable[positionNumber] then
			beatblockTable[positionNumber] = {}
			tableList += 1
		end
		table.insert(beatblockTable[positionNumber], {
			part = part,
			size = part.Size,
			material = part.Material,
		})
	end

	local sound = beatblockConfig:FindFirstChild("DingSound") or script.DefaultDingSound
	local function playSound(partList: { block })
		local newSound = Instance.fromExisting(sound) :: Sound

		local closest = {}
		for _, part in partList do
			local distance = localPlayer:DistanceFromCharacter(part.part.Position)
			if distance < (closest[2] or math.huge) then
				closest = { part, distance }
			end
		end

		newSound.Parent = closest[1].part
		newSound:Play()
		newSound.Ended:Once(function()
			newSound:Destroy()
		end)
	end

	local function displayNext(nextIndex: number)
		local parts = beatblockTable[nextIndex]
		if not parts or not configuration.Indicator then
			return
		end

		for _, data in parts do
			local part = data.part
			part.Size = configuration.IndicatorSize
			part.CanCollide = configuration.OffCanCollide
			part.Transparency = configuration.OffTransparency
			part.Material = configuration.MaterialIndicator
		end
	end

	local function toggleBeatBlock(index: number)
		for i, parts in beatblockTable do
			local activated = i == index
			if activated then
				playSound(parts)
			end

			for _, data in parts do
				local part = data.part
				part.Material = data.material
				part.Size = data.size
				part.CanCollide = if activated then configuration.OnCanCollide else configuration.OffCanCollide
				part.CanTouch = if activated then configuration.OnCanTouch else configuration.OffCanTouch
				part.Transparency = if activated then configuration.OnTransparency else configuration.OffTransparency
			end
		end
	end

	local totalBeats = #beatblockTable
	scope:spawn(function()
		if syncData then
			-- Music Sync mode enabled
			local backgroundMusic = ReplicatedStorage:WaitForChild("Background Music")
			if not musicManager then
				musicManager = require(backgroundMusic:WaitForChild("MusicSystemManager"))
			end

			local musicZonesContainer = backgroundMusic:WaitForChild("BackgroundMusicZones")
			local musicZone = musicZonesContainer:FindFirstChild(syncConfiguration.ZoneName, true)
			if not musicZone then
				scope:log({
					`Could not find music zone named "{syncConfiguration.ZoneName}"`,
					type = "warn",
				})
				return
			end

			local lastBeat = -1
			local shownNextBeat = false
			while task.wait(REFRESH_RATE) do
				local currentZone = musicManager.CurrentZone
				if not currentZone or currentZone.instance ~= musicZone then
					continue
				end

				local currentSound = musicManager.CurrentSong
				if not currentSound or currentSound.zoneID ~= currentZone.id then
					continue
				end

				local position = currentSound.song.TimePosition
				local beat = syncData:BeatFromSecond(position)
				local flooredBeat = beat // 1
				if lastBeat ~= flooredBeat then
					lastBeat = flooredBeat
					shownNextBeat = false
					toggleBeatBlock((flooredBeat % totalBeats) + 1)
				end

				local _, fraction = math.modf(beat)
				if not shownNextBeat and fraction >= configuration.IndicatorInterval then
					shownNextBeat = true
					displayNext(((flooredBeat + 1) % totalBeats) + 1)
				end
			end
		else
			--> Default Mode
			local currentBeat = 0
			while true do
				currentBeat = (currentBeat % totalBeats) + 1
				toggleBeatBlock(currentBeat)

				local indicatorTime = if configuration.Indicator then configuration.IndicatorInterval else 0
				task.wait(configuration.Interval - indicatorTime)

				displayNext((currentBeat % totalBeats) + 1)

				if configuration.Indicator then
					task.wait(configuration.IndicatorInterval)
				end
			end
		end
	end)
end

return BeatBlock
