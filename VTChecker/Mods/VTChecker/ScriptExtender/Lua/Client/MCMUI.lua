local VT = Ext.Require("Shared/Constants.lua")
local State = Ext.Require("Shared/State.lua")
local Util = Ext.Require("Shared/Util.lua")

local MCMUI = {}

local function hasMCM()
    return MCM
        and MCM.Set
        and MCM.EventButton
        and MCM.EventButton.RegisterCallback
        and MCM.EventButton.SetDisabled
        and MCM.EventButton.ShowFeedback
end

local function setManagedSetting(settingId, value)
    if not hasMCM() then
        return false
    end

    local state = State.Get()
    state.AllowManagedSettingWrite = true
    local ok = pcall(MCM.Set, settingId, value or "", ModuleUUID, false)
    state.AllowManagedSettingWrite = false
    return ok
end

function MCMUI.RegisterCallbacks(runHandler, exportHandler)
    if not hasMCM() then
        return false
    end

    local state = State.Get()

    if not state.RunCallbackRegistered then
        state.RunCallbackRegistered = MCM.EventButton.RegisterCallback(VT.RUN_BUTTON_ID, runHandler, ModuleUUID) and true or false
    end

    if not state.ExportCallbackRegistered then
        state.ExportCallbackRegistered = MCM.EventButton.RegisterCallback(VT.EXPORT_BUTTON_ID, exportHandler, ModuleUUID) and true or false
    end

    return state.RunCallbackRegistered and state.ExportCallbackRegistered
end

function MCMUI.RefreshButtons()
    if not hasMCM() then
        return false
    end

    local state = State.Get()
    local runDisabled = state.IsBusy or not state.SessionLoaded
    local exportDisabled = state.IsBusy or not state.SessionLoaded or Util.IsBlank(state.OutputText)

    MCM.EventButton.SetDisabled(VT.RUN_BUTTON_ID, runDisabled, "", ModuleUUID)
    MCM.EventButton.SetDisabled(VT.EXPORT_BUTTON_ID, exportDisabled, "", ModuleUUID)
    return true
end

function MCMUI.SyncFields()
    local state = State.Get()
    setManagedSetting(VT.OUTPUT_SETTING_ID, Util.NormalizeMultiline(state.OutputText or ""))
    MCMUI.RefreshButtons()
end

function MCMUI.ShowRunFeedback(message, feedbackType, durationInMs)
    if not hasMCM() then
        return false
    end

    return MCM.EventButton.ShowFeedback(VT.RUN_BUTTON_ID, message, feedbackType, ModuleUUID, durationInMs or 5000)
end

function MCMUI.ShowExportFeedback(message, feedbackType, durationInMs)
    if not hasMCM() then
        return false
    end

    return MCM.EventButton.ShowFeedback(VT.EXPORT_BUTTON_ID, message, feedbackType, ModuleUUID, durationInMs or 5000)
end

return MCMUI
