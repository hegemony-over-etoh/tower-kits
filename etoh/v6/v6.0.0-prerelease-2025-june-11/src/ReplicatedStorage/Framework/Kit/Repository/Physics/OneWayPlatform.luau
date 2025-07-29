--!strict
--!optimize 2
--@version onewayplatform-6.0.0
--@creator synnwave

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

type PlatformData = {
	Active: boolean,
	Offset: CFrame,
	SetActive: boolean,
}
type PlatformCache = { [BasePart]: PlatformData }

local ACTIVE_KEY = "OneWayPlatform_Activated"
local ACTIVE_CHECK_IGNORES = { [ACTIVE_KEY] = true }

return function(scope: _T.Scope)
	local utility = scope:utility()
	local platformConfig = scope.instance
    if not platformConfig or not platformConfig:IsDescendantOf(Workspace) then
		return
	end

	local platform = platformConfig.Parent
	if not platform or not platform:IsA("BasePart") then
		return
	end

	local clientObjectUtil = utility.ClientObjects
	local cache = utility.Scope.getCached(scope, scope.scriptPath, function()
		local cache = {} :: PlatformCache

		local rootPart = utility.Character.getHitbox("RootPart")[1]
		local setInstanceActive = clientObjectUtil.setInstanceActive
		local isTableEmpty = utility.Table.IsEmpty
		scope.rootScope:add(RunService.Stepped:Connect(function()
			debug.profilebegin("Handle OneWayPlatforms")

			if isTableEmpty(cache) then
				debug.profileend()
				return
			end

			local characterPivot = rootPart:GetPivot()
			for part, data in cache do
				local partPivot = part:GetPivot()
				local upVector = partPivot.UpVector
				local look = CFrame.lookAt(
					(partPivot * data.Offset).Position,
					(characterPivot * CFrame.new(0, -math.sign(upVector:Dot(Vector3.yAxis)), 0)).Position
				).LookVector

				local active = data.Active and upVector:Dot(look) > 0
				if part.CanCollide ~= active then
					part.CanCollide = active
					if data.SetActive then
						setInstanceActive(scope, part, ACTIVE_KEY, active)
					end
				end
			end

			debug.profileend()
		end))

		return cache
	end)

	local config = utility.Config.GetConfig(scope, platformConfig, {
		SetActivated = false,
		Offset = CFrame.identity,
	})

	local platformData: PlatformData = {
		Active = clientObjectUtil.isInstanceActive(scope, platform, ACTIVE_CHECK_IGNORES),
		Offset = CFrame.new(Vector3.yAxis * (platform.Size.Y * 0.5)) * config.Offset,
		SetActive = config.SetActivated,
	}
	cache[platform] = platformData
	scope:attach(platform)
	scope:add(
		function()
			cache[platform] = nil
		end,
		platform:GetPropertyChangedSignal("Size"):Connect(function()
			platformData.Offset = CFrame.new(Vector3.yAxis * (platform.Size.Y * 0.5)) * config.Offset
		end)
	)

	-- these get automatically added to the scope, no need to add it here
	clientObjectUtil.listenInstanceActive(scope, platform, ACTIVE_CHECK_IGNORES, function(isActive)
		platformData.Active = isActive
	end)
end
