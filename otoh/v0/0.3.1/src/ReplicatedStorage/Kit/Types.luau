--!strict
-- junekept 2025
-- this script was originally made for OToH

--[==[
	This module contains types used in general throughout kit modules.
	Technically if you aren't using typechecking this module is irrelevant but it's convenient if you are lol
]==]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries

local LemonSignal = require(Libraries.LemonSignal)
local Trove = require(Libraries.Trove)

-- Base type for client objects to be used in code.
export type ClientObject = {
	-- The physical in-world instance of the client object
	instance: Instance,
	-- The trove used to manage cleaning up the client object when the tower is unloaded.
	-- Throw things like connections, new parts, etc... in this folder.
	trove: Trove.Trove,
	-- List of signals that can be fired at will to recieve requests fired from other client objects. Useful if you need cross-object behavior.
	signals: {[string]: LemonSignal.Signal<...any>}
}

-- Global configuration options for towers.
export type TowerConfig = {
	-- Whether or not to render additional debug information
	debug: boolean,
	
	-- The amount of damage poison bricks deal when the poison bar is full.
	poisonBrickDamage: number,
	-- How fast you lose poison when not in a poison brick
	poisonDecrementRate: number,
	-- The treshold at which posion begins to deal damage
	posionDamageThreshold: number
}

-- Base type for a loaded Tower to be able to access some parts of it from code.
export type Tower = {
	config: TowerConfig,
	clientObjectFolder: Folder,
	trove: Trove.Trove
}

-- Commonly used character children so one does not have to continuously assert they exist
export type Character = {
	Humanoid: Humanoid,
	HumanoidRootPart: BasePart,
	["Left Leg"]: BasePart,
	["Left Arm"]: BasePart,
	["Right Leg"]: BasePart,
	["Right Arm"]: BasePart,
	["Torso"]: BasePart,
	["Head"]: BasePart,
} & Model

-- Expected return value for client object scripts
export type ClientObjectFunction = (ClientObject) -> ()

-- Doubly Linked List data structure type node.
export type DoubleLinkedListNode<T> = {
	last: DoubleLinkedListNode<T>?,
	next: DoubleLinkedListNode<T>?,
	value: T
}

-- Represents a key object.
export type Key = {
	model: Model,
	id: string
}


return {}