-- GROUP PROPERTIES
-- IgnoreBoxes: If true, boxes cannot toggle the group.
-- IgnorePlayers: If true, players cannot toggle the group.
-- OffTransparency: The part transparency of a deactivated toggle block.
-- OnTransparency: The part transparency of an activated toggle block.
-- ToggleTime: The time needed for a group to fully toggle upon contact.

-- PART PROPERTIES
-- IgnoreBoxes: This part will ignore box contact.
-- IgnoreOutline: The part's outline will retain its original transparency, toggled or not.
-- IgnorePlayers: This part will ignore player contact.
-- IgnoreTransparency: The part will retain its original transparency, toggled or not.
-- Inverted: When the group's Activated property is true, this part will be deactivated, and vice versa.
-- Silent: This part will not make a sound when touched.
-- ToggleTime: Overrides the group's toggle time with this value if this part is touched.


local ts=game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local on = tonumber(script.Parent.OnTransparency.Value)
local off = tonumber(script.Parent.OffTransparency.Value)
local tt = tonumber(script.Parent.ToggleTime.Value)

local act = script.Parent.Activated.Value

local parts = {}
for _, p in pairs(script.Parent:GetDescendants()) do
	if p:IsA"BasePart" and p.Name == "Part" then
		table.insert(parts, p)
	end
end

local ignore = {game.Players.LocalPlayer.Character} --ignore uncollidable parts and the player

---

function xor(a,b)
	return (a or b) and not (a and b)
end

function tween(part,time,inf)
	local tweeninf=TweenInfo.new(
		time,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out
	)
	local tw=ts:Create(part,tweeninf,inf)
	tw:Play()
end

function ding()
	local snd = script.ToggleSound:Clone()
	snd.Parent = workspace
	snd.PlayOnRemove = true --set it here so that the player doesn't hear a ding when leaving the place
	snd:Destroy()
end

function activate(t)
	act = not act
	for _, p in pairs(parts) do
		local inv = p:FindFirstChild('Inverted')
		local b = p:FindFirstChild('SelectionBox')
		if not xor(inv, act) then
			if not p:FindFirstChild('IgnoreTransparency') then
				tween(p, t, {Transparency = off})
			end
			if not p:FindFirstChild('IgnoreOutline') then
				tween(b, t, {Transparency = 1})	
			end
			p.CanTouch = false
			delay(t, function()
				if not p:FindFirstChild('IgnoreCanCollide') then
					p.CanCollide = false	
				end
			end)
		else
			if not p:FindFirstChild('IgnoreTransparency') then
				tween(p, t, {Transparency = on})
			end
			delay(t, function()
				p.CanTouch = true
				if not p:FindFirstChild('IgnoreCanCollide') then
					p.CanCollide = true	
				end
				if not p:FindFirstChild('IgnoreOutline') then
					b.Transparency = 0
				end
			end)
		end
	end
end

---

return function()
	local players = not (script.Parent:FindFirstChild("IgnorePlayers") and script.Parent.IgnorePlayers.Value)
	local boxes = not (script.Parent:FindFirstChild("IgnoreBoxes") and script.Parent.IgnoreBoxes.Value)
	print(players)
	print(boxes)
	for _, p in pairs(parts) do
		p.Touched:Connect(function(part)
			if (Players:GetPlayerFromCharacter(part.Parent) == player and players and not p:FindFirstChild("IgnorePlayers"))
				or (part.Name == "Pushbox" and boxes and not p:FindFirstChild("IgnoreBoxes")) then
				local t = p:FindFirstChild("ToggleTime")
				if not p:FindFirstChild("Silent") then
					ding()
				end
				activate((t and t.Value) or tt)
				wait()
			end
		end)
	end
end