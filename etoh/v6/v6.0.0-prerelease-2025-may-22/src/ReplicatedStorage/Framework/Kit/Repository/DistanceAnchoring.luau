--!strict
--!optimize 2
--@version distanceanchoring-6.0.0
--@creator Camille

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local player = Players.LocalPlayer

local DEFAULT_DISTANCE = 150
local UPDATE_INTERVAL = 0.2
local lastTick = os.clock()

export type DistanceAnchoringTable = {
	part: BasePart,
	distance: number,
}

local Module = {
	-- Determines whether or not the script can be used by client objects
	CanQueue = false,
	-- Determines whether or not the script will be loaded upon entering
	-- (the script will be loaded without an instance attacted to the scope,
	--  remove the lines that use the "objectConfig" variable if you use this)
	RunOnStart = true,
}

function Module.Run(scope: _T.Scope)
	local utility = scope:utility()

	local objectTable: { DistanceAnchoringTable } = {}

	--> update function
	local distanceFromCharacter = player.DistanceFromCharacter
	local function updateDistanceAnchoring()
		for tableIndex, distanceAnchorTable in objectTable do
			local distance = distanceFromCharacter(player, distanceAnchorTable.part.Position)
			distanceAnchorTable.part.Anchored = distance > distanceAnchorTable.distance
		end
	end

	--> grab objects
	for _, object in scope.clientObjects:GetDescendants() do
		if object:IsA("Model") then
			local anchorDistance = object:GetAttribute("DistanceAnchor")
			if anchorDistance then
				-- find primary part
				local primaryPart = nil
				for _, modelPart in object:GetChildren() do
					if modelPart:IsA("BasePart") and modelPart:HasTag("DistanceAnchorPrimary") then
						primaryPart = modelPart
						break
					end
				end

				if not primaryPart then
					return
				end

				-- set distance
				if anchorDistance <= 0 then
					anchorDistance = DEFAULT_DISTANCE
				end

				-- set up distance anchoring table
				local distanceAnchorData: DistanceAnchoringTable = {
					part = primaryPart,
					distance = anchorDistance,
				}

				table.insert(objectTable, distanceAnchorData)
			end
		end
	end

	--> run loop
	scope:add(RunService.RenderStepped:Connect(function()
		debug.profilebegin("Update Distance Anchoring")

		local now = os.clock()
		if now - lastTick > UPDATE_INTERVAL then
			lastTick = now
			updateDistanceAnchoring()
		end

		debug.profileend()
	end))
end

return Module
