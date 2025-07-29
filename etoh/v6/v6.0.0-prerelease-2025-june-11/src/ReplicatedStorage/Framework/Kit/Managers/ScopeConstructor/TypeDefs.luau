--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = ReplicatedStorage.Framework
local Log = require(Framework.Log.TypeDefs)
local Utility = require(Framework.Kit.Utility)

-----------------------------------------
--> Communicator Types

type COMMUNICATOR_TYPES = "event" | "request"
export type __Communicator_params = {
	type: COMMUNICATOR_TYPES,
	name: string,

	__listener: ((...any) -> ...any)?,
	__hash: { [any]: any },
	__threads: { [thread]: any },
	__scope: any,
	__instance: BindableEvent | BindableFunction,
}

export type __Communicator_metatable = {
	__index: __Communicator_metatable,
	__newindex: nil,
	__tostring: (self: ScopeCommunicator) -> string,
	__metatable: "ScopeCommunicator",

	listen: (self: ScopeCommunicator, callback: (...any) -> ...any) -> () -> (),
	listenOnce: (self: ScopeCommunicator, callback: (...any) -> ...any) -> () -> (),
	listenWait: (self: ScopeCommunicator) -> ...any,
	fire: (self: ScopeCommunicator, ...any) -> ScopeCommunicator,
	request: (self: ScopeCommunicator, ...any) -> ...any,
	destroy: (self: ScopeCommunicator) -> (),
}

export type ScopeCommunicator = typeof(setmetatable({} :: __Communicator_params, {} :: __Communicator_metatable))

-----------------------------------------
--> Scope Types

export type RepositoryModule = { Run: (scope: Scope) -> (), [string]: any }
export type LegacyRepositoryModule = (scope: Scope) -> ()

export type __Scope_params = {
	instance: Instance?,
	scriptPath: string,

	rootScope: Scope,
	parentScope: Scope?,
	id: string,

	-- global scope items
	tower: string,
	clientObjects: Instance,
	shared: { [any]: unknown },
	debug: boolean,
	repository: { [string]: (LegacyRepositoryModule | RepositoryModule)? },
	data: { [any]: any? },

	-- private items
	--__root: nil, -- hidden property
	active: boolean,
	__items: { __cleaning: boolean, [unknown]: boolean? },
	__communicators: {
		event: { [string]: ScopeCommunicator? },
		request: { [string]: ScopeCommunicator? },
		hash: { [any]: any },
	},
}

export type __Scope_metatable = {
	__index: __Scope_metatable,
	__newindex: nil,
	__tostring: (self: Scope) -> string,
	__metatable: "Scope",

	inherit: (self: Scope, data: { [string]: any }?) -> Scope,
	add: <T...>(self: Scope, T...) -> T...,
	remove: (self: Scope, item: unknown, doNotCleanup: boolean?) -> Scope,
	cleanup: (self: Scope, defer: boolean?, destroy: boolean?) -> Scope,
	attach: (self: Scope, instance: Instance, removeFromParentScope: boolean?) -> (RBXScriptConnection, Instance),
	isAlive: (self: Scope) -> boolean,

	spawn: <T...>(self: Scope, fn: (T...) -> ...unknown, T...) -> thread,
    defer: <T...>(self: Scope, fn: (T...) -> ...unknown, T...) -> thread,
    delay: <T...>(self: Scope, seconds: number, fn: (T...) -> ...unknown, T...) -> thread,

	getCommunicator: (self: Scope, type: COMMUNICATOR_TYPES, key: string) -> ScopeCommunicator,
	log: (self: Scope, data: Log.logData) -> Scope,
	utility: (self: Scope) -> Utility.Utility,
}

export type Scope = typeof(setmetatable({} :: __Scope_params, {} :: __Scope_metatable))

export type __constructorData = {
	tower: string,
	clientObjects: Instance,
	repository: any,
}
export type ScopeConstructor = {
	new: (data: __constructorData) -> Scope,
}

return nil
