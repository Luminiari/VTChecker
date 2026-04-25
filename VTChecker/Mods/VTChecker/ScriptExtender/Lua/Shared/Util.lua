local VT = Ext.Require("Shared/Constants.lua")

local Util = {}

local JSON_OPTIONS = {
    Beautify = true,
    AvoidRecursion = true,
    IterateUserdata = true,
    StringifyInternalTypes = true,
    MaxDepth = 16
}

local function tryJsonStringify(value)
    local ok, result = pcall(Ext.Json.Stringify, value, JSON_OPTIONS)
    if ok and type(result) == "string" and result ~= "" then
        return result
    end

    return nil
end

function Util.StringifyValue(value)
    local valueType = type(value)

    if value == nil then
        return "nil"
    end

    if valueType == "string" then
        return value
    end

    if valueType == "number" or valueType == "boolean" then
        return tostring(value)
    end

    if valueType == "table" then
        local lines = {}
        local isList = true

        for key, entry in pairs(value) do
            if type(key) ~= "number" then
                isList = false
                break
            end

            lines[key] = Util.StringifyValue(entry)
        end

        if isList and #value > 0 then
            return table.concat(lines, "\n")
        end

        return tryJsonStringify(value) or tostring(value)
    end

    return tryJsonStringify(value) or tostring(value)
end

function Util.JoinPrintableArgs(...)
    local parts = {}

    for i = 1, select("#", ...) do
        parts[#parts + 1] = Util.StringifyValue(select(i, ...))
    end

    return table.concat(parts, "\t")
end

function Util.NormalizeMultiline(text)
    local normalized = tostring(text or "")
    normalized = normalized:gsub("\r\n", "\n"):gsub("\r", "\n")

    while normalized:find("\n\n\n", 1, true) do
        normalized = normalized:gsub("\n\n\n", "\n\n")
    end

    return normalized
end

function Util.IsBlank(text)
    return text == nil or tostring(text) == ""
end

function Util.BuildRelativeExportPath()
    return VT.EXPORT_FILENAME
end

function Util.BuildAbsoluteExportPath(relativePath)
    return string.format(
        "%%LOCALAPPDATA%%\\Larian Studios\\Baldur's Gate 3\\Script Extender\\%s",
        tostring(relativePath or ""):gsub("/", "\\")
    )
end

return Util
