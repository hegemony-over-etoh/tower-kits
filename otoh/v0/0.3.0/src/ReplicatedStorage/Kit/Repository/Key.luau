--!strict
-- junekept 2025

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = ReplicatedStorage.Kit
local Libraries = ReplicatedStorage.Libraries
local Utility = require(Kit.Utility)

local Types = require(Kit.Types)

-- when dealing with a cache like this we run into a unique scenario: 
-- we need to push/pop from both ends as well as read any segment in O(1) complexity.
-- regular luau tables would require an entire table move to insert a new value at the front,
-- and taking from the "back" of a stack-like structure would cause the data to sort of "drift" in memory.
-- the solution to this is to create a "circular buffer" where we record a "start" position for our table index.
-- when we want to insert a value, we can move this "start" position back by one and overwrite the value previously there.
-- conveniently, this would also be the oldest value in the array!
-- by looping around the array like this we can effectively create a FIFO queue where you can arbitrarily read any value.
local keyPositionCache = {
	-- cast to vector type so hopefully the interpreter understands how much memory to reserve
	-- assuming the `vector` type consumes 24 bytes (3 64-bit floats) we're looking at 24kb per 1000 segments (not bad !) 
	_inner = table.create(Utility.Config.keyCacheSize) :: {Vector3},
	_capacity = Utility.Config.keyCacheSize,
	_currentStartPos = 2,
	_currentEndPos = 1,
}

function keyPositionCache.get(self: typeof(keyPositionCache), key: number): Vector3
	return self._inner[(self._currentStartPos + key - 2) % self._capacity + 1]
end

function keyPositionCache.set(self: typeof(keyPositionCache), key: number, value: Vector3)
	self._inner[(self._currentStartPos + key - 2) % self._capacity + 1] = value
end

function keyPositionCache.getLast(self: typeof(keyPositionCache)): Vector3
	return self._inner[self._currentEndPos]
end

function keyPositionCache.getCapacity(self: typeof(keyPositionCache)): number
	return self._capacity
end

function keyPositionCache.queue(self: typeof(keyPositionCache), value: Vector3)
	self._currentStartPos -= 1
	-- wraparound
	if self._currentStartPos == 0 then
		self._currentStartPos = self._capacity
	end
	if self._inner[self._currentStartPos] then
		self._currentEndPos = self._currentStartPos - 1
		if self._currentEndPos == 0 then
			self._currentEndPos = self._capacity
		end
	end
	self._inner[self._currentStartPos] = value
end

local function circularBufferIter(circularBuffer: typeof(keyPositionCache))
	return function(tbl: {Vector3}, lastKey: number?)
		local lastKey = lastKey or 0
		local currentKey = lastKey + 1
		-- key is technically an offset and since 1 = 0 offset we can just use the last key instead
		local actualIndex = circularBuffer._currentStartPos + lastKey % circularBuffer._capacity
		return if lastKey + 1 ~= #tbl and tbl[actualIndex] then currentKey else nil, tbl[actualIndex] 
	end, circularBuffer._inner
end

type DoubleLinkedListNode<T> = Types.DoubleLinkedListNode<T>
type Key = Types.Key

-- local firstKey: DoubleLinkedListNode<Key>
-- local lastKey: DoubleLinkedListNode<Key>

local function linkedListIterator<T>(start: DoubleLinkedListNode<T>)
	local currentNode: DoubleLinkedListNode<T>? = start
	-- since the first argument is meant to be table to "iterate" over,
	-- we just kinda don't use it since we want to change the node each call
	return function(_, lastKey: number?): (number?, DoubleLinkedListNode<T>)
		local temp = currentNode :: DoubleLinkedListNode<T>
		currentNode = currentNode and currentNode.next
		return if temp then (lastKey or 0) + 1 else nil, temp
	end, nil
end

-- os.clock() made it choppy for some reason
local currentKeyRotation = CFrame.Angles(0, 0, 0)
RunService.RenderStepped:Connect(function(deltaTime: number)
	currentKeyRotation *= CFrame.Angles(0, Utility.Config.keyRotateRate * deltaTime, 0)
end)

local keyIncrement = Utility.Config.keyIncrement
local incrementsPerStud = 1 / keyIncrement
local lastRecordedPos: Vector3 = nil
RunService:BindToRenderStep("UpdateKeyPositions", Enum.RenderPriority.Last.Value, function(deltaTime: number)
	local character = Players.LocalPlayer.Character :: Types.Character
	
	-- another failsafe check yay
	if not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local currentPos = character.HumanoidRootPart.Position
	
	if lastRecordedPos and lastRecordedPos.Unit == lastRecordedPos.Unit then
		-- if we include the y axis in our measurements, we run into an issue where the key "jerks" ahead when we jump
		-- I believe this is because you have a higher total magnitude movement per frame when you are jumping/falling
		-- to remedy this, we only record the y-axis, so the key distance is now *horizontal* key distance, fixing the jerkiness
		local noYLast = lastRecordedPos * Vector3.new(1, 0, 1)
		local noYCurrent = currentPos * Vector3.new(1, 0, 1)
		local distanceFromIncrement = (noYLast - noYCurrent).Magnitude

		local segmentsThisFrame = distanceFromIncrement // keyIncrement
		
		if segmentsThisFrame == 0 then
			return
		end
		
		local distanceInSegments = distanceFromIncrement / keyIncrement
		local finalSegmentPosition = lastRecordedPos:Lerp(currentPos, segmentsThisFrame / distanceInSegments)

		for i = 1, segmentsThisFrame do
			keyPositionCache:queue(lastRecordedPos:Lerp(finalSegmentPosition, i / segmentsThisFrame))
		end

		lastRecordedPos = finalSegmentPosition
	else
		lastRecordedPos = currentPos
		assert(lastRecordedPos)
		keyPositionCache:queue(lastRecordedPos)
	end
	
	
	local firstKeyNode = Utility.Character.getFirstKeyNode()
	if firstKeyNode then
		for originalIndex, node in linkedListIterator(firstKeyNode) do
			-- dear god help me this sucks
			--[[
			local index = Utility.Config.keyDistance * originalIndex * incrementsPerStud
			print(index)
			local positionIntervalStart = keyPositionCache:get(index) or keyPositionCache:getLast()
			local positionIntervalEnd = keyPositionCache:get(index - 1) or keyPositionCache:getLast()
			print(distanceFromIncrement / keyIncrement, distanceFromIncrement)
			local newPosition = positionIntervalStart:Lerp(positionIntervalEnd, distanceFromIncrement / incrementsPerStud)
			print((keyPositionCache:get(1) - currentPos).Magnitude)
			-- newPosition = positionIntervalStart
			]]
			if originalIndex > Utility.Config.keyRenderLimit then
				-- key is not being rendered
				return
			end
			
			local index = Utility.Config.keyDistance * originalIndex * incrementsPerStud
			local newPosition = keyPositionCache:get(index) or keyPositionCache:getLast()
			local model = node.value.model
			model:PivotTo(CFrame.new(newPosition) * model:GetPivot().Rotation)
		end
	end
end)
-- RunService.PreRender:Connect()

return function(object: Types.ClientObject)
	local mainModel = object.instance :: Model
	local keyHitbox = mainModel:FindFirstChild("KeyHitbox") :: BasePart
	local keyModel = mainModel:FindFirstChild("KeyModel") :: Model
	
	keyHitbox.Transparency = 1
	
	object.trove:Connect(RunService.PreRender, function(deltaTime: number)
		if keyModel:IsDescendantOf(workspace) then
			keyModel:PivotTo(currentKeyRotation + keyModel:GetPivot().Position)
		end
	end)
	
	local touchConnection
	local triggerConnection
	local function pickupKey()
		Utility.Character.addKeyToNodeList({model = keyModel, id = mainModel:GetAttribute("KeyId")}, Utility.Character.getLastKeyNode())

		local sfx = keyHitbox:FindFirstChild("Pickup") :: Sound
		if sfx and mainModel:GetAttribute("PlaySound") then sfx:Play() end
		
		touchConnection:Disconnect()
		triggerConnection:Disconnect()
	end
	
	touchConnection = object.trove:Connect(keyHitbox.Touched, function(otherPart: BasePart)
		if not mainModel:GetAttribute("_Active") or not Utility.ClientObjects.isTouchValid(mainModel, otherPart) then
			return
		end
		
		pickupKey()
	end)
	
	triggerConnection = object.trove:Connect(object.signals.onTrigger :: any, pickupKey)
end