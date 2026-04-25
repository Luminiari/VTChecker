local Util = Ext.Require("Shared/Util.lua")
local Script = Ext.Require("Scripts/Script.lua")

local Executor = {}

local function appendLine(buffer, value)
    local line = Util.StringifyValue(value)
    if line ~= "" then
        buffer[#buffer + 1] = line
    end
end

local function buildApi(buffer, contextLabel)
    local api = {
        Context = contextLabel,
        Lines = buffer
    }

    function api.Append(value)
        appendLine(buffer, value)
    end

    function api.AppendMany(...)
        appendLine(buffer, Util.JoinPrintableArgs(...))
    end

    function api.Write(...)
        appendLine(buffer, Util.JoinPrintableArgs(...))
    end

    function api.Dump(value)
        appendLine(buffer, Util.StringifyValue(value))
    end

    function api.GetOutput()
        return Util.NormalizeMultiline(table.concat(buffer, "\n"))
    end

    return api
end

local function capturePrinter(buffer, original)
    return function(...)
        appendLine(buffer, Util.JoinPrintableArgs(...))

        if type(original) == "function" then
            pcall(original, ...)
        end
    end
end

function Executor.Run(contextLabel)
    local script = Script or {}
    if type(script) ~= "table" or type(script.Run) ~= "function" then
        local message = "Scripts/Script.lua must return a table with a Run(api) function."
        return false, message, message
    end

    local buffer = {}
    local api = buildApi(buffer, contextLabel or "server")

    local originalPrint = print
    local originalP = _P
    local originalD = _D

    print = capturePrinter(buffer, originalPrint)
    _P = capturePrinter(buffer, originalP)
    _D = capturePrinter(buffer, originalD)

    local ok, resultOrError = xpcall(function()
        return script.Run(api)
    end, debug.traceback)

    print = originalPrint
    _P = originalP
    _D = originalD

    if ok then
        if resultOrError ~= nil and resultOrError ~= buffer then
            appendLine(buffer, resultOrError)
        end

        local output = Util.NormalizeMultiline(table.concat(buffer, "\n"))
        if output == "" then
            output = "Script finished without producing any output."
        end

        return true, output, nil
    end

    appendLine(buffer, resultOrError)

    local failedOutput = Util.NormalizeMultiline(table.concat(buffer, "\n"))
    if failedOutput == "" then
        failedOutput = tostring(resultOrError)
    end

    return false, failedOutput, tostring(resultOrError)
end

function Executor.GetExecutionContext()
    local executionContext = type(Script) == "table"
        and type(Script.ExecutionContext) == "string"
        and string.lower(Script.ExecutionContext)
        or "server"

    if executionContext ~= "client" then
        executionContext = "server"
    end

    return executionContext
end

return Executor
