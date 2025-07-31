--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Types = require(Kit.Types)

return function(object: Types.ClientObject)
	local shoverModel = object.instance :: Model
	local constraintHolder = shoverModel:FindFirstChild("ConstraintHolder") :: BasePart
	local prismaticConstraint = constraintHolder:FindFirstChild("PrismaticConstraint") :: PrismaticConstraint
	
	local function doThing(inOut: "In" | "Out")
		Utility.ClientObjects.respectActivityWait(shoverModel, shoverModel:GetAttribute(`{inOut}Delay`))
		prismaticConstraint.LinearResponsiveness = shoverModel:GetAttribute(`{inOut}Speed`)
		prismaticConstraint.Speed = shoverModel:GetAttribute(`{inOut}Speed`)
		prismaticConstraint.TargetPosition = if inOut == "Out" then prismaticConstraint.UpperLimit else 0
	end
	
	while true do
		doThing("In")
		doThing("Out")
	end
end