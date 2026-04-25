local VT = Ext.Require("Shared/Constants.lua")

local State = {}

local function ensure()
    Mods = Mods or {}
    Mods[VT.MOD_TABLE] = Mods[VT.MOD_TABLE] or {
        SessionLoaded = false,
        OutputText = "",
        IsBusy = false,
        RunCallbackRegistered = false,
        ExportCallbackRegistered = false,
        AllowManagedSettingWrite = false,
        ClientInitialized = false,
        ServerInitialized = false
    }

    return Mods[VT.MOD_TABLE]
end

function State.Get()
    return ensure()
end

function State.MarkSessionLoaded(value)
    ensure().SessionLoaded = value and true or false
end

function State.SetBusy(value)
    ensure().IsBusy = value and true or false
end

function State.SetOutput(text)
    ensure().OutputText = text or ""
end

return State
