local tv = script.Parent.TimeVisible.Value
local ti = script.Parent.TimeInvisible.Value
return function()
	local parts = script.Parent:GetDescendants()
	local ot = {}
	for _, p in pairs(parts) do
		if (p.Name == "Memory Platform" and p:IsA'BasePart') then
			ot[p] = p.Transparency
			if p:FindFirstChild("Invert") then
				p.Transparency = 1
			end
		end
	end
	while wait() do
		wait(tv)
		for _, p in pairs(parts) do
			if (p.Name == "Memory Platform" and p:IsA'BasePart') then
				if p:FindFirstChild("Invert") then
					p.Transparency = ot[p]
				else
					p.Transparency = 1
				end
			end
		end
		wait(ti)
		for _, p in pairs(parts) do
			if (p.Name == "Memory Platform" and p:IsA'BasePart') then
				if p:FindFirstChild("Invert") then
					p.Transparency = 1
				else
					p.Transparency = ot[p]
				end
			end
		end
	end
end