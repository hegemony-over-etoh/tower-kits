--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Scope_TypeDefs = require(ReplicatedStorage.Framework.Kit.Managers.ScopeConstructor.TypeDefs)

export type ClientObjectsController = {
	--> BaseController
	Init: (self: ClientObjectsController) -> ClientObjectsController,
	__initialized: boolean,

	--> ClientObjectsController
	LoadClientObjects: (
		self: ClientObjectsController,
		from: Instance,
		target: Instance,
		towerRepository: Instance?
	) -> Scope_TypeDefs.Scope,
}

return nil
