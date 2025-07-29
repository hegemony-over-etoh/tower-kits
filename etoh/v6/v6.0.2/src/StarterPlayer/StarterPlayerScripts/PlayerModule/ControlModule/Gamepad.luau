--[[
	Gamepad Character Control - This module handles controlling your avatar using a game console-style controller

	2018 PlayerScripts Update - AllYourBlox
--]]

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

--[[ Constants ]]--
local ZERO_VECTOR3 = Vector3.new(0,0,0)
local NONE = Enum.UserInputType.None
local thumbstickDeadzone = 0.2

local COMPASS_DIR = {
    Vector3.new(1, 0, 0),			-- E   1
    Vector3.new(1, 0, 1).unit,		-- SE  2
    Vector3.new(0, 0, 1),			-- S   3
    Vector3.new(-1, 0, 1).unit,		-- SW  4
    Vector3.new(-1, 0, 0),			-- W   5
    Vector3.new(-1, 0, -1).unit,	-- NW  6
    Vector3.new(0, 0, -1),			-- N   7
    Vector3.new(1, 0, -1).unit,		-- NE  8
}

local DPAD_MAP = {
    [Enum.KeyCode.DPadUp] = 7,    -- up,    North
    [Enum.KeyCode.DPadDown] = 3,  -- down,  South
    [Enum.KeyCode.DPadLeft] = 5,  -- left,  West
    [Enum.KeyCode.DPadRight] = 1, -- right, East
}

--[[ The Module ]]--
local BaseCharacterController = require(script.Parent:WaitForChild("BaseCharacterController"))
local Gamepad = setmetatable({}, BaseCharacterController)
Gamepad.__index = Gamepad

function Gamepad.new(CONTROL_ACTION_PRIORITY)
    local self = setmetatable(BaseCharacterController.new(), Gamepad)

    self.CONTROL_ACTION_PRIORITY = CONTROL_ACTION_PRIORITY

    self.forwardValue  = 0
    self.backwardValue = 0
    self.leftValue = 0
    self.rightValue = 0

    self.activeGamepad = NONE	-- Enum.UserInputType.Gamepad1, 2, 3...
    self.gamepadConnectedConn = nil
    self.gamepadDisconnectedConn = nil
    return self
end

function Gamepad:Enable(enable)
    if not UserInputService.GamepadEnabled then
        return false
    end

    if enable == self.enabled then
        -- Module is already in the state being requested. True is returned here since the module will be in the state
        -- expected by the code that follows the Enable() call. This makes more sense than returning false to indicate
        -- no action was necessary. False indicates failure to be in requested/expected state.
        return true
    end

    self.forwardValue  = 0
    self.backwardValue = 0
    self.leftValue = 0
    self.rightValue = 0
    self.moveVector = ZERO_VECTOR3
    self.isJumping = false

    if enable then
        self.activeGamepad = self:GetHighestPriorityGamepad()
        if self.activeGamepad ~= NONE then
            self:BindContextActions()
            self:ConnectGamepadConnectionListeners()
        else
            -- No connected gamepads, failure to enable
            return false
        end
    else
        self:UnbindContextActions()
        self:DisconnectGamepadConnectionListeners()
        self.activeGamepad = NONE
    end

    self.enabled = enable
    return true
end

-- This function selects the lowest number gamepad from the currently-connected gamepad
-- and sets it as the active gamepad
function Gamepad:GetHighestPriorityGamepad()
    local connectedGamepads = UserInputService:GetConnectedGamepads()
    local bestGamepad = NONE -- Note that this value is higher than all valid gamepad values
    for _, gamepad in pairs(connectedGamepads) do
        if gamepad.Value < bestGamepad.Value then
            bestGamepad = gamepad
        end
    end
    return bestGamepad
end

function Gamepad:BindContextActions()

    if self.activeGamepad == NONE then
        -- There must be an active gamepad to set up bindings
        return false
    end

    local handleJumpAction = function(actionName, inputState, inputObject)
        self.isJumping = (inputState == Enum.UserInputState.Begin)
        return Enum.ContextActionResult.Sink
    end

    --@edit controller D-Pad movement implementation
    local attributeKey = "ControllerMovement"
    local configValue 
    task.spawn(function()
        configValue = Players.LocalPlayer:WaitForChild("KitConfiguration") 
    end)

    local dpadHeld = {}
    local handleThumbstickInput = function(actionName, inputState, inputObject)
        local currentValue = "off"
        if configValue then
            -- mode strings:
            -- off
            -- m1: joystick alt mode
            -- m2: dpad alt mode
            -- m3: both alt modes enabled
            currentValue = configValue:GetAttribute(attributeKey)
        end

        if inputState == Enum.UserInputState.Cancel then
            dpadHeld = {}
            self.moveVector = ZERO_VECTOR3
            return Enum.ContextActionResult.Sink
        end

        if self.activeGamepad ~= inputObject.UserInputType then
            return Enum.ContextActionResult.Pass
        end

        if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 then
            if inputObject.Position.magnitude > thumbstickDeadzone then
                if currentValue == "m1" or currentValue == "m3" then
                    local angle = math.atan2(-inputObject.Position.y, inputObject.Position.x)
                    local octant = (math.floor(8 * angle / (2 * math.pi) + 8.5) % 8) + 1
                    self.moveVector = COMPASS_DIR[octant]
                else
                    self.moveVector = Vector3.new(inputObject.Position.X, 0, -inputObject.Position.Y)
                end
            else
                self.moveVector = ZERO_VECTOR3
            end
            
        elseif DPAD_MAP[inputObject.KeyCode] ~= nil and (currentValue == "m2" or currentValue == "m3") then
            dpadHeld[inputObject.KeyCode] = inputState == Enum.UserInputState.Begin

            local finalVector = ZERO_VECTOR3
            for keycode, isHeld in dpadHeld do
                if not isHeld then 
                    continue 
                end
                finalVector += COMPASS_DIR[DPAD_MAP[keycode]]
            end

            self.moveVector = finalVector
        end

        return Enum.ContextActionResult.Sink
    end

    ContextActionService:BindActivate(self.activeGamepad, Enum.KeyCode.ButtonR2)
    ContextActionService:BindActionAtPriority("jumpAction", handleJumpAction, false,
        self.CONTROL_ACTION_PRIORITY, Enum.KeyCode.ButtonA)
    ContextActionService:BindActionAtPriority("moveThumbstick", handleThumbstickInput, false,
        self.CONTROL_ACTION_PRIORITY, 
        Enum.KeyCode.Thumbstick1, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight)

    return true
end

function Gamepad:UnbindContextActions()
    if self.activeGamepad ~= NONE then
        ContextActionService:UnbindActivate(self.activeGamepad, Enum.KeyCode.ButtonR2)
    end
    ContextActionService:UnbindAction("moveThumbstick")
    ContextActionService:UnbindAction("jumpAction")
end

function Gamepad:OnNewGamepadConnected()
    -- A new gamepad has been connected.
    local bestGamepad = self:GetHighestPriorityGamepad()

    if bestGamepad == self.activeGamepad then
        -- A new gamepad was connected, but our active gamepad is not changing
        return
    end

    if bestGamepad == NONE then
        -- There should be an active gamepad when GamepadConnected fires, so this should not
        -- normally be hit. If there is no active gamepad, unbind actions but leave
        -- the module enabled and continue to listen for a new gamepad connection.
        warn("Gamepad:OnNewGamepadConnected found no connected gamepads")
        self:UnbindContextActions()
        return
    end

    if self.activeGamepad ~= NONE then
        -- Switching from one active gamepad to another
        self:UnbindContextActions()
    end

    self.activeGamepad = bestGamepad
    self:BindContextActions()
end

function Gamepad:OnCurrentGamepadDisconnected()
    if self.activeGamepad ~= NONE then
        ContextActionService:UnbindActivate(self.activeGamepad, Enum.KeyCode.ButtonR2)
    end

    local bestGamepad = self:GetHighestPriorityGamepad()

    if self.activeGamepad ~= NONE and bestGamepad == self.activeGamepad then
        warn("Gamepad:OnCurrentGamepadDisconnected found the supposedly disconnected gamepad in connectedGamepads.")
        self:UnbindContextActions()
        self.activeGamepad = NONE
        return
    end

    if bestGamepad == NONE then
        -- No active gamepad, unbinding actions but leaving gamepad connection listener active
        self:UnbindContextActions()
        self.activeGamepad = NONE
    else
        -- Set new gamepad as active and bind to tool activation
        self.activeGamepad = bestGamepad
        ContextActionService:BindActivate(self.activeGamepad, Enum.KeyCode.ButtonR2)
    end
end

function Gamepad:ConnectGamepadConnectionListeners()
    self.gamepadConnectedConn = UserInputService.GamepadConnected:Connect(function(gamepadEnum)
        self:OnNewGamepadConnected()
    end)

    self.gamepadDisconnectedConn = UserInputService.GamepadDisconnected:Connect(function(gamepadEnum)
        if self.activeGamepad == gamepadEnum then
            self:OnCurrentGamepadDisconnected()
        end
    end)

end

function Gamepad:DisconnectGamepadConnectionListeners()
    if self.gamepadConnectedConn then
        self.gamepadConnectedConn:Disconnect()
        self.gamepadConnectedConn = nil
    end

    if self.gamepadDisconnectedConn then
        self.gamepadDisconnectedConn:Disconnect()
        self.gamepadDisconnectedConn = nil
    end
end

return Gamepad
