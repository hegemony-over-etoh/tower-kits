--!strict
--!optimize 2

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local humanoid: Humanoid? = character:WaitForChild("Humanoid")
if not humanoid then
	return
end

-- Head collision glitch fix
local head = character:FindFirstChild("Head")
if head and head:IsA("BasePart") then
	head:GetPropertyChangedSignal("CanCollide"):Connect(function()
		head.CanCollide = true
	end)
end

-- Truss Fix
-- Original script by AkaWhats (& some help by MasSpartan)
-- Code touchups & some micro-optimizations done by synnwave

local DEFAULT_FPS = 1 / 60
local TRIGGER_FPS = 1 / 75
local fps

local states = {
	Enum.HumanoidStateType.Jumping,
	Enum.HumanoidStateType.Climbing,
	Enum.HumanoidStateType.Freefall,
	Enum.HumanoidStateType.Running,
	Enum.HumanoidStateType.Landed,
	Enum.HumanoidStateType.Seated,
	Enum.HumanoidStateType.Swimming,
	Enum.HumanoidStateType.GettingUp,
	Enum.HumanoidStateType.FallingDown,
}
local function onStateChanged(oldState, newState)
	if newState ~= oldState then
		for _, state in states do
			if state ~= newState then
				humanoid:SetStateEnabled(state, false)
			end
		end
		task.wait(DEFAULT_FPS - fps)
		for _, state in states do
			if state ~= newState then
				humanoid:SetStateEnabled(state, true)
			end
		end
	end
end

local stateConnection: RBXScriptConnection?
RunService.Heartbeat:Connect(function(delta: number)
	debug.profilebegin("Truss Fix > Update")

	if delta < TRIGGER_FPS then
		fps = delta
		if stateConnection == nil then
			stateConnection = humanoid.StateChanged:Connect(onStateChanged)
		end
	elseif delta > TRIGGER_FPS and stateConnection ~= nil then
		stateConnection:Disconnect()
		stateConnection = nil
	end

	debug.profileend()
end)
