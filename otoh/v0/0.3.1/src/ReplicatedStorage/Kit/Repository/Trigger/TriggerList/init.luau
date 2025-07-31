local TriggerTypes = require(script.Parent.TriggerTypes)

local TriggerList: {[string]: TriggerTypes.TriggerInfo} = {
	Activate = require(script.Activate),
	Arithmetic = require(script.Arithmetic),
	ButtonSet = require(script.ButtonSet),
	Camera = require(script.Camera),
	Compare = require(script.Compare),
	Delay = require(script.Delay),
	Format = require(script.Format),
	Humanoid = require(script.Humanoid),
	Jump = require(script.Jump),
	PropertyGet = require(script.PropertyGet),
	PropertySet = require(script.PropertySet),
	StateChange = require(script.StateChange),
	Touch = require(script.Touch),
	TowerLoad = require(script.TowerLoad)
}

return TriggerList
