--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local LemonSignal = require(Libraries.LemonSignal)
local Utility = require(Kit.Utility)

local Types = require(Kit.Types)
local TriggerTypes = require(script.Parent.TriggerTypes)

local BEAM_TEXTURE_ID = "rbxassetid://9632168658"

local TriggerFunctions = {}

function TriggerFunctions.fireNextChain(object: Types.ClientObject, nextChain: TriggerTypes.TriggerChainList)
	task.delay(object.instance:GetAttribute("Delay"), function()
		for _, chainObject in nextChain do
			if chainObject.Value then
				-- get the client object of the value and fire it's "trigger" event, thus continuing the chain
				Utility.Tower.loadedClientObjects[chainObject.Value].signals.trigger:Fire()
			else
				warn(`{chainObject} did not have attached instance, ignoring`)
			end
		end
		
		if Utility.Tower.loadedTower.config.debug then
			object.signals.activated:Fire()
		end
	end)
end

function TriggerFunctions.isPointingToVariableTrigger(objectValue: ObjectValue)
	return objectValue.Value and objectValue.Value:FindFirstChild("Value")
end

function TriggerFunctions.getVariableValueOrSelf<T>(
	value: Instance & (ObjectValue | T), 
	disallowNonVariableObject: boolean?
): Instance & (ObjectValue | T)
	type ReturnType = Instance & (ObjectValue | T)
	if value:IsA("ObjectValue") and TriggerFunctions.isPointingToVariableTrigger(value) then
		-- TriggerFunctions.isPointingToVariableTrigger being true guaruntees that the value is not empty
		local variableTrigger = value.Value :: ReturnType
		return TriggerFunctions.getVariableValueOrSelf(variableTrigger:FindFirstChild("Value") :: ReturnType)
	else
		if disallowNonVariableObject and value:IsA("ObjectValue") then
			error(`calling code does not expect non-variable ObjectValue, `
				.. `but {value.Value} does not qualify as a VariableTrigger.`)
		else
			return value :: ReturnType
		end
	end
end

function TriggerFunctions.getDefaultChainList(object: Types.ClientObject): {ObjectValue}
	return object.instance:FindFirstChild("Chain"):GetChildren() :: any
end

function TriggerFunctions.getArguments(object: Types.ClientObject): {[string]: any}
	local argumentList = {}
	for _, argument in object.instance:GetChildren() do
		if argument:IsA("ValueBase") then
			argumentList[argument.Name] = argument
		end
	end
	return argumentList
end

function TriggerFunctions.createDebugBeams(object: Types.ClientObject)
	local startPart = object.instance
	for _, descendant in startPart:GetDescendants() do
		if descendant:IsA("ObjectValue") and descendant.Value then
			local startPart = startPart :: BasePart
			local endPart = descendant.Value :: BasePart
			if not endPart:IsA("BasePart") then
				if not endPart:IsA("Model") then return end
				local model = endPart :: Model
				
				endPart = Instance.new("Part")
				endPart.Anchored = true
				endPart.CanCollide = false
				endPart.Size = Vector3.zero
				endPart.CFrame = model:GetPivot()
				endPart.Parent = model
			end
			
			-- swizzle attachment parents when pointing to non-output variable trigger
			if TriggerFunctions.isPointingToVariableTrigger(descendant) and descendant.Name ~= "Output" then
				startPart, endPart = endPart, startPart
			end
			
			local beam = Instance.new("Beam")
			local attachment0 = Instance.new("Attachment")
			local attachment1 = Instance.new("Attachment")

			beam.Attachment0 = attachment0
			beam.Attachment1 = attachment1
			beam.Texture = BEAM_TEXTURE_ID
			beam.Width0 = 6
			beam.Width1 = 6
			beam.TextureSpeed = 0.5
			beam.TextureLength = 5
			beam.TextureMode = Enum.TextureMode.Wrap
			beam.FaceCamera = true
			
			attachment0.Parent = startPart
			attachment0.CFrame *= CFrame.Angles(-math.pi/2, 0, 0)
			
			attachment1.Parent = endPart
			attachment1.CFrame *= CFrame.Angles(-math.pi/2, 0, 0)
			
			beam.Parent = startPart
		end
	end
end

return TriggerFunctions