--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local APIDump = require(ReplicatedStorage.Framework.ClientTypes.APIDump)

type DefaultData = "PlaceDefault" | "TowerDefault" | string
type constructorReturns = {
	Type: string,
	Configuration: { [string]: any? },
	TweenInfo: TweenInfo?,
}
-- this type decides to stop working if i use intersections so have fun reading
-- this xd
export type Constructor = ((
	type: "ColorCorrectionEffect"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		TweenInfo: TweenInfo?,
		Configuration: (ColorCorrectionEffect | APIDump.ColorCorrectionEffect)?,
	}
) -> constructorReturns) & ((
	type: "BlurEffect"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (BlurEffect | APIDump.BlurEffect)?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "Lighting"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: APIDump.Lighting?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "BloomEffect"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (BloomEffect | APIDump.BloomEffect)?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "DepthOfFieldEffect"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (DepthOfFieldEffect | APIDump.DepthOfFieldEffect)?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "Atmosphere"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (Atmosphere | (APIDump.Atmosphere & { Enabled: boolean? }))?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns) & ((
	type: "Sky"
) -> (
	data: {
		UseDefault: DefaultData?,
		SetDefault: DefaultData?,
		Configuration: (Sky | APIDump.Sky)?,
		TweenInfo: TweenInfo?,
	}
) -> constructorReturns)

local function constructor(type: string)
	return function(data: any)
		-- Only keep the properties we need in memory
		return {
			Type = type,
			Configuration = data.Configuration,
			TweenInfo = data.TweenInfo,
			SetDefault = data.SetDefault,
			UseDefault = data.UseDefault,
		}
	end
end
local typedConstructor = (constructor :: any) :: Constructor
return typedConstructor
