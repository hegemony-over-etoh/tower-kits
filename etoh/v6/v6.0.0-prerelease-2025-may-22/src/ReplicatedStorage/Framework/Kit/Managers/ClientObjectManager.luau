--!strict
--!optimize 2
-- By @synnwave (09/12/24 DD/MM/YY)

--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Framework = ReplicatedStorage.Framework
local _TDefs = require(script.TypeDefs)

local Kit = Framework.Kit
local ScopeConstructor = require(Kit.Managers.ScopeConstructor)
local Utility = require(Kit.Utility)
local Log = require(Framework.Log)
local LightingManager = require(Kit.Managers.LightingManager)

local ClientObjectManager = {
	__initialized = false,
} :: _TDefs.ClientObjectsController

local requireCache = {}
local function getRepository(overrideRepository: Instance?)
	local repository = {}
	local function traverseFolders(folder: Instance, startingPath: string?)
		local rootPath = startingPath or folder:GetFullName()
		for _, instance in folder:GetChildren() do
			if instance:IsA("ModuleScript") then
				local path = instance:GetFullName():gsub(rootPath, ""):gsub("%.", "/"):sub(2)
				if repository[path] then
					continue
				end

				local cached = requireCache[instance]
				if not requireCache[instance] then
					-- requires already cache but i think it'l be a bit more
					-- performant doing this
					local loadSuccess, loadReturns = pcall(require, instance)
					if not loadSuccess then
						Log {
							`Failed to load repository script "{path}"`,
							`Error: "{loadReturns}"`,
							type = "info",
							printType = "warn",
						}
						continue
					end

					cached = loadReturns
					requireCache[instance] = loadReturns
					if typeof(loadReturns) == "table" then
						if loadReturns.Enabled == false then
							continue
						end

						if typeof(loadReturns.Init) == "function" and not loadReturns.Initialized then
							loadReturns.Init(Utility)
							loadReturns.Initialized = true
						end
					end
				end

				repository[path] = cached
			elseif instance:IsA("Folder") then
				traverseFolders(instance, rootPath)
			end
		end
	end

	if overrideRepository then
		traverseFolders(overrideRepository)
	end
	traverseFolders(Kit.Repository)
	return table.freeze(repository)
end

function ClientObjectManager:LoadClientObjects(from, target, towerRepository)
	if not from.Parent then
		-- Temporarily parent container under this script so CollectionService
		-- can detect instances
		from.Parent = script
	end

	local thisRepository = getRepository(towerRepository)
	local activeScripts = {}

	local rootScope = ScopeConstructor.new({
		tower = "Kit",
		clientObjects = target,
		repository = thisRepository,
	})

	local function applyObject(object: Instance)
		if object:IsA("BasePart") then
			if object.CollisionGroup == "Default" then
				-- if it wasnt for this collision group we wouldnt need to do a
				-- getdescendants loop LOL
				object.CollisionGroup = "ClientObjects"
			end
		end

		if object.Name == "ClientObjectScript" then
			Log {
				"ClientObjectScripts are not supported in this kit version. Please switch to using the new Script Repository.",
				"For more info, please read: aAAAaadadfasfgh",
				`Path: {object:GetFullName()}`,
				type = "info",
				printType = "warn",
			}
		end
	end

	local function loadScript(targetScope, scriptPath: string, instance: Instance?)
		local thisScript = thisRepository[scriptPath]
		if not thisScript then
			return
		end

		local thread: thread
		thread = task.defer(function()
			debug.setmemorycategory(scriptPath)
			if instance then
				activeScripts[scriptPath][instance] = true
			end

			local innerScope = targetScope:inherit({
				instance = instance,
				scriptPath = scriptPath,
			})
			if typeof(thisScript) == "function" then
				thisScript(innerScope)
			elseif typeof(thisScript) == "table" and typeof(thisScript.Run) == "function" then
				thisScript.Run(innerScope)
			end

			innerScope:add(function()
				targetScope:remove(thread, true)
			end)
			task.defer(function()
				innerScope:add(thread)
			end)
		end)
		targetScope:add(thread)
	end

	local function scanFolder(targetScope, path: Instance, doNotIgnoreObjects: boolean?, targetPath: Instance?)
		--> Get objects that shouldnt be loaded in (yet?)
		local objectBlacklist = {}
		if not doNotIgnoreObjects then
			for _, instance in CollectionService:GetTagged("SkipObjectLoad") do
				if instance == path or instance:IsDescendantOf(path) then
					objectBlacklist[instance] = true
				end
			end
		end

		--> Get scripts
		local scriptQueue = {}
		for scriptPath, thisScript in thisRepository do
			for _, instance in CollectionService:GetTagged("CO_" .. scriptPath) do
				if activeScripts[scriptPath] and activeScripts[scriptPath][instance] then
					continue
				end

				local shouldQueue = true
				if not doNotIgnoreObjects then
					for blacklistedInstance in objectBlacklist do
						if blacklistedInstance == instance or instance:IsDescendantOf(blacklistedInstance) then
							shouldQueue = false
							break
						end
					end
				end
				if typeof(thisScript) == "table" and thisScript.CanQueue == false then
					shouldQueue = false
				end

				if shouldQueue then
					scriptQueue[instance] = scriptPath
					if not activeScripts[scriptPath] then
						activeScripts[scriptPath] = {}
					end
				end
			end
		end

		--> Parent & apply parts
		applyObject(path)
		for _, instance in path:GetChildren() do
			if targetPath then
				instance.Parent = targetPath
			end

			applyObject(instance)
			for _, descendant in instance:GetDescendants() do
				applyObject(descendant)
			end
		end

		--> Run Scripts
		for instance, scriptPath in scriptQueue do
			loadScript(targetScope, scriptPath, instance)
		end
	end

	-- TODO: make a better access point for this
	rootScope.data.scanFolder = scanFolder

	-- scan folder for reposcripts
	scanFolder(rootScope, from, false, target)
	from:Destroy()

	-- load RunOnStart repo scripts
	for scriptPath, thisScript in thisRepository do
		if typeof(thisScript) == "table" and thisScript.RunOnStart then
			loadScript(rootScope, scriptPath)
		end
	end

	-- deregister any lighting presets on scope cleanup
	local tower = rootScope.tower
	rootScope:add(function()
		LightingManager:DeregisterPreset(tower)
	end)

	return rootScope
end

function ClientObjectManager:Init()
	if self.__initialized then
		return ClientObjectManager
	end
	self.__initialized = true

	--> Set Invisible Parts
	for _, instance in CollectionService:GetTagged("Invisible") do
		if instance:IsA("BasePart") then
			instance.Transparency = 1
		end
	end

	CollectionService:GetInstanceAddedSignal("Invisible"):Connect(function(instance)
		if instance:IsA("BasePart") then
			instance.Transparency = 1
		end
	end)

	--> Destroy parts that should only be visible in studio
	for _, instance in CollectionService:GetTagged("OnlyInStudio") do
		instance:Destroy()
	end
	CollectionService:GetInstanceAddedSignal("OnlyInStudio"):Connect(function(instance)
		instance:Destroy()
	end)

	return ClientObjectManager
end

return ClientObjectManager
