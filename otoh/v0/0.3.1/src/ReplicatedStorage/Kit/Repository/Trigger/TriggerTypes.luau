--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local LemonSignal = require(Libraries.LemonSignal)
local Utility = require(Kit.Utility)

local Types = require(Kit.Types)

export type ActualValueBase = ObjectValue | NumberValue | IntValue | BoolValue | Vector3Value | RayValue | CFrameValue
	| Color3Value | StringValue | BrickColorValue

-- born to use typechecking forced to cast to any
export type TriggerArguments = {[string]: any}
export type TriggerChainList = {ObjectValue}
export type TriggerFunction = (object: Types.ClientObject, args: TriggerArguments) -> ()

type Signal = LemonSignal.Signal<...any>
export type ConnectionInfo = {
	signal: Signal, 
	clause: ((...any) -> boolean)?
}
export type NumericValue = NumberValue | IntValue

export type TriggerInfo = {
	behavior: (object: Types.ClientObject, args: TriggerArguments) -> {ObjectValue},
	setup: ((object: Types.ClientObject) -> ())?,
	connections: (object: Types.ClientObject) -> {ConnectionInfo}
}

return nil