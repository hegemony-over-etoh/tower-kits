--!strict
--!optimize 2
--@version pushboxspawn-6.0.0
--@creator synnwave

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local spawnConfig = scope.instance
	if not spawnConfig or not spawnConfig.Parent then
		return
	end

	local pushboxTemplate = spawnConfig.Parent:FindFirstChild("Pushbox")
	if not pushboxTemplate then
		return
	end
	if not pushboxTemplate:HasTag("SkipObjectLoad") then
		scope:log({
			"Pushbox is missing it's 'SkipObjectLoad' tag.",
			`Path: {pushboxTemplate:GetFullName()}`,
			type = "warn",
		})
		return
    end
    
    scope:add(pushboxTemplate)
    pushboxTemplate.Parent = nil
    pushboxTemplate:RemoveTag("SkipObjectLoad")
    -- ^ this line above is important to reduce IsDescendantOf checks and also
    -- allows nested pushboxes to actually work
    
    -- TODO: test the lines below in laggy situations to see if it's worth 
    -- uncommenting
	--for _, instance in pushboxTemplate:GetDescendants() do
	--	if not instance:IsA("BasePart") or instance:HasTag("BoxAnchor") then
	--		continue
	--	end
	--	instance.Anchored = false
	--end

	local pushboxSpawner = spawnConfig.Parent:FindFirstChild("Button")
	if not pushboxSpawner or not pushboxSpawner:IsA("BasePart") then
		return
	end

	local spawnSound = spawnConfig:FindFirstChild("SpawnSound")

	local utility = scope:utility()

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, spawnConfig, {
		Cooldown = 0.5,
		DontSpawnFirst = true,
	}):ObserveChanges()

	local touchConfiguration =
		Config.GetConfig(scope, spawnConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):ObserveChanges()

	local pushboxScope = scope:inherit()
	local function spawnPushbox()
		if spawnSound and spawnSound:IsA("Sound") then
			spawnSound:Play()
		end
		pushboxScope:cleanup()
		local thisBox = pushboxScope:add(pushboxTemplate:Clone())
		thisBox.Parent = spawnConfig.Parent
		utility.ClientObjects.scanFolder(pushboxScope, thisBox, false)
	end

    local cooldown = false
	scope:attach(pushboxSpawner)
	scope:add(pushboxSpawner.Touched:Connect(function(touchingPart)
		if
			cooldown
			or pushboxSpawner:GetAttribute("Activated") == false
			or not utility.ClientObjects.evaluateToucher(pushboxSpawner, touchingPart, touchConfiguration)
		then
			return
		end
		cooldown = true
		task.delay(configuration.Cooldown, function()
			cooldown = false
		end)

		spawnPushbox()
	end))

	if not configuration.DontSpawnFirst then
		task.defer(spawnPushbox)
	end
end
