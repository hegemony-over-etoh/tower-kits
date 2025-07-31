local DamageEvent = game:GetService("ReplicatedStorage").DamageEvent
local HealEvent = game:GetService("ReplicatedStorage").HealEvent
local DebounceArray = {}

local types={
	Normal=5,
	DoubleDamage=10,
	HighDamage=20,
	Instakill=math.huge, --scary number
}
local healtypes = {
	WeakHeal = 5,
	StrongHeal = 20,
	FullHeal = 100
}

DamageEvent.OnServerEvent:Connect(function(Player,Type)
	if DebounceArray[Player.Name] then return end
	DebounceArray[Player.Name] = true
	local char = Player.Character
	if char ~= nil then
		local Humanoid = char:WaitForChild("Humanoid")
		if tonumber(Type) ~= nil then
			Humanoid:TakeDamage(Type)
		else
			Humanoid:TakeDamage(types[Type] or types.Normal)
		end
		wait(0.05) 
		DebounceArray[Player.Name] = nil
	end
end)

HealEvent.OnServerEvent:Connect(function(Player,Type)
	if DebounceArray[Player.Name] then return end
	DebounceArray[Player.Name] = true
	local char = Player.Character
	if char ~= nil then
		local Humanoid = char:WaitForChild("Humanoid")
		if tonumber(Type) ~= nil then
			if (Humanoid.Health + Type) >= 100 then
				Humanoid.Health = 100
			else
				Humanoid.Health += Type
			end
		else
			if (Humanoid.Health + (healtypes[Type] or healtypes.WeakHeal)) >= 100 then
				Humanoid.Health = 100
			else
				Humanoid.Health += (healtypes[Type] or healtypes.WeakHeal)
			end
		end
		wait(0.05) 
		DebounceArray[Player.Name] = nil
	end
end)