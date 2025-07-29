--!strict

export type Evaluator = {
	GetPropertyFromTag: (objectTag: string, property: string) -> any,
	GetPropertyFromChanger: (property: string) -> any,
	GetSequenceVariable: (variable: string) -> any,

	Toucher: () -> { Instance },
	Tagged: (objectTag: string) -> { Instance },

	GetValue: ((value: "PlayerName") -> string)
		& ((value: "PlayerDisplayName") -> string)
		& ((value: "UserId") -> number)
		& ((value: "Distance", position: Vector3) -> number)
		& ((value: "CharacterPosition") -> Vector3)
		& ((value: "CharacterCFrame") -> CFrame)
		& ((value: "PlayerHealth") -> number),
}

export type Cache = {
	tagged: { [string]: { Instance } },
	getTagged: (tag: string) -> { Instance },
	changers: { [BasePart]: (touchingPart: BasePart?, variables: { [string]: any }) -> () },
}

return nil
