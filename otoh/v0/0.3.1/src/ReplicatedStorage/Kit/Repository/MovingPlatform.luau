--!strict
-- junekept 2025
-- this script was originally made for OToH

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Trove = require(Libraries.Trove)

local Types = require(Kit.Types)

type PositionInfo = {
	CFrame: CFrame,
	interval: number
}

local killbrickDebounceTime = Utility.Config.killbrickDebounceTime

local isTouching = false
return function(object: Types.ClientObject)
	local platformModel = object.instance :: BasePart
	local positionsFolder = platformModel:FindFirstChild("Positions") :: Folder
	local platform = platformModel:FindFirstChild("Platform") :: BasePart
	local alignPosition = platform:FindFirstChild("AlignPosition") :: AlignPosition
	local alignOrientation = platform:FindFirstChild("AlignOrientation") :: AlignOrientation
	
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	
	local positions: {PositionInfo} = {
		{
			CFrame = platform.CFrame, 
			interval = platform:GetAttribute("Interval")
		}
	}
	for i = 1, #positionsFolder:GetChildren() do
		local hopefullyExists = positionsFolder:FindFirstChild(`{i}`); assert(hopefullyExists and hopefullyExists:IsA("BasePart"), `Moving platform {platformModel.Name} missing position {i} in sequence`)
		if platformModel:GetAttribute("InvisiblePositions") then
			hopefullyExists.Transparency = 1
		end
		positions[i + 1] = {
			CFrame = hopefullyExists.CFrame,
			interval = hopefullyExists:GetAttribute("Interval")
		}
	end
	
	-- Utility.ClientObjects.respectActivityWait(mainModel, interval - indicationDuration)
	
	-- these are anchored by default to prevent the platform going crazy before it's "set up" properly lol
	platform.Anchored = false
	
	local currentPosition = 0
	while true do
		currentPosition += 1
		if currentPosition > #positions then
			currentPosition = 1
		end
		alignPosition.Position = positions[currentPosition].CFrame.Position
		alignOrientation.CFrame = positions[currentPosition].CFrame.Rotation

		local nextPosition = positions[currentPosition + 1] or positions[1]
		Utility.ClientObjects.respectActivityWait(platformModel, nextPosition.interval or platformModel:GetAttribute("Interval"))
	end
end