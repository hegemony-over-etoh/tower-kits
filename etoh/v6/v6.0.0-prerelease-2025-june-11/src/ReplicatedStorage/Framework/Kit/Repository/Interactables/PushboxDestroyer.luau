--!strict
--!optimize 2
--@version pushboxdestroyer-6.0.0
--@creator Camille

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local utility = scope:utility()
	local Config = utility.Config

	local destroyerConfig = scope.instance
	if not destroyerConfig or not destroyerConfig.Parent then
		return
	end

	--> Setup
	local destroyer = destroyerConfig.Parent

	if not destroyer:IsA("BasePart") then
		scope:log({
			"This PushboxDestroyer is set up incorrectly and will not function, it must be a Part.",
			`Path: {destroyer:GetFullName()}`,
			type = "warn",
		})

		return
	end

	local configuration = Config.GetConfig(scope, destroyerConfig, {
		DestroyWholeModel = false,
		ColorSpecific = false,
	}):ObserveChanges()

	scope:attach(destroyer)

	--> Destroyer functionality
	scope:add(destroyer.Touched:Connect(function(touchingPart: BasePart)
		-- evaluateToucher doesn't work here because it doesn't check ancestors
		-- so the destoyer wouldn't work if the box is in a model
		-- (which it is by default)

		if utility.ClientObjects.isPushbox(touchingPart) then
			if configuration.ColorSpecific then
				local boxColor = utility.Functions.roundColor(touchingPart.Color)
				local destroyerColor = utility.Functions.roundColor(destroyer.Color)

				if boxColor ~= destroyerColor then
					return
				end
			end

			if configuration.DestroyWholeModel then
				local model = touchingPart:FindFirstAncestor("Pushbox")
				if model then
					model:Destroy()
				end
			else
				touchingPart:Destroy()
			end
		end
	end))
end
