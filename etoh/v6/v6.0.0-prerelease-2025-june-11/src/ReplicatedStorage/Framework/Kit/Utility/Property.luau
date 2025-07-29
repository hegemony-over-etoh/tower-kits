--!strict

--[=[
    @class Property
    @client
    A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.
    
]=]
local Property = {}

--[=[
    @within Property
    @tag shorthand
        
    Safely gets a property of an object. 
    Will return `nil` if the property does not exist, or if any errors occur.
]=]
function Property.getPropertySafe(instance: any, property: string): (any, boolean)
	local result
	local success = pcall(function()
		result = instance[property]
	end)
	return result, success
end

--[=[
    @within Property
    @tag shorthand
    
    Safely sets a property of an object.
]=]
function Property.setPropertySafe(instance: any, property: string, value: any): boolean
	return (pcall(function()
		instance[property] = value
	end))
end

--[=[
    @within Property
    @tag shorthand
        
    Checks if `value` and `default` are of the same type. 
    If not, it will return the `default` value.
]=]
function Property.assureValueType<defaultType>(value: unknown, default: defaultType): defaultType
	return if typeof(default) == typeof(value) then value :: defaultType else default
end

--[=[
    @within Property
    @tag shorthand
    @param default
    @return defaultType
        
    Shorthand for `utility.assureValueType(instance:GetAttribute(configName), default)`
]=]
function Property.assureConfig<defaultType>(instance: Instance, configName: string, default: defaultType): defaultType
	return Property.assureValueType(instance:GetAttribute(configName), default)
end

return table.freeze(Property)
