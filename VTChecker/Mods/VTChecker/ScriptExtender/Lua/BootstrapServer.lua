local Channels = Ext.Require("Shared/Channels.lua")
local Runner = Ext.Require("Server/Runner.lua")
local State = Ext.Require("Shared/State.lua")

local state = State.Get()
if not state.ServerInitialized then
    state.ServerInitialized = true

    local function isPlayableGameState(stateName)
        local stateNameLower = tostring(stateName or ""):lower()
        return stateNameLower:find("running", 1, true) ~= nil
            or stateNameLower:find("pause", 1, true) ~= nil
            or stateNameLower:find("dialog", 1, true) ~= nil
    end

    local function isNonPlayableGameState(stateName)
        local stateNameLower = tostring(stateName or ""):lower()
        return stateNameLower:find("menu", 1, true) ~= nil
            or stateNameLower:find("load", 1, true) ~= nil
            or stateNameLower:find("unload", 1, true) ~= nil
    end

    Ext.Events.SessionLoading:Subscribe(function()
        State.MarkSessionLoaded(false)
        State.SetBusy(false)
    end)

    Ext.Events.SessionLoaded:Subscribe(function()
        State.MarkSessionLoaded(true)
    end)

    Ext.Events.GameStateChanged:Subscribe(function(event)
        local toState = tostring(event and event.ToState or "")
        if isNonPlayableGameState(toState) then
            State.MarkSessionLoaded(false)
            State.SetBusy(false)
        elseif isPlayableGameState(toState) then
            State.MarkSessionLoaded(true)
        end
    end)

    Channels.RunScript:SetRequestHandler(function(payload, user)
        return Runner.Run(user, payload)
    end)
end
