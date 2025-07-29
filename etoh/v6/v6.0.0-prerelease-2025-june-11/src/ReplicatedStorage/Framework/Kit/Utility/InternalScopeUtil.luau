--!strict

local InternalScopeUtil = {}

-- mock type since we can't access the scope type from within utility functions
-- because of it being a recursive type
export type Scope = typeof(setmetatable({}, {} :: { __index: any, __metatable: "Scope" }))

function InternalScopeUtil.isScope(scope)
	return getmetatable(scope) == "Scope"
end

function InternalScopeUtil.assertScope(scope: any, warning)
	if not InternalScopeUtil.isScope(scope) then
		error(`Scope expected for {warning}, got {typeof(scope)}`, 4)
	end
end

return table.freeze(InternalScopeUtil)
