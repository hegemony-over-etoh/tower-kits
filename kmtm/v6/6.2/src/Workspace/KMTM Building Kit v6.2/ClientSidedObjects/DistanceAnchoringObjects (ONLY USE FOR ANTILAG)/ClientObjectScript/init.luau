
return function()
	local defaultDistance = script.DefaultDistance.Value
	local char = game.Players.LocalPlayer.Character
	game.Players.LocalPlayer.CharacterAdded:Connect(function(c)
		char = c --thank you heksi for bringing this line to my attention
	end)
	for _,m in pairs(script.Parent:GetChildren()) do
		if m:IsA("Model") then
			local dynamicTable = {}
			local primary
			for _,p in pairs(m:GetDescendants()) do
				if p:IsA("BasePart") then
					if p.Anchored == true then
						primary = p
					else
						table.insert(dynamicTable,p)
					end
				end
			end
			coroutine.wrap(function()
				while task.wait(.125) do
					if char ~= nil then
						local distance = (char.Torso.Position-primary.Position).magnitude
						local md = (m:FindFirstChild("CustomDistance") ~= nil and m.CustomDistance.Value) or defaultDistance
						for _,d in pairs(dynamicTable) do
							d.Anchored = (distance > md and true) or false
						end
					end
				end
			end)()
		end
	end
end