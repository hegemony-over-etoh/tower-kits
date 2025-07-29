--!strict

--[=[
    @class Table
    @client
    A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.
    
]=]
local Table = {}

local tableUtil = require(script["table-util"])

--stylua: ignore
type mergeTable = -- LOL 💔
    (<A>(A & {}) -> A)
    & (<A, B>(A & {}, B & {}) -> A & B)
    & (<A, B, C>(A & {}, B & {}, C & {}) -> A & B & C)
    & (<A, B, C, D>(A & {}, B & {}, C & {}, D & {}) -> A & B & C & D)
    & (<A, B, C, D, E>(A & {}, B & {}, C & {}, D & {}, E & {}) -> A & B & C & D & E)
    & (<A, B, C, D, E, F>(A & {}, B & {}, C & {}, D & {}, E & {}, F & {}) -> A & B & C & D & E & F)
-- max: 6 tables
local function merge(itemA: any, itemB: any?, ...: any): any
	if itemB == nil then
		return itemA
	end
	for i, v in itemB do
		itemA[i] = v
	end

	return merge(itemA, ...)
end
Table.Merge = merge :: mergeTable

--[=[
    @within Table
    @function Copy
    @param item Array of items to splice
    @param min Starting index of splice
    @param max Ending index of splice
]=]
function Table.Splice<T>(item: { T }, min: number, max: number): { T }
	return table.move(item, min, max, 1, {})
end

function Table.Size(item: { [unknown]: unknown }): number
	local final = 0
	for _ in item do
		final += 1
	end

	return final
end

function Table.Compare(itemA: any, itemB: any, ignoreMetatable: boolean?): boolean
	-- i stole this from stack overflow
	local typeA = typeof(itemA)
	local type2 = typeof(itemB)
	if typeA ~= type2 then
		return false
	end
    if typeA ~= "table" and type2 ~= "table" then
        -- non-table types can be directly compared
		return itemA == itemB
	end 

    local metatable = getmetatable(itemA) 
    -- as well as tables which have the metamethod __eq
	if (not ignoreMetatable) and (metatable and metatable.__eq) then
		return itemA == itemB
	end

	for i, v1 in itemA do
		local v2 = itemB[i]
		if v2 == nil or not Table.Compare(nil, v1, v2) then
			return false
		end
	end
	for i, v2 in itemB do
		local v1 = itemA[i]
		if v1 == nil or not Table.Compare(nil, v1, v2) then
			return false
		end
	end

	return true
end

local merged = Table.Merge(Table, tableUtil) --table.freeze messes this type up
return table.freeze(merged) :: typeof(merged)
