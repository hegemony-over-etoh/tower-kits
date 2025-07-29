--!strict
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

export type logData = {
	[number]: string,
	traceback: (boolean | number)?,
	type: ("success" | "error" | "warn" | "info" | "debug" | boolean | number)?,
	printType: ("print" | "warn" | "error" | number)?,
	path: string?,
}

export type Log = (data: logData) -> ()

return nil
