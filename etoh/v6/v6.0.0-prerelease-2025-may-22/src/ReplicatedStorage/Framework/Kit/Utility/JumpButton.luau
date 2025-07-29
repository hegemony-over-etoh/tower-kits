--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

--[=[
    @class JumpButton
    @client
    A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.
    
]=]
local JumpButton = {}

local KEYCODE_WHITELIST = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA }
local JUMP_EVENT = Instance.new("BindableEvent")
JUMP_EVENT.Parent = script

local isDown = false
JumpButton.JumpEvent = JUMP_EVENT
function JumpButton.IsDown()
	return isDown
end

local function updateJumpState(isPressed: boolean)
	if isDown ~= isPressed then
		isDown = isPressed
		JUMP_EVENT:Fire(isPressed)
	end
end

local localPlayer = Players.LocalPlayer
if UserInputService.TouchEnabled then
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	-- if roblox ever changes this path just change it here
	local mobileButton = playerGui:WaitForChild("TouchGui").TouchControlFrame.JumpButton

	mobileButton.MouseButton1Down:Connect(function()
		updateJumpState(true)
	end)

	mobileButton.MouseButton1Up:Connect(function()
		updateJumpState(false)
	end)
end

UserInputService.InputBegan:Connect(function(inputObj: InputObject)
	if table.find(KEYCODE_WHITELIST, inputObj.KeyCode) then
		updateJumpState(true)
	end
end)

UserInputService.InputEnded:Connect(function(inputObj: InputObject)
	if table.find(KEYCODE_WHITELIST, inputObj.KeyCode) then
		updateJumpState(false)
	end
end)

return table.freeze(JumpButton)
