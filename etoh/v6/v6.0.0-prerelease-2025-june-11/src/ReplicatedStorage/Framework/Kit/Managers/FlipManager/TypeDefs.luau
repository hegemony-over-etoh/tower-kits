--!strict

export type FlipManager = {
	--> BaseController
	Init: (self: FlipManager) -> FlipManager,
	__initialized: boolean,

	--> FlipManager
	Flip: (self: FlipManager) -> (),
	BindToFlip: (self: FlipManager, part: BasePart, callback: () -> ()) -> () -> (),
	__callbacks: { [BasePart]: { [any]: () -> () } },
}

return nil
