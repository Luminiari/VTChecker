local VT = Ext.Require("Shared/Constants.lua")
local State = Ext.Require("Shared/State.lua")
local Util = Ext.Require("Shared/Util.lua")
local Channels = Ext.Require("Shared/Channels.lua")
local Executor = Ext.Require("Shared/Executor.lua")
local MCMUI = Ext.Require("Client/MCMUI.lua")

local Controller = {}
local onRunClicked
local onExportClicked

local function clearSessionState()
    State.MarkSessionLoaded(false)
    State.SetBusy(false)
end

local function updateUi()
    MCMUI.SyncFields()
end

local function ensureUiReady()
    MCMUI.RegisterCallbacks(onRunClicked, onExportClicked)
    updateUi()
end

local function queueExportFeedback(message, feedbackType, durationInMs)
    Ext.OnNextTick(function()
        MCMUI.ShowExportFeedback(message, feedbackType, durationInMs)
    end)
end

local function applyRunResult(response)
    State.SetBusy(false)

    local payload = response or {}
    local output = Util.NormalizeMultiline(payload.Output or "")
    local success = payload.Success == true
    local statusMessage = payload.StatusMessage or (success and "Script completed successfully." or "Script failed.")

    State.SetOutput(output)
    updateUi()

    if success then
        MCMUI.ShowRunFeedback(statusMessage, "success")
    else
        MCMUI.ShowRunFeedback(statusMessage, "error", 8000)
    end
end

local function runClientScript()
    local ok, output, err = Executor.Run("client")
    applyRunResult({
        Success = ok,
        Output = output,
        StatusMessage = ok and "Script completed successfully." or (err or "Script failed.")
    })
end

local function runServerScript()
    Channels.RunScript:RequestToServer({}, function(response)
        applyRunResult(response)
    end)
end

onRunClicked = function()
    local state = State.Get()
    if state.IsBusy then
        return
    end

    if not state.SessionLoaded then
        local message = "Load a save before running the script."
        MCMUI.ShowRunFeedback(message, "warning")
        return
    end

    State.SetBusy(true)
    updateUi()

    local executionContext = Executor.GetExecutionContext()
    if executionContext == "client" then
        runClientScript()
    else
        runServerScript()
    end
end

onExportClicked = function()
    local state = State.Get()
    if not state.SessionLoaded then
        queueExportFeedback("Load a save before exporting output.", "warning")
        return
    end

    if Util.IsBlank(state.OutputText) then
        queueExportFeedback("There is no output to export yet.", "warning")
        return
    end

    local relativePath = Util.BuildRelativeExportPath()
    local saved = Ext.IO.SaveFile(relativePath, state.OutputText)
    local displayPath = Util.BuildAbsoluteExportPath(relativePath)

    if saved then
        local message = "Saved output to " .. displayPath
        queueExportFeedback(message, "success", 8000)
    else
        local message = "Failed to save output to " .. displayPath
        queueExportFeedback(message, "error", 8000)
    end
end

local function registerMcmEventHandlers()
    if not Ext.ModEvents or not Ext.ModEvents.BG3MCM then
        return
    end

    Ext.ModEvents.BG3MCM["MCM_Setting_Saved"]:Subscribe(function(payload)
        if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
            return
        end

        local state = State.Get()
        if state.AllowManagedSettingWrite then
            return
        end

        if payload.settingId == VT.OUTPUT_SETTING_ID then
            Ext.OnNextTick(ensureUiReady)
        end
    end)

    Ext.ModEvents.BG3MCM["MCM_Window_Opened"]:Subscribe(function()
        Ext.OnNextTick(ensureUiReady)
    end)

    Ext.ModEvents.BG3MCM["MCM_Mod_Tab_Activated"]:Subscribe(function(payload)
        if payload and payload.modUUID == ModuleUUID then
            Ext.OnNextTick(ensureUiReady)
        end
    end)
end

local function registerSessionHandlers()
    Ext.Events.SessionLoading:Subscribe(function()
        clearSessionState()
        updateUi()
    end)

    Ext.Events.SessionLoaded:Subscribe(function()
        State.MarkSessionLoaded(true)
        updateUi()
    end)

    Ext.Events.GameStateChanged:Subscribe(function(event)
        local toState = tostring(event and event.ToState or "")
        if toState:find("Menu", 1, true) or toState:find("Unload", 1, true) then
            clearSessionState()
            updateUi()
        end
    end)
end

function Controller.Init()
    local state = State.Get()
    clearSessionState()
    state.OutputText = state.OutputText or ""

    registerSessionHandlers()
    registerMcmEventHandlers()

    Ext.OnNextTick(function()
        ensureUiReady()
    end)
end

return Controller
