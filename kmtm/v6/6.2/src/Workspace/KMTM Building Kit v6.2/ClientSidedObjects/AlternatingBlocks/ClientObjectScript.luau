local ts = game:GetService("TweenService")
local plr = game.Players.LocalPlayer
local char = game.Workspace:WaitForChild(plr.Name)
local hum = char:WaitForChild("Humanoid")

return function()
	hum.Jumping:Connect(function(IsJumping: boolean)
		if IsJumping then
			for _, v in pairs(script.Parent:GetChildren()) do --loop through the folder
				if v.Name == "AlternatingBlock" then
					if v.Inverted.Value == true then
						v.CanCollide = true
						
						local t1 = ts:Create(v, TweenInfo.new(0.5), {Transparency = 0})
						t1:Play()
						
						local s1 = ts:Create(v.SelectionBox, TweenInfo.new(0.5), {Color3 = Color3.fromRGB(255,255,255)})
						s1:Play()
						
						v.Inverted.Value = false
					
					elseif v.Inverted.Value == false then
						v.CanCollide = false
						
						local t2 = ts:Create(v, TweenInfo.new(0.5), {Transparency = 0.5})
						t2:Play()
						
						local s2 = ts:Create(v.SelectionBox, TweenInfo.new(0.5), {Color3 = Color3.fromRGB(255, 102, 102)})
						s2:Play()
						
						v.Inverted.Value = true
					end
					
				end
				
			end
			
		end
		
	end)
	
end