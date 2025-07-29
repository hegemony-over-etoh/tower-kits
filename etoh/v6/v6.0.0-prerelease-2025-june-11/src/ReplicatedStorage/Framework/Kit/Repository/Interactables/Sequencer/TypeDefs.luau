--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

export type SequenceData = {
	canAwait: boolean,
	instance: PVInstance,
	activators: { ActivatorFn }?,
	hasPassed: boolean,
	activatorData: { [any]: any },
	point: CFrame,
	doNotOptimize: boolean?,
}
type ActivatorFn = (sequenceData: SequenceData, variables: { [string]: any }) -> ()
export type ActivatorData = {
	check: (sequenceData: SequenceData, optimize: (Instance?) -> ()) -> (),
	activate: ActivatorFn,
	priority: number?,
}
export type SequencerCache = {
	activators: { [string]: ActivatorData },
	sequencers: { [Instance]: (variables: { [string]: any }) -> () },
	fetchActivators: (sequenceData: SequenceData) -> { ActivatorFn },
	makeSequenceData: (instance: PVInstance, forceAwait: boolean?, doNotOptimize: boolean?) -> SequenceData,
}

return nil
