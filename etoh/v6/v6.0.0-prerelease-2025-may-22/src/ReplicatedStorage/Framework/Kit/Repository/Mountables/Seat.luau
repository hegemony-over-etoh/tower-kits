--!strict
--!optimize 2
--@version seat-6.0.0
--@creator Gammattor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

return function(scope: _T.Scope)
	local utility = scope:utility()
	local JumpButton = utility.JumpButton

	local seatConfig = scope.instance
	if not seatConfig then
		return
	end

	local seat = seatConfig.Parent
	if not seat or not seat:IsA("BasePart") then
		return
	end

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	if not rootPart then
		return
	end

	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, seatConfig, {
		Cooldown = 1,
	}):CheckForChanges()

	------------------------------------------------------------------------
	--> Mount seat
	local seatDebounce = false
	local seatScope = scope:inherit()

	scope:add(seat.Touched:Connect(function(touch)
		if seatDebounce or seat:GetAttribute("Activated") == false then
			return
		end

		if not table.find(utility.Character.getHitbox("StaticWholeBody"), touch) then
			return
		end

		if mountedCOs[rootPart] then
			for _, mountName in mountedCOs[rootPart] do
				if mountName == "Seat" then
					return
				end
			end
		else
			mountedCOs[rootPart] = {}
		end
		mountedCOs[rootPart][seat] = "Seat"
		seatDebounce = true

		humanoid.Sit = true
		rootPart.CFrame = seat.CFrame + seat.CFrame.UpVector * (seat.Size.Y / 2 + 1.5)

		local seatWeld = Instance.new("WeldConstraint")
		seatWeld.Parent = seat
		seatWeld.Part0 = seat
		seatWeld.Part1 = rootPart

		------------------------------------------------------------------------
		--> Dismount function
		local function dismountSeat()
			seatScope:cleanup(true)
			if seatWeld then
				seatWeld:Destroy()
			end

			if mountedCOs[rootPart] and mountedCOs[rootPart][seat] then
				mountedCOs[rootPart][seat] = nil
				if #mountedCOs[rootPart] < 1 then
					mountedCOs[rootPart] = nil
				end
			end

			rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

			task.delay(configuration.Cooldown, function()
				seatDebounce = false
			end)
		end

		if JumpButton.IsDown() then
			dismountSeat()
		end

		seatScope:add(JumpButton.JumpEvent.Event:Connect(function(isPressed: boolean)
			if not isPressed then
				return
			end
			dismountSeat()
		end))

		seatScope:add(task.spawn(function()
			while task.wait() do
				debug.profilebegin("Seat Checking")
				if not (mountedCOs[rootPart] and mountedCOs[rootPart][seat]) then
					dismountSeat()
					break
				end
				debug.profileend()
			end
		end))
	end))
end
