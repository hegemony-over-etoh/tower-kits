--!strict

local POINTER_TAG = "OBJ_POINTER"

--[=[
@class Instance
@client
A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.

]=]
local InstanceUtil = { POINTER_TAG = POINTER_TAG }

--[=[
    @within Instance
    
    Returns whether the `object` is a module pointer. Module pointers are used
    for things such as module-based object configurations to help reduce
    memory usage when requiring them.
]=]
function InstanceUtil.isPointer(object: Instance?)---: boolean
    return typeof(object) == "Instance" and object:HasTag(POINTER_TAG) and object:IsA("ObjectValue")
end

--[=[
    @within Instance
    
    If the given `object` is a pointer, this function will return it's value.
    Otherwise, it will just return the object that was passed in.
]=]
function InstanceUtil.getPointer(object: Instance?): Instance?
    if object and InstanceUtil.isPointer(object) and object:IsA("ObjectValue") then
		return object.Value
	end

	return object
end

return table.freeze(InstanceUtil)
