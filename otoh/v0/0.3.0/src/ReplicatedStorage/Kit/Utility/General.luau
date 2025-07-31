--!strict
-- junekept 2025
-- this script was originally made for OToH

--[==[
	This module contains methods for general purpose functionality that does not fit in any particular module.
]==]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Kit.Utility.Config)

local General = {}

-- Waits for the update interval as specified in the config module.
function General.waitForUpdateInterval(): number
	if Config.updateOnPreRender then
		return RunService.PreRender:Wait()
	else
		return task.wait(Config.updateInterval)
	end
end

-- Welds two parts together, optionally unachoring the second part.
function General.weld(part0: BasePart, part1: BasePart, unanchor: boolean?): WeldConstraint
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = part0
	weldConstraint.Part1 = part1
	weldConstraint.Parent = part0

	if unanchor then
		part1.Anchored = false
	end

	return weldConstraint
end

-- Creates 2 attachments and sets them to the constraint attachment properties.
function General.populateConstraintAttachments(constraint: Constraint): (Attachment, Attachment)
	local attachment0 = Instance.new("Attachment")
	local attachment1 = Instance.new("Attachment")

	constraint.Attachment0 = attachment0
	constraint.Attachment1 = attachment1

	attachment0.Name = constraint.Name .. "Attachment0"
	attachment1.Name = constraint.Name .. "Attachment1"

	return attachment0, attachment1
end

-- Clone a sound and play it, optionally parenting to a specific location for spatial sound.
function General.cloneAndPlay(sound: Sound, parent: Instance?)
	local clone = sound:Clone()
	clone.Parent = parent or sound.Parent
	clone:Play()
	Debris:AddItem(clone, clone.TimeLength + 0.2)
end

-- Make a number look like an actual timer
function General.beautifyTimerCount(t: number, keepDecimalPastMinute: boolean): string
	local hours = t // 3600
	local minutes = (t % 3600) // 60
	local seconds = t % 60

	local formatted = ""
	if hours > 0 then
		formatted ..= `{hours}h `
	end

	if minutes > 0 then
		formatted ..= `{minutes}m `
	end

	if seconds > 0 then
		formatted ..= `{string.format(if minutes > 0 and not keepDecimalPastMinute then "%d" else "%.1f", seconds)}s`
	end
	
	return formatted
end

return General
