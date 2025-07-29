--!strict

export type logData = {
    [number]: string,
    traceback: (boolean | number)?,
    type: ("success" | "error" | "warn" | "info" | "debug" | boolean | number)?,
    printType: ("print" | "warn" | "error" | number)?,
    path: string?,
}

export type Log = (data: logData) -> ()

return nil
