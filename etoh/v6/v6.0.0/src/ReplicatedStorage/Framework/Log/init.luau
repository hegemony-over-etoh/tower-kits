--!strict
-- By @synnwave (30/11/24 DD/MM/YY)

--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local _TDefs = require(script.TypeDefs)

local startTypes = {
	[1] = "success",
	[2] = "error",
	[3] = "warn",
	[4] = "info",

	[false] = "error",
	[true] = "success",

	success = "success",
	error = "error",
	warn = "warn",
	info = "info",
	debug = "info",
} :: {
	[number | boolean | string]: string,
}

local tagEmojis = {
	success = `✅`,
	error = `❎`,
	warn = `⚠️`,
	info = `ℹ️`,
}

local printTypes = {
	[1] = print,
	[2] = warn,
	[3] = error,

	print = print,
	warn = warn,
	error = function(str)
		error(str, 0)
	end,
} :: {
	[number | string]: (string) -> (),
}

return function(data: _TDefs.logData)
	local emoji: string = tagEmojis[startTypes[data.type or 4]]
	local scriptCaller: string, scriptLine: number, functionName: string? =
		debug.info(tonumber(data.traceback) or 2, "sln")

	if data.path then
		scriptCaller = data.path
	else
		local isFrameworkScript = scriptCaller:find("ReplicatedStorage%.Framework") ~= nil
		if isFrameworkScript then
			scriptCaller = scriptCaller:gsub("ReplicatedStorage%.", "")
		else
			local locations = scriptCaller:split(".")
			scriptCaller = locations[#locations] or "[?]"
		end
	end

	local startingString = `{emoji} {scriptCaller}`
	if data.traceback then
		startingString ..= `{if functionName ~= "" then `.{functionName}()` else ""} #{scriptLine}`
	end

	local newStr = ""
	for i, currentStr in ipairs(data) do
		newStr ..= `{if i ~= 1 then "\n" else ""}{currentStr}`
	end

	newStr = newStr:gsub("[^\n]+", function(currentString: string)
		return `\t\t\t > {currentString}`
	end)

	local printFn: any = printTypes[(data.printType or data.type) :: any] or print -- or print
	printFn(`[{startingString}]:\n{newStr}`)
end
