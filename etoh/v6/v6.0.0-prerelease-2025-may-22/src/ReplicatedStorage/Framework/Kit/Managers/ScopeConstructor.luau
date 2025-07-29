--!strict
--!optimize 2
-- By @synnwave (30/11/24 DD/MM/YY)

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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local _TDefs = require(script.TypeDefs)
local Framework = ReplicatedStorage.Framework
local Log = require(Framework.Log)

local Kit = Framework.Kit
local Managers = Kit.Managers
local Utility = require(Kit.Utility)

local CLEANUP_METHODS = { "Destroy", "Disconnect", "cleanup", "destroy", "disconnect" }

local function doNothing() end
local generateUID = Utility.Functions.generateUID

-- private key wrapper shorthand; for items that aren't meant to be accessed
local PRIVATE_KEY = generateUID() --newproxy()
local function wrap<T>(t: T): { [any]: T }
	return { [PRIVATE_KEY] = t }
end

--------------------------------------------------------------------------------
--> Setup

--[=[
    @class Scope
    @client
    
    Scope
]=]
local Scope = {} :: _TDefs.__Scope_metatable
Scope.__metatable = "Scope"
Scope.__index = function(self: _TDefs.Scope, key: string)
	if key:sub(1, 1) == "_" then
		Scope.log(self, { `Attempt to access private scope property '{key}'`, type = "error" })
	end

	local rawData = self[PRIVATE_KEY]
	if not rawData then
		return
	end

	if key == "rootScope" then
		return rawData.__root or self
	end

	local item = rawData[key]
	if item ~= nil then
		return item
	end

	item = Scope[key]
	if item == nil then -- get item from rootScope
		local rootScope = self.rootScope
		if rootScope == self then
			return nil
		end

		local rawRootScopeData = rootScope and rootScope[PRIVATE_KEY]
		if rawRootScopeData then
			item = item or rawRootScopeData[key]
		end
	end

	return item
end :: any
Scope.__newindex = function(self: _TDefs.Scope, key: string)
	self:log { `Cannot add property '{key}' to scope ({self.id})`, type = "error", traceback = 4 }
end :: any

function Scope:__tostring()
	return `Scope ({self.scriptPath} - {self.id})`
end

function Scope:log(data)
	data.path = if self.scriptPath and self.scriptPath ~= "" then ("Repository." .. self.scriptPath) else data.path
	Log(data)
	return self
end

local function assureScopeIsActive(self: _TDefs.Scope, method: string)
	local rawData = self[PRIVATE_KEY]
	if not rawData.active then
		self:log {
			`Current scope has been destroyed (calling method '{method}', {rawData.id})`,
			type = "error",
			traceback = 4,
		}
	end
end

function Scope:utility() -- why is this a function? Because luau types suck lol
	assureScopeIsActive(self, "utility")
	return Utility
end

--------------------------------------------------------------------------------
--> Memory Management

local totalItemsAdded = 0
local function addItem<T...>(self: _TDefs.Scope, ...: T...): T...
	assureScopeIsActive(self, "add")

	local items = self[PRIVATE_KEY].__items
	if items.__cleaning then
		self:log {
			"Attempted to add an item to a scope during cleanup",
			traceback = 4,
			type = "error",
		}
	end

	for i = 1, select("#", ...) do
		local item = select(i, ...)
		if item ~= nil and items[item] == nil then
			totalItemsAdded += 1
			items[item] = totalItemsAdded
		end
	end

	return ...
end

Scope.add = addItem

function Scope:inherit(data: any)
	assureScopeIsActive(self, "inherit")

	local thisData = data or {}
	local rootScope = self.rootScope
	local rawSelf = self[PRIVATE_KEY]
	local rawRootScope = rootScope[PRIVATE_KEY]
	local newData: any = wrap {
		instance = thisData.instance or rawSelf.instance,
		scriptPath = thisData.scriptPath or rawSelf.scriptPath,
		active = true,

		id = "INNER-" .. generateUID(),
		parentScope = self,

		-- items copied from rootscope to save on __index
		shared = rawRootScope.shared,
		__communicators = rawRootScope.__communicators,
		clientObjects = rawRootScope.clientObjects,
		debug = rawRootScope.debug,

		__root = rootScope,
		__items = { __cleaning = false },
		data = {},
	}

	return addItem(self, setmetatable(newData, Scope))
end

local cleanupScope, cleanupItem, destroyScope
function destroyScope(self: _TDefs.Scope)
	local rawData = self[PRIVATE_KEY]
	if not rawData or not rawData.active then
		return
	end
	rawData.active = false
	rawData.data = nil
	if not rawData.__items.__cleaning then
		cleanupScope(self)
	end

	if rawData.parentScope then
		rawData.parentScope:remove(self, true)
		rawData.parentScope = nil
	end

	return self
end

function cleanupItem(item: any)
	local cleanupSuccess, cleanupError
	local type = typeof(item)
	if type == "function" then
		task.spawn(item)
	elseif type == "thread" then
		cleanupSuccess, cleanupError = pcall(task.cancel, item)
	elseif type == "Instance" then
		item:Destroy()
	elseif type == "RBXScriptConnection" then
		item:Disconnect()
	elseif type == "table" then
		if getmetatable(item) == "Scope" then
			destroyScope(item)
		else
			cleanupSuccess, cleanupError = pcall(function()
				for _, method in CLEANUP_METHODS do
					if typeof(item[method]) == "function" then
						item[method](item)
						break
					end
				end
			end)
		end
	end

	if cleanupSuccess == false then
		Log { "Failed to cleanup scope item", cleanupError, type = "warn" }
	end
end

function cleanupScope(self: _TDefs.Scope, ignoreWarning: boolean?)
	local items = self[PRIVATE_KEY].__items
	if not ignoreWarning and items.__cleaning then
		return self:log { "Scope is already cleaning up!!", traceback = 4, type = "warn" }
	end

	items.__cleaning = true
	for item in items do
		if item == "__cleaning" then
			continue
		end
		items[item] = nil
		cleanupItem(item)
	end
	items.__cleaning = false

	return self
end

function Scope:remove(item, doNotCleanup)
	local rawSelf = self[PRIVATE_KEY]
	local items = rawSelf.__items
	if items.__cleaning or not rawSelf.active then
		return self
	end

	if items[item] then
		items[item] = nil
		if not doNotCleanup then
			cleanupItem(item)
		end
	end

	return self
end

function Scope:cleanup(defer, destroy)
	if self == self.rootScope then
		self:log {
			`WARNING - Cleaning up RootScope`,
			traceback = 4,
			type = "warn",
		}
	end

	local method: any = if destroy then destroyScope else cleanupScope
	if defer then
		task.defer(method, self)
	else
		method(self)
	end

	return self
end

function Scope:attach(instance, removeFromParentScope)
	assureScopeIsActive(self, "attach")
	if self == self.rootScope then
		self:log {
			`WARNING - ATTEMPTING TO ATTACH INSTANCE TO ROOTSCOPE. DANGEROUS!!`,
			traceback = 4,
			type = "warn",
		}
	end

	if removeFromParentScope then
		addItem(self, function()
			destroyScope(self)
		end)
	end

	return addItem(
		self,
		instance.Destroying:Connect(function()
			cleanupScope(self, true)
		end),
		instance
	)
end

--------------------------------------------------------------------------------
--> Scope Communication

---------------------------------------
--> Setup

--[=[
    @class Communicator
    @client
    
    Scope Communicator
]=]
local Communicator = {} :: _TDefs.__Communicator_metatable
Communicator.__index = Communicator
--Communicator.__metatable = "ScopeCommunicator"
Communicator.__newindex = function(self: _TDefs.ScopeCommunicator, key: string, value)
	if key == "__listener" then
		rawset(self :: any, key, value)
		return
	end

	self.__scope:log {
		`Cannot add property '{key}' to communicator`,
		traceback = 4,
		type = "error",
	}
end :: any

function Communicator:__tostring()
	return `Communicator ({self.type} - {self.name})`
end

-----------------------------------------
--> Methods

function Communicator:listen(callback)
	if self.type == "event" and self.__instance:IsA("BindableEvent") then
		local connection = self.__instance.Event:Connect(function(id: string)
			callback(table.unpack(self.__hash[id]))
		end)
		addItem(self.__scope, connection)
		return function()
			connection:Disconnect()
		end
	elseif self.type == "request" and self.__instance:IsA("BindableFunction") then
		if self.__listener and self.__scope.debug then
			self.__scope:log {
				`Replacing callback for request communicator '{self.name}'`,
				type = "info",
			}
		end

		local function callbackWrapper(id: string)
			-- reuse id to send in new data returned by the callback
			-- wow
			self.__hash[id] = table.pack(callback(table.unpack(self.__hash[id])))
			return id
		end
		self.__listener = callbackWrapper
		self.__instance.OnInvoke = callbackWrapper

		return function()
			if self.__listener == callbackWrapper then
				self.__instance.OnInvoke = nil :: any
				callbackWrapper = nil :: any
			end
		end
	end

	return doNothing
end

function Communicator:listenOnce(callback)
	if not self.__instance:IsA("BindableEvent") then
		self.__scope:log {
			`Cannot use method 'listenOnce' for communicator type '{self.type}'`,
			traceback = 4,
			type = "error",
		}
		return doNothing
	end

	local disconnect
	disconnect = self:listen(function(...)
		callback(...)
		disconnect()
	end)

	return disconnect
end

function Communicator:listenWait()
	if not self.__instance:IsA("BindableEvent") then
		self.__scope:log {
			`Cannot use method 'listenWait' for communicator type '{self.type}'`,
			traceback = 4,
			type = "error",
		}
		return nil
	end

	local thread = coroutine.running()
	self.__threads[thread] = true
	self:listenOnce(function(...)
		self.__threads[thread] = nil
		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

function Communicator:fire(...)
	if not self.__instance:IsA("BindableEvent") then
		self.__scope:log {
			`Cannot use method 'fire' for communicator type '{self.type}'`,
			traceback = 4,
			type = "error",
		}
		return self
	end
	if not self.__hash then
		return self
	end

	local id = generateUID()
	self.__hash[id] = table.pack(...)
	self.__instance:Fire(id)

	return self
end

function Communicator:request(...)
	if not self.__instance:IsA("BindableFunction") then
		self.__scope:log {
			`Cannot use method 'request' for communicator type '{self.type}'`,
			traceback = 4,
			type = "error",
		}
		return self
	end

	local id = generateUID()
	self.__hash[id] = table.pack(...)

	-- TODO: some tests to see if it's worth reenabling the code below
	--local thread = coroutine.running()
	--self.__threads[thread] = true

	--local requestThread
	--requestThread = task.defer(function()
	--	self.__instance:Invoke(id)
	--	task.spawn(thread, table.unpack(self.__hash[id]))
	--	self.__hash[id] = nil
	--	self.__threads[thread] = nil
	--	self.__threads[requestThread] = nil
	--	requestThread = nil :: any
	--end)
	--self.__threads[requestThread] = true

	--return coroutine.yield()

	self.__instance:Invoke(id)
	local data = self.__hash[id]
	self.__hash[id] = nil
	return table.unpack(data)
end

function Communicator.destroy(self: any)
	if getmetatable(self) ~= Communicator then
		return
	end

	self.__listener, self.__hash = nil
	for thread in self.__threads do
		if coroutine.status(thread) ~= "suspended" then
			continue
		end
		pcall(task.cancel, thread)
	end
	self.__threads = nil

	self.__scope.rootScope:remove(self.__instance)
	self.__scope[PRIVATE_KEY].__communicators[self.type][self.name] = nil
	self.name, self.type, self.__scope = nil

	setmetatable(self, nil)
end

---------------------------------------
--> Creation

function Scope:getCommunicator(type, key)
	assureScopeIsActive(self, "getCommunicator")
	local rootScope = self.rootScope
	local rawRootScope = rootScope[PRIVATE_KEY]
	local communicators = rawRootScope.__communicators

	local existingCommunicator = communicators[type][key]
	if existingCommunicator then
		return existingCommunicator
	end

	local communicatorProps = {
		type = type,
		name = key,

		__hash = communicators.hash,
		__threads = {},
		__scope = self,
	}
	if type == "event" then
		communicatorProps.__instance = Instance.new("BindableEvent") :: any
		communicatorProps.__instance.Event:Connect(function(id: string)
			-- bindable events run in reverse order; this will always run last
			communicatorProps.__hash[id] = nil
		end)
	elseif type == "request" then
		communicatorProps.__instance = Instance.new("BindableFunction")
	end

	communicatorProps.__instance.Parent = script
	communicatorProps.__instance.Name = self.id

	local newCommunicator = addItem(rootScope, setmetatable(communicatorProps, Communicator))
	communicators[type][key] = newCommunicator
	return newCommunicator :: _TDefs.ScopeCommunicator
end

--------------------------------------------------------------------------------

return table.freeze({
	new = function(data: _TDefs.__constructorData): _TDefs.Scope
		local scopeData: any = wrap {
			instance = nil,
			scriptPath = "",

			-- global scope items
			clientObjects = data.clientObjects,
			repository = data.repository,
			rootScope = nil,
			shared = {},
			debug = true,
			id = "ROOT-" .. generateUID(),
			tower = data.tower,
			active = true,
			data = {},

			-- private items
			__items = { __cleaning = false },
			__communicators = {
				event = {},
				request = {},
				hash = {},
			},
		}

		return setmetatable(scopeData, Scope)
	end,
})
