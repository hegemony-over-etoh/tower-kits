--!strict

--[=[
    @class ScopeUtil
    @client
    A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.

]=]
local ScopeUtil = {}

local InternalScopeUtil = require(script.Parent.InternalScopeUtil)
type Scope = InternalScopeUtil.Scope

function ScopeUtil.getCached<T>(scope: Scope, key: string, initializer: (rootScope: any) -> T): T
	local inCache = scope.shared[key]
	if inCache then
		return inCache
	end

	local returned = initializer(scope.rootScope)
	scope.shared[key] = returned
	return returned
end

return table.freeze(ScopeUtil)
