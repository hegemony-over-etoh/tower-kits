--!strict

local POINTER_TAG = "OBJ_POINTER"

--[=[
@class Instance
@client
A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.

]=]
local InstanceUtil = { POINTER_TAG = POINTER_TAG }

function InstanceUtil.isPointer(object: Instance?)---: boolean
    return typeof(object) == "Instance" and object:HasTag(POINTER_TAG) and object:IsA("ObjectValue")
end

function InstanceUtil.getPointer(object: Instance?): Instance?
    if object and InstanceUtil.isPointer(object) and object:IsA("ObjectValue") then
		return object.Value
	end

	return object
end

return table.freeze(InstanceUtil)
