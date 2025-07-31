--!strict
-- junekept 2025
-- this script was originally made for OToH.

local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Utility = require(Kit.Utility)

local DAMAGE_OVERLAY_ASSET = "rbxasset://textures/ui/TopBar/WhiteOverlayAsset.png"

local player = Players.LocalPlayer
local mainGui = player.PlayerGui:WaitForChild("MainTowerGui")
local musicButton = mainGui.MusicButton
local mutedID = "http://www.roblox.com/asset/?id=6026671214"
local unmutedID = "http://www.roblox.com/asset/?id=6026671215"

-- it's an r6 game lol
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
-- we use a custom healthbar
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
ContentProvider:PreloadAsync({mutedID, unmutedID}, function(content: string, fetchStatus: Enum.AssetFetchStatus)
	if fetchStatus ~= Enum.AssetFetchStatus.Success then
		warn(`Could not load asset {content}, current status is {fetchStatus}`)
	end
end)

-- handle mute/unmute
musicButton.Activated:Connect(function()
	local isMuted = not musicButton:GetAttribute("Muted")
	musicButton:SetAttribute("Muted", isMuted)
	
	musicButton.ImageLabel.Image = if isMuted then mutedID else unmutedID
	-- musicButton.TextColor3 = if isMuted then Color3.fromHex("#000") else Color3.fromHex("#FFF")
	-- musicButton.Style = if isMuted then Enum.ButtonStyle.RobloxRoundDropdownButton else Enum.ButtonStyle.RobloxRoundDefaultButton
end)

-- Set collision group of players/characters being added
local function setCharacterCollision(model: Model, group: string)
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
	end
end

local function playerAdded(player: Player)
	local function characterAdded(character)
		setCharacterCollision(character, if player == Players.LocalPlayer then "Player" else "OtherPlayers")
	end
	
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then
		characterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(playerAdded)
for _, player in Players:GetPlayers() do
	playerAdded(player)
end

-- alignment keys

-- flip part functionality
-- TODO: move to a cleaner spot?
local flipOverlapParams = OverlapParams.new()
flipOverlapParams.CollisionGroup = ""
flipOverlapParams.FilterType = Enum.RaycastFilterType.Include
flipOverlapParams.Tolerance = 0.05
local function flip()
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	flipOverlapParams.FilterDescendantsInstances = CollectionService:GetTagged("Flip")

	local flipPartsInHitbox = workspace:GetPartsInPart(rootPart, flipOverlapParams)
	if #flipPartsInHitbox == 0 then
		return
	end

	local flipPart: BasePart = nil
	for _, part in flipPartsInHitbox do
		if part:GetAttribute("_Active") and (not flipPart or flipPart:GetAttribute("Priority") < part:GetAttribute("Priority")) then
			flipPart = part
		end
	end

	if not flipPart then
		return
	end

	local origin: CFrame
	local teleportToPart = flipPart:FindFirstChild("TeleportTo") :: ObjectValue
	if teleportToPart and teleportToPart.Value then
		local part = teleportToPart.Value :: BasePart
		assert(part:IsA("BasePart"), `TeleportTo value for {flipPart} not set to BasePart type, got {part} (which is a {part.ClassName}) instead.`)

		origin = part.CFrame
	else
		origin = flipPart.CFrame
	end

	if teleportToPart and not flipPart:GetAttribute("IncludeOffsetWhenTeleporting") then
		rootPart.CFrame = rootPart.CFrame.Rotation + origin.Position
	else
		rootPart.CFrame = origin * CFrame.Angles(0, math.pi, 0) * flipPart.CFrame:ToObjectSpace(rootPart.CFrame)
	end

	local sfx = flipPart:FindFirstChild("FlipSound")
	if sfx and flipPart:GetAttribute("PlaySound") then
		Utility.General.cloneAndPlay(sfx :: Sound)
	end
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
	local keyCode = input.KeyCode

	if gameProcessedEvent or UserInputService:GetFocusedTextBox() or not (keyCode == Enum.KeyCode.F or keyCode == Enum.KeyCode.ButtonX) then
		return
	end

	flip()
end)

if not UserInputService.KeyboardEnabled then
	UserInputService.TouchTapInWorld:Connect(function(position: Vector2, processedByUI: boolean) 
		if not processedByUI then
			flip()
		end
	end)
end