local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local process = require("@lune/process")

local Enum: typeof(Enum) = (roblox :: any).Enum

local CONTAINER_CLASSES = {
	Folder = true,
	Model = true,
	StarterPlayerScripts = true,
	StarterCharacterScripts = true,
}

local function getParentsToExport(instance: roblox.DataModel): { roblox.Instance }
	return {
		instance:GetService("Workspace"),
		instance:GetService("StarterPack"),
		instance:GetService("StarterGui"),
		instance:GetService("ServerScriptService"),
		instance:GetService("ReplicatedStorage"),
		instance:GetService("StarterPlayer"),
	}
end

local delimiter = if process.os == "windows" then "\\" else "/"
local function path(...: string)
	return table.concat({ ... }, delimiter)
end

local function extractInstances(instances: { roblox.Instance }, baseDir: string)
	for _, inst in instances do
		if CONTAINER_CLASSES[inst.ClassName] then
			local children = inst:GetChildren()
			if #children == 0 then
				continue
			end
			local dir = path(baseDir, inst.Name)
			fs.writeDir(dir)
			extractInstances(inst:GetChildren(), dir)
		elseif inst:IsA("LuaSourceContainer") then
			local fileExtension = if inst.ClassName == "Script"
				then if (inst :: any).RunContext == Enum.RunContext.Client then ".client.luau" else ".server.luau"
				elseif inst.ClassName == "LocalScript" then ".client.luau"
				else ".luau"
			fs.writeFile(path(baseDir, `{inst.Name}{fileExtension}`), (inst :: any).Source)
		else
			fs.writeFile(path(baseDir, `{inst.Name}.rbxm`), roblox.serializeModel({ inst }))
		end
	end
end

local function extract(game: roblox.DataModel, outputDir: string)
	local srcDir = path(outputDir, "src")
	pcall(fs.removeDir, srcDir)
	fs.writeDir(srcDir)

	local workspace = game:GetService("Workspace")
	local camera = workspace:FindFirstChildOfClass("Camera")
	local terrain = workspace:FindFirstChildOfClass("Terrain")

	local removed: { roblox.Instance } = {
		camera,
		terrain,
	} :: any

	for _, parent in getParentsToExport(game) do
		print("> Processing parent", parent.Name)
		local instances = parent:GetChildren()

		for _, toRemove in removed do
			local index = table.find(instances, toRemove)
			if index then
				table.remove(instances, index)
			end
		end

		if #instances == 0 then
			print(">> No instances found, skipping")
			continue
		end

		local parentDir = path(srcDir, parent.Name)
		fs.writeDir(parentDir)

		extractInstances(instances, parentDir)
	end
end

if #process.args == 0 then
	print("Extracts the `place.rbxl` in a directory and outputs it to a `src` directory")
	print("Usage: lune run extract [DIRS...]")
else
	for _, dir in process.args do
		print("Processing", dir)
		local outputDir = path(process.cwd, dir)
		extract(roblox.deserializePlace(fs.readFile(path(outputDir, "place.rbxl"))), outputDir)
	end
end
